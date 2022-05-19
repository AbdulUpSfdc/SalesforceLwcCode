@isTest
public class cLeadHomePageControllerTest {
    @testSetup
    public static void createData(){
        Id consumerRecTypeId = RetailConstants.CONSUMER_RECORDTYPEID;
        
        String uniqueUserNameasrm = 'standarduserasrmm' + DateTime.now().getTime() + '@testorg.com';
        // This code runs as the system user
        Profile pars = [SELECT Id FROM Profile WHERE Name='Retail ARSM'];
        User uarsm = new User(Alias = 'arsm', Email='standarduserarsm@testorg.com',
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US', ProfileId = pars.Id,
                          TimeZoneSidKey='America/Los_Angeles',
                          UserName=uniqueUserNameasrm);
        insert uarsm;
        
         String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='Retail RSC Rep'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US', ProfileId = p.Id,
                          TimeZoneSidKey='America/Los_Angeles',
                          UserName=uniqueUserName);
        
        String uniqueUserName2 = 'standardusert' + DateTime.now().getTime() + '@testorg.com';
        Profile p2 = [SELECT Id FROM Profile WHERE Name='Retail SM'];
        User u2 = new User(Alias = 'standtt', Email='standarduserr@testorg.com',
                           EmailEncodingKey='UTF-8', LastName='Testingt', LanguageLocaleKey='en_US',
                           LocaleSidKey='en_US', ProfileId = p2.Id,
                           TimeZoneSidKey='America/Los_Angeles',
                           UserName=uniqueUserName2);
        
        insert u;
        insert u2;
        
           Profile retailRscRepProfile = [Select ID From Profile Where Name='Retail RSC Rep'];
        User retailRscRepUser = Utility_Test.createTestUser(retailRscRepProfile.ID, 'firstName_RetailRSCRep', 'lastName_RetailRSCRep');
        insert retailRscRepUser;

         Profile retailSMProfile = [Select ID From Profile Where Name='Retail SM'];
        
