public without sharing class customerUpNextController {
    @AuraEnabled
    public static list<RetailCheckinQueue__c> getRetailQueues(Integer limitVal){
        list<RetailCheckinQueue__c> queues= new List<RetailCheckinQueue__c>();
        RetailDTO.DCIHomePageDataDTO initialData = DCIController.getInitialData();
        EmployeeStoreRetail__c empStore = initialData.employeeDetails;
        try { queues=[SELECT Id,Name,EstimatedWaitTimeWithMin__c,QueuePosition__c,WaitTimeStatus__c,
            DCITimeWaiting__c,DCIAssignedRSC__c,DCICheckinType__c,CustomerRequestedRep__c,
            Lead__r.PreferedLanguage__c 
            FROM RetailCheckinQueue__c where Store__c =: empStore.Store__c AND QueuePosition__c > 0
            AND (Status__c=: RetailConstants.ARRIVED OR Status__c=: RetailConstants.PENDING)
            ORDER BY QueuePosition__c ASC NULLS LAST
            limit :limitVal ];  
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return queues;
    }
}