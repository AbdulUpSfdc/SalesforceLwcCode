@isTest
private class CaseEscalationFieldsControllerTest{
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

    static testMethod void validateCaseEsc() {
        Case parentCase = TestData_Case.generateCase();

        Account testAccount = BWC_TestDataFactory.createAccount();
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount('Wireless', testAccount);

        Asset equipment = BWC_TestDataFactory.createEquipment('',testAccount,billingAccount, null);


        parentCase.AccountId = testAccount.Id;
        parentCase.Billing_Account__c = billingAccount.Id;

        //@manoj Start feb-19-2021
        parentCase.type='Product Service | Feature | Add Change Remove';
        //@manoj end feb-19-2021

        update parentCase;
        //@manoj start feb-19-2021
        Escalate_Case_Action_Fieldset_Mapping__mdt objmdt=[select id,Case_Action__c,Field_Set_API_Name__c from Escalate_Case_Action_Fieldset_Mapping__mdt where Case_Action__c='Unable to change rate plan - Regular' limit 1];
        CaseEscalationFieldsController.getCaseDetails(objmdt.Case_Action__c,parentCase.type,parentCase.Id);
        //@manoj End feb-19-2021

        System.assertEquals(parentCase.Product__c ,'Digital Life');
    }

    @IsTest
    static void getCaseActionValues(){

        Test.startTest();
        String response = CaseEscalationFieldsController.getCaseActionValues('Billing | Inquiry');
        Test.stopTest();

    }

}