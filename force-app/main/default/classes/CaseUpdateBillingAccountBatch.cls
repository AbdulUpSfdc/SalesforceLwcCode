/* ================================================
* @class name: CaseUpdateBillingAccountBatch 
* @author: Salesforce Inc.
* @purpose: batch class to update billing account on cases 
* @created date (mm/dd/yyyy) :  03/24/2021
* @Database.executeBatch(new CaseUpdateBillingAccountBatch(),5);
//ha623y	04/29/2021	Updated class to without sharing.
================================================*/ 


global without sharing class CaseUpdateBillingAccountBatch implements Database.Batchable<sObject>, Database.Stateful {
    private String query;
    
    
    global CaseUpdateBillingAccountBatch (){
        
       query = 'SELECT ID,ParentId,AccountIdentifier__c,Billing_Account__c FROM Case where Billing_Account__c = Null ORDER BY CreatedDate ASC';
       
    }
    
    // The batch job starts
    global Database.Querylocator start(Database.BatchableContext bc){        
        return Database.getQuerylocator(query);
    } 
    
    // The batch job executes and operates on one batch of records
    global void execute(Database.BatchableContext bc, List<Case> scope){
        
        Set<Id> parentCaseIds = new Set<Id>();
        List<String> acctidentiferslst = new List<String>();
        Map<Id,Case> casesAcctIdentifiers = new Map<Id,Case>();
        Map<Id,Case> casesRelatedParentId = new Map<Id,Case>();
        
        Map<Id,Case> retrieveParentCases = new Map<Id,Case>();
        
        List<Case> updateCaselst = new List<Case>();
        
        for(Case c:scope){
            if(String.isNotBlank(c.AccountIdentifier__c)){
                acctidentiferslst.add(c.AccountIdentifier__c);   
                casesAcctIdentifiers.put(c.Id,c);             
            } 
            else if(String.isNotBlank(c.ParentId)){
                parentCaseIds.add(c.Id);
                casesRelatedParentId.put(c.Id,c);
            }   
        }
        
        if(parentCaseIds.size()>0){
            retrieveParentCases = new Map<Id,Case>([SELECT Id,ParentId,AccountIdentifier__c,Billing_Account__c FROM Case where Id IN :parentCaseIds]);
            if(retrieveParentCases.size()>0){
                for(Case parentCase : retrieveParentCases.values()){
                    if(String.isNotBlank(parentCase.AccountIdentifier__c)){
                        acctidentiferslst.add(parentCase.AccountIdentifier__c); 
                    } 
                }
            }
        }
        
        if(acctidentiferslst.size()>0){
            Map<Id,Billing_Account__c> getBillAccts = new Map<Id,Billing_Account__c>([SELECT id, Billing_Account_Number__c, CreatedDate FROM Billing_Account__c WHERE Billing_Account_Number__c IN :acctidentiferslst
                                                                                    Order by CreatedDate desc]);
            
            Map<String,Billing_Account__c> customerAcctRelatedBillAcct = new Map<String,Billing_Account__c>();
            
            if(getBillAccts.size()>0){
                for(Billing_Account__c b:getBillAccts.values()){
                    if((customerAcctRelatedBillAcct.size()>0 && !customerAcctRelatedBillAcct.containsKey(b.Billing_Account_Number__c)) || customerAcctRelatedBillAcct.size()==0){
                        customerAcctRelatedBillAcct.put(b.Billing_Account_Number__c,b);
                    }
                }
                
                if(casesAcctIdentifiers.size()>0){
                    for(Case c : casesAcctIdentifiers.values()){
                        if(customerAcctRelatedBillAcct.containsKey(c.AccountIdentifier__c)){
                            c.Billing_Account__c = customerAcctRelatedBillAcct.get(c.AccountIdentifier__c).Id;
                            updateCaselst.add(c);
                        } 
                    }
                    
                    for(Case pc : casesRelatedParentId.values()){
                        if(retrieveParentCases.size()>0 && retrieveParentCases.containsKey(pc.ParentId)){
                            if(String.isNotBlank(retrieveParentCases.get(pc.ParentId).Billing_Account__c)){
                                pc.Billing_Account__c = retrieveParentCases.get(pc.ParentId).Billing_Account__c;
                                updateCaselst.add(pc);
                            }
                            else if(String.isNotBlank(retrieveParentCases.get(pc.ParentId).AccountIdentifier__c) && customerAcctRelatedBillAcct.containsKey(retrieveParentCases.get(pc.ParentId).AccountIdentifier__c)){
                                pc.Billing_Account__c = customerAcctRelatedBillAcct.get(retrieveParentCases.get(pc.ParentId).AccountIdentifier__c).Id;
                                updateCaselst.add(pc);
                            }
                        }  
                    }
                    
                    
                }
                
            }
            
        }
        
        if(updateCaselst.size()>0){
            update updateCaselst;
        }
        
        
        
    }
    
    // The batch job finishes
    global void finish(Database.BatchableContext bc) {
        
    }
    
    
}