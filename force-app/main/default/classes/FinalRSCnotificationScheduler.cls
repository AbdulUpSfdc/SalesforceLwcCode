/*
* This Schedulable class is called every day in order to check if Lead expiration date is in next 5 days and if it is, then create bell notification
* in the system for final RSC notification to lean owner Reps and/or Managers about Lead Expiration
*
* itrack : SPTSFDCSLS-729
* Author: Srinivas Vallepu
*
* Modifications Log 
* Ver   Date         Author                                    Modification
* 
*/

public class FinalRSCnotificationScheduler implements Schedulable {
    
    public void execute(SchedulableContext ctx) {
        Integer batchSize = 2000;
        BatchStatus__c batchDetails = BatchStatus__c.getValues(RetailConstants.FINAL_RSC_NOTIF);
        if(batchDetails != null && batchDetails.BatchSize__c != null && batchDetails.BatchSize__c <= 2000) {
            batchSize = Integer.valueOf(batchDetails.BatchSize__c);
        } 
        FinalRSCnotificationBatch finalRSCnotifBatch = new FinalRSCnotificationBatch(); 
        if(batchSize > 0)
            database.executebatch(finalRSCnotifBatch, batchSize);
    }
}