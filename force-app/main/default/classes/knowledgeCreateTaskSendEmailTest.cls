@isTest
private class knowledgeCreateTaskSendEmailTest {
    static testMethod void leadClosureSchedulerTest() {        
         test.starttest();
         knowledgeCreateTask_SendEmailScheduler taskEmailScheduler = new knowledgeCreateTask_SendEmailScheduler();   
         String cron = '0 0 23 * * ?';        
         system.schedule('Test Task Email Scheduler', cron, taskEmailScheduler);
         test.stopTest();
    }
}