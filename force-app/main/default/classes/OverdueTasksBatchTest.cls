@isTest
private class OverdueTasksBatchTest
{
    @testSetup
    static void setup()
    {
        /*Profile oopAdminProfile = [Select ID From Profile Where Name='Minimum Access OOP Admin'];
        UserRole oopAdminRole = [SELECT Id FROM UserRole WHERE DeveloperName='OOPAdmin'];
        
        User oppAdministratorUser = Utility_Test.createTestUserWithRole(oopAdminProfile.ID, 'firstName_oopAdmin', 'lastName_oopAdmin', oopAdminRole.Id);
        insert oppAdministratorUser;

        List<Utility_Test.UserPermissionSetWrapper> wrapperList = new List<Utility_Test.UserPermissionSetWrapper>();
        Utility_Test.UserPermissionSetWrapper wrapper = new Utility_Test.UserPermissionSetWrapper();
        wrapper.user = oppAdministratorUser;
        wrapper.permissionSetNames.add('OOPCaseAdmin');
        wrapperList.add(wrapper);
        System.runAs(new User(Id = UserInfo.getUserId()))
        {
        	Utility_Test.assignPermissionSet(wrapperList);
        }
        Utility_Test.createCaseAdminRecords();*/
        

        Case c = TestData_Case.generateCase();
        TestData_Task.generateTasksForWhatId(c.Id, 3);
    }

    static testmethod void test()
    {
        Test.startTest();
        OverdueTasksBatch batch = new OverdueTasksBatch();
        Id batchId = Database.executeBatch(batch);
        Test.stopTest();

        List<Case> overdueCases = [SELECT Id, OverdueTasks__c FROM Case];
        System.assertEquals(true, overdueCases[0].OverdueTasks__c);
    }
}