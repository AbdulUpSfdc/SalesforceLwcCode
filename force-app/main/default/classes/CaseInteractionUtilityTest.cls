/*
    Class Name # CaseInteractionUtilityTest
    Purpose # Code coverage class for CaseInteractionUtility
    
*/    

@isTest 
private class CaseInteractionUtilityTest{

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
    
    static testmethod  void testcaseInteraction(){
           Account acct = BWC_TestDataFactory.createAccount();
           Interaction__c interaction = BWC_TestDataFactory.createInteraction(acct);
 
           Case currentCase = TestData_Case.generateCase();
           currentCase.Last_Interaction__c=interaction.id;
           update currentCase;
           
           Case retrieveCase = [Select Id,Last_Interaction__c from Case where Id = :currentCase.Id];
        
          
         
          System.assertEquals(retrieveCase.Last_Interaction__c,interaction.Id);
           
    }
}