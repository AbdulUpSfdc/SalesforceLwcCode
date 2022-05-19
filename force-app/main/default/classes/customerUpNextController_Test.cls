@isTest
public with sharing class customerUpNextController_Test {
    
    @TestSetup
    static void setupStoreAndQueue(){
        Store__c testStore = new Store__c();
        testStore.Name = 'test_Store';
        testStore.LocationType__c = RetailConstants.IHX_LOCATIONTYPE;
        testStore.LocationId__c = 'DCILead';
        testStore.status__c = 'selling close';
        insert testStore; 
        
        ID CURRENT_USER = UserInfo.getUserId();
        Employee__c employee = new Employee__c();
        employee.user__c = CURRENT_USER;
        employee.BWDefaultKMChannel__c = 'ACC';
        insert employee;
        
        EmployeeStoreRetail__c empStr = new EmployeeStoreRetail__c();
        empStr.Employee__c = employee.Id;
        empStr.Store__c = testStore.Id;
        insert empStr;
        RetailCheckinQueue__c dciQueue = new RetailCheckinQueue__c();
        dciQueue.Store__c = testStore.Id;
        dciQueue.Status__c = DCIConstants.ALL_PENDING[0];
        dciQueue.ArrivingTime__c = System.now().addDays(1);
        dciQueue.QueuePosition__c = 1;
        dciQueue.EstimatedWaitTime__c = 10;
        dciQueue.LastMessageReceived__c ='C';
        insert dciQueue;  
        
        /* EmployeeStoreRetail__c retStoreRetail = new EmployeeStoreRetail__c();
        retStoreRetail.Employee__c= employee.Id;
        retStoreRetail.Store__c = testStore.Id;
        
       List<RetailCheckinQueue__c> dciQueue = new List<RetailCheckinQueue__c>();
        dciQueue.add(new RetailCheckinQueue__c(Store__c =testStore.Id,Status__c = DCIConstants.ALL_PENDING[0],QueuePosition__c = 1));
        dciQueue.add(new RetailCheckinQueue__c(Store__c =testStore.Id,Status__c = 'Arrived',QueuePosition__c = 1));
        insert dciQueue;*/
    }
    @IsTest
    static void test_getRetailQueues(){
        
        Test.startTest();
        List<RetailCheckinQueue__c> dciQueues=customerUpNextController.getRetailQueues(49999);
        system.assertEquals(1, dciQueues.size());
        Test.stopTest();
        
    } 
}