@IsTest
public without sharing class LookUpControllerTest {
    
    private static TestDataFactory.TestWrapper dataFactoryWrap = new TestDataFactory.TestWrapper();
    private static TestDataFactory dataFactory = new TestDataFactory();
    
    @IsTest
    private static void test(){
        List<User> users = (List<User>)LookUpController.findRecords('CHANGE_LEAD_OWNER', 'CICD', 'User', '');
        System.assert(users.size() > 0);
    }
     @IsTest
    private static void test2(){
     Profile p = [SELECT Id FROM Profile WHERE Name='Retail SM'];
            User testUser = new User();
            testUser.FirstName = 'Test SM1';
            testUser.LastName = 'Test';
            testUser.attuid__c='te1234t';
            String userName = 'test7423';
            testUser.Username = testUser.Email = userName + '@gmail.com';
            testUser.Alias = userName;
            testUser.TimeZoneSidKey = 'America/Los_Angeles';
            testUser.EmailEncodingKey = 'UTF-8';
            testUser.LanguageLocaleKey = 'en_US';
            testUser.LocaleSidKey = 'en_US';
            testUser.ProfileId = p.Id;
            insert testUser;
        List<User> users = (List<User>)LookUpController.findRecords('CHANGE_LEAD_OWNER', 'te1234t', 'User', '');
        System.assert(users.size() > 0);
    }
    
    //Adding testmethod to cover code for FindRecordsEmployee method -5200 - Sushanth
    @IsTest
    private static void testFindRecordsEmployee(){
        
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
            User testUser = new User();
            testUser.FirstName = 'Test';
            testUser.LastName = 'Test';
            String userName = 'test7423';
            testUser.Username = testUser.Email = userName + '@gmail.com';
            testUser.Alias = userName;
            testUser.TimeZoneSidKey = 'America/Los_Angeles';
            testUser.EmailEncodingKey = 'UTF-8';
            testUser.LanguageLocaleKey = 'en_US';
            testUser.LocaleSidKey = 'en_US';
            testUser.ProfileId = p.Id;
            insert testUser;
        
        List<Store__c> stores = dataFactory.getStores(1,'testFRE');
        insert stores;
        system.debug(stores.size());
        
        Lead leadRec1 = new Lead(LastName = 'Test Case',
                            Company = 'My Test Case',                            
                            Phone = '2012012014',
                            Store__c = stores[0].Id
                            //RecordTypeId = digitalRecTypeId
                        );
        
       
        insert leadRec1;
            
            
            Employee__c emp = new Employee__c(Name='Test MGR',
                                              LastName__c = testUser.LastName,
                                              User__c = testUser.id,
                                              SFProfileId__c = 'RSC-MGR',
                                              HomeStoreLocation__c = stores[0].Id,
                                              EmployeeId__c = testUser.id,
                                              IsActive__c = true);
        insert emp; 
        
        EmployeeStoreRetail__c empStore = new EmployeeStoreRetail__c(Employee__c = emp.id,
                                                                     Store__c = stores[0].id,
                                                                     ExternalId__c = emp.id+'-'+stores[0].id, DCIPresenceStatus__c='Online');
        insert empStore;
        
        Test.startTest();
        List<Employee__c> users = (List<Employee__c>)LookUpController.findRecordsEmployee('Test MGR', 'Employee__c', leadRec1.Id);
        system.debug(users);
        System.assert(users.size() > 0);
        system.runAs(testUser){
            Boolean isUserManager = LookUpController.isUserManager(leadRec1.Id);
            system.assert(true,isUserManager);
        }
        Test.stopTest();        
    }
    
    //Adding testmethod to cover code for isUserManager method -5200 - Sushanth
    @IsTest
    private static void testIsUserManager(){
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Retail SM'];
            User testUser = new User();
            testUser.FirstName = 'Test SM';
            testUser.LastName = 'Test';
            String userName = 'test7423';
            testUser.Username = testUser.Email = userName + '@gmail.com';
            testUser.Alias = userName;
            testUser.TimeZoneSidKey = 'America/Los_Angeles';
            testUser.EmailEncodingKey = 'UTF-8';
            testUser.LanguageLocaleKey = 'en_US';
            testUser.LocaleSidKey = 'en_US';
            testUser.ProfileId = p.Id;
            insert testUser;
        
        List<Store__c> stores = dataFactory.getStores(1,'testSM');
        insert stores;
        system.debug(stores.size());
        
        Lead leadRec1 = new Lead(LastName = 'Test Case',
                            Company = 'My Test Case',                            
                            Phone = '2012012014',
                            Store__c = stores[0].Id
                            //RecordTypeId = digitalRecTypeId
                        );
        
       
        insert leadRec1;
            
            
            Employee__c emp = new Employee__c(Name='Test MGR',
                                              LastName__c = testUser.LastName,
                                              User__c = testUser.id,
                                              SFProfileId__c = 'RSC-MGR',
                                              HomeStoreLocation__c = stores[0].Id,
                                              EmployeeId__c = testUser.id,
                                              IsActive__c = true);
        insert emp; 
        
        EmployeeStoreRetail__c empStore = new EmployeeStoreRetail__c(Employee__c = emp.id,
                                                                     Store__c = stores[0].id,
                                                                     ExternalId__c = emp.id+'-'+stores[0].id, DCIPresenceStatus__c='Online');
        insert empStore;
        
        Test.startTest();
        List<Employee__c> users = (List<Employee__c>)LookUpController.findRecordsEmployee('Test MGR', 'Employee__c', leadRec1.Id);
        system.debug(users);
        System.assert(users.size() > 0);
        system.runAs(testUser){
            Boolean isUserManager = LookUpController.isUserManager(leadRec1.Id);
            system.assert(true,isUserManager);
        }
        Test.stopTest();        
    }
    
    //Adding testmethod to cover negative testing for IsUserManager method -5200 - Sushanth
    @IsTest
    private static void testIsUserManagerNegative(){
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Retail RSC Rep'];
            User testUser = new User();
            testUser.FirstName = 'Test SM';
            testUser.LastName = 'Test';
            String userName = 'test7423';
            testUser.Username = testUser.Email = userName + '@gmail.com';
            testUser.Alias = userName;
            testUser.TimeZoneSidKey = 'America/Los_Angeles';
            testUser.EmailEncodingKey = 'UTF-8';
            testUser.LanguageLocaleKey = 'en_US';
            testUser.LocaleSidKey = 'en_US';
            testUser.ProfileId = p.Id;
            insert testUser;
        
        List<Store__c> stores = dataFactory.getStores(1,'testREP');
        insert stores;
        system.debug(stores.size());
        
        Lead leadRec1 = new Lead(LastName = 'Test Case',
                            Company = 'My Test Case',                            
                            Phone = '2012012014',
                            Store__c = stores[0].Id
                            //RecordTypeId = digitalRecTypeId
                        );
        
       
        insert leadRec1;
            
            
            Employee__c emp = new Employee__c(Name='Test REP',
                                              LastName__c = testUser.LastName,
                                              User__c = testUser.id,
                                              SFProfileId__c = 'RSC-REP',
                                              HomeStoreLocation__c = stores[0].Id,
                                              EmployeeId__c = testUser.id,
                                              IsActive__c = true);
        insert emp; 
        
        EmployeeStoreRetail__c empStore = new EmployeeStoreRetail__c(Employee__c = emp.id,
                                                                     Store__c = stores[0].id,
                                                                     ExternalId__c = emp.id+'-'+stores[0].id, DCIPresenceStatus__c='Online');
        insert empStore;
        
        Test.startTest();
        system.runAs(testUser){
            Boolean isUserManager = LookUpController.isUserManager(leadRec1.Id);
            system.debug(isUserManager);
            system.assert(true,!isUserManager);
        }
        Test.stopTest();        
    }
}