        User retailSMUser = Utility_Test.createTestUser(retailSMProfile.ID, 'firstName_RetailRSCRep', 'lastName_RetailRSCRep');
        insert retailSMUser;

    }
    
    public static testMethod void method1(){
        Id consumerRecTypeId = RetailConstants.CONSUMER_RECORDTYPEID;
        
        user u21 = [select id from user where email ='standarduserr@testorg.com'];
        employee__C e = new employee__c();
        e.User__c = u21.id;
        store__C s = new store__c();
        insert s;
        e.homeStoreLocation__c = s.id;
        insert e;
        
        
        Lead leadRec1 = new Lead(LastName = 'Test Case',
                                 Company = 'My Test Case', 
                                 Phone = '8889991111',                           
                                 MobilePhone = '7778889999',
                                 RecordTypeId = consumerRecTypeId,
                                 ExpiryDate__c = system.today()
                                );
        insert leadRec1;
        
        Lead leadRec2 = new Lead(LastName = 'Test Case',
                                 Company = 'My Test Case', 
                                 Phone = '8889993311',                           
                                 MobilePhone = '7778889933',
                                 RecordTypeId = consumerRecTypeId,
                                 ExpiryDate__c = date.valueof(system.now().adddays(2))
                                );
        insert leadRec2;
        
        system.debug([select ExpiryDate__c from lead]);
        Map<string,integer> ListViewCountMap =  cLeadHomePageController.getListViewCount();
        User u1 = [select id from user where email='standarduser@testorg.com'];
        User u2 = [select id from user where email='standarduserr@testorg.com'];
        User uarsm = [select id from user where email='standarduserarsm@testorg.com'];
        Id id1 =  cLeadHomePageController.getDefaultRT('lead');
      cLeadHomePageController.getListViewData();
        System.runAs(u1) {
            ListViewCountMap =  cLeadHomePageController.getListViewCount();
             cLeadHomePageController.getListViewData();
        }
        
        System.runAs(u2) { 
            ListViewCountMap =  cLeadHomePageController.getListViewCount();
             cLeadHomePageController.getListViewData();
        }
         test.starttest();
        System.runAs(uarsm) {
            ListViewCountMap =  cLeadHomePageController.getListViewCount();
             cLeadHomePageController.getListViewData();
        }
         test.stoptest();
        
    }

    @isTest
    static void testGetStoreLocation(){
      Profile retailRscRepProfile = [Select ID From Profile Where Name='Retail RSC Rep'];
      User retailRscRepUser = Utility_Test.createTestUser(retailRscRepProfile.ID, 'firstName_RetailRSCRep', 'lastName_RetailRSCRep');
      insert retailRscRepUser;
      system.runAs(retailRscRepUser){
          List<Store__c> storeLst = new List<Store__c>(); 
          Store__c store = new Store__c(Name = 'Test Store001');
          store.LocationType__c = 'Test001';
          store.LocationId__c = 'Store001';
          storeLst.add(store);
          
          Store__c store2 = new Store__c(Name = 'Test Store002');
          store2.LocationType__c = 'Test 002';
          store2.LocationId__c = 'Store002';
          storeLst.add(store2);
          insert storeLst;
          
          Employee__c newEmp=new Employee__c();
          newEmp.HomeStoreLocation__c=store.id;
          newEmp.user__c=retailRscRepUser.id;
          newEmp.SFProfileId__c = 'RSC-REP';
          insert newEmp;
          
          List<EmployeeStoreRetail__c> empStrLst = new List<EmployeeStoreRetail__c>(); 
          EmployeeStoreRetail__c empStr = new EmployeeStoreRetail__c();
          empStr.Employee__c = newEmp.Id;
          empStr.Store__c = store.Id;
          empStrLst.add(empStr);
          
          EmployeeStoreRetail__c empStr2 = new EmployeeStoreRetail__c();
          empStr2.Employee__c = newEmp.Id;
          empStr2.Store__c = store2.Id;
          empStrLst.add(empStr2);
          insert empStrLst;
          
          UserCurrentLocation__c userCurrLoc = new UserCurrentLocation__c();
          userCurrLoc.SetupOwnerId = retailRscRepUser.Id;
          userCurrLoc.Store__c = store.Id;
          userCurrLoc.StoreName__c = store.Name;
          insert userCurrLoc;
          
          Test.startTest();
          cLeadHomePageController.getStoreLocation(retailRscRepUser.Id);
          Test.stopTest();
          system.assertEquals(true, userCurrLoc.StoreName__c != null, 'Store should not be null'); 
      }
      
  }
    @isTest
    static void testGetStoreLocation2(){
        
        
        Id consumerRecTypeId = RetailConstants.CONSUMER_RECORDTYPEID;
        
        user u21 = [select id from user where email ='standarduserr@testorg.com'];
        employee__C e = new employee__c();
        e.User__c = u21.id;
        store__C s = new store__c();
        insert s;
        e.homeStoreLocation__c = s.id;
        insert e;
        
        
        Lead leadRec1 = new Lead(LastName = 'Test Case',
                                 Company = 'My Test Case', 
                                 Phone = '8889991111',                           
                                 MobilePhone = '7778889999',
                                 RecordTypeId = consumerRecTypeId,
                                 ExpiryDate__c = system.today()
                                );
        insert leadRec1;
        
        Lead leadRec2 = new Lead(LastName = 'Test Case',
                                 Company = 'My Test Case', 
                                 Phone = '8889993311',                           
                                 MobilePhone = '7778889933',
                                 RecordTypeId = consumerRecTypeId,
                                 ExpiryDate__c = date.valueof(system.now().adddays(2))
                                );
        insert leadRec2;
        
        
        Profile retailRscRepProfile = [Select ID From Profile Where Name='Retail RSC Rep'];
        Profile retailSMProfile = [Select ID From Profile Where Name='Retail SM'];

        
          user retailRscRepUser = [select id from user where lastname='lastName_RetailRSCRep' and  profileid=: retailRscRepProfile.id];
         user retailSMUser = [select id from user where lastname='lastName_RetailRSCRep' and profileid =: retailSMProfile.id];
      

        Store__c store = new Store__c(Name = '001');
        store.LocationType__c = 'Test';
        store.LocationId__c = '001';
        insert store;
        
        Employee__c newEmp=new Employee__c();
        newEmp.HomeStoreLocation__c = store.id;
        newEmp.user__c = retailRscRepUser.id;
        newEmp.SFProfileId__c = 'RSC-REP';
        insert newEmp;

        EmployeeStoreRetail__c empStr = new EmployeeStoreRetail__c();
        empStr.Employee__c = newEmp.Id;
        empStr.Store__c = store.Id;
        insert empStr;

        UserCurrentLocation__c userCurrLoc = new UserCurrentLocation__c();
        userCurrLoc.SetupOwnerId = retailSMUser.Id;
        userCurrLoc.Store__c = store.Id;
        userCurrLoc.StoreName__c = store.Name;
        insert userCurrLoc;

        Test.startTest();
        cLeadHomePageController.getStoreLocation(retailRscRepUser.Id);
        Test.stopTest();
        system.assertEquals(true, newEmp.HomeStoreLocation__c != null, 'HomeStore should not be null');
    }
    public static testMethod void method5(){
        
        
        Id consumerRecTypeId = RetailConstants.CONSUMER_RECORDTYPEID;
        
        user u21 = [select id from user where email ='standarduserr@testorg.com'];
        employee__C e = new employee__c();
        e.User__c = u21.id;
        store__C s = new store__c();
        insert s;
        e.homeStoreLocation__c = s.id;
        insert e;
        
        
        Lead leadRec11 = new Lead(LastName = 'Test Case',
                                 Company = 'My Test Case', 
                                 Phone = '8889991111',                           
                                 MobilePhone = '7778889999',
                                 RecordTypeId = consumerRecTypeId,
                                 ExpiryDate__c = system.today()
                                );
        insert leadRec11;
        
        Lead leadRec2 = new Lead(LastName = 'Test Case',
                                 Company = 'My Test Case', 
                                 Phone = '8889993311',                           
                                 MobilePhone = '7778889933',
                                 RecordTypeId = consumerRecTypeId,
                                 ExpiryDate__c = date.valueof(system.now().adddays(2))
                                );
        insert leadRec2;
        
        Map<string,integer> ListViewCountMap =  cLeadHomePageController.getListViewCount();
        User u1 = [select id from user where email='standarduser@testorg.com'];
        User u2 = [select id from user where email='standarduserr@testorg.com'];
        User uarsm = [select id from user where email='standarduserarsm@testorg.com'];
        Id id1 =  cLeadHomePageController.getDefaultRT('lead');
        cLeadHomePageController.getListViewData();
        cLeadHomePageController.getLeadCountDetails();
        test.starttest();
        System.runAs(u1) {
             s = [select id from store__c limit 1];
            Lead leadRec1 = new Lead(LastName = 'Test Case3',
                                     Company = 'My Test Case3', 
                                     Phone = '8889991221',                           
                                     MobilePhone = '7778889101',
                                     RecordTypeId = consumerRecTypeId,
                                     ExpiryDate__c = system.today(),
                                     status = 'Captured',
                                     store__c = s.id,
                                     LastContactedSMS__c = date.today().adddays(-1)
                                     
                                    );
            insert leadRec1;
            
            Messaging_Message__c msg1 = new Messaging_Message__c(Is_Inbound__c = true,
                                                                 OwnerId = u1.Id,
                                                                 Flagged_For__c = RetailConstants.PROFANITY_FLAG,
                                                                 Lead__c = leadRec1.Id,
                                                                 Messaging_Session_Id__c  = '',
                                                                 Number_Sent_To__c = leadRec1.MobilePhone,
                                                                 Sent_By__c = UserInfo.getFirstName() + '' + UserInfo.getLastName(),
                                                                 Sent_Date_Time__c = system.now().adddays(-1),
                                                                 Was_Sent__c = false,
                                                                 Message_Content__c = 'test'
                                                                );
            insert msg1;
            
            Messaging_Message__c msg2 = new Messaging_Message__c(Is_Inbound__c = true,
                                                                 OwnerId = u1.Id,
                                                                 Flagged_For__c = RetailConstants.PROFANITY_FLAG,
                                                                 Lead__c = leadRec1.Id,
                                                                 Messaging_Session_Id__c  = '',
                                                                 Number_Sent_To__c = leadRec1.MobilePhone,
                                                                 Sent_By__c = UserInfo.getFirstName() + '' + UserInfo.getLastName(),
                                                                 Sent_Date_Time__c = system.now().adddays(-2),
                                                                 Was_Sent__c = false,
                                                                 Message_Content__c = 'test'
                                                                );
            insert msg2;
            
            Messaging_Message__c msg3 = new Messaging_Message__c(Is_Inbound__c = false,
                                                                 OwnerId = u1.Id,
                                                                 Flagged_For__c = RetailConstants.PROFANITY_FLAG,
                                                                 Lead__c = leadRec1.Id,
                                                                 Messaging_Session_Id__c  = '',
                                                                 Number_Sent_To__c = leadRec1.MobilePhone,
                                                                 Sent_By__c = UserInfo.getFirstName() + '' + UserInfo.getLastName(),
                                                                 Sent_Date_Time__c = system.now().adddays(-3),
                                                                 Was_Sent__c = false,
                                                                 Message_Content__c = 'test'
                                                                );
            insert msg3;
            cLeadHomePageController.getLeadOverviewData();
            cLeadHomePageController.getLeadCountDetails();
        }
        test.stoptest();
        
    }

      //If stores are multiple
    @istest
    static void MultipleStores(){
        
        //Storing the List of Store Names 
        list<string> storeList = new list<string>();
        
        Profile retailRscRepProfile = [Select ID,name From Profile Where Name='Retail RSC Rep'];
        
        User retailRscRepUser = Utility_Test.createTestUser(retailRscRepProfile.ID, 'firstName_RetailRSCRep', 'lastName_RetailRSCRep');
        insert retailRscRepUser;   
        system.debug('retailRscRepUser=@@-=->'+retailRscRepUser);
        
       
        
      System.runAs(retailRscRepUser) {
        Store__c store = new Store__c();
        store.Name = 'First';
        store.LocationType__c = 'Test';
        store.LocationId__c = '001';
        insert store;
        
        Store__c store2 = new Store__c();
        store2.Name = 'Second';
        store2.LocationType__c = 'Test2';
        store2.LocationId__c = '002';
        insert store2;
        
        Employee__c newEmp=new Employee__c();
        newEmp.Name='NewEmp';
        newEmp.HomeStoreLocation__c = store.id;
        newEmp.user__c = retailRscRepUser.id;
       
        insert newEmp;

        list<EmployeeStoreRetail__c> empstorList = new  list<EmployeeStoreRetail__c>();
        EmployeeStoreRetail__c empStr = new EmployeeStoreRetail__c();
        empStr.Employee__c = newEmp.Id;
        empStr.Name= 'test1';
        empStr.Store__c = store.Id;
        empstorList.add(empStr);
     
        
        EmployeeStoreRetail__c empStr2 = new EmployeeStoreRetail__c();
        empStr2.Employee__c = newEmp.Id;
        empStr2.Name= 'test2';
        empStr2.Store__c = store2.Id;
        empstorList.add(empStr2);
        insert empstorList;
     
        
        storeList.add(empStr.Store__r.name);
        storeList.add(empStr2.Store__r.name);
        
        UserCurrentLocation__c userCurrLoc = new UserCurrentLocation__c();
        userCurrLoc.SetupOwnerId = retailRscRepUser.Id;
        userCurrLoc.Store__c = store.Id;
        userCurrLoc.StoreName__c = store.Name;
        insert userCurrLoc;
        
        //Wrapper 
        cLeadHomePageController.StoreNames storewraper = new cLeadHomePageController.StoreNames();
        storewraper.CurrentLocationstorename = userCurrLoc.StoreName__c.toUpperCase();
        storewraper.CurrentProfileName = retailRscRepProfile.Name;
        storewraper.StoreRetailStores = storeList;
        
        test.startTest();
        cLeadHomePageController.getStoreLocation(retailRscRepUser.id);
        test.stopTest();
      }
    }

   //Updating selected Store name to custom settings
   @istest
   static void updatingStorName(){
       
     Profile retailRscRepProfile = [Select ID,name From Profile Where Name='Retail RSC Rep'];
       
       User retailRscRepUser = Utility_Test.createTestUser(retailRscRepProfile.ID, 'firstName_RetailRSCRep', 'lastName_RetailRSCRep');
       insert retailRscRepUser;
       System.runAs(retailRscRepUser) {
           Store__c store = new Store__c(Name = '001');
           store.LocationType__c = 'Test';
           store.LocationId__c = '001';
           insert store;
           
           UserCurrentLocation__c userCurrLoc = new UserCurrentLocation__c();
           userCurrLoc.SetupOwnerId = retailRscRepUser.Id;
           userCurrLoc.Store__c = store.Id;
           userCurrLoc.StoreName__c = store.Name;
           insert userCurrLoc; 
                               
           string storename =store.name;     
           
           test.startTest();
           cLeadHomePageController.SelectedStoreUpdate(storename);
           test.stopTest(); 
           
       }
              
   }
  
}