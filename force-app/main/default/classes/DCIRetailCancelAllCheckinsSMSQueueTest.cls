@isTest
    public with sharing class DCIRetailCancelAllCheckinsSMSQueueTest {
        @IsTest
        static void testDCIScenarios(){
      
            RetailCustomSetting__c smsSettings = new RetailCustomSetting__c();
            smsSettings.Name = 'WelcomeSMSForOnlineLeads';
            smsSettings.KeyValue__c = 'true';
            insert smsSettings;
        insert new RetailCustomSetting__c(Name= 'DCIATTURL', Key__c = 'DCIATTURL', KeyValue__c  = 'https://www.att.com/support/checkin/W{0}');
           
            Lead testLead = new Lead();
            testLead.FirstName='Test';
            testLead.LastName='Test';
            testLead.ReasonforLeaving__c ='Did Not Have Time';
            insert  testLead;      
            String leadId = testLead.id;
           
            
            Lead testLead1 = new Lead();
            testLead1.FirstName='Test';
            testLead1.LastName='Test';
            testLead1.DCICheckinType__c = DCIConstants.FUTURE;
            testLead1.ReasonforLeaving__c ='Did Not Have Time';
            
            Store__c testStore = new Store__c();
            testStore.Name = 'test_Store';
            testStore.LocationType__c = RetailConstants.IHX_LOCATIONTYPE;
            testStore.LocationId__c = 'DCILead';
            testStore.status__c = 'selling close';
            insert testStore;
            User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
            System.runAs ( thisUser ) {
                Group g = new Group(Type='Queue', Name=testStore.Name);
                insert g;
                QueueSObject q1 = new QueueSObject(SobjectType='Lead', QueueId=g.Id);
                insert q1;
                QueueSObject q2 = new QueueSObject(SobjectType='RetailCheckinQueue__c', QueueId=g.Id);
                insert q2;
            }
            StoreHandleTime__c storeHandle = new StoreHandleTime__c();
            storeHandle.TransactionType__c = 'Upgrade or trade in phone';
            storeHandle.HandleTime__c = 10;
            storeHandle.Store__c=testStore.id;
            insert storeHandle;
            
            Employee__c emp = new Employee__c();
            emp.User__c = UserInfo.getUserId();
            insert emp;
            
            EmployeeStoreRetail__c empStr = new EmployeeStoreRetail__c();
            empStr.Employee__c = emp.Id;
            empStr.Store__c = testStore.Id;
            empStr.DCIPresenceStatus__c = 'Online';
            insert empStr;
            
            RetailCheckinQueue__c dciQueue = new RetailCheckinQueue__c();
            dciQueue.Store__c = testStore.Id;
            dciQueue.Status__c = DCIConstants.ALL_PENDING[0];
            dciQueue.ArrivingTime__c = System.now().addDays(1);
            dciQueue.CheckInTime__c = System.now();
            dciQueue.QueuePosition__c = 1;
            dciQueue.EstimatedWaitTime__c = 10;
            dciQueue.LastMessageReceived__c ='C';
            dciQueue.Lead__c = testLead.Id;
            insert dciQueue;
            Set<Id> checkinRecordId = new Set<Id>();
            checkinRecordId.add(dciQueue.Id);
            Test.startTest();
            DCIRetailCancelAllCheckinsSMSQueuable sendSMSQueue = new DCIRetailCancelAllCheckinsSMSQueuable(checkinRecordId);
            System.enqueueJob(sendSMSQueue);
            Test.stopTest();
        }
    }