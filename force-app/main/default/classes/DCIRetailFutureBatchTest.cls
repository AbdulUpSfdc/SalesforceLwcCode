@isTest
public class DCIRetailFutureBatchTest {
    private static TestDataFactory.TestWrapper dataFactoryWrap = new TestDataFactory.TestWrapper();
    private static TestDataFactory dataFactory = new TestDataFactory();
    
    @TestSetup
    static void setUpData(){
        dataFactoryWrap = dataFactory.createTestData(1,'SMSTest');
        insert new RetailCustomSetting__c(Name= 'DCIATTURL', Key__c = 'DCIATTURL', KeyValue__c  = 'https://www.att.com/support/checkin/W{0}');
    }
    
    @isTest
    static void testFutureBatchOneHour(){
        String recordType = RetailConstants.DIGITALCHECKIN_RECORDTYPE;
        insert new RetailCustomSetting__c(Name= 'PST', Key__c = 'PST', KeyValue__c  = 'America/Los_Angeles');
        List<Store__c> lstStore = [SELECT id FROM Store__c WHERE Name LIKE '%store%'];
        lstStore[0].Address2__c = 'Test address';
        lstStore[0].TimeZone__c = 'PST';
        update lstStore[0];
        
        MessagingSession ms = dataFactory.getMessagingSession(recordType, 'SMSDCI');
        if (ms != null) {
            Lead lead = [SELECT Id, DCICheckinType__c , MobilePhone FROM Lead WHERE LastName = 'SMSDCI'];
            lead.DCICheckinType__c = 'Future';
            lead.SmsConsent__c = 'Yes';
            update lead;
            
            List<RetailCheckinQueue__c> dciCheckInList = new List<RetailCheckinQueue__c>();
            RetailCheckinQueue__c newCheckinDci= new RetailCheckinQueue__c();
            newCheckinDci.Status__c = DCIConstants.INSTORE;
            newCheckinDci.Store__c = lstStore[0].Id;
            newCheckinDci.ArrivingTime__c = System.now().addMinutes(55);
            newCheckinDci.CheckInTime__c = System.now().addMinutes(55);
            newCheckinDci.QueuePosition__c = 1;
            newCheckinDci.EstimatedWaitTime__c = 10;
            newCheckinDci.Lead__c = lead.Id;
            newCheckinDci.LastMessageReceived__c ='C';
            
            RetailCheckinQueue__c newCheckinDci2= new RetailCheckinQueue__c();
            newCheckinDci2.Status__c = DCIConstants.INSTORE;
            newCheckinDci2.Store__c = lstStore[0].Id;
            newCheckinDci2.ArrivingTime__c = System.now().addDays(1);
            newCheckinDci2.QueuePosition__c = 2;
            newCheckinDci2.EstimatedWaitTime__c = 10;
            newCheckinDci2.LastMessageReceived__c ='C';
            dciCheckInList.add(newCheckinDci);
            dciCheckInList.add(newCheckinDci2);
            insert dciCheckInList;
            
            Test.startTest();
            database.executeBatch(new DCIRetailFutureAlertBatch(System.now(), new Set<String>{newCheckinDci.Id, newCheckinDci2.Id}));
            Test.stopTest();
            RetailCheckinQueue__c newCheckinDciUpdated = [SELECT Id, Batch_SMS_Status__c FROM RetailCheckinQueue__c WHERE Id = :newCheckinDci.Id];
            System.assertEquals('1HR', newCheckinDciUpdated.Batch_SMS_Status__c);
        }
    }
    
