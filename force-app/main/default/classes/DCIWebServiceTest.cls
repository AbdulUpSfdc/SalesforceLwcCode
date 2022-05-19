@isTest
public class DCIWebServiceTest {
    
     @isTest
    static void testDCIWebServiceRescheduleErros(){
        Lead testLead = new Lead();
        testLead.FirstName='Test';
        testLead.LastName='Test';
        testLead.ReasonforLeaving__c ='Did Not Have Time';
        insert testLead;
        
        String leadId =  testLead.Id;
            
            //CreateLead.createLead(testLead);
        
        Store__c testStore = new Store__c();
        insert testStore;
        
        Employee__c emp = new Employee__c();
        emp.User__c = UserInfo.getUserId();
        insert emp;
        
        EmployeeStoreRetail__c empStr = new EmployeeStoreRetail__c();
        empStr.Employee__c = emp.Id;
        empStr.Store__c = testStore.Id;
        insert empStr;
        
        RetailCheckinQueue__c dciQueue = new RetailCheckinQueue__c();
        
        
        dciQueue.Status__c = DCIConstants.ALL_PENDING[0];
        dciQueue.QueuePosition__c = 1;
        dciQueue.Lead__c = leadId;
        //insert dciQueue;
        string sdciID = dciQueue.Id;
        DCIConstants dciConst = new DCIConstants();
        
        
        string sJsonbody = '{ '+
                             '"id" : "'+dciQueue.ID+'", '+
                             '"reasonForLeaving__c"   : "Price Too High",'+
                             '"dciOtherVisitReason__c"   : "terminate service",'+
                              '"othernotes__c": "I want to terminate my plan",'+
                              '"checkInTime__c" : "2021-01-31T04:00:00Z" '+                          
                            '}'; 

        
        Restrequest req = new Restrequest();
        RestResponse res = new Restresponse();
        req.requestURI = '/Services/apextest/DCIReschedule/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(sJsonbody);
        Restcontext.request = req;
        Restcontext.response = res;
        DCIWebServiceReschedule.doGet();
        DCIWebServiceReschedule.doPost();
    } 
               
    @isTest
    static void testDCIWebServiceReschedule(){
        Lead testLead = new Lead();
        testLead.FirstName='Test';
        testLead.LastName='Test';
        testLead.ReasonforLeaving__c ='Did Not Have Time';
        insert testLead;
        
        String leadId =  testLead.Id;
            
            //CreateLead.createLead(testLead);
        
        Store__c testStore = new Store__c();
        insert testStore;
        
        Employee__c emp = new Employee__c();
        emp.User__c = UserInfo.getUserId();
        insert emp;
        
        EmployeeStoreRetail__c empStr = new EmployeeStoreRetail__c();
        empStr.Employee__c = emp.Id;
        empStr.Store__c = testStore.Id;
        insert empStr;
        
        RetailCheckinQueue__c dciQueue = new RetailCheckinQueue__c();
        
        
        dciQueue.Status__c = DCIConstants.ALL_PENDING[0];
        dciQueue.QueuePosition__c = 1;
        dciQueue.Lead__c = leadId;
        insert dciQueue;
        string sdciID = dciQueue.Id;
        DCIConstants dciConst = new DCIConstants();
        
        
        string sJsonbody = '{ '+
                             '"id" : "'+dciQueue.ID+'", '+
                             '"reasonForLeaving__c"   : "Price Too High",'+
                             '"dciOtherVisitReason__c"   : "terminate service",'+
                              '"othernotes__c": "I want to terminate my plan",'+
                              '"checkInTime__c" : "2021-01-31T04:00:00Z" '+                          
                            '}'; 

        
        Restrequest req = new Restrequest();
        RestResponse res = new Restresponse();
        req.requestURI = '/Services/apextest/DCIReschedule/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(sJsonbody);
        Restcontext.request = req;
        Restcontext.response = res;
        DCIWebServiceReschedule.doGet();
        DCIWebServiceReschedule.doPost();
        dciQueue.QueuePosition__c = null;
        update dciQueue;
        DCIWebServiceReschedule.doPost();
    } 
    
