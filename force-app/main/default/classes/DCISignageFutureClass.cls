public without sharing class DCISignageFutureClass
{
    @future
    public static void publishSignageEvents(Set<ID> storeIds)
    {   
        List<StoreQueueUpdateNotification__e> sueList = new List<StoreQueueUpdateNotification__e>(); 
        // Get those records based on the IDs
        List<Store__c> stores = [SELECT Id, Name, LocationId__c FROM Store__c WHERE Id IN :storeIds];
        // Process records
        for(Store__c store: stores){
            sueList.add(new StoreQueueUpdateNotification__e(StoreId__c=store.Id,StoreLocationId__c = store.LocationId__c));   
        }
        //US 2566
        try{
            if(sueList.size()>0){
                // Call method to publish events
                List<Database.SaveResult> results = EventBus.publish(sueList);
            }
        }catch (Exception e){
            BWC_ExceptionUtils.handleException(e, True);
        }
    }
}