    @isTest
    static void testFutureBatchFifteenMinutes(){
        String recordType = RetailConstants.DIGITALCHECKIN_RECORDTYPE;
        
        List<Store__c> lstStore = [SELECT id,Address2__c FROM Store__c WHERE Name LIKE '%store%'];
        
        MessagingSession ms = dataFactory.getMessagingSession(recordType, 'SMSDCI');
        if (ms != null) {
            Lead lead = [SELECT Id, DCICheckinType__c , MobilePhone FROM Lead WHERE LastName = 'SMSDCI'];
            lead.DCICheckinType__c = 'Future';
            lead.SmsConsent__c = 'Yes';
            update lead;
            
            List<RetailCheckinQueue__c> dciCheckInList = new List<RetailCheckinQueue__c>();
            RetailCheckinQueue__c newCheckinDci= new RetailCheckinQueue__c();
            newCheckinDci.Status__c = DCIConstants.INSTORE;
            newCheckinDci.Store__c = lstStore[0].Id;
            newCheckinDci.ArrivingTime__c = System.now().addMinutes(10);
            newCheckinDci.CheckInTime__c = System.now().addMinutes(10);
            newCheckinDci.EstimatedWaitTime__c = 10;
            newCheckinDci.Lead__c = lead.Id;
            newCheckinDci.LastMessageReceived__c ='C';
            dciCheckInList.add(newCheckinDci);
            insert dciCheckInList;
            
            Test.startTest();
            database.executeBatch(new DCIRetailFutureBatch());
            Test.stopTest();
            
            RetailCheckinQueue__c newCheckinDciUpdated = [SELECT Id, QueuePosition__c FROM RetailCheckinQueue__c WHERE Id = :newCheckinDci.Id];
            System.assertEquals(1, newCheckinDciUpdated.QueuePosition__c);
        }
    }
    
    @isTest
    static void testFutureBatchFifteenMinutesWithQueue(){
        String recordType = RetailConstants.DIGITALCHECKIN_RECORDTYPE;
        
        List<Store__c> lstStore = [SELECT id,Address2__c FROM Store__c WHERE Name LIKE '%store%'];
        lstStore[0].Address2__c = 'Test address';
        lstStore[0].TimeZone__c = 'EST';
        update lstStore[0];
       
        MessagingSession ms = dataFactory.getMessagingSession(recordType, 'SMSDCI');
        if (ms != null) {
            Lead lead = [SELECT Id, DCICheckinType__c , MobilePhone FROM Lead WHERE LastName = 'SMSDCI'];
            lead.DCICheckinType__c = 'Future';
            lead.SmsConsent__c = 'Yes';
            update lead;
            
            List<RetailCheckinQueue__c> dciCheckInList = new List<RetailCheckinQueue__c>();
            RetailCheckinQueue__c newCheckinDci= new RetailCheckinQueue__c();
            newCheckinDci.Status__c = DCIConstants.INSTORE;
            newCheckinDci.Store__c = lstStore[0].Id;
            newCheckinDci.ArrivingTime__c = System.now().addMinutes(10);
            newCheckinDci.CheckInTime__c = System.now().addMinutes(10);
            newCheckinDci.EstimatedWaitTime__c = 10;
            newCheckinDci.Lead__c = lead.Id;
            newCheckinDci.LastMessageReceived__c ='C';
            
            RetailCheckinQueue__c newCheckinDci2= new RetailCheckinQueue__c();
            newCheckinDci2.Status__c = DCIConstants.INSTORE;
            newCheckinDci2.Store__c = lstStore[0].Id;
            newCheckinDci2.ArrivingTime__c = System.now().addDays(1);
            newCheckinDci2.QueuePosition__c = 1;
            newCheckinDci2.EstimatedWaitTime__c = 10;
            newCheckinDci2.LastMessageReceived__c ='C';
            dciCheckInList.add(newCheckinDci);
            dciCheckInList.add(newCheckinDci2);
            insert dciCheckInList;
            
            Test.startTest();
            database.executeBatch(new DCIRetailFutureBatch());
            Test.stopTest();
            
            RetailCheckinQueue__c newCheckinDciUpdated = [SELECT Id, QueuePosition__c FROM RetailCheckinQueue__c WHERE Id = :newCheckinDci.Id];
            RetailCheckinQueue__c newCheckinDci2Updated = [SELECT Id, QueuePosition__c FROM RetailCheckinQueue__c WHERE Id = :newCheckinDci2.Id];
            System.assertEquals(1, newCheckinDciUpdated.QueuePosition__c);
            System.assertEquals(2, newCheckinDci2Updated.QueuePosition__c);
        }
    }
    
