public with sharing class StoreUpdateQueueable implements Queueable {
    
    public List<Group> groupsList = new List<Group>();
    public List<Store__c> closedStoreList = new List<Store__c>();
    Public Map<string,Store__c> storeMap = new Map<string, Store__c>();
    
    public StoreUpdateQueueable(List<Group> listGroup, Map<string,Store__c> retailStoreMap, List<Store__c>  closedStoreList) {
        this.groupsList = listGroup;
        this.storeMap = retailStoreMap;
		 this.closedStoreList = closedStoreList;
    }
    
    public void execute(QueueableContext context) {
        Map<Id, Store__c> storeToUpdate = new Map<Id, Store__c> ();
        if(!groupsList.isEmpty() && !storeMap.isEmpty()) {
            for(Group grp: groupsList){
                Store__c s = new Store__c();
                s.Id = storeMap.get(grp.DeveloperName).Id;
                s.PublicGroupId__c = grp.id;
                storeToUpdate.put(s.Id, s);
            }
        }
        if(closedStoreList!=null && !closedStoreList.isEmpty()){
            for(Store__c store : closedStoreList){
                Store__c s = new Store__c();
                s.Id = store.Id;
                s.publicGroupId__c = null;
                storeToUpdate.put(store.Id, s);
            }
        }
        if (storeToUpdate.size() > 0) {
            update storeToUpdate.values();
        }
    }
}