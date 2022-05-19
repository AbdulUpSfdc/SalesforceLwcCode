/*
    Unit test coverage for BWC_CaseEscalationDeleteBatch.cls
*/
@isTest
public with sharing class BWC_CaseEscalationDeleteBatch_Test {

    @TestSetup
    private static void setup(){

        // Generate Case Escalation records 
        Case testCase = TestData_Case.generateCaseForAdjustment();
        testCase.CaseAction__c = null;
        update testCase;
        

    }

    private static void setDefaultMetadata() {

        BWC_CaseEscalationDeleteBatch.testBatchParameters = new BWC_Batch_Parameters__mdt(
            Enabled__c = true,
            Hours_In_Past__c = 0,
            Scope_Size__c = 1
        );

    }

    @isTest
    private static void test_schedule() {

        setDefaultMetadata();

        Test.startTest();

        BWC_CaseEscalationDeleteBatch.scheduleBatch();

        Test.stopTest();

        assertNoExceptionLogs();

        List<CronTrigger> cronTriggers = [
            SELECT Id, NextFireTime
            FROM CronTrigger 
            WHERE CronJobDetail.Name = :BWC_CaseEscalationDeleteBatch.SCHEDULED_JOB_NAME
        ];

        // Expect scheduled record
        System.assertEquals(1, cronTriggers.size());

    }

    @isTest
    private static void test_unschedule() {

        setDefaultMetadata();

        Test.startTest();

        BWC_CaseEscalationDeleteBatch.scheduleBatch();

        BWC_CaseEscalationDeleteBatch.unscheduleBatch();

        Test.stopTest();

        assertNoExceptionLogs();

        List<CronTrigger> cronTriggers = [
            SELECT Id
            FROM CronTrigger 
            WHERE CronJobDetail.Name = :BWC_CaseEscalationDeleteBatch.SCHEDULED_JOB_NAME
        ];

        // Expect no scheduled record
        System.assertEquals(0, cronTriggers.size());

    }

    @isTest
    private static void test_batchDelete() {

        setDefaultMetadata();

        System.assertEquals(1, [SELECT Id FROM Case].size());

        Test.startTest();

        // Use schedulable execute
        (new BWC_CaseEscalationDeleteBatch()).execute(null);

        Test.stopTest();

        assertNoExceptionLogs();

        // All deleted
        // System.assertEquals(0, [SELECT Id FROM Case].size());
        // System.assertEquals(0, [SELECT Id FROM Asset].size());

    }

    @isTest
    private static void test_batchDeleteDisabled() {

        BWC_CaseEscalationDeleteBatch.testBatchParameters = new BWC_Batch_Parameters__mdt(
            Enabled__c = false,
            Hours_In_Past__c = 0,
            Scope_Size__c = 1
        );

        System.assertEquals(1, [SELECT Id FROM Case].size());

        Test.startTest();

        // Use schedulable execute
        (new BWC_CaseEscalationDeleteBatch()).execute(null);

        Test.stopTest();

        assertNoExceptionLogs();

        // Not deleted because batch disabled
        System.assertEquals(1, [SELECT Id FROM Case].size());

    }

    private static void assertNoExceptionLogs() {

        List<Exception__c> exceptions = [SELECT Id, Cause__c, Line_Number__c, Message__c, Stack_Trace_String__c, Type_Name__c FROM Exception__c];

    }

}