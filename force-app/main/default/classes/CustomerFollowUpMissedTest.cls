/*
* Test class for CustomerRequestedFollowUpMissedScheduler class
* @Author : Reshma Jewrani
*/
@isTest 
public with sharing class CustomerFollowUpMissedTest {
    
    private static TestDataFactory.TestWrapper dataFactoryWrap = new TestDataFactory.TestWrapper();
    private static TestDataFactory dataFactory = new TestDataFactory();
    
    @TestSetup
    static void makeData(){
        Test.startTest();
        dataFactoryWrap = dataFactory.createTestData(3, 'Deployment');
        System.debug('***** mapRoleVsUsers'+dataFactoryWrap.mapRoleVsUsers);
        System.debug('***** lstStore'+dataFactoryWrap.lstStore);
        System.debug('***** mapEmpRetailStoreVsRole'+dataFactoryWrap.mapEmpRetailStoreVsRole);
        System.debug('***** mapStoreVsMapRoleEmployee'+dataFactoryWrap.mapStoreVsMapRoleEmployee);
        System.debug('***** lstLead'+dataFactoryWrap.lstLead);
        BatchStatus__c batchDetails = new BatchStatus__c(Name = RetailConstants.MISSED_FOLLOWUP_BATCH,
                                                        Email__c = 'test@test.com',
                                                        BatchSize__c = 100);
        insert batchDetails;
        Test.stopTest();
    }
    
    @isTest 
    static void testScheduler() {
        String cronExpr = '0 0 0 15 3 ? 2023';
        Test.startTest();
        RetailHierarchySetting__c retailHierarchySetting = RetailHierarchySetting__c.getInstance(UserInfo.getUserId());
        retailHierarchySetting.ByPassValidationRule__c = true;
        upsert retailHierarchySetting;
        Lead leadRec = new Lead(LastName = 'Test'+system.currentTimeMillis(),
                                Company = 'Test',
                                NextFollowUpDate__c = System.today() - 1
                               );
        insert leadRec;
        CustomerRequestedFollowUpMissedScheduler scheduler= new CustomerRequestedFollowUpMissedScheduler();
        String jobId = System.schedule('myJobTestJobName', cronExpr, scheduler);
        scheduler.execute(null);
        Test.stopTest();
    }
}