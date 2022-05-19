/*
* This class is used to Schedule the batch job for processing Employee-store records to mark them Expired if past date
* Author: Mohit Pandey
*/
public with sharing class EmpStoreExpirationDateScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        Integer batchSize = 0;
        BatchStatus__c batchDetails = BatchStatus__c.getValues(RetailConstants.EXPIRATIONDATE_BATCH_NAME);
        if(batchDetails != null && batchDetails.BatchSize__c != null && batchDetails.BatchSize__c <= 2000) {
            batchSize = Integer.valueOf(batchDetails.BatchSize__c);
        } 
        EmpStoreExpirationDateBatch bulkEmpStoreBatch = new EmpStoreExpirationDateBatch(); 
        if(batchSize > 0)
            database.executebatch(bulkEmpStoreBatch, batchSize);
        else
            database.executebatch(bulkEmpStoreBatch);
    }
}