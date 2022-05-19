/************************************************
 * Class - EmployeeJobDutyAssignHandlerTest
 * Description - Test class for EmployeeJobDutyAssignHandlerTest
 * **********************************************/
@isTest(seeAllData=false)
private class EmployeeJobDutyAssignHandlerTest {
    
    public static List<ProfileMapping__c> listProfileMap = new list<ProfileMapping__c>();
    public static list<Employee_Jobduty_Reference__c> listEmplJobRef = new list<Employee_Jobduty_Reference__c>();
    public static list<Jobduty_Group_Config__c> listGrpConf = new list<Jobduty_Group_Config__c>();
    public static list<MyLogin_Profile_Jobduty__c> listMyLoginProfJobduty = new list<MyLogin_Profile_Jobduty__c>();
    public static User u;
    public static User u1;
    
    
    static testmethod void EmployeeInsertWithExistingAssignment() {
        User LoggedInUser = [SELECT Id from User WHERE Id = :Userinfo.getUserId()];
        List<User> listNewUser = new list<User>();
        list<Id> listUserId = new list<Id>();
        System.runAs(LoggedInUser) {
            String strUnique, strUnique1;
            strUnique = String.valueOf(Crypto.getRandomLong());
            strUnique = strUnique.length() > 15 ? strUnique.abbreviate(15) : strUnique;
            strUnique1 = String.valueOf(Crypto.getRandomLong());
            strUnique1 = strUnique1.length() > 15 ? strUnique1.abbreviate(15) : strUnique1;
            List<Profile> p = new list<profile>();
            p = [SELECT Id, Name from Profile where Name='Minimum Access Agent' limit 1];
            UserRole uRole = [SELECT Id from UserRole limit 1];
            u = new User(
                LastName = strUnique+p.get(0).Name.deleteWhitespace(),
                Email = strUnique+p.get(0).Name.deleteWhitespace()+'@attonetest.com',
                Username = strUnique+p.get(0).Name.deleteWhitespace()+'@attonetest.com',
                CompanyName = 'TEST',
                Title = 'title',
                Alias = (strUnique.length() > 8 ? strUnique.abbreviate(7) : strUnique),
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                profileId = p.get(0).id
            );
            listNewUser.add(u);
            listUserId.add(u.Id);
            u1 = new User (
                LastName = strUnique1+p.get(0).Name.deleteWhitespace(),
                Email = strUnique1+p.get(0).Name.deleteWhitespace()+'@attonetest.com',
                Username = strUnique1+p.get(0).Name.deleteWhitespace()+'@attonetest.com',
                CompanyName = 'TEST',
                Title = 'title',
                Alias = (strUnique1.length() > 8 ? strUnique.abbreviate(7) : strUnique1),
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                profileId = p.get(0).id
            );
            listNewUser.add(u1);
            listUserId.add(u1.Id);
            insert listNewUser;
            PermissionSet ps = [SELECT Id from PermissionSet WHERE IsOwnedByProfile=false and Name = 'OOPAgent' and IsCustom=true limit 1];
            PermissionSetAssignment objpsa = new PermissionSetAssignment();
            objpsa.AssigneeId = listNewUser.get(0).Id;
            objpsa.PermissionSetId = ps.Id;
            insert objpsa;
            Group setupGrp = [SELECT Id from Group WHERE DeveloperName = 'All_ATT_Internal_Users' limit 1];
            system.debug(setupGrp);
            GroupMember objGrpMem = new GroupMember();
            objGrpMem.GroupId = setupGrp.Id;
            objGrpMem.UserOrGroupId = listNewUser.get(0).Id;
            insert objGrpMem;
        }
        
        RecordType rc = [SELECT Id from RecordType where SobjectType = 'Employee__c' and DeveloperName = 'Center'];
        Jobduty_Rollout_Indicator__c objIndicator = new Jobduty_Rollout_Indicator__c();
        objIndicator.RecordType__c = String.valueof(rc.Id);
        objIndicator.Organization_List__c = 'OOP';
        objIndicator.Last_Job_Run_Timestamp__c = DateTime.newInstance(2021, 1, 1, 0, 0, 0);
        objIndicator.Last_Group_Assignment_Job_Timestamp__c = DateTime.newInstance(2021, 1, 1, 0, 0, 0);
        insert objIndicator;
        //updating User_Onboarding_Config__c to run batch job & trigger related to EmployeeGroupAssignment
        User_Onboarding_Config__c indicatorUOC = new User_Onboarding_Config__c();
        indicatorUOC.Employee_Group_Assignment_Trigger__c = true;
        indicatorUOC.Group_Assignment_Active__c = true;
        insert indicatorUOC;

        CallCenter objCallctr = [SELECT Id from CallCenter limit 1];
        Profile objProf = [select Id from Profile where Name = 'OOPAdminProfile' limit 1];
        PermissionSet objPermset = [select Id from PermissionSet where Name = 'OOPAdmin' limit 1];
        PermissionSetGroup objPermSetGrp = [select Id from PermissionSetGroup where DeveloperName = 'CommonPermissionWithEA' limit 1];
        listProfileMap = Test.loadData(ProfileMapping__c.sObjectType, 'EmplJobDutyAssign_ProfMapping');
        listEmplJobRef = Test.loadData(Employee_Jobduty_Reference__c.sObjectType, 'EmplJobDutyAssign_EJRef');
        listEmplJobRef.get(0).ProfileId__c = objProf?.Id;
        listEmplJobRef.get(0).PermissionSetId__c = objPermset?.Id;
        listEmplJobRef.get(0).PermissionSetGroupId__c = objPermSetGrp?.Id;
        listEmplJobRef.get(0).CallCenterId__c = objCallctr?.Id;
        listEmplJobRef.get(0).IsFlowUser__c = true;
        listEmplJobRef.get(0).IsChatUser__c = true;
        listEmplJobRef.get(0).IsMarketingUser__c = true;
        Update listEmplJobRef;
        
        listGrpConf = Test.loadData(Jobduty_Group_Config__c.sObjectType, 'EmplJobDutyAssign_JobdutyGrpConf');
        Group objGrp = [select Id from Group where Name = 'OOP Admins' limit 1];
        listGrpConf.get(0).GroupId__c = objGrp.Id;
        Update listGrpConf;
        
        listMyLoginProfJobduty = Test.loadData(MyLogin_Profile_Jobduty__c.sObjectType, 'EmplJobDutyAssign_MyLoginProfJobDuty');
        
        List<Employee__c> listNewEmployee = new list<Employee__c>();
        Employee__c emp = new Employee__c();
        emp.SFPRofileId__c = 'OOPAdminProfile';
        emp.RecordTypeId = rc.Id;
        emp.Organization__c = 'OOP';
        emp.Channel1__c = 'Office of the President';
        emp.Sub_Channel__c = 'Office of the President';
        emp.Is_Remote__c = false;
        emp.IsActive__c = true;
        emp.EmployeeId__c = '67BHGT';
        emp.User__c = listNewUser.get(0).Id;
        
        Employee__c emp1 = new Employee__c();
        emp1.SFPRofileId__c = 'OOPAdminProfile';
        emp1.RecordTypeId = rc.Id;
        emp1.Organization__c = 'OOP';
        emp1.Channel1__c = 'Office of the President';
        emp1.Sub_Channel__c = 'Office of the President';
        emp1.Is_Remote__c = false;
        emp1.IsActive__c = true;
        emp1.EmployeeId__c = '67BHGT2';
        emp1.User__c = listNewUser.get(1).Id;
        
        listNewEmployee.add(emp);
        listNewEmployee.add(emp1);

        Test.startTest();
        INSERT listNewEmployee;
        //started - test data setup for Employee Queue Assignment testing
        List<Employee_Group_Assignment__c> listEmpGrpAssignInsert = new List<Employee_Group_Assignment__c>();
        Employee_Group_Assignment__c listEmpGrpAssignUpdate;
        Employee_Group_Assignment__c unitEmpGrpAssign1 = new Employee_Group_Assignment__c();
        unitEmpGrpAssign1.Employee__c = emp.Id;
        unitEmpGrpAssign1.Group_Type__c = 'Queue';
        unitEmpGrpAssign1.Public_Group_Queue_Name__c = 'Business Queue';
        unitEmpGrpAssign1.Activity__c = 'Adding employee to Public Group/Queue';
        unitEmpGrpAssign1.Group_ID__c = '';

        listEmpGrpAssignInsert.add(unitEmpGrpAssign1);
        Insert listEmpGrpAssignInsert;
        
        listEmpGrpAssignUpdate = [SELECT Id, Activity__c FROM Employee_Group_Assignment__c WHERE Employee__c = :emp.Id AND Activity__c = 'Adding employee to Public Group/Queue' AND Group_Type__c = 'Queue' AND Public_Group_Queue_Name__c = 'Business Queue' LIMIT 1];
        listEmpGrpAssignUpdate.Activity__c = 'Removing employee from Public Group/Queue';
        Update listEmpGrpAssignUpdate;
        //ended - test data setup for Employee Queue Assignment testing
        
        System.runAs(LoggedInUser) {
            UserAccessBatch objUserAccess = new UserAccessBatch();
			Id BatchId = Database.executeBatch(objUserAccess);
        }
        
        Test.stopTest();
        listNewEmployee.get(0).EmployeeId__c = '98NNH76';
        UPDATE listNewEmployee;
        system.debug(listProfileMap);
        system.debug(listEmplJobRef);
        system.debug(listGrpConf);
        system.debug(listMyLoginProfJobduty);
        System.debug(listEmpGrpAssignInsert);
        System.debug(listEmpGrpAssignUpdate);
    }
    
    
    static testmethod void createNewEmployeeWithoutAssignment() {
        User LoggedInUser = [SELECT Id from User WHERE Id = :Userinfo.getUserId()];
        System.runAs(LoggedInUser) {
            String strUnique;
            strUnique = String.valueOf(Crypto.getRandomLong());
            strUnique = strUnique.length() > 15 ? strUnique.abbreviate(15) : strUnique;
            List<Profile> p = new list<profile>();
            p = [SELECT Id, Name from Profile where Name='Minimum Access Agent' limit 1];
            UserRole uRole = [SELECT Id from UserRole limit 1];
            u = new User(
                LastName = strUnique+p.get(0).Name.deleteWhitespace(),
                Email = strUnique+p.get(0).Name.deleteWhitespace()+'@attonetest.com',
                Username = strUnique+p.get(0).Name.deleteWhitespace()+'@attonetest.com',
                CompanyName = 'TEST',
                Title = 'title',
                Alias = (strUnique.length() > 8 ? strUnique.abbreviate(7) : strUnique),
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                profileId = p.get(0).id
            );
            insert u;
        }
        
        RecordType rc = [SELECT Id from RecordType where SobjectType = 'Employee__c' and DeveloperName = 'Center'];
        Jobduty_Rollout_Indicator__c objIndicator = new Jobduty_Rollout_Indicator__c();
        objIndicator.RecordType__c = String.valueof(rc.Id);
        objIndicator.Organization_List__c = 'OOP';
        objIndicator.Last_Job_Run_Timestamp__c = DateTime.newInstance(2021, 1, 1, 0, 0, 0);
        insert objIndicator;
        
        Profile objProf = [select Id from Profile where Name = 'OOPAdminProfile' limit 1];
        PermissionSet objPermset = [select Id from PermissionSet where Name = 'OOPAdmin' limit 1];
        PermissionSet objPermSetGrp = [select PermissionSetGroupId from PermissionSet where Name = 'CommonPermissionWithEA' limit 1];
        listProfileMap = Test.loadData(ProfileMapping__c.sObjectType, 'EmplJobDutyAssign_ProfMapping');
        listEmplJobRef = Test.loadData(Employee_Jobduty_Reference__c.sObjectType, 'EmplJobDutyAssign_EJRef');
        listEmplJobRef.get(0).ProfileId__c = objProf.Id;
        listEmplJobRef.get(0).PermissionSetId__c = objPermset.Id;
        listEmplJobRef.get(0).PermissionSetGroupId__c = objPermSetGrp.Id;
        Update listEmplJobRef;
        
        listGrpConf = Test.loadData(Jobduty_Group_Config__c.sObjectType, 'EmplJobDutyAssign_JobdutyGrpConf');
        Group objGrp = [select Id from Group where Name = 'OOP Admins' limit 1];
        listGrpConf.get(0).GroupId__c = objGrp.Id;
        Update listGrpConf;
        listMyLoginProfJobduty = Test.loadData(MyLogin_Profile_Jobduty__c.sObjectType, 'EmplJobDutyAssign_MyLoginProfJobDuty');
        Test.startTest();
        Employee__c emp = new Employee__c();
        emp.SFPRofileId__c = 'OOPAdminProfile';
        emp.RecordTypeId = rc.Id;
        emp.Organization__c = 'OOP';
        emp.Channel1__c = 'Office of the President';
        emp.Sub_Channel__c = 'Office of the President';
        emp.Is_Remote__c = false;
        emp.IsActive__c = true;
        emp.EmployeeId__c = '67BHGT';
        emp.User__c = u.Id;
        
        INSERT emp;
        System.runAs(LoggedInUser) {
            JobdutyAccessGrantSchedulable objSch = new JobdutyAccessGrantSchedulable();
            String CRON_EXP = '0 0 * ? * * *';
            String JobId = System.schedule('User Access Grant Job', CRON_EXP, objSch);
        }
        
        Test.stopTest();
    }
    
    //static testmethod void createEmployee()

}