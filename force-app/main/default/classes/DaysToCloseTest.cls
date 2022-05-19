@isTest
private class DaysToCloseTest {
    
    @testSetup
    private static void testSetup(){
        Billing_Account__c  objBillAcc=new Billing_Account__c ();
        objBillAcc.Product_Name_360__c='Wireless';
        objBillAcc.Billing_Account_Number__c='331525754';
        objBillAcc.Billing_Address_Line_1__c='8600 FM 2451';
        objBillAcc.Billing_City__c='NEW BERLIN';
        objBillAcc.Billing_State__c='FL';
        objBillAcc.Billing_Zipcode__c='32901-8117';
        objBillAcc.Service_Address_Line_1__c='8600 FM 2451';
        objBillAcc.Service_Address_Line_2__c='3392 FAN PALM BLVD';
        objBillAcc.Service_City__c='NEW BERLIN';
        objBillAcc.Service_State__c='FL';
        objBillAcc.Service_Zipcode__c ='32901-8117';
        objBillAcc.First_Name__c='test';
        objBillAcc.Last_Name__c='test';
        objBillAcc.Contact_Number__c='1234567890';
        objBillAcc.Email__c='test@gmail.com';
        objBillAcc.Service_Country__c='United States';
        objBillAcc.Billing_Country__c='United States';
        objBillAcc.Account_Type__c = 'Uverse';
        insert objBillAcc;
        
        Profile oopAdminProfile = [Select ID From Profile Where Name='Minimum Access OOP Admin'];
        UserRole fieldAdminRole = [SELECT Id FROM UserRole WHERE DeveloperName='FieldAdmin'];
        User oppAdministratorUser = Utility_Test.createTestUserWithRole(oopAdminProfile.ID, 'firstName_oopAdmin', 'lastName_oopAdmin', fieldAdminRole.Id);
        //insert oppAdministratorUser;

        List<Utility_Test.UserPermissionSetWrapper> wrapperList = new List<Utility_Test.UserPermissionSetWrapper>();
        Utility_Test.UserPermissionSetWrapper wrapper = new Utility_Test.UserPermissionSetWrapper();
        wrapper.user = oppAdministratorUser;
        wrapper.permissionSetNames.add('OOPCaseAdmin');
        wrapperList.add(wrapper);
        system.runAs(new User(Id=UserInfo.getUserId())){
           // Utility_Test.assignPermissionSet(wrapperList);      
        }
        Utility_Test.createCaseAdminRecords();
    }

    static testmethod void testCountOpenCasesForSameCustomer() {
        Case currentCase = TestData_Case.generateCase();
        Billing_Account__c   billAcc=[select id from Billing_Account__c   limit 1];
        Test.startTest();
        String accountName = 'Test Account';
        Integer otherCaseCount = DaysToClose.countOpenCasesForSameCustomer('test', currentCase.Id,billAcc.id);
        
        Set<Id> billAccts=new Set<Id>();
        billAccts.add(billAcc.id);
        DaysToClose.getBillingAcctCasesCount(billAccts);
        Test.stopTest();
        
        System.assertEquals(0, otherCaseCount);
    }
    
    static testmethod void testgetRelatedOOPCasesCount() {
        Case currentCase = TestData_Case.generateCase();
        Billing_Account__c  billAcc=[select id from Billing_Account__c limit 1];
        
        Test.startTest();
        currentCase.Billing_Account__c = billAcc.Id;
        update currentCase;
        
        List<Id> caseIds = new List<Id>();
        caseIds.add(currentCase.Id);
        
        List<String> matchExist = DaysToClose.getRelatedOOPCasesCount(caseIds);
        Test.stopTest();
        
        //System.assertEquals(0, otherCaseCount);
    }
    
    
}