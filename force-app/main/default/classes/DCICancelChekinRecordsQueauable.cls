public without sharing class DCICancelChekinRecordsQueauable implements Queueable {
    String cancellationReason;
    String storeId;
    public DCICancelChekinRecordsQueauable (String cancellationReason, String storeId){
        this.cancellationReason = cancellationReason;
        this.storeId = storeId;
    }		
    public void execute(QueueableContext context) {
        try{
            List<Store__c> storeList = new List<Store__c>([SELECT Id FROM Store__c WHERE Id=:this.storeId]);
            if(!storeList.isEmpty()){
                Store__c storeObj = storeList[0];
                storeObj.DCIEstimatedWaitTime__c = 0;
                storeObj.DCILeadsinCheckinQueue__c = 0;
                update storeObj;
                List<EmployeeStoreRetail__c> empStoreList = new List<EmployeeStoreRetail__c>([SELECT Id FROM EmployeeStoreRetail__c WHERE Store__c=:this.storeId AND DCIPresenceStatus__c != 'Offline']);
                if(!empStoreList.isEmpty()){
                    for(EmployeeStoreRetail__c empObj: empStoreList){
                        empObj.DCIPresenceStatus__c = 'Offline';
                    }
                    Database.update(empStoreList, false);
                }
                
                Set<Id> leadIds = new Set<Id>();
                List<RetailCheckinQueue__c> retailchecktobecancelled = new List<RetailCheckinQueue__c>([SELECT Id,Lead__c FROM RetailCheckinQueue__c WHERE Status__c IN('Pending', 'Arrived', 'No Show') AND Store__c=:this.storeId AND CheckInTime__c=TODAY]);      
                for(RetailCheckinQueue__c obj :retailchecktobecancelled){
                    obj.Status__c = 'Cancelled';
                    leadIds.add(obj.Lead__c);
                }
                List<Lead> leadList = new List<Lead>([SELECT Id FROM Lead WHERE Id IN:leadIds]);
                for(Lead leadObj :leadList){
                    leadObj.Status = 'Closed';
                    leadObj.ClosedStatus__c = 'Cancelled';
                    leadObj.DCIReasonForCancellation__c = this.cancellationReason;
                }
                if(!retailchecktobecancelled.isEmpty()) Database.update(retailchecktobecancelled,false);
                if(!leadList.isEmpty()) Database.update(leadList,false);
                Set<Id> checkinRecordId = new Set<Id>();
                
                for(RetailCheckinQueue__c obj :retailchecktobecancelled){
                    checkinRecordId.add(obj.Id);
                }
                if( !checkinRecordId.isEmpty()){
                    DCIRetailCancelAllCheckinsSMSQueuable sendSMSQueue = new DCIRetailCancelAllCheckinsSMSQueuable(checkinRecordId);
                    System.enqueueJob(sendSMSQueue);
                }
            }
        }
        catch(Exception e){
            System.debug(e.getMessage());
        }
    }
}