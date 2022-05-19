@isTest
public with sharing class ProcessUnicaLeadsTest {
    private static TestDataFactory.TestWrapper dataFactoryWrap = new TestDataFactory.TestWrapper();
    private static TestDataFactory dataFactory = new TestDataFactory();
    /* 
    *This method is used to setup test data of employee,employee store retail,leads and stores
    */
    @TestSetup
    static void makeData(){
        dataFactoryWrap = dataFactory.createTestData(3,'Empl');
        //create another set of data to   add more employees to each store
        dataFactory.addMoreEmpToHomeStore('moreRep');
        List<BatchConditions__c> conditions =  new List<BatchConditions__c>();
        BatchConditions__c condition1 = new BatchConditions__c(Name = RetailConstants.UNICA_BATCH_NAME+'1',
                                                            BatchClassName__c = RetailConstants.UNICA_BATCH_NAME,
                                                            FieldApiName__c= 'LeadSource',
                                                            Operator__c = '=',
                                                            Value__c='\'Campaign\'');
        
        conditions.add(condition1);
        BatchConditions__c condition2 = new BatchConditions__c(Name = RetailConstants.UNICA_BATCH_NAME+'2',
                                                            BatchClassName__c = RetailConstants.UNICA_BATCH_NAME,
                                                            FieldApiName__c= 'Owner.Profile.Name',
                                                            Operator__c = '=',
                                                            Value__c='\''+RetailConstants.INTEGRATION_PROFILE+'\'');
        conditions.add(condition2);
        insert conditions;
    }

    /* 
    * This method tests the core functionality and Schedulable class for Unica Leads
    */
    @IsTest
    static void testScheduledJob(){
        List<Store__c> lstStore = [SELECT id FROM Store__c WHERE Name LIKE '%store%'];
        dataFactory.getUnicaLeads(lstStore, 150, 'Test');
        BatchStatus__c batchDetails = new BatchStatus__c(Name = RetailConstants.UNICA_BATCH_NAME,
                                                LastRun__c = System.now().addDays(-2));
        insert batchDetails;
        Test.starttest();
            ProcessUnicaLeadsScheduler unicaScheduler = new ProcessUnicaLeadsScheduler ();   
            String cron = '0 0 23 * * ?';        
            system.schedule(RetailConstants.UNICA_BATCH_NAME, cron, unicaScheduler);
        Test.stopTest();
        batchDetails.BatchSize__c = 3;
        update batchDetails;
        system.schedule('Test', cron, unicaScheduler);
    }

    /* 
    * This method tests the batch job w/o the availablity of any custom setting
    */
    @IsTest
    static void testBatchJob(){
        List<Store__c> lstStore = [SELECT id FROM Store__c WHERE Name LIKE '%store%'];
        dataFactory.getUnicaLeads(lstStore, 150, 'Test');
        Test.startTest();
            database.executeBatch(new ProcessUnicaLeadsBatch());
        Test.stopTest();
    }

    /* 
    * This method tests the batch job with the ability to send email in finish
    */
    @IsTest
    static void testBatchJobWithEmail(){
        List<Store__c> lstStore = [SELECT id FROM Store__c WHERE Name LIKE '%store%'];
        dataFactory.getUnicaLeads(lstStore, 150, 'Test');
        BatchStatus__c batchDetails = new BatchStatus__c(Name = RetailConstants.UNICA_BATCH_NAME,
                                                LastRun__c = System.now().addDays(-2),
                                                Email__c = 'test@test.com');
        insert batchDetails;
        Test.startTest();
            database.executeBatch(new ProcessUnicaLeadsBatch());
        Test.stopTest();
    }
}