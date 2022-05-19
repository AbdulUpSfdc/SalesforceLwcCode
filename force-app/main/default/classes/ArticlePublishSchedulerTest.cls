@isTest
public class ArticlePublishSchedulerTest {
    
    public static testmethod void testScheduleBatch(){
        Test.startTest();
        String CRON_EXP = '0 0 * * * ?';
        // Schedule the test job
        String jobId = System.schedule('ArticlePublishScheduler', CRON_EXP, new ArticlePublishScheduler());
        // Get the information from the CronTrigger API object 
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId]; 
        // Verify the job has not run 
        System.assertNotEquals(null, ct.TimesTriggered); 
        // Verify the next time the job will run 
        System.assertNotEquals(null, String.valueOf(ct.NextFireTime));   
        Test.stopTest();        
    }
}