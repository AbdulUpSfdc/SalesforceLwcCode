@isTest
private class OverdueChildCasesBatchTest {
    @testSetup 
    static void setup() {
        Profile oopAdminProfile = [Select ID From Profile Where Name='Minimum Access OOP Admin'];
        UserRole oopAdminRole = [SELECT Id FROM UserRole WHERE DeveloperName='OOPAdmin'];
        User oppAdministratorUser = Utility_Test.createTestUserWithRole(oopAdminProfile.ID, 'firstName_oopAdmin', 'lastName_oopAdmin', oopAdminRole.Id);
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
    
    static testmethod void test() {
        Case parent = TestData_Case.generateCase();
        Case_Action__c ca = new Case_Action__c();
        ca.Case__c = parent.Id;
        ca.RecordTypeId = Case_Action_Constants.FIELD_RECORDTYPE_ID;
        ca.Admin_Close_Date__c = Date.today().addDays(-1);
        ca.Expected_Close_Date__c = Date.today().addDays(-1);
        Test.startTest();
        OverdueCasesActionsBatch batch = new OverdueCasesActionsBatch();
        List<Case_Action__c> caseActionList = new List<Case_Action__c>();
        caseActionList.Add(ca);
        batch.execute(null, caseActionList);
        Id batchId = Database.executeBatch(batch);
        Test.stopTest();

    }
    
}