/*
* Test Class for ChildCaseAssignmentConfigTriggerHandler, ChildCaseAssignmentConfigTriggerHelper.
*/ 
@isTest
private class ChildCaseAssignmentConfig_Tst {
    @testSetup
    private static void testSetup(){
        Profile oopAdminProfile = [Select ID From Profile Where Name='Minimum Access OOP Admin'];
        UserRole fieldAdminRole = [Select ID From UserRole Where DeveloperName='FieldAdmin' Limit 1];
        List<User> userList = new List<User>();
        User oppAdministratorUser = Utility_Test.createTestUser(oopAdminProfile.ID, 'firstName_oopAdmin', 'lastName_oopAdmin');
        userList.add(oppAdministratorUser);
        
        oppAdministratorUser = Utility_Test.createTestUser(oopAdminProfile.ID, 'firstName_oopAdmin2', 'lastName_oopAdmin2');
        oppAdministratorUser.UserRoleId = fieldAdminRole.ID;
        userList.add(oppAdministratorUser);
        
        oppAdministratorUser = Utility_Test.createTestUser(oopAdminProfile.ID, 'firstName_oopAdmin3', 'lastName_oopAdmin3');
        oppAdministratorUser.UserRoleId = fieldAdminRole.ID;
        userList.add(oppAdministratorUser);
        
        oppAdministratorUser = Utility_Test.createTestUser(oopAdminProfile.ID, 'firstName_oopAdmin4', 'lastName_oopAdmin4');
        oppAdministratorUser.UserRoleId = MetadataSelector.rolesToDeveloperName_Map.get('OOPAgent').ID; 
        userList.add(oppAdministratorUser);
        
        insert userList;
        
        List<GroupMember> groupMember_List = new List<GroupMember>();
        Group intakeQueue = [Select ID From Group Where DeveloperName='IntakeQueue' And Type='Queue' Limit 1];
        GroupMember member = new GroupMember();
        member.UserOrGroupId = userList[1].ID;
        member.GroupId = intakeQueue.ID;
        groupMember_List.add(member);
        
        member = new GroupMember();
        member.UserOrGroupId = userList[2].ID;
        member.GroupId = intakeQueue.ID;
        groupMember_List.add(member);
        
        
        system.runAs(new User(ID=UserInfo.getUserId())){
            insert groupMember_List;
        }
    }
    
    @isTest
    private static void filterOnBeforeInsert_test(){
        User oppAdministratorUser = [Select ID From User Where LastName='lastName_oopAdmin'];
        system.runAs(oppAdministratorUser){
            ChildCaseAssignmentConfig__c config =  new ChildCaseAssignmentConfig__c();
            config.Action1__c = 'Billing'; 
            config.Action2__c = 'Simple';
            config.Action3__c = 'Midwest'; 
            config.CustomerType__c = 'Consumer';
            // 01-06-2020
            //config.Product__c = 'AT&T - DTV';
            config.Product__c = 'DIRECTV STREAM';
            config.Queue__c = 'IntakeQueue';
            config.User__c = [Select ID From User Where LastName='lastName_oopAdmin2'][0].ID;
            
            test.startTest();
            insert config;
            test.stopTest();
            system.assert([Select count() From ChildCaseAssignmentConfig__c]>0);
        }
    }
    
    @isTest
    private static void filterOnBeforeInsert_test2(){
        User oppAdministratorUser = [Select ID From User Where LastName='lastName_oopAdmin'];
        system.runAs(oppAdministratorUser){
            ChildCaseAssignmentConfig__c config =  new ChildCaseAssignmentConfig__c();
            config.Action1__c = 'Billing'; 
            config.Action2__c = 'Simple';
            config.Action3__c = 'Midwest'; 
            config.CustomerType__c = 'Consumer';
            // 01-06-2020
            //config.Product__c = 'AT&T - DTV';
            config.Product__c = 'DIRECTV STREAM';
            config.Queue__c = 'IntakeQueue';
            config.User__c = [Select ID From User Where LastName='lastName_oopAdmin2'][0].ID;
            insert config;
            
            test.startTest();
            config.User__c = [Select ID From User Where LastName='lastName_oopAdmin3'][0].ID;
            update config;
            test.stopTest();
            system.assert([Select count() From ChildCaseAssignmentConfig__c]>0);
        }
    }
    
    @isTest
    private static void filterOnBeforeUpdate_test(){
        User oppAdministratorUser = [Select ID From User Where LastName='lastName_oopAdmin'];
        system.runAs(oppAdministratorUser){
            ChildCaseAssignmentConfig__c config =  new ChildCaseAssignmentConfig__c();
            config.Action1__c = 'Billing'; 
            config.Action2__c = 'Simple';
            config.Action3__c = 'Midwest'; 
            config.CustomerType__c = 'Consumer';
            // 01-06-2020
            //config.Product__c = 'AT&T - DTV';
            config.Product__c = 'DIRECTV STREAM';
            config.Queue__c = 'IntakeQueue';
            config.User__c = [Select ID From User Where LastName='lastName_oopAdmin2'][0].ID;
            insert config;
            
            test.startTest();
            config.User__c = [Select ID From User Where LastName='lastName_oopAdmin4'][0].ID;
            try{
                update config;
            }
            catch(Exception ex){
                system.assert(String.isNotBlank(ex.getMessage()));    
            }
            test.stopTest();
        }
    }
}