@isTest
private class LeadClosureAfter30DaySchedulerTest {
    static testMethod void leadClosureSchedulerTest() {        
         test.starttest();
         LeadClosureAfter30DayScheduler leadScheduler = new LeadClosureAfter30DayScheduler ();   
         String cron = '0 0 23 * * ?';        
         system.schedule('Test Lead Closure Scheduler', cron, leadScheduler);
         test.stopTest();
    }
}