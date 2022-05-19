/*
    * DCIChangeCustomerStatusController Test Class 
    * Last modified on - 03/17/2021
    * Last modified by - Akshay Kumar akshay.kumar@salesforce.com
    *   3/3/2021 - Daniel Muldoon - Added code coverage for new move up in queue functionality
    *                               and existing functionality
    */
    @isTest
    public with sharing class DCIChangeCustomerStatusControllerTest {
        private static TestDataFactory.TestWrapper dataFactoryWrap = new TestDataFactory.TestWrapper();
        private static TestDataFactory dataFactory = new TestDataFactory();
        @IsTest
        static void testupdateLeadWithRep(){
            RetailCheckinQueue__c checkInQueue = New RetailCheckinQueue__c();
            checkInQueue.Status__c = DCIConstants.INSTORE;
            checkInQueue.ArrivingTime__c = System.now().addDays(1);
            insert checkInQueue;
            ApexPages.StandardController sc = new ApexPages.StandardController(checkInQueue);
            DCIChangeCustomerStatusController controller = new DCIChangeCustomerStatusController(sc);
            DCIChangeCustomerStatusController.updateLeadWithRep(checkInQueue.id,userinfo.getUserId(),userinfo.getFirstName());
        }
        @IsTest
        static void testChangeCustomerStatus(){
            RetailCheckinQueue__c checkInQueue = New RetailCheckinQueue__c();
            checkInQueue.Status__c = DCIConstants.INSTORE;
            checkInQueue.ArrivingTime__c = System.now().addDays(1);
            insert checkInQueue;
    
            List<RetailCheckinQueue__c> customerCheckInsList = [Select id, Status__c, ArrivingTime__c, DCITimeWaiting__c, ElapsedWaitTime__c, EstimatedWaitTime__c FROM RetailCheckinQueue__c WHERE Id =: checkInQueue.Id];
            Datetime arrivingTime = customerCheckInsList[0].ArrivingTime__c;
            Long milliseconds = System.now().getTime() - arrivingTime.getTime();
            Long seconds = milliseconds / 1000;
            Long minutes = seconds / 60;
            String action=DCIConstants.MARK_ARRIVED;
           
    
            Test.startTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(checkInQueue);
            DCIChangeCustomerStatusController controller = new DCIChangeCustomerStatusController(sc);
            
            DCIChangeCustomerStatusController.changeCustomerStatus(customerCheckInsList[0].Id,action);
            action=DCIConstants.MARK_PENDING;
            DCIChangeCustomerStatusController.changeCustomerStatus(customerCheckInsList[0].Id,action);
            action=DCIConstants.HELP_NEXT;
            DCIChangeCustomerStatusController.changeCustomerStatus(customerCheckInsList[0].Id,action);
            
            //System.assertEquals(System.Label.DCIStatusUpdateSuccess, DCIChangeCustomerStatusController.result.get('message'));
    
            List<RetailCheckinQueue__c> updatedCustomerCheckInsList = [Select id, Status__c, ArrivingTime__c, DCITimeWaiting__c, ElapsedWaitTime__c, EstimatedWaitTime__c FROM RetailCheckinQueue__c WHERE Id =: checkInQueue.Id];
            System.assertEquals(minutes, updatedCustomerCheckInsList[0].ElapsedWaitTime__c);
            System.assertEquals(DCIConstants.PENDING, updatedCustomerCheckInsList[0].Status__c);
            System.assertEquals(NULL, updatedCustomerCheckInsList[0].ArrivingTime__c);
            Test.stopTest();
        }
        @IsTest
        static void negativeTestChangeCustomerStatus(){
            RetailCheckinQueue__c checkInQueue = New RetailCheckinQueue__c();
            checkInQueue.Status__c = DCIConstants.PENDING;
            checkInQueue.ArrivingTime__c = System.now().addDays(1);
            insert checkInQueue;
            String action=DCIConstants.INSTORE;
    
            List<RetailCheckinQueue__c> customerCheckInsList = [Select id, Status__c, ArrivingTime__c, DCITimeWaiting__c, ElapsedWaitTime__c, EstimatedWaitTime__c FROM RetailCheckinQueue__c WHERE Id =: checkInQueue.Id];
            Test.startTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(checkInQueue);
            DCIChangeCustomerStatusController controller = new DCIChangeCustomerStatusController(sc);
            DCIChangeCustomerStatusController defaultConstructor = new DCIChangeCustomerStatusController();
            
            DCIChangeCustomerStatusController.changeCustomerStatus(customerCheckInsList[0].Id,action);
            // System.assertEquals(System.Label.DCIStatusUpdateSuccess, DCIChangeCustomerStatusController.result.get('message'));
            Test.stopTest();
        }
        
        @isTest
        public static void testMoveQueuePositionUp() {
            dataFactoryWrap = dataFactory.createTestData(2,'DCILead');
            Store__c testStore =  dataFactoryWrap.lstStore[0];
            List<Lead> leadList = dataFactoryWrap.lstLead;
            
            //Create 2 members in Queue
            RetailCheckinQueue__c checkInQueue = New RetailCheckinQueue__c();
            checkInQueue.Status__c = DCIConstants.INSTORE;
            checkInQueue.Store__c = testStore.Id;
            checkInQueue.ArrivingTime__c = System.now().addDays(1);
            checkInQueue.QueuePosition__c = 1;
            checkInQueue.Lead__c = leadList[0].Id;
            checkInQueue.EstimatedWaitTime__c = 10;
            checkInQueue.DCIMaximum_EWT__c = 30;
            checkInQueue.DCIMinimum_EWT__c = 0;
            RetailCheckinQueue__c checkInQueue2 = New RetailCheckinQueue__c();
            checkInQueue2.Status__c = DCIConstants.INSTORE;
            checkInQueue2.Store__c = testStore.Id;
            checkInQueue2.ArrivingTime__c = System.now().addDays(1);
            checkInQueue2.QueuePosition__c = 2;
            checkInQueue2.Lead__c = leadList[1].Id;
            checkInQueue2.EstimatedWaitTime__c = 20;
            checkInQueue.DCIMaximum_EWT__c = 30;
            checkInQueue.DCIMinimum_EWT__c = 0;
            List<RetailCheckinQueue__c> retailCheckInQueueList = new List<RetailCheckinQueue__c>{checkInQueue, checkInQueue2};
            insert retailCheckInQueueList;
            
            Test.startTest();
            
            DCIChangeCustomerStatusController.swapQueuePositions(checkInQueue2.Id, DCIConstants.MOVE_UP);
            
            Test.stopTest();
            
            //Get Updated Record
            RetailCheckinQueue__c checkInQueueUpdatedRecord = [SELECT Id, QueuePosition__c FROM RetailCheckinQueue__c WHERE Id = :checkInQueue2.Id];
            System.assertEquals(1, checkInQueueUpdatedRecord.QueuePosition__c, 'Queue Position was not updated as expected.');
        }
        
        @isTest
        public static void testMoveQueuePositionUpNonArrived() {
            dataFactoryWrap = dataFactory.createTestData(2,'DCILead');
            Store__c testStore =  dataFactoryWrap.lstStore[0];
            List<Lead> leadList = dataFactoryWrap.lstLead;
            
            //Create 2 members in Queue
            RetailCheckinQueue__c checkInQueue = New RetailCheckinQueue__c();
            checkInQueue.Status__c = DCIConstants.PENDING;
            checkInQueue.Store__c = testStore.Id;
            checkInQueue.ArrivingTime__c = System.now().addDays(1);
            checkInQueue.QueuePosition__c = 1;
            checkInQueue.Lead__c = leadList[0].Id;
            checkInQueue.EstimatedWaitTime__c = 10;
            RetailCheckinQueue__c checkInQueue2 = New RetailCheckinQueue__c();
            checkInQueue2.Status__c = DCIConstants.PENDING;
            checkInQueue2.Store__c = testStore.Id;
            checkInQueue2.ArrivingTime__c = System.now().addDays(1);
            checkInQueue2.QueuePosition__c = 2;
            checkInQueue2.Lead__c = leadList[1].Id;
            checkInQueue2.EstimatedWaitTime__c = 20;
            List<RetailCheckinQueue__c> retailCheckInQueueList = new List<RetailCheckinQueue__c>{checkInQueue, checkInQueue2};
            insert retailCheckInQueueList;
            
            Test.startTest();
            
            map<String, String> returnMap = DCIChangeCustomerStatusController.swapQueuePositions(checkInQueue2.Id, DCIConstants.MOVE_UP);
            
            Test.stopTest();
            
            //Get Updated Record
            RetailCheckinQueue__c checkInQueueUpdatedRecord = [SELECT Id, QueuePosition__c FROM RetailCheckinQueue__c WHERE Id = :checkInQueue2.Id];
            System.assertEquals(2, checkInQueueUpdatedRecord.QueuePosition__c, 'Queue Position was not updated as expected.');
            System.assertEquals('error', returnMap.get('type'));
        }
        
        @isTest
        public static void testMoveQueuePositionUpException() {
            dataFactoryWrap = dataFactory.createTestData(2,'DCILead');
            Store__c testStore =  dataFactoryWrap.lstStore[0];
            List<Lead> leadList = dataFactoryWrap.lstLead;
            
            //Create 2 members in Queue with missing data
            RetailCheckinQueue__c checkInQueue = New RetailCheckinQueue__c();
            checkInQueue.Status__c = DCIConstants.INSTORE;
            checkInQueue.Store__c = testStore.Id;
            checkInQueue.ArrivingTime__c = System.now().addDays(1);
            checkInQueue.QueuePosition__c = 1;
            RetailCheckinQueue__c checkInQueue2 = New RetailCheckinQueue__c();
            checkInQueue2.Status__c = DCIConstants.INSTORE;
            checkInQueue2.Store__c = testStore.Id;
            checkInQueue2.ArrivingTime__c = System.now().addDays(1);
            checkInQueue2.QueuePosition__c = 2;
            List<RetailCheckinQueue__c> retailCheckInQueueList = new List<RetailCheckinQueue__c>{checkInQueue, checkInQueue2};
            insert retailCheckInQueueList;
            
            Test.startTest();
            
            map<String, String> returnMap = DCIChangeCustomerStatusController.swapQueuePositions(checkInQueue2.Id, DCIConstants.MOVE_UP);
            
            Test.stopTest();
            
            //Get Updated Record
            RetailCheckinQueue__c checkInQueueUpdatedRecord = [SELECT Id, QueuePosition__c FROM RetailCheckinQueue__c WHERE Id = :checkInQueue2.Id];
            System.assertEquals(2, checkInQueueUpdatedRecord.QueuePosition__c, 'Queue Position was not updated as expected.');
            System.assertEquals('error', returnMap.get('type'));
        }
        
        @isTest
        public static void testMoveQueuePositionUpOnlyOneInQueue() {
            dataFactoryWrap = dataFactory.createTestData(1,'DCILead');
            Store__c testStore =  dataFactoryWrap.lstStore[0];
            List<Lead> leadList = dataFactoryWrap.lstLead;
            
            //Create 1 member in queue
            RetailCheckinQueue__c checkInQueue = New RetailCheckinQueue__c();
            checkInQueue.Status__c = DCIConstants.INSTORE;
            checkInQueue.Store__c = testStore.Id;
            checkInQueue.ArrivingTime__c = System.now().addDays(1);
            checkInQueue.QueuePosition__c = 1;
            checkInQueue.Lead__c = leadList[0].Id;
            checkInQueue.EstimatedWaitTime__c = 10;
            List<RetailCheckinQueue__c> retailCheckInQueueList = new List<RetailCheckinQueue__c>{checkInQueue};
            insert retailCheckInQueueList;
            
            Test.startTest();
            
            map<String, String> returnMap = DCIChangeCustomerStatusController.swapQueuePositions(checkInQueue.Id, DCIConstants.MOVE_UP);
            
            Test.stopTest();
            
            //Get Updated Record
            RetailCheckinQueue__c checkInQueueUpdatedRecord = [SELECT Id, QueuePosition__c FROM RetailCheckinQueue__c WHERE Id = :checkInQueue.Id];
            System.assertEquals('error', returnMap.get('type'));
        }
        
        @isTest
        public static void testValidateStatusMarkPendingValid() {
            dataFactoryWrap = dataFactory.createTestData(1,'DCILead');
            Store__c testStore =  dataFactoryWrap.lstStore[0];
            List<Lead> leadList = dataFactoryWrap.lstLead;
            
            //Create 1 member in queue
            RetailCheckinQueue__c checkInQueue = New RetailCheckinQueue__c();
            checkInQueue.Status__c = DCIConstants.INSTORE;
            checkInQueue.Store__c = testStore.Id;
            checkInQueue.ArrivingTime__c = System.now().addDays(1);
            checkInQueue.QueuePosition__c = 1;
            checkInQueue.Lead__c = leadList[0].Id;
            checkInQueue.EstimatedWaitTime__c = 10;
            List<RetailCheckinQueue__c> retailCheckInQueueList = new List<RetailCheckinQueue__c>{checkInQueue};
            insert retailCheckInQueueList;
            
            Test.startTest();
            
            Map<String, Object> returnMap = DCIChangeCustomerStatusController.validateStatus(checkInQueue.Id, DCIConstants.MARK_PENDING);
            
            Test.stopTest();
            
            System.assert((Boolean) returnMap.get('isValid'));
        }
        
        @isTest
        public static void testValidateStatusMarkPendingInvalid() {
            dataFactoryWrap = dataFactory.createTestData(1,'DCILead');
            Store__c testStore =  dataFactoryWrap.lstStore[0];
            List<Lead> leadList = dataFactoryWrap.lstLead;
            
            //Create 1 member in queue
            RetailCheckinQueue__c checkInQueue = New RetailCheckinQueue__c();
            checkInQueue.Status__c = DCIConstants.CANCELLED;
            checkInQueue.Store__c = testStore.Id;
            checkInQueue.ArrivingTime__c = System.now().addDays(1);
            checkInQueue.QueuePosition__c = 1;
            checkInQueue.Lead__c = leadList[0].Id;
            checkInQueue.EstimatedWaitTime__c = 10;
            List<RetailCheckinQueue__c> retailCheckInQueueList = new List<RetailCheckinQueue__c>{checkInQueue};
            insert retailCheckInQueueList;
            
            Test.startTest();
            
            Map<String, Object> returnMap = DCIChangeCustomerStatusController.validateStatus(checkInQueue.Id, DCIConstants.MARK_PENDING);
            
            Test.stopTest();
            
            System.assert(!((Boolean) returnMap.get('isValid')));
        }
        
        @isTest
        public static void testValidateStatusMarkArrivedValid() {
            dataFactoryWrap = dataFactory.createTestData(1,'DCILead');
            Store__c testStore =  dataFactoryWrap.lstStore[0];
            List<Lead> leadList = dataFactoryWrap.lstLead;
            
            //Create 1 member in queue
            RetailCheckinQueue__c checkInQueue = New RetailCheckinQueue__c();
            checkInQueue.Status__c = DCIConstants.PENDING;
            checkInQueue.Store__c = testStore.Id;
            checkInQueue.ArrivingTime__c = System.now().addDays(1);
            checkInQueue.QueuePosition__c = 1;
            checkInQueue.Lead__c = leadList[0].Id;
            checkInQueue.EstimatedWaitTime__c = 10;
            List<RetailCheckinQueue__c> retailCheckInQueueList = new List<RetailCheckinQueue__c>{checkInQueue};
            insert retailCheckInQueueList;
            
            Test.startTest();
            
            Map<String, Object> returnMap = DCIChangeCustomerStatusController.validateStatus(checkInQueue.Id, DCIConstants.MARK_ARRIVED);
            
            Test.stopTest();
            
            System.assert((Boolean) returnMap.get('isValid'));
        }
        
        @isTest
        public static void testValidateStatusMarkArrivedInvalid() {
            dataFactoryWrap = dataFactory.createTestData(1,'DCILead');
            Store__c testStore =  dataFactoryWrap.lstStore[0];
            List<Lead> leadList = dataFactoryWrap.lstLead;
            
            //Create 1 member in queue
            RetailCheckinQueue__c checkInQueue = New RetailCheckinQueue__c();
            checkInQueue.Status__c = DCIConstants.CANCELLED;
            checkInQueue.Store__c = testStore.Id;
            checkInQueue.ArrivingTime__c = System.now().addDays(1);
            checkInQueue.QueuePosition__c = 1;
            checkInQueue.Lead__c = leadList[0].Id;
            checkInQueue.EstimatedWaitTime__c = 10;
            List<RetailCheckinQueue__c> retailCheckInQueueList = new List<RetailCheckinQueue__c>{checkInQueue};
            insert retailCheckInQueueList;
            
            Test.startTest();
            
            Map<String, Object> returnMap = DCIChangeCustomerStatusController.validateStatus(checkInQueue.Id, DCIConstants.MARK_ARRIVED);
            
            Test.stopTest();
            
            System.assert(!((Boolean) returnMap.get('isValid')));
        }
        
        @isTest
        public static void testValidateStatusMoveUpValid() {
            dataFactoryWrap = dataFactory.createTestData(1,'DCILead');
            Store__c testStore =  dataFactoryWrap.lstStore[0];
            List<Lead> leadList = dataFactoryWrap.lstLead;
            
            //Create 1 member in queue
            RetailCheckinQueue__c checkInQueue = New RetailCheckinQueue__c();
            checkInQueue.Status__c = DCIConstants.INSTORE;
            checkInQueue.Store__c = testStore.Id;
            checkInQueue.ArrivingTime__c = System.now().addDays(1);
            checkInQueue.QueuePosition__c = 1;
            checkInQueue.Lead__c = leadList[0].Id;
            checkInQueue.EstimatedWaitTime__c = 10;
            List<RetailCheckinQueue__c> retailCheckInQueueList = new List<RetailCheckinQueue__c>{checkInQueue};
            insert retailCheckInQueueList;
            
            Test.startTest();
            
            Map<String, Object> returnMap = DCIChangeCustomerStatusController.validateStatus(checkInQueue.Id, DCIConstants.MOVE_UP);
            
            Test.stopTest();
            
            System.assert((Boolean) returnMap.get('isValid'));
        }
        
        @isTest
        public static void testValidateStatusMoveUpInvalid() {
            dataFactoryWrap = dataFactory.createTestData(1,'DCILead');
            Store__c testStore =  dataFactoryWrap.lstStore[0];
            List<Lead> leadList = dataFactoryWrap.lstLead;
            
            //Create 1 member in queue
            RetailCheckinQueue__c checkInQueue = New RetailCheckinQueue__c();
            checkInQueue.Status__c = DCIConstants.CANCELLED;
            checkInQueue.Store__c = testStore.Id;
            checkInQueue.ArrivingTime__c = System.now().addDays(1);
            checkInQueue.QueuePosition__c = 1;
            checkInQueue.Lead__c = leadList[0].Id;
            checkInQueue.EstimatedWaitTime__c = 10;
            List<RetailCheckinQueue__c> retailCheckInQueueList = new List<RetailCheckinQueue__c>{checkInQueue};
            insert retailCheckInQueueList;
            
            Test.startTest();
            
            Map<String, Object> returnMap = DCIChangeCustomerStatusController.validateStatus(checkInQueue.Id, DCIConstants.MOVE_UP);
            
            Test.stopTest();
            
            System.assert(!((Boolean) returnMap.get('isValid')));   
        }
        
        @isTest
        public static void setMarkNoShowValid()
        {
            Store__c store = new Store__c(Name = '001');
            store.LocationType__c = RetailConstants.IHX_LOCATIONTYPE;
            store.LocationId__c = '001';
            insert store;
            
            Lead newLead1=new Lead(company='Test company1', firstname='Joe', lastname='Doe', email='test@test.org',DCIActualServiceStartTime__c=DateTime.newInstance(2021,02,03,14,0,0));
            insert newLead1;
            
            //Create 1 member in queue
            RetailCheckinQueue__c checkInQueue = New RetailCheckinQueue__c();
            checkInQueue.Status__c = DCIConstants.CANCELLED;
            checkInQueue.store__c=store.id;
            checkInQueue.ArrivingTime__c = System.now().addDays(1);
            checkInQueue.QueuePosition__c = 1;
            checkInQueue.Lead__c = newLead1.Id;
            checkInQueue.EstimatedWaitTime__c = 10;
            List<RetailCheckinQueue__c> retailCheckInQueueList = new List<RetailCheckinQueue__c>{checkInQueue};
            insert retailCheckInQueueList;
            
            Test.startTest();
            
            Map<String, Object> returnMap = DCIChangeCustomerStatusController.validateStatus(checkInQueue.Id, DCIConstants.MARK_NOSHOW);
            DCIChangeCustomerStatusController.validateStatus(checkInQueue.Id, DCIConstants.ASSIGN_CUSTOMER);
            DCIChangeCustomerStatusController.validateStatus(checkInQueue.Id, DCIConstants.MARK_REMOVE);
            
            Test.stopTest();
            System.assert(!((Boolean) returnMap.get('isValid')));   
        }
    
        @isTest
        public static void setMarkNoShowInValid()
        {
            User uTemp=[Select id,name from user where isactive=true and id=:UserInfo.getUserId()];
            Store__c store = new Store__c(Name = '001');
            store.LocationType__c = RetailConstants.IHX_LOCATIONTYPE;
            store.LocationId__c = '001';
            insert store;
    
            Employee__c newEmp=new Employee__c();
            newEmp.HomeStoreLocation__c=store.id;
            newEmp.user__c=uTemp.id;
            insert newEmp;
            
            EmployeeStoreRetail__c esr=new EmployeeStoreRetail__c();
            esr.name=uTemp.name;
            esr.Employee__c=newEmp.id;
            esr.Store__c=store.id;
            //esr.UserIsActive__c=True;
            //esr.user__c=uTemp.id;
            insert esr;
            Lead newLead1=new Lead(company='Test company1', firstname='Joe', lastname='Doe', email='test@test.org',DCIActualServiceStartTime__c=DateTime.newInstance(2021,02,03,14,0,0), RecordTypeId=RetailConstants.DIGITALCHECKIN_RECORDTYPEID,ReasonForLeaving__c='Shop for accessories');
            insert newLead1;
            
            //Create 1 member in queue
            List<RetailCheckinQueue__c> retailCheckInQueueList = new List<RetailCheckinQueue__c>();
            RetailCheckinQueue__c checkInQueue = New RetailCheckinQueue__c();
            checkInQueue.Status__c = DCIConstants.PENDING;
            checkInQueue.store__c=store.id;
            checkInQueue.ArrivingTime__c = System.now().addDays(1);
            checkInQueue.QueuePosition__c = 1;
            checkInQueue.Lead__c = newLead1.Id;
            checkInQueue.EstimatedWaitTime__c = 10;
            retailCheckInQueueList.add(checkInQueue);
            insert retailCheckInQueueList;
            
            Test.startTest();
            
            Map<String, Object> returnMap = DCIChangeCustomerStatusController.validateStatus(checkInQueue.Id, DCIConstants.MARK_NOSHOW);
            DCIChangeCustomerStatusController.changeCustomerStatus(retailCheckInQueueList.get(0).Id, DCIConstants.MARK_NOSHOW);
            Test.stopTest();
            System.assert(!((Boolean) returnMap.get('isValid')));   
            
            EmployeeStoreRetail__c checkESR=[select id, DCIPresenceStatus__c from EmployeeStoreRetail__c  where id =:esr.id];
            System.debug(checkESR);
            //System.assert(checkESR.DCIPresenceStatus__c =='Online'); 
        }
        
        @isTest
        public static void checkRecordMarkedNoShow()
        {
            User uTemp=[Select id,name from user where isactive=true Limit 1];
            Store__c store = new Store__c(Name = '001');
            store.LocationType__c = RetailConstants.IHX_LOCATIONTYPE;
            store.LocationId__c = '001';
            insert store;
            
            Employee__c newEmp=new Employee__c();
            newEmp.HomeStoreLocation__c=store.id;
            newEmp.user__c=uTemp.id;
            insert newEmp;
            
            EmployeeStoreRetail__c esr=new EmployeeStoreRetail__c();
            esr.name=uTemp.name;
            esr.Employee__c=newEmp.id;
            esr.Store__c=store.id;
            //esr.UserIsActive__c=True;
            //esr.user__c=uTemp.id;
            insert esr;
            
            Lead newLead1=new Lead(company='Test company1', firstname='Joe', lastname='Doe', email='test@test.org',DCIActualServiceStartTime__c=DateTime.newInstance(2021,02,03,14,0,0));
            insert newLead1;
            
            //Create 1 member in queue
            RetailCheckinQueue__c checkInQueue = New RetailCheckinQueue__c();
            checkInQueue.Status__c = DCIConstants.NOSHOW;
            checkInQueue.store__c=store.id;
            checkInQueue.ArrivingTime__c = System.now().addDays(1);
            checkInQueue.QueuePosition__c = 1;
            checkInQueue.Lead__c = newLead1.Id;
            checkInQueue.EstimatedWaitTime__c = 10;
            List<RetailCheckinQueue__c> retailCheckInQueueList = new List<RetailCheckinQueue__c>{checkInQueue};
            insert retailCheckInQueueList; 
            
            Test.startTest();
            Map<String, Object> returnMap = DCIChangeCustomerStatusController.validateStatus(checkInQueue.Id, DCIConstants.MARK_NOSHOW);
            DCIChangeCustomerStatusController.changeCustomerStatus(retailCheckInQueueList.get(0).id,DCIConstants.MARK_NOSHOW);
            Test.stopTest();
            
            System.assert(!((Boolean) returnMap.get('isValid')));    
        }
    
        @IsTest// Krishna
        static void testChangeCustomerStatusRemove(){
            RetailCheckinQueue__c checkInQueue = New RetailCheckinQueue__c();
            checkInQueue.Status__c = DCIConstants.PENDING;
            checkInQueue.ArrivingTime__c = System.now().addDays(1);
            insert checkInQueue;
            List<RetailCheckinQueue__c> customerCheckInsList = [Select id, Status__c, ArrivingTime__c, DCITimeWaiting__c, ElapsedWaitTime__c, EstimatedWaitTime__c FROM RetailCheckinQueue__c WHERE Id =: checkInQueue.Id];
            Test.startTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(checkInQueue);
            DCIChangeCustomerStatusController controller = new DCIChangeCustomerStatusController(sc);
    
            DCIChangeCustomerStatusController.changeCustomerStatus(customerCheckInsList[0].Id,DCIConstants.MARK_REMOVE);
            //System.assertEquals(System.Label.DCIStatusUpdateSuccess, DCIChangeCustomerStatusController.result.get('message'));
    
            List<RetailCheckinQueue__c> updatedCustomerCheckInsList = [Select id, Status__c, ArrivingTime__c, DCITimeWaiting__c, ElapsedWaitTime__c, EstimatedWaitTime__c FROM RetailCheckinQueue__c WHERE Id =: checkInQueue.Id];
            //System.assertEquals(DCIConstants.CANCELLED, updatedCustomerCheckInsList[0].Status__c);
            Test.stopTest();
        }
         @IsTest
        static void testChangeCustomerStatusArrived(){
             User uTemp=[Select id,name from user where isactive=true Limit 1];
            Store__c store = new Store__c(Name = '001');
            store.LocationType__c = RetailConstants.IHX_LOCATIONTYPE;
            store.LocationId__c = '001';
            insert store;
            
            Employee__c newEmp=new Employee__c();
            newEmp.HomeStoreLocation__c=store.id;
            newEmp.user__c=uTemp.id;
            insert newEmp;
            
            EmployeeStoreRetail__c esr=new EmployeeStoreRetail__c();
            esr.name=uTemp.name;
            esr.Employee__c=newEmp.id;
            esr.Store__c=store.id;
            //esr.UserIsActive__c=True;
            //esr.user__c=uTemp.id;
            insert esr;
            
            Lead newLead1=new Lead(company='Test company1', firstname='Joe', lastname='Doe', email='test@test.org',DCIActualServiceStartTime__c=DateTime.newInstance(2021,02,03,14,0,0));
            insert newLead1;
            
            //Create 1 member in queue
            RetailCheckinQueue__c checkInQueue = New RetailCheckinQueue__c();
            checkInQueue.Status__c = DCIConstants.NOSHOW;
            checkInQueue.store__c=store.id;
            checkInQueue.ArrivingTime__c = System.now().addDays(1);
            checkInQueue.QueuePosition__c = 1;
            checkInQueue.Lead__c = newLead1.Id;
            checkInQueue.EstimatedWaitTime__c = 10;
            List<RetailCheckinQueue__c> retailCheckInQueueList = new List<RetailCheckinQueue__c>{checkInQueue};
            insert retailCheckInQueueList; 
            
            Test.startTest();
            DCIChangeCustomerStatusController.changeCustomerStatus(retailCheckInQueueList.get(0).id,DCIConstants.MARK_ARRIVED);
            Test.stopTest();
        
        }
    }