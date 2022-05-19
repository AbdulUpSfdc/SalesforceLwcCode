/**
* @description       : Batch class to send Bell Notification for the Bulk Leads unread messages
* @author            : Abdul Khan
* @JIRA NO           : SPTSLSATT-42                      
**/
global without sharing class UnrespondedSMSNotificationBatch implements Database.Batchable<SObject>, Database.Stateful, schedulable{
    
    static final string RETAIL_SM = 'Retail SM';
    public Map<String,Integer> leadsCountMap = new Map<String,Integer>();
    public Map<String,Set<String>> mapIdOwner = new Map<String,Set<String>>();
    public Map<String,Set<String>> mapCustomerName = new Map<String,Set<String>>();
    public Map<String,set<String>> mapUserIds = new Map<String,set<String>>();
    
    public void execute(schedulablecontext sc){
        UnrespondedSMSNotificationBatch notification = new UnrespondedSMSNotificationBatch();
        database.executeBatch(notification);
    }
    /**
* @description:   Start method for the batch
*/
    public Database.QueryLocator start(Database.BatchableContext BC){
        string query;
         DateTime currentTime = DateTime.Now().addHours(-24);

        if(Test.isRunningTest() ){
            query = 'Select id,Lead__r.Name,Lead__r.OwnerFullName__c,Is_Inbound__c,Lead__r.Store__c from Messaging_Message__c where Is_Inbound__c = true and Lead__c != null';
        }
        else {
            query = 'Select id,Lead__c,Lead__r.Name,Lead__r.OwnerFullName__c,Is_Inbound__c,Lead__r.Store__c, lead__r.status from Messaging_Message__c  where lead__r.owner__r.profile.name =	  \'Retail RSC Rep\' and Is_Inbound__c = true and Lead__r.Store__c != null and Lead__c != null and Lead__r.LastContactedSMS__c != null and lead__r.Status != \'Closed\' and Lead__r.LastContactedSMS__c <:currentTime'; 
            
        }
       System.debug('query==>'+query);
        return Database.getQueryLocator(query);
    }
    /**
* @description:   Execute method for the batch
*/
    public void execute(Database.BatchableContext ctx, List<Messaging_Message__c> messagingList) {
        Integer count = 0;
        set<Id> storeIds = new set<Id>();
        for(Messaging_Message__c objMessage:messagingList){
            if(leadsCountMap.containsKey(objMessage.Lead__r.Store__c)) {
                count = leadsCountMap.get(objMessage.Lead__r.Store__c)+1;
                leadsCountMap.put(objMessage.Lead__r.Store__c,count);
            }  
            else {
                leadsCountMap.put(objMessage.Lead__r.Store__c, 1);
                storeIds.add(objMessage.Lead__r.Store__c);
            }
            //Based on store get the rep names
            if(mapIdOwner.containsKey(objMessage.Lead__r.Store__c)) {
                Set<String> ownerList = mapIdOwner.get(objMessage.Lead__r.Store__c);
                ownerList.add(objMessage.Lead__r.OwnerFullName__c);
                mapIdOwner.put(objMessage.Lead__r.Store__c,ownerList);
            }  
            else {
                mapIdOwner.put(objMessage.Lead__r.Store__c,new Set<string>{objMessage.Lead__r.OwnerFullName__c});                
            }
            //Based on store get the customer names
            if(mapCustomerName.containsKey(objMessage.Lead__r.Store__c)) {
                Set<String> ownerList = mapCustomerName.get(objMessage.Lead__r.Store__c);
                ownerList.add(objMessage.Lead__r.Name);
                mapCustomerName.put(objMessage.Lead__r.Store__c,ownerList);
            }  
            else {
                mapCustomerName.put(objMessage.Lead__r.Store__c,new Set<string>{objMessage.Lead__r.Name});                
            }
            
            
        }
        //Fetch Managers based on store
        for(Employee__c objE:[select id,User__c,HomeStoreLocation__c from Employee__c where SMSNotificationOptInOut__c = false AND User__r.profile.name =: RETAIL_SM 
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
        SendLeadUnRespondedMgrNotificationsBatch batchInst = new SendLeadUnRespondedMgrNotificationsBatch( leadsCountMap, mapIdOwner,mapCustomerName, mapUserIds);
        Database.executeBatch(batchInst);
        
    }
    
}