@isTest
/*
* This class is used for test coverage of Apex class StoreTriggerHandler.
* Author: Anand Tiwari
*/
private  class StoreTriggerHandlerTest {
    private static TestDataFactory.TestWrapper dataFactoryWrap = new TestDataFactory.TestWrapper();
    private static TestDataFactory dataFactory = new TestDataFactory();
    
    /* 
*This method is used to setup test data of employee,employee store retail,leads and stores
*/
    @TestSetup
    static void makeData(){
        dataFactoryWrap = dataFactory.createTestData(1,'StoreEmp');
        System.debug('dataFactoryWrap : '+ dataFactoryWrap);
    }
    
    @isTest
    static void testAfterUpdateMethod() {
        
        try
        {
            Store__c  updateStoreRec = [Select Id,publicgroupid__c from Store__c limit 1];
            updateStoreRec.locationId__c = '7777Testloc';
            updateStoreRec.marketid__c = 55;
            updateStoreRec.Status__c = 'Selling Open';
            update updateStoreRec; 
            
            Test.startTest();
            Store__c  updateStoreRec1 = [Select Id,publicgroupid__c from Store__c limit 1];
            Group g = [select id from group  where developername like '%7777Testloc%' limit 1];
            updateStoreRec1.marketid__c = 60;
            updateStoreRec1.publicgroupid__c = g.id;
            updateStoreRec1.Status__c = 'Selling Close';
            update updateStoreRec1; 
            Test.stopTest();
            
        }catch(Exception e){System.debug(e);}
        
        
    }
}