    @isTest
    static void testDCIWebServiceReschedule1(){
        Lead testLead = new Lead();
        testLead.FirstName='Test';
        testLead.LastName='Test';
        testLead.ReasonforLeaving__c ='Did Not Have Time';
        insert testLead;
        
        String leadId =  testLead.Id;
        
        // CreateLead.createLead(testLead);
        
        Store__c testStore = new Store__c();
        insert testStore;
        
        Employee__c emp = new Employee__c();
        emp.User__c = UserInfo.getUserId();
        insert emp;
        
        EmployeeStoreRetail__c empStr = new EmployeeStoreRetail__c();
        empStr.Employee__c = emp.Id;
        empStr.Store__c = testStore.Id;
        insert empStr;
        
        RetailCheckinQueue__c dciQueue = new RetailCheckinQueue__c();
        
        
        dciQueue.Status__c = DCIConstants.ALL_PENDING[0];
        dciQueue.QueuePosition__c = 1;
        
        insert dciQueue;
        string sdciID = dciQueue.Id;
        DCIConstants dciConst = new DCIConstants();
        
        
        string sJsonbody = '{ '+
                             '"id" : "", '+
                             '"reasonForLeaving__c"   : "Get help with something else",'+
                             '"dciOtherVisitReason__c"   : "terminate service",'+
                              '"othernotes__c": "I want to terminate my plan",'+
                              '"checkInTime__c" : "2021-01-31T04:00:00Z" '+                          
                            '}'; 

        
        Restrequest req = new Restrequest();
        RestResponse res = new Restresponse();
        req.requestURI = '/Services/apextest/DCIReschedule/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(sJsonbody);
        Restcontext.request = req;
        Restcontext.response = res;
        DCIWebServiceReschedule.doGet();
        DCIWebServiceReschedule.doPost();
        dciQueue.QueuePosition__c = null;
        update dciQueue;
        DCIWebServiceReschedule.doPost();
        //DCIService.parseDCIRescheduleJsontoMap(null);
    }
    