    @isTest
    static void testFutureBatchFifteenMinutesNoQueue(){
        String recordType = RetailConstants.DIGITALCHECKIN_RECORDTYPE;
        
        List<Store__c> lstStore = [SELECT id,Address2__c FROM Store__c WHERE Name LIKE '%store%'];
       
        MessagingSession ms = dataFactory.getMessagingSession(recordType, 'SMSDCI');
        if (ms != null) {
            Lead lead = [SELECT Id, DCICheckinType__c , MobilePhone FROM Lead WHERE LastName = 'SMSDCI'];
            lead.DCICheckinType__c = 'Future';
            lead.SmsConsent__c = 'Yes';
            update lead;
            
            List<RetailCheckinQueue__c> dciCheckInList = new List<RetailCheckinQueue__c>();
            RetailCheckinQueue__c newCheckinDci= new RetailCheckinQueue__c();
            newCheckinDci.Status__c = DCIConstants.INSTORE;
            newCheckinDci.Store__c = lstStore[0].Id;
            newCheckinDci.ArrivingTime__c = System.now().addMinutes(10);
            newCheckinDci.CheckInTime__c = System.now().addMinutes(10);
            newCheckinDci.QueuePosition__c = 1;
            newCheckinDci.EstimatedWaitTime__c = 10;
            newCheckinDci.Lead__c = lead.Id;
            newCheckinDci.LastMessageReceived__c ='C';
            insert newCheckinDci;
            
            Test.startTest();
            database.executeBatch(new DCIRetailFutureAlertBatch(System.now(), new Set<String>{newCheckinDci.Id}));
            Test.stopTest();
            
            RetailCheckinQueue__c newCheckinDciUpdated = [SELECT Id, Batch_SMS_Status__c FROM RetailCheckinQueue__c WHERE Id = :newCheckinDci.Id];
            System.assertEquals('15MIN', newCheckinDciUpdated.Batch_SMS_Status__c);
        }
    }
    
    @isTest
    static void testDCIRetailFutureBatchScheduler() {        
        test.starttest();
        DCIRetailFutureBatchScheduler dciRetailFutureBatchSched = new DCIRetailFutureBatchScheduler ();   
        String cron = '0 0 23 * * ?';        
        system.schedule('Test DCI Retail Future Batch Scheduled', cron, dciRetailFutureBatchSched);
        test.stopTest();
    }
    
    @isTest
    static void testFutureBatchAlert15MINQNE(){
        String recordType = RetailConstants.DIGITALCHECKIN_RECORDTYPE;
        
        List<Store__c> lstStore = [SELECT id,Address2__c FROM Store__c WHERE Name LIKE '%store%'];
       
        MessagingSession ms = dataFactory.getMessagingSession(recordType, 'SMSDCI');
        if (ms != null) {
            Lead lead = [SELECT Id, DCICheckinType__c , MobilePhone FROM Lead WHERE LastName = 'SMSDCI'];
            lead.DCICheckinType__c = 'Future';
            lead.SmsConsent__c = 'Yes';
            update lead;
            
            List<RetailCheckinQueue__c> dciCheckInList = new List<RetailCheckinQueue__c>();
            RetailCheckinQueue__c newCheckinDci= new RetailCheckinQueue__c();
            newCheckinDci.Status__c = DCIConstants.INSTORE;
            newCheckinDci.Store__c = lstStore[0].Id;
            newCheckinDci.ArrivingTime__c = System.now().addMinutes(10);
            newCheckinDci.CheckInTime__c = System.now().addMinutes(10);
            newCheckinDci.EstimatedWaitTime__c = 10;
            newCheckinDci.Lead__c = lead.Id;
            newCheckinDci.LastMessageReceived__c ='C';
            insert newCheckinDci;
            
            Test.startTest();
            database.executeBatch(new DCIRetailFutureAlertBatch(System.now(), new Set<String>{newCheckinDci.Id}));
            Test.stopTest();
            
            RetailCheckinQueue__c newCheckinDciUpdated = [SELECT Id, Batch_SMS_Status__c FROM RetailCheckinQueue__c WHERE Id = :newCheckinDci.Id];
            System.assertEquals('15MIN', newCheckinDciUpdated.Batch_SMS_Status__c);
        }
    }
    
}