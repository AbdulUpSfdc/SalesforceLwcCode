/*
* This class is used to Schedule the batch job for Processing the bulk load of Unica Leads
* Author: Reshma Jewrani
*/
public with sharing class ProcessUnicaLeadsScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        Integer batchSize = 0;
        BatchStatus__c batchDetails = BatchStatus__c.getValues(RetailConstants.UNICA_BATCH_NAME);
        if(batchDetails != null && batchDetails.BatchSize__c != null && batchDetails.BatchSize__c <= 2000) {
            batchSize = Integer.valueOf(batchDetails.BatchSize__c);
        } 
        ProcessUnicaLeadsBatch bulkLeadBatch = new ProcessUnicaLeadsBatch(); 
        if(batchSize > 0)
            database.executebatch(bulkLeadBatch, batchSize);
        else
            database.executebatch(bulkLeadBatch);
    }
}