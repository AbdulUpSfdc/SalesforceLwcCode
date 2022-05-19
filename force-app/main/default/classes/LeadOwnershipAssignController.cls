/*
* This class is called on the quick action-accept on leads to enable reps to self assign prospects
* Author: Rashmi Thippeswamy
*/
public without sharing class LeadOwnershipAssignController {
    public static final String Reatil_Cons ='Eval_Address_Doctor_Valid_Statuses';
/*
* This method is called on the quick action-accept on leads which changes the recordtype from 
*Prospect-business to SMB and owner = unassigned queue and lead store to the user's home store
*/
    private static  Lead lead=new Lead();
    @AuraEnabled
    public static void manageProspectConversion(Id leadId){
        System.debug('***** leadId '+leadId);
        if(leadId <> NULL){
            List<Lead> lstLead = new List<Lead>();
            lstLead = [SELECT id,OwnerId,RecordTypeId,Store__c,City,PostalCode,State FROM Lead WHERE id=:leadId WITH SECURITY_ENFORCED];
            if(!lstLead.isEmpty()){
                assignLoginUserAsOwner(lstLead[0]); 
                changeRecordType(lstLead[0]);
                assignHomeStore(lstLead[0]);
                System.debug('****** lstLead '+lstLead[0]);
                // Accepted_Lead__c acpL = new Accepted_Lead__c(Name=leadId);
                //insert acpL;
                LeadConsent__c Leadconsent = new LeadConsent__c();
                Leadconsent.LeadId__c=leadId;
                Leadconsent.City__c=lstLead[0].City;
                Leadconsent.State__c=lstLead[0].State;
                Leadconsent.Type__c =  RetailConstants.LEAD_CONSENT_TYPE;
                if(lstLead[0].PostalCode != null){
                    Leadconsent.Zip__c=lstLead[0].PostalCode.substring(0,5);
                }                
                insert Leadconsent;
                update lstLead[0];
            }
        }
    }
 /*
* This method would perform Lead Owner assignment to Current logged in user
*/
    private static void assignLoginUserAsOwner(Lead lead){
        lead.OwnerId = RetailConstants.RETAILLEADOWNERQUEUE; //updates for public sharing group
        lead.Owner__c = UserInfo.getUserId();
    }
 /*
* This method would change the record type from Prospect-Business to Small Business
*/
    private static void changeRecordType(Lead lead){
        Id businessTypeId = TriggerHelper.getRecordTypeIdFromName('Small_Business', 'Lead');
        System.debug('****** businessTypeId '+businessTypeId);
        if(businessTypeId <> NULL){
            lead.RecordTypeId = businessTypeId;
        }
    }
/*
* This method shall assign home store location of the logged in user to the lead store
*/
    private static void assignHomeStore(Lead lead){
        String strStore = StoreController.getStoreFromCache();
        if(String.isNotBlank(strStore)){
            lead.Store__c = strStore;
        }
        else{
            List<Employee__c> lstEmp = new List<Employee__c>();
            lstEmp = [SELECT id,User__c,HomeStoreLocation__c FROM Employee__c 
                            WHERE User__c =:UserInfo.getUserId() 
                            AND UserIsActive__c = true AND HomeStoreLocation__c!=NULL WITH SECURITY_ENFORCED LIMIT 1];
            if(!lstEmp.isEmpty()){
                lead.Store__c = lstEmp[0].HomeStoreLocation__c;
            }
        }
    }
}