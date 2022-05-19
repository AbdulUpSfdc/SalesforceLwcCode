/*******
Name            : UrgentFlagSchedularTest
Description     : This is the Test class for UrgentFlagSchedular and UrgentFlagBatch .
*******/
@isTest
public with sharing class UrgentFlagSchedularTest {
    static testMethod void testMethod1() 
    {   // Create knowledge article record.
        Knowledge__kav knowledgekav = KM_TestDataFactory.getKnowledKav(system.today(),'test','testurl',true, 'ABC');
        //Get RecordTypeId.
        Id accRecordTypeId = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByName().get('News Article').getRecordTypeId();  
        //Create Record for RecordTypeName 'News Article'.
        Knowledge__kav knowledge = KM_TestDataFactory.getKnowledKavTest(accRecordTypeId,System.Now().AddDays(5),'testone','testing',true, 'ABC');
         
        Test.startTest();     
            String cronExp = '0 0 0 * * ?';
            String jobId = System.schedule('ScheduleApexClassTest',  cronExp, new UrgentFlagSchedular());
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
            System.assertEquals(cronExp, ct.CronExpression);
            System.assertEquals(0, ct.TimesTriggered);         
        Test.stopTest();
    }
}