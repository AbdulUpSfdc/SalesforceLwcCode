@isTest
private class CreateChildCaseTest {
    
    @testSetup
    private static void testSetup(){
        Profile oopAdminProfile = [Select ID From Profile Where Name='Minimum Access OOP Admin'];
        UserRole fieldAdminRole = [SELECT Id FROM UserRole WHERE DeveloperName='FieldAdmin'];
        User oppAdministratorUser = Utility_Test.createTestUserWithRole(oopAdminProfile.ID, 'firstName_oopAdmin', 'lastName_oopAdmin', fieldAdminRole.Id);
        insert oppAdministratorUser;

        List<Utility_Test.UserPermissionSetWrapper> wrapperList = new List<Utility_Test.UserPermissionSetWrapper>();
        Utility_Test.UserPermissionSetWrapper wrapper = new Utility_Test.UserPermissionSetWrapper();
        wrapper.user = oppAdministratorUser;
        wrapper.permissionSetNames.add('OOPCaseAdmin');
        wrapperList.add(wrapper);
        system.runAs(new User(Id=UserInfo.getUserId())){
        	Utility_Test.assignPermissionSet(wrapperList);	    
        }
        Utility_Test.createCaseAdminRecords();
    }

    static testmethod void testGetChildCaseInfo() {
        Case parentCase = TestData_Case.generateCase();
        
        Test.startTest();
        CreateChildCase.ChildCaseInfo info = CreateChildCase.getChildCaseInfo(parentCase.Id);
        Test.stopTest();
        
        Case theParent = [SELECT Id, ExpectedCloseDate__c FROM Case WHERE Id = :parentCase.Id];
  		System.assertEquals(theParent.Id, info.parentCase.Id);
  		System.assertEquals(theParent.ExpectedCloseDate__c, info.parentExpectedCloseDate);
    }
}