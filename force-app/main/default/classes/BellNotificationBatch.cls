/**
 * @description       : Batch class to Handle Bell Notification for the Bulk Leads
 * @author            : madhava Allam
 * @created Date      : 06-07-2021
 * @JIRA NO           : SPTSLSATT-15                        
**/
global without sharing class BellNotificationBatch implements Database.Batchable<SObject>, Database.Stateful{
    
    static final string RETAIL_SM = 'Retail SM';
    public Map<String,Integer> leadsCountMap = new Map<String,Integer>();
    public Map<String,String> mapIdLocation = new Map<String,String>();
    public Map<String,set<String>> mapUserIds = new Map<String,set<String>>();
    /**
     * @description:   Start method for the batch
     */
    public Database.QueryLocator start(Database.BatchableContext BC){
        string query;
        if(Test.isRunningTest() ){
            query = 'Select Id,Store__c,Store__r.Name,LeadSource from Lead where Store__c != null';
        }
        else {
            query = 'Select Id,Store__c,Store__r.Name,LeadSource from Lead where (LeadSource = \'Campaign\' OR ' 
                        +'(LeadSource = \'Business\' AND Recordtype.Name = \'Small Business\')) '
                        +'AND DAY_ONLY(CreatedDate) = TODAY AND Store__c != null';
        }
        return Database.getQueryLocator(query);
    }
    /**
     * @description:   Execute method for the batch
     */
    public void execute(Database.BatchableContext ctx, List<Lead> leadsList) {
        Integer count = 0;
        set<Id> storeIds = new set<Id>();
        for(Lead objL:leadsList){
            if(leadsCountMap.containsKey(objL.Store__c+'_'+objL.LeadSource)) {
                count = leadsCountMap.get(objL.Store__c+'_'+objL.LeadSource)+1;
                leadsCountMap.put(objL.Store__c+'_'+objL.LeadSource,count);
            }  
            else {
                leadsCountMap.put(objL.Store__c+'_'+objL.LeadSource, 1);
                mapIdLocation.put(objL.Store__c,objL.Store__r.Name);
                storeIds.add(objL.Store__c);
            }
        }
        
        for(Employee__c objE:[select id,User__c,HomeStoreLocation__c from Employee__c where User__r.profile.name =: RETAIL_SM 
                                and HomeStoreLocation__c in:storeIds AND User__c != null]){
                                    
            if(mapUserIds.containsKey(objE.HomeStoreLocation__c) && mapUserIds.get(objE.HomeStoreLocation__c) != null) {
                mapUserIds.get(objE.HomeStoreLocation__c).add(objE.User__c);
            }   
            else {
                mapUserIds.put(objE.HomeStoreLocation__c, new set<String> {objE.User__c});
            }
        }
    }

    /**
     * @description:   Finish method for the batch
     */
    public void finish(Database.BatchableContext ctx) { 
        SendBellNotificationBatch batchInst = new SendBellNotificationBatch();
        batchInst.leadsCountMap = leadsCountMap;
        batchInst.mapIdLocation = mapIdLocation;
        batchInst.mapUserIds = mapUserIds;
        Database.executeBatch(batchInst);
                
    }

}