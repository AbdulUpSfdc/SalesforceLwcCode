public with sharing class OLMLeadAssignmentBatch_sch implements Schedulable {
    public void execute(SchedulableContext sc) {
        Integer batchSize = 0;
        BatchStatus__c batchDetails = BatchStatus__c.getValues(RetailConstants.OLM_BATCH);
        if(batchDetails != null && batchDetails.BatchSize__c != null && batchDetails.BatchSize__c <= 2000) {
            batchSize = Integer.valueOf(batchDetails.BatchSize__c);
        } 
        OLMLeadAssignmentBatch batch = new OLMLeadAssignmentBatch(); 
        if(batchSize > 0)
            database.executebatch(batch, batchSize);
        else
            database.executebatch(batch);
    }
}