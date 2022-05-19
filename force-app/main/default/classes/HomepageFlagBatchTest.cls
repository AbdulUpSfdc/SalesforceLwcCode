/***********
    Name        : HomepageFlagBatchTest
    Description : This is the test class for the HomepageFlagBatch and HomepageFlagSchedular
**********/
@isTest
public class HomepageFlagBatchTest{

    public static testMethod void testMethod1(){
        Knowledge__kav knowledgekav = KM_TestDataFactory.getKnowledKav(system.today(),'vidhi12','manas21',true, 'ABC');
        //Get RecordTypeId.
        Id newsArticleRecordTypeId = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByDeveloperName().get('News_Article').getRecordTypeId();  
        //Create Record for RecordTypeName 'News Article'.
        Knowledge__kav knowledge = KM_TestDataFactory.getKnowledKavTest(newsArticleRecordTypeId ,System.Now().AddDays(5),'vishwas32','ata23',true, 'ABC');
         
        Test.startTest();     
            String cronExp = '0 0 0 * * ?';
            String jobId = System.schedule('ScheduleApexClassTest',  cronExp, new HomepageFlagSchedular());
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
            System.assertEquals(cronExp, ct.CronExpression);
            System.assertEquals(0, ct.TimesTriggered);         
        Test.stopTest();
        System.assert(knowledge.BW_News_Start_Date__c != NULL);
    }
}