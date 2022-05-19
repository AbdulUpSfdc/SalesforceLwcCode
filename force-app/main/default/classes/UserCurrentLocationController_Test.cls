/*******************************************************
 * Description : Test class for UserCurrentLocationController
 * Created date: 10-15-2021
 * Created By  : Narasimha Dara
 * *****************************************************/


@istest   
public class UserCurrentLocationController_Test {

    @istest static void testMethod1(){
        
       
        //User Creation
        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            FirstName = 'last',
            LastName = 'test',            
            Email = 'puser000@amamama.com',
            Username = 'puser000@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            
        );
        
        insert u;
       
        
        system.runAs(u){
            
            //Employe record 
            employee__C e = new employee__c();
            e.User__c = u.id;
            
            //HomeStore record 
            store__C s = new store__c();
            s.Name = 'TestStore';
            insert s;
            
            e.homeStoreLocation__c = s.id;
            insert e;
            
            //EmployeStoreRetail record
            List<EmployeeStoreRetail__c> empStrLst = new List<EmployeeStoreRetail__c>(); 
            EmployeeStoreRetail__c empStr = new EmployeeStoreRetail__c();
            empStr.Employee__c = e.Id;
            empStr.Store__c = s.Id;
            empStrLst.add(empStr);
            insert empStrLst;
     
                      
            UserCurrentLocationController.getUserCurrentLocation();
        
       
        
        //Getting current logged in user profile
        String profileId = UserInfo.getProfileId();
        
        //Getting profile information
        Profile profile = [SELECT Id, Name FROM Profile WHERE Id =:profileId];
        
        //Wrapper coverage
        UserCurrentLocationController.UserDetails wrapperinfo = new UserCurrentLocationController.UserDetails();
        wrapperinfo.storename = e.homeStoreLocation__r.name;
        wrapperinfo.userProfile = profile.Name;
        
        }      
    }
    
    @istest static void testMethod2(){
        
        //User Creation
        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            FirstName = 'last',
            LastName = 'test',            
            Email = 'puser000@amamama.com',
            Username = 'puser000@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            
        );
        
        insert u;
       
        
        system.runAs(u){
            
            //Employe record 
            employee__C e = new employee__c();
            e.User__c = u.id;
            
            //HomeStore record 
            store__C s = new store__c();
            s.Name = 'TestStore';
            insert s;
            
            e.homeStoreLocation__c = s.id;
            insert e;
            
            //EmployeStoreRetail record
            List<EmployeeStoreRetail__c> empStrLst = new List<EmployeeStoreRetail__c>(); 
            EmployeeStoreRetail__c empStr = new EmployeeStoreRetail__c();
            empStr.Employee__c = e.Id;
            empStr.Store__c = s.Id;
            empStrLst.add(empStr);
            
            EmployeeStoreRetail__c empStr2 = new EmployeeStoreRetail__c();
            empStr2.Employee__c = e.Id;
            empStr2.Store__c = s.Id;
            empStrLst.add(empStr2);
            insert empStrLst;
            
            //User current location custom setting 
            UserCurrentLocation__c ucl = new UserCurrentLocation__c();           
            ucl.SetupOwnerId = u.Id;
            ucl.StoreName__c ='Las Colinas';
            insert ucl;            
                      
            UserCurrentLocationController.getUserCurrentLocation();
        
       
        
        //Getting current logged in user profile
        String profileId = UserInfo.getProfileId();
        
        //Getting profile information
        Profile profile = [SELECT Id, Name FROM Profile WHERE Id =:profileId];
        
        //Wrapper coverage
        UserCurrentLocationController.UserDetails wrapperinfo = new UserCurrentLocationController.UserDetails();
        wrapperinfo.storename = ucl.StoreName__c;
        wrapperinfo.userProfile = profile.Name;
        
        }  
        
        
        
    }
}