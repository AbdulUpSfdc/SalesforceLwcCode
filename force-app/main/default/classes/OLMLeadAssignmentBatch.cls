/******************************************************************************************************
* @Class Name   : OLMLeadAssignmentBatch
* @Version      : 1.0
* @Created Date : 9-16-2021
* @Description  : This class is used to process Interaction Lead records submitted by store agents that will need to be reassign to care agents
* @Author       : Accenture
*
* Change Log:
* Date               Owner                          Description
* ============================================================================================================
* 9-13-2021          Soumitra (sc578a)              Initial Version
*
*
*******************************************************************************************************/
global class OLMLeadAssignmentBatch implements Database.Batchable<sObject> {

    /*
     * This method fetches the relevant Lead data to be processed 
    */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        Date expired = Date.Today().addDays(-3);
        String query =  'SELECT id,Owner__c, Owner__r.ATTUID__c,ExpiryDate__c FROM Lead WHERE CustomerType__c=\'New Customer\' AND LocationType__c !=\'IN-HOME EXPERTS\' AND LeadSource =\'Customer Interaction\' AND Status =\'CAPTURED\' AND (SmsConsent__c =\'YES\' AND CallConsent__c =\'YES\') AND Store__r.MarketGroup__c in (\'FLORIDA\',\'MID-ATLANTIC STATES\') AND store__r.ChannelType__c =\'company\' AND ExpiryDate__c =:expired';
        return Database.getQueryLocator(query);
    }

    /*
     * This method performs the Lead Redistribution
    */
    global void execute(Database.BatchableContext BC, List<Lead> leadList) {
        List<EmployeeStoreRetail__c> esr = new List<EmployeeStoreRetail__c>();
        Map<String, Integer> employeeLeadCount = new Map<String, Integer>();
        List<Lead> leadownerChange = new List<Lead>();
        
        List<String> virtualStoreList = RetailConstants.virtual_store.split(',');
        List<String> Care_Mgr_List=RetailConstants.Care_MGR.split(',');

        esr = [select id,user__c from employeestoreRetail__c where store__r.locationid__c in :virtualStoreList and employee__r.employeeId__c in :Care_Mgr_List and employee__r.isactive__c=true];
        
        for(EmployeeStoreRetail__c e : esr){
            employeeLeadCount.put(e.user__c, 0);
        }
        
        leadownerChange = OLMLeadUtil.reassignLeads(leadList, employeeLeadCount); 
        
        try{
           update leadownerChange;
        }
        
        catch(exception e){
            System.debug('update failed due to the error : '+ e.getMessage());
        }
    }
    
    /*
     * This method sends a batch status email if the same is configured in the custom setting
    */
    public void finish(Database.BatchableContext BC) {}
  
}