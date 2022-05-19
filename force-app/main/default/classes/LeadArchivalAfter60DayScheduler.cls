public class LeadArchivalAfter60DayScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        LeadArchivalAfter60DayBatch leadArchivalBatch = new LeadArchivalAfter60DayBatch();
        BatchStatus__c batchDetails = BatchStatus__c.getValues(RetailConstants.LEAD_ARCHIVAL_BATCH_NAME);
        if(batchDetails != null && batchDetails.BatchSize__c != null) {
            database.executebatch(leadArchivalBatch, integer.valueOf(batchDetails.BatchSize__c));
        }else{
            database.executebatch(leadArchivalBatch);
        }
    }
}