    @isTest
    static void testDCIWebService(){
        
        Lead testLead = new Lead();
        testLead.FirstName='Test';
        testLead.LastName='Test';
        testLead.mobilephone ='9876543211';
        testLead.ReasonforLeaving__c ='Did Not Have Time';
        insert testLead;
        
        String leadId =  testLead.Id;
        // CreateLead.createLead(testLead);
        
        Store__c testStore = new Store__c();
        testStore.LocationId__c = '2724';
        insert testStore;
        
        Employee__c emp = new Employee__c();
        emp.User__c = UserInfo.getUserId();
        insert emp;
        
        EmployeeStoreRetail__c empStr = new EmployeeStoreRetail__c();
        empStr.Employee__c = emp.Id;
        empStr.Store__c = testStore.Id;
        insert empStr;
        
        RetailCheckinQueue__c dciQueue = new RetailCheckinQueue__c();
        
        
        dciQueue.Status__c = DCIConstants.ALL_PENDING[0];
        dciQueue.QueuePosition__c = 1;
        dciQueue.Lead__c = leadId;
        insert dciQueue;
        string sdciID = dciQueue.Id;
        DCIConstants dciConst = new DCIConstants();
        
        string sJsonbody = '{ '+
   '"leadrecord": {'+
      '"firstname": "Timmy",'+
      '"lastname": "Doe",'+
      '"store__r.LocationId__c": "2724",'+
      '"mobilephone": "9876543211",'+
      '"email": "a.p@att.com",'+
      '"recordtypeid": "012g0000000E6rxAAC",'+
      '"reasonForLeaving__c": "Get help with something else",'+
      '"dciOtherVisitReason__c": "terminate service",'+
      '"preferredMethodofContact__c": "SMS",'+
	  '"PreferedLanguage__c": "English",'+
      '"emailConsent__c": "No",'+
      '"smsConsent__c": "Yes",'+
      '"callConsent__c": "No",'+
      '"othernotes__c": "I want to terminate my plan",'+
      '"leadSource": "In-Store Check-in",'+
      '"dciCheckinType__c": "Future",'+
      '"dciBOPISOrder__c": ""'+
   '},'+
   '"checkinrecord": {'+
      '"status__c": "Pending",'+
      '"checkInTime__c": "2021-01-31T04:00:00Z"'+
   '}'+
'}';
        
        Restrequest req = new Restrequest();
        RestResponse res = new Restresponse();
        req.requestURI = '/Services/apextest/DCIReschedule/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(sJsonbody);
        Restcontext.request = req;
        Restcontext.response = res;
        DCIWebService.doGet();
        DCIWebService.doPost();
        dciQueue.Status__c = null;
        update dciQueue;
        DCIWebService.doPost();
        
        
    } 
    
    
    
       
    @isTest
    static void testDCIWebService2(){
        
        Lead testLead = new Lead();
        testLead.FirstName='Test';
        testLead.LastName='Test';
        testLead.mobilephone ='9876543211';
        testLead.ReasonforLeaving__c ='Did Not Have Time';
        insert testLead;
        
        String leadId =  testLead.Id;
        // CreateLead.createLead(testLead);
        
        Store__c testStore = new Store__c();
        testStore.LocationId__c = '2724';
        insert testStore;
        
        Employee__c emp = new Employee__c();
        emp.User__c = UserInfo.getUserId();
        emp.EmployeeId__c = '12345';
        insert emp;
        
        EmployeeStoreRetail__c empStr = new EmployeeStoreRetail__c();
        empStr.Employee__c = emp.Id;
        empStr.Store__c = testStore.Id;
        insert empStr;
        
        RetailCheckinQueue__c dciQueue = new RetailCheckinQueue__c();
        
        
        dciQueue.Status__c = DCIConstants.ALL_PENDING[0];
        dciQueue.QueuePosition__c = 1;
        dciQueue.Lead__c = leadId;
        insert dciQueue;
        string sdciID = dciQueue.Id;
        DCIConstants dciConst = new DCIConstants();
        
        string sJsonbody = '{ '+
   '"leadrecord": {'+
      '"firstname": "Timmy",'+
      '"lastname": "Doe",'+
      '"store__r.LocationId__c": "2724",'+
      '"mobilephone": "9876543211",'+
      '"email": "a.p@att.com",'+
      '"recordtypeid": "012g0000000E6rxAAC",'+
      '"reasonForLeaving__c": "Get help with something else",'+
      '"dciOtherVisitReason__c": "terminate service",'+
      '"preferredMethodofContact__c": "SMS",'+
	  '"PreferedLanguage__c": "English",'+
      '"emailConsent__c": "No",'+
      '"smsConsent__c": "Yes",'+
      '"callConsent__c": "No",'+
      '"othernotes__c": "I want to terminate my plan",'+
      '"leadSource": "In-Store Check-in",'+
      '"dciCheckinType__c": "Future",'+
      '"dciBOPISOrder__c": "",'+
      '"owner__c" : "12345"'+
   '},'+
   '"checkinrecord": {'+
      '"status__c": "Pending",'+
      '"checkInTime__c": "2021-01-31T04:00:00Z"'+
   '}'+
'}';
        
        Restrequest req = new Restrequest();
        RestResponse res = new Restresponse();
        req.requestURI = '/Services/apextest/DCIReschedule/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(sJsonbody);
        Restcontext.request = req;
        Restcontext.response = res;
        DCIWebService.doGet();
        DCIWebService.doPost();
        dciQueue.Status__c = null;
        update dciQueue;
        DCIWebService.doPost();
        
        
    } 
    
   
    
    
    @isTest
    static void testDCIWebServiceFail(){
        
        Lead testLead = new Lead();
        testLead.FirstName='Test';
        testLead.LastName='Test';
        testLead.mobilephone ='9876543211';
        testLead.ReasonforLeaving__c ='Did Not Have Time';
        insert testLead;
        
        String leadId =  testLead.Id;
        // CreateLead.createLead(testLead);
        
        Store__c testStore = new Store__c();
        testStore.LocationId__c = '2724';
        insert testStore;
        
        Employee__c emp = new Employee__c();
        emp.User__c = UserInfo.getUserId();
        insert emp;
        
        EmployeeStoreRetail__c empStr = new EmployeeStoreRetail__c();
        empStr.Employee__c = emp.Id;
        empStr.Store__c = testStore.Id;
        insert empStr;
        
        RetailCheckinQueue__c dciQueue = new RetailCheckinQueue__c();
        
        
        dciQueue.Status__c = DCIConstants.ALL_PENDING[0];
        dciQueue.QueuePosition__c = 1;
        dciQueue.Lead__c = leadId;
        insert dciQueue;
        string sdciID = dciQueue.Id;
        DCIConstants dciConst = new DCIConstants();
        
        string sJsonbody = '{ '+
            '"leadrecord" : { '+
                  '"firstname"  : "Timmy",'+
                  '"lastname"   : "Doe",'+
                  '"store__r.LocationId__c"  : "2724",'+
                  '"mobilephone" : "9876543211",'+
                  '"email"       : "a.p@att.com",'+
                  '"recordtypeid"   : "012g0000000E6rxAAC",'+
                  '"reasonForLeaving__c"   : "Get help with something else",'+
                  '"dciOtherVisitReason__c"   : "terminate service",'+
                  '"preferredMethodofContact__c": "SMS",'+
                  '"emailConsent__c": "No",'+
                  '"smsConsent__c": "Yes",'+
                  '"callConsent__c": "No",'+
                  '"othernotes__c": "I want to terminate my plan",'+
                  '"leadSource": "In-Store Check-in",'+
                   '"dciCheckinType__c": "Future",'+
                   '"dciBOPISOrder__c": "" '+       
                  '},'+
            '"checkinrecord": {'+
                     '"status__c" : "Pending",'+
                       '"checkInTime__c" : "2021-01-31T04:00:00Z"'+
                      '}'+
            '}';
        
        Restrequest req = new Restrequest();
        RestResponse res = new Restresponse();
        req.requestURI = '/Services/apextest/DCIReschedule/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(sJsonbody);
        Restcontext.request = req;
        Restcontext.response = res;
        DCIWebService.doGet();
        DCIWebService.doPost();
        dciQueue.Status__c = null;
        update dciQueue;
        DCIWebService.doPost();
        
        
    } 
    
    @isTest
    static void testDCIWebService1(){
        
        Lead testLead = new Lead();
        testLead.FirstName='Test';
        testLead.LastName='Test';
        testLead.mobilephone ='9876543211';
        testLead.ReasonforLeaving__c ='Did Not Have Time';
        insert testLead;
        
        String leadId =  testLead.Id;
        // CreateLead.createLead(testLead);
        
        Store__c testStore = new Store__c();
        testStore.LocationId__c = '2724';
        insert testStore;
        
        Employee__c emp = new Employee__c();
        emp.User__c = UserInfo.getUserId();
        insert emp;
        
        EmployeeStoreRetail__c empStr = new EmployeeStoreRetail__c();
        empStr.Employee__c = emp.Id;
        empStr.Store__c = testStore.Id;
        insert empStr;
        
        RetailCheckinQueue__c dciQueue = new RetailCheckinQueue__c();
        
        
        dciQueue.Status__c = DCIConstants.ALL_PENDING[0];
        dciQueue.QueuePosition__c = 1;
        dciQueue.Lead__c = leadId;
        insert dciQueue;
        string sdciID = dciQueue.Id;
        DCIConstants dciConst = new DCIConstants();
        
        string sJsonbody = '{ '+
                '“errorCode”: “BAD_REQUEST”,'+
                '“statusCode”: “1”,'+
                 '“message”: ”Invalid Record ID sent”'+
                '}';
                
        
        Restrequest req = new Restrequest();
        RestResponse res = new Restresponse();
        req.requestURI = '/Services/apextest/DCIReschedule/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(sJsonbody);
        Restcontext.request = req;
        Restcontext.response = res;
        DCIWebService.doGet();
        DCIWebService.doPost();
        dciQueue.Status__c = null;
        update dciQueue;
        DCIWebService.doPost();
        
        
    }  
    
     @IsTest
    static void BopisCalloutTest(){
        // rmeda test class fix
        //create retailcustom settings for welcome onboarding leads
        RetailCustomSetting__c smsSettings = new RetailCustomSetting__c();
        smsSettings.Name = 'WelcomeSMSForOnlineLeads';
        smsSettings.KeyValue__c = 'true';
        insert smsSettings;
        // rmeda test class fix ends
        Lead testLead = new Lead();
        testLead.FirstName='Test abc';
        testLead.LastName='Test abc';
        testLead.ReasonforLeaving__c ='Did Not Have Time';
       
        insert  testLead;      
        String leadId = testLead.id;
        // CreateLead.createLead(testLead);
       
        Lead testLead1 = new Lead();
        testLead1.FirstName='Test abc';
        testLead1.LastName='Test abc';
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
        insert empStr;
       
        RetailCheckinQueue__c dciQueue = new RetailCheckinQueue__c();
        dciQueue.Store__c = testStore.Id;
        dciQueue.Status__c = DCIConstants.ALL_PENDING[0];
        dciQueue.ArrivingTime__c = System.now().addDays(1);
        dciQueue.QueuePosition__c = 1;
        dciQueue.EstimatedWaitTime__c = 10;
        dciQueue.LastMessageReceived__c ='C';
        dciQueue.Lead__c = testLead.Id;
        insert dciQueue;
        DCIConstants dciConst = new DCIConstants();
       
        RetailCheckinQueue__c dciQueue1 = new RetailCheckinQueue__c();
        dciQueue1.Store__c = testStore.Id;
        dciQueue1.Status__c = DCIConstants.ALL_PENDING[0];
        dciQueue1.ArrivingTime__c = System.now().addDays(1);
        dciQueue1.QueuePosition__c = 1;
        dciQueue1.EstimatedWaitTime__c = 10;
        dciQueue1.LastMessageReceived__c ='C';
        }
        Test.startTest();
       
            //tapawini
            BopisHttpCalloutMock fakeResponse = new BopisHttpCalloutMock(404,
                                                 ' {\"transactionID\":\"492c1772-c735-47e9-bfae-c506b55dbd2b\",\"code\":404,\"message\":\"order not found\"}');
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        DCIController.BopisOrderCallout('12-123456789','6565612345');
        
        List<String> messages = new List<String>();
        messages.add(testStore.Id);
        //CacheManager.putMessageInCache(messages);
        
        try{
            CacheManager.putMessageInCache(messages);
        }catch (exception e){
            system.debug('Exception:'+e.getMessage());
        }
        
             BopisHttpCalloutMock fakeResponse3 = new BopisHttpCalloutMock(400,
                                                 ' {\"transactionID\":\"492c1772-c735-47e9-bfae-c506b55dbd2b\",\"code\":400,\"description\":\"found some issue\"}');
        Test.setMock(HttpCalloutMock.class, fakeResponse3);
        DCIController.BopisOrderCallout('','6565612345');
        
            BopisHttpCalloutMock fakeResponse1 = new BopisHttpCalloutMock(407,
                                                 ' "{""transactionID"": ""492c1772-c735-47e9-bfae-c506b55dbd2b"",""code"": 200,""message"": ""Order 23-205803664538421 found""}"');
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        DCIController.BopisOrderCallout('12-123456789','6565612345');
       
            BopisHttpCalloutMock fakeResponse10 = new BopisHttpCalloutMock(404,
                                                 ' {\"transactionID\":\"492c1772-c735-47e9-bfae-c506b55dbd2b\",\"code\":404,\"message\":\"Order 23-205803664538421 found but its cancelled\"}');
        Test.setMock(HttpCalloutMock.class, fakeResponse10);
        DCIController.BopisOrderCallout('12-123456789','6565612345');
       
            BopisHttpCalloutMock fakeResponse2 = new BopisHttpCalloutMock(404,
                                                 ' {\"transactionID\":\"492c1772-c735-47e9-bfae-c506b55dbd2b\",\"code\":404,\"message\":\"Order 23-205803664538421 found but its already picked up\"}');
        Test.setMock(HttpCalloutMock.class, fakeResponse2);
        DCIController.BopisOrderCallout('12-123456789','6565612345');
         
           
        BopisHttpCalloutMock fakeResponse4 = new BopisHttpCalloutMock(250,' callout failed');
        Test.setMock(HttpCalloutMock.class, fakeResponse4);
        DCIController.BopisOrderCallout('','6565612345');
       
            BopisHttpCalloutMock fakeResponse5 = new BopisHttpCalloutMock(404,
                                                 ' {\"transactionID\":\"492c1772-c735-47e9-bfae-c506b55dbd2b\",\"code\":404,\"message\":\"order not found\"}');
        Test.setMock(HttpCalloutMock.class, fakeResponse5);
            DCIController.BopisOrderCallout('12-123456789','6565612345');
       
            BopisHttpCalloutMock fakeResponse6 = new BopisHttpCalloutMock(404,
                                                 ' {\"transactionID\":\"492c1772-c735-47e9-bfae-c506b55dbd2b\",\"code\":404,\"message\":\"Order 23-205803664538421 found but its not ready for pick up\"}');
        Test.setMock(HttpCalloutMock.class, fakeResponse6);
            DCIController.BopisOrderCallout('12-123456789','6565612345');
       
            BopisHttpCalloutMock fakeResponse7 = new BopisHttpCalloutMock(404,
                                                 ' {\"transactionID\":\"492c1772-c735-47e9-bfae-c506b55dbd2b\",\"code\":404,\"message\":\"Order 23-205803664538421 found but fulfillment type is not c2s\"}');
        Test.setMock(HttpCalloutMock.class, fakeResponse7);
            DCIController.BopisOrderCallout('12-123456789','6565612345');
        
        DCIController.DCIcheckIfBusywithCustomer();
        DCIController.cancelAllCheckins('test','12345678');
       //upto
        Test.stopTest();
    }

}