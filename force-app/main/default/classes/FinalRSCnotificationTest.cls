/*
* Test class for FinalRSCnotificationScheduler class
* Author : Srinivas Vallepu
* itrack : SPTSFDCSLS-729
*/

@isTest 
public with sharing class FinalRSCnotificationTest {
    
    private static TestDataFactory.TestWrapper dataFactoryWrap = new TestDataFactory.TestWrapper();
    private static TestDataFactory dataFactory = new TestDataFactory();
    
    @TestSetup
    static void makeData(){
 
        BatchStatus__c batchDetails = new BatchStatus__c(Name = RetailConstants.FINAL_RSC_NOTIF,
                                                        Email__c = 'test@test.com',
                                                        BatchSize__c = 100);
        insert batchDetails;
    }
    
    @isTest 
    static void testScheduler() {
        String cronExpr = '0 0 0 15 3 ? 2023';
        Test.startTest();
        Lead leadRec = new Lead(LastName = 'Testsv744hijk'+system.currentTimeMillis(),
                                Company = 'Test',
                                Status = 'Captured',
                                LeadSource = 'Customer Interaction',
                                CustomerType__c = 'New Customer',
                                MobilePhone = '2349091010',
                                LeadExpirationDate__c  = System.today() + 5,
				Owner__c = UserInfo.getUserId(),
                                RecordTypeId = RetailConstants.CONSUMER_RECORDTYPEID
                               );
        insert leadRec;
        FinalRSCnotificationScheduler scheduler= new FinalRSCnotificationScheduler();
        String jobId = System.schedule('myJobTestJobName', cronExpr, scheduler);
        scheduler.execute(null);
        Test.stopTest();
    }
}