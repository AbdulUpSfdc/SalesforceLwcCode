public without sharing class DaysToClose {
        
     public static final String CASE_MERGED_STATUS = CaseConstants.CASE_STATUS_MERGED;
     public static final String CASE_STATUS_CANCELLED = CaseConstants.CASE_STATUS_CANCELLED;     
    // count of current or recently closed (120 days) non-child Cases for the same customer 
    @AuraEnabled 
    public static Integer countOpenCasesForSameCustomer(String accountName, Id currentCaseId, Id caseBillingAcctId) {
        Integer caseCount = 0;
        Date closeDate = Date.today().addDays(-Integer.valueOf(System.Label.Opp_Case_Days_to_Close.trim()));   
        
        Set<Id> caseOppRecordTypeIds = getOppRecordTypes();
        
        if(String.isNotBlank(accountName)) {
            caseCount = [SELECT count() FROM Case 
                         WHERE ParentId = NULL AND RecordTypeId IN :caseOppRecordTypeIds 
                         AND (ClosedDate = NULL OR ClosedDate >=: closeDate )
                         AND (Status != :CASE_STATUS_CANCELLED   AND Status != :CASE_MERGED_STATUS)
                         AND Billing_Account__c != NULL AND Billing_Account__c = :caseBillingAcctId
                         AND Id != :currentCaseId];
         }
        //AND Account.Name = :accountName 
        return caseCount;
    }
    
    
    
    //retrieve billingaccts with case counts for initial case assignment -- used at OOP creation (FROM TRIGGER)
    public static Map<Id,Integer> getBillingAcctCasesCount(Set<Id> billAccts) {
        
        Date closeDate = Date.today().addDays(-Integer.valueOf(System.Label.Opp_Case_Days_to_Close.trim()));
        Id OOPRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(CaseConstants.OOP_RECORD_TYPE).getRecordTypeId();
        
        List<Billing_Account__c> billAcctslst = new List<Billing_account__c>([SELECT Id, Billing_Account_Number__c, 
                                                                                (SELECT Id, CaseNumber, ParentId, ClosedDate, Status FROM Cases__r
                                                                                 WHERE ParentId = NULL
                                                                                     AND (ClosedDate = NULL OR ClosedDate >=: closeDate)
                                                                                     AND (Status != :CASE_STATUS_CANCELLED AND Status != :CASE_MERGED_STATUS)
                                                                                     AND RecordType.Name = :CaseConstants.OOP_RECORD_TYPE ) FROM Billing_Account__c 
                                                                                WHERE Id IN :billAccts]);
        Map<Id,List<Case>> billAcctCasesMap = new Map<Id,List<Case>>();   
        Map<Id,Integer> billAcctCasesCount = new Map<Id,Integer>(); 
                                                                                
        if(billAcctslst.size()>0){
            for(Billing_Account__c ba : billAcctslst){
                if(ba.Cases__r.size()>1){
                    billAcctCasesMap.put(ba.Id,ba.Cases__r); 
                    billAcctCasesCount.put(ba.Id,ba.Cases__r.size());
                }
            }
        }
            
        return billAcctCasesCount;
        
        
    }
    
    
    
    //retrieve billingaccts with case counts for OOP case assignment -- used at OOP case update (FROM FLOW # OOP Case Assign Queue)
    @InvocableMethod
    public static List<String> getRelatedOOPCasesCount(List<Id> caseIds) {
        
        List<String> returnlst = new List<String>();
        
        
        Date closeDate = Date.today().addDays(-Integer.valueOf(System.Label.Opp_Case_Days_to_Close.trim()));
        Id OOPRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(CaseConstants.OOP_RECORD_TYPE).getRecordTypeId();
                
        Set<Id> billAccts = new Set<Id>();
        
        List<Case> caselst = new List<Case>([Select Id,Billing_Account__c,Priority,Product__c,OwnerId,Send_to_Intake_Queue__c,Product_Type_OOP__c,SubmissionSourceCode__c,//CustomerType__c,
                                             Origin,ServiceEmail__c,ServicePhone__c,Description,
                                             ServiceCustFirstName__c,ServiceCustLastName__c,StreetName__c,City__c,State__c,ZipPostalCode__c from Case where Id = :caseIds]);
        
        if(caselst.size()>0){
            for(Case c: caselst){
                if(String.isNotBlank(c.Billing_Account__c)){
                    billAccts.add(c.Billing_Account__c);
                }
            }
            
            if(billAccts.size()>0){
                List<Billing_Account__c> billAcctslst = new List<Billing_account__c>([SELECT Id, Billing_Account_Number__c, 
                                                                                        (SELECT Id, CaseNumber, ParentId, ClosedDate, Status FROM Cases__r
                                                                                         WHERE ParentId = NULL
                                                                                             AND (ClosedDate = NULL OR ClosedDate >=: closeDate)
                                                                                             AND (Status != :CASE_STATUS_CANCELLED AND Status != :CASE_MERGED_STATUS)
                                                                                             AND RecordType.Name = :CaseConstants.OOP_RECORD_TYPE ) FROM Billing_Account__c 
                                                                                        WHERE Id IN :billAccts]);
                Map<Id,List<Case>> billAcctCasesMap = new Map<Id,List<Case>>();   
                Map<Id,Integer> billAcctCasesCount = new Map<Id,Integer>(); 
                                                                                        
                if(billAcctslst.size()>0){
                    for(Billing_Account__c ba : billAcctslst){
                        if(ba.Cases__r.size()>1){
                            returnlst.add(CaseConstants.CASE_RELATED_OOPCASES_EXIST);
                        }
                        else{returnlst.add(CaseConstants.CASE_RELATED_NO_OOPCASES_EXIST);}
                    }
                }    
            }
            else{returnlst.add(CaseConstants.CASE_RELATED_NO_OOPCASES_EXIST);}
            
        }
        else{returnlst.add(CaseConstants.CASE_RELATED_NO_OOPCASES_EXIST);}
          
        return returnlst;
        
    }
    
    
    //retrieve all recordtype ids for OOP 
    public static Set<Id> getOppRecordTypes() {
        
        Map<String,RecordType> recordTypeMap = MetadataSelector.caseRecordTypeToDeveloperName_Map;
        Set<Id> oppRecordTypesId = new Set<Id>();
        if(recordTypeMap.size()>0){
            for(String rt : recordTypeMap.keySet()){
                if(rt == CaseConstants.OOP_RECORD_TYPE || rt == CaseConstants.OOP_READ_ONLY_RECORD_TYPE || rt == CaseConstants.OOP_CLOSED_READ_ONLY_RECORD_TYPE || rt == CaseConstants.OOP_FIELD_RECORD_TYPE || 
                    rt == CaseConstants.OOP_RESPONSE_RECORD_TYPE || rt == CaseConstants.OOP_FIELD_READ_ONLY_RECORD_TYPE || rt == CaseConstants.OOP_RESPONSE_READ_ONLY_RECORD_TYPE){
                        oppRecordTypesId.add(recordTypeMap.get(rt).Id);
                    }
            }
        }
        
        return oppRecordTypesId;
    
    }
    
}