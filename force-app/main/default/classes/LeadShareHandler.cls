/*
*   Author : Rajesh Meda
*   This classe contains methods to add/remove the lead share with Store Queue, Custom lead owner
*/
public without sharing class LeadShareHandler {
    public LeadShareHandler() {

    }
    public class leadShareDetails{
        //public Map<Id, Id> storeIdStoreQueueIdMap;
        //public Set<Id> storeIds;
        public Map<Id, Id> leadIdVsOldOwnerId;
        public Map<Id, Id> leadIdVsNewOwnerId;
        //public Map<Id, Id> leadIdVsOldStoreId;
        //public Map<Id, Id> leadIdVsNewStoreId;
        public Map<Id, Id> leadIdVsNewStoreQueueId;
        public Map<Id, Id> leadIdVsOldStoreQueueId;
        
        public leadShareDetails(){
            //storeIdStoreQueueIdMap = new Map<Id, Id>();
            leadIdVsOldOwnerId = new Map<Id, Id> ();
            leadIdVsNewOwnerId = new Map<Id, Id> ();
            //leadIdVsOldStoreId = new Map<Id, Id> ();
            //leadIdVsNewStoreId = new Map<Id, Id> ();
            leadIdVsNewStoreQueueId = new Map<Id, Id>();
            leadIdVsOldStoreQueueId = new Map<Id, Id>();
            //storeIds = new Set<Id>();
        }
    }
    public void dmlLeadShare(List<LeadShare> leadShares, String dmlType){
        if (dmlType == RetailConstants.DELETE_OPERATION) {
            delete leadShares;
        } else if(dmlType == RetailConstants.INSERT_OPERATION) {
            insert leadShares;
        }
    }

    /*Not needed as StoreQueueId__c formula field on lead will be used to get the storequeue id.
    public static leadShareDetails getStoreIdVsStoreQueueIdMap(Set<Id> storeIds, leadShareDetails leadSharemap){
        List<Store__c> stores = new List<Store__c>();
        Map<String, Id> storeGroupDevNameVsStoreIdMap = new Map<String, Id>();
        
        stores = [SELECT Id, Name, LocationId__c FROM Store__c WHERE Id IN : storeIds and LocationId__c != NULL];
        
        for(Store__c store: stores){
            if(store.LocationId__c != NULL){
                storeGroupDevNameVsStoreIdMap.put('ST'+store.LocationId__c, store.Id);
            }
        }
        //Deletes the store Group when lead owner home store location change is less than 5 miles.
        if(storeGroupDevNameVsStoreIdMap.size() > 0 ){
            for(Group storeGroup: [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN : storeGroupDevNameVsStoreIdMap.keySet()] ){
                if(storeGroupDevNameVsStoreIdMap.size() > 0 && storeGroupDevNameVsStoreIdMap.containsKey(storeGroup.DeveloperName)){
                    Id storeId = storeGroupDevNameVsStoreIdMap.get(storeGroup.DeveloperName);
                    leadSharemap.storeIdStoreQueueIdMap.put(storeId, storeGroup.Id);
                }
            }
        }
        return leadSharemap;
    }*/


    /* rmeda lead share
     * This method checks lead share conditions and based on these adds or removes the lead share.
     */
    public static void checkLeadShareConditions(TriggerHelper.RoleMap roleMap){
        //if(roleMap.leadShareDetails.storeIds.size() > 0 ){
            //roleMap.leadShareDetails = getStoreIdVsStoreQueueIdMap(roleMap.leadShareDetails.storeIds, roleMap.leadShareDetails);
            
            Set<Id> leadIds = new Set<Id>();
            Set<Id> userOrGroupIds = new Set<Id>();
            
            //remove lead share
            leadIds.addAll(roleMap.leadShareDetails.leadIdVsOldOwnerId.keySet());
            userOrGroupIds.addAll(roleMap.leadShareDetails.leadIdVsOldOwnerId.values());
            
            //adding old store group id to user or group id whose leadshare needs to be removed.
            /*for(Id leadId : roleMap.leadShareDetails.leadIdVsOldStoreId.keySet()){
                Id oldStoreId = roleMap.leadShareDetails.leadIdVsOldStoreId.get(leadId);
                if(roleMap.leadShareDetails.storeIdStoreQueueIdMap.containsKey(oldStoreId)){
                    Id oldStoreGroupId = roleMap.leadShareDetails.storeIdStoreQueueIdMap.get(oldStoreId);
                    leadIds.add(leadId);
                	userOrGroupIds.add(oldStoreGroupId);
                }
            }*/

            for(Id leadId : roleMap.leadShareDetails.leadIdVsOldStoreQueueId.keySet()){
                Id oldStoreGroupId = roleMap.leadShareDetails.leadIdVsOldStoreQueueId.get(leadId);
                if(oldStoreGroupId != NULL && leadId != NULL){
                    leadIds.add(leadId);
                    userOrGroupIds.add(oldStoreGroupId);
                }
            }

            if(leadIds.size() > 0 && userOrGroupIds.size() > 0){
                removeLeadShares(leadIds, userOrGroupIds);
                leadIds.clear();
                userOrGroupIds.clear();
            }
            
            //add lead share
            List<LeadShare> leadSharesAdd = new List<LeadShare> ();

            //owner share instance
            for(Id leadId : roleMap.leadShareDetails.leadIdVsNewOwnerId.keySet()){
                Id ownerId = roleMap.leadShareDetails.leadIdVsNewOwnerId.get(leadId);
                LeadShare ownerLeadShare = createLeadShareInstance(RetailConstants.LEAD_ACCESS_ALL, leadId, ownerId);
                System.debug('Owner Lead share::'+ownerLeadShare);
                leadSharesAdd.add(ownerLeadShare);
            }

            //store group share instance
            /*
            for(Id leadId : roleMap.leadShareDetails.leadIdVsNewStoreId.keySet()){
                Id newStoreId = roleMap.leadShareDetails.leadIdVsNewStoreId.get(leadId);
                if(roleMap.leadShareDetails.storeIdStoreQueueIdMap.containsKey(newStoreId)){
                    Id newStoreGroupId = roleMap.leadShareDetails.storeIdStoreQueueIdMap.get(newStoreId);
                    LeadShare storeGroupLeadShare = createLeadShareInstance(RetailConstants.LEAD_ACCESS_ALL, leadId, newStoreGroupId);
                    System.debug('Store Group Lead share::'+storeGroupLeadShare);
                    leadSharesAdd.add(storeGroupLeadShare);
                }
            }*/

            for(Id leadId : roleMap.leadShareDetails.leadIdVsNewStoreQueueId.keySet()){
                Id newStoreGroupId = roleMap.leadShareDetails.leadIdVsNewStoreQueueId.get(leadId);
                if(newStoreGroupId != NULL && leadId != NULL){
                    LeadShare storeGroupLeadShare = createLeadShareInstance(RetailConstants.LEAD_ACCESS_ALL, leadId, newStoreGroupId);
                    System.debug('Store Group Lead share::'+storeGroupLeadShare);
                    leadSharesAdd.add(storeGroupLeadShare);
                }
            }
            if(leadSharesAdd.size() > 0){
                addLeadShare(leadSharesAdd);
            }
            leadIds.clear();
            userOrGroupIds.clear();
        //}
    }
    


    /* 
    *This method creates lead share instances for lead insert/update
    */
    public static LeadShare createLeadShareInstance(String accessLevel, Id leadId, Id userOrGroupId) {
        LeadShare leadShareRec = new LeadShare(
                                                LeadAccessLevel = accessLevel, 
                                                LeadId = leadId,
                                                RowCause = Schema.LeadShare.RowCause.Manual,
                                                UserOrGroupId = userOrGroupId);
        return leadShareRec;
    }

    /* 
    *This method adds lead share for lead insert/update
    */
    public static void addLeadShare(List<LeadShare> leadSharesAdd) {
        System.debug('Add Lead share::'+leadSharesAdd.size());
        if(leadSharesAdd != NULL && leadSharesAdd.size() > 0){
            for(database.saveResult dsr : database.insert(leadSharesAdd, false)){
                if (!dsr.isSuccess()) {
                    // Operation failed, so get all errors  
                    for(Database.Error err : dsr.getErrors()) {
                        System.debug('Add Lead Share Error: '+err.getMessage());
                    }
                }
            }
        }
    }


    /* 
    *This method gets the lead shares of lead which needs to be removed
    */
    public static List<LeadShare> getLeadSharesRemove(Set<Id> leadIds, Set<Id> userOrGroupIds) {
        List<LeadShare> leadSharesRemove = new List<LeadShare> ();
        leadSharesRemove = [SELECT Id FROM LeadShare WHERE LeadId IN : leadIds AND UserOrGroupId IN : userOrGroupIds];
        return leadSharesRemove;
    }

    /* 
    *This method removes lead share instances for lead insert/update
    */
    public static void removeLeadShares(Set<Id> leadIds, Set<Id> userOrGroupIds) {
        List<LeadShare> leadSharesRemove = getLeadSharesRemove(leadIds, userOrGroupIds);
        if(leadSharesRemove != NULL && leadSharesRemove.size() > 0){
            for(Database.DeleteResult dr : Database.delete(leadSharesRemove, false)) {
                if (!dr.isSuccess()) {
                    for(Database.Error err : dr.getErrors()) {
                        System.debug('Remove Lead Share Error: '+err.getMessage());
                    }
                }
            }
        }
    }
}