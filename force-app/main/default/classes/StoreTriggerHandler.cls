/*
* This class is called from the Store Trigger to handle various scenarios to be covered for all events on Store Object
* Currently, this class handles creating store group.
* Author: Rajesh Meda
*/
public without sharing class StoreTriggerHandler extends TriggerHandler {
    public override void afterInsert(){
        List<Store__c> stores = (List<Store__c>) Trigger.New;
        List<Group> groups = new List<Group>();
        List<GroupMember> groupMembers = new List<GroupMember>();    
        Map<string,Store__c> storeMap = new Map<string,Store__c> ();
        Map<String, String> mapGroupNameStoreMarketID = new Map<String, String>();
        for(Store__c store: stores){
            if(store.Name != Null && store.LocationId__c != Null){
                Group storeGroup = new Group();
                storeGroup.Type = 'Regular';
                storeGroup.Name = store.Name.Left(39); 
                //DeveloperName API Name can only contain underscores and alphanumeric characters. 
                //It must be unique, begin with a letter, not include spaces, not end with an underscore, and not contain two consecutive underscores.
                //storeGroup.DeveloperName = 'ST' + store.LocationId__c;
                String groupDeveloperName = 'Retail_' + store.LocationId__c;
                storeGroup.DeveloperName = groupDeveloperName;
                groups.add(storeGroup);
                storeMap.put(groupDeveloperName, store);
                if(store.MarketId__c!=null){
                    mapGroupNameStoreMarketID.put(storeGroup.DeveloperName, RetailConstants.STORE_USER_ROLE + (Integer)store.MarketId__c);
                }             
            }
        }
        Map<Id,Store__c> storeToUpdate = new Map<Id,Store__c> ();
        if(groups.size() > 0){
            try{
                insert groups;
            }catch (exception e){
                system.debug('Store Group Insert Exception is:'+e.getStackTraceString());                            
            }
            RetailGroupMemberQueueable retailGroupMemberQueue = new RetailGroupMemberQueueable(mapGroupNameStoreMarketID, 
                                                                                               storeMap,null,null,null);
            system.enqueueJob(retailGroupMemberQueue);
        }
    }
    public override void afterUpdate(){
        // This is executed only once with stores update via workbench to create the store queues.
        List<Store__c> stores = (List<Store__c>) Trigger.New;
        Map<Id,Store__c> oldStoreMap = (Map<Id,Store__c>)Trigger.oldMap; //
        List<Group> groups = new List<Group>();
        List<GroupMember> groupMembers = new List<GroupMember>();    
        Map<string,Store__c> storeMap = new Map<string,Store__c> ();
        Map<String, String> mapGroupNameStoreMarketID = new Map<String, String>();
        
        Map<String, String> deleteGroupMembersMap = new Map<String, String>(); 
        Set<Id> deleteGroupIds = new Set<Id>(); //
        List<Store__c> closedStoreList = new List<Store__c>(); 
        //US 2566
        List<StoreQueueUpdateNotification__e> sueList = new List<StoreQueueUpdateNotification__e>();
       
        for(Store__c store: stores){
            System.debug('store ::::' + store.Name + ' : ' + store.Id);
            if(store.Name != Null && store.LocationId__c != Null && store.PublicGroupId__c == null && store.status__c != null && store.status__c.tolowercase() != 'selling close'){
                Group storeGroup = new Group();
                storeGroup.Type = 'Regular';
                storeGroup.Name = store.Name.Left(39);             
                String groupDeveloperName = 'Retail_' + store.LocationId__c;
                System.debug('groupDeveloperName :::: ' + groupDeveloperName);
                storeGroup.DeveloperName = groupDeveloperName;
                groups.add(storeGroup);
                storeMap.put(groupDeveloperName, store);
                if(store.MarketId__c!=null){
                    mapGroupNameStoreMarketID.put(storeGroup.DeveloperName, RetailConstants.STORE_USER_ROLE+ (Integer) store.MarketId__c);
                } 
                                                
            }
            //US 2566
           if(store.DCIEstimatedWaitTime__c != oldStoreMap.get(store.Id).DCIEstimatedWaitTime__c || store.DCILeadsinCheckinQueue__c != oldStoreMap.get(store.Id).DCILeadsinCheckinQueue__c ){
                    StoreQueueUpdateNotification__e sue = new StoreQueueUpdateNotification__e();
                    sue.StoreId__c = store.Id;
                    sue.StoreLocationId__c = store.LocationId__c;
                    sueList.add(sue);
            }
            // Delete the existing group ember and insert new group member based on market id
            if(store.LocationId__c != Null && store.MarketId__c!=null &&  oldStoreMap.get(store.Id).MarketId__c != store.MarketId__c && store.PublicGroupId__c != null){
                String groupDeveloperName = 'Retail_' + store.LocationId__c;
                storeMap.put(groupDeveloperName, store);
                mapGroupNameStoreMarketID.put( groupDeveloperName, RetailConstants.STORE_USER_ROLE+ (Integer) store.MarketId__c);
                if(oldStoreMap.get(store.Id).MarketId__c != null){
                    deleteGroupMembersMap.put( groupDeveloperName, RetailConstants.STORE_USER_ROLE+ (Integer) oldStoreMap.get(store.Id).MarketId__c);
                } 
            }
            
            // Delete the group if store status is selling close and public group id is not blank
            if(store.Status__c!=null && store.Status__c.toLowerCase() == 'selling close' && store.PublicGroupId__c != null){
                deleteGroupIds.add(store.PublicGroupId__c);
                closedStoreList.add(store);
            }
        }
        try{
            
            Map<Id,Store__c> storeToUpdate = new Map<Id,Store__c> ();
            if(groups.size() > 0){
                insert groups;
            }
            if(mapGroupNameStoreMarketID.keySet().size() > 0 || deleteGroupIds.size() > 0 || deleteGroupMembersMap.size() > 0 ){
                system.debug('no. of jobs queued'+Limits.getQueueableJobs());
                system.debug('nmapGroupNameStoreMarketID'+mapGroupNameStoreMarketID);
                if(!Test.isRunningTest()){ 
                    //if(Limits.getQueueableJobs() == 0 ){
                   RetailGroupMemberQueueable  retailGroupQueue = new RetailGroupMemberQueueable(mapGroupNameStoreMarketID, storeMap, 
					 deleteGroupIds,deleteGroupMembersMap, closedStoreList);
                    system.enqueueJob(retailGroupQueue);
                }    
            }
            
        }catch (exception e){
            system.debug('Store Group Update Exception is:'+e.getMessage());                            
        }
        //US 2566
        try{
            if(!sueList.isEmpty()){
                    // Call method to publish events
                List<Database.SaveResult> results = EventBus.publish(sueList);
            }
        }catch (exception e){
            system.debug('Store Platform Event:'+e.getMessage()); 
            BWC_ExceptionUtils.handleException(e, True);
        }
    }
    
}