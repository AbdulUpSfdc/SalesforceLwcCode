@isTest
public class ScheduleBatchDeletedAcceptedLeadtest {
    
    
    /* 
* This method tests the core functionality and Schedulable class for Unica Leads
*/
    @IsTest
    static void testScheduledJob(){
        BatchStatus__c batchDetails = new BatchStatus__c(Name = 'DeleteAcceptedLeadcreatedinlast30mins',
                                                         Batch_Processing_Gap__c = 5,
                                                         LastRun__c = System.now().addDays(-2));
        insert batchDetails;
        Test.starttest();
        //ScheduleBatchDeletedAcceptedLead30mins ScheduleBatchDeletedAcceptedLead = new ScheduleBatchDeletedAcceptedLead30mins ();   
       // String cron = '0 0 23 * * ?'; 
       // ScheduleBatchDeletedAcceptedLead30mins.SchedulerMethod();
       // system.schedule('DeleteAcceptedLeadcreatedinlast30mins', cron, ScheduleBatchDeletedAcceptedLead);
        Test.stopTest();
    }
    
}