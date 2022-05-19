@isTest
private class SyncCaseWithProducts_Tst {
    private static final string strNAMED_CREDENTIAL=BWC_Constants.NAMEDCR_CUSTOMER_SEARCH;
    private static final integer intTWO_HUNDRED=BWC_Constants.HTTP_STATUS_CODE_200;
    

    @testSetup
    private static void testSetup(){
        Profile oopAdminProfile = [Select ID From Profile Where Name='Minimum Access OOP Admin'];
        UserRole oopAdminRole = [SELECT Id FROM UserRole WHERE DeveloperName='OOPAdmin'];
        
        List<User> userList = new List<User>();
        User oppAdministratorUser = Utility_Test.createTestUserWithRole(oopAdminProfile.ID, 'firstName_oopAdmin', 'lastName_oopAdmin', oopAdminRole.Id);
        userList.add(oppAdministratorUser);
        insert userList;

        List<GroupMember> groupMember_List = new List<GroupMember>();
        GroupMember groupMember = new GroupMember();
        groupMember.GroupId = [SELECT ID From Group Where DeveloperName='OOPAdmins' AND Type='Regular' Limit 1].ID;
        groupMember.UserOrGroupId = userList[0].ID;
        groupMember_List.add(groupMember);

        insert groupMember_List;
        
        
        //assign permission set to users...
        List<Utility_Test.UserPermissionSetWrapper> wrapperList = new List<Utility_Test.UserPermissionSetWrapper>();
        Utility_Test.UserPermissionSetWrapper wrapper = new Utility_Test.UserPermissionSetWrapper();
        wrapper.user = userList[0];
        //wrapper.permissionSetNames.add('OOPCaseAdmin');
        wrapper.permissionSetNames.add('OOPCaseFullPermission');
        wrapperList.add(wrapper);
            
        wrapper = new Utility_Test.UserPermissionSetWrapper();
        wrapper.user = userList[0];
        wrapper.permissionSetNames.add('C360_Agent');
        wrapperList.add(wrapper);
        
        wrapper = new Utility_Test.UserPermissionSetWrapper();
        wrapper.user = userList[0];
        wrapper.permissionSetNames.add('OOPCaseTransfer');
        wrapperList.add(wrapper);
        
        Utility_Test.assignPermissionSet(wrapperList);

        
        system.runAs(new User(Id=UserInfo.getUserId())){
            //Utility_Test.assignPermissionSet(wrapperList);
            Utility_Test.createCaseAdminRecords();
            Utility_Test.createProductMapping();
            //insert groupMember_List;
        }
        
        //create case admin, case admin states records...
    }// test setup method ends...

    @isTest
    private static void syncCaseWithProducts_Tst1(){
        User oppAdministratorUser = [Select ID From User Where LastName='lastName_oopAdmin'];
        Case parentCase;
        Account testAccount;
        Billing_Account__c billingAccount;
        ID caseId;
        String ban = '423432423';

            

        system.runAs(oppAdministratorUser){
            //testAccount = BWC_TestDataFactory.createAccount();
            //billingAccount = BWC_TestDataFactory.createBillingAccount('Wireless', testAccount);
            //parentCase = DataFactory_Test.createParentCase();

            // Mock return from product search
            testAccount = BWC_TestDataFactory.createAccount();
            billingAccount = BWC_TestDataFactory.createBillingAccount('Wireless', testAccount);
            billingAccount.Billing_Account_Number__c = '1111111111111';
            update billingAccount;
            parentCase = DataFactory_Test.createParentCase();
            parentCase.AccountId = testAccount.ID;
            parentCase.AccountIdentifier__c=ban;
            parentCase.Product__c='Wireless';
            insert parentCase;
            caseId = parentCase.ID; 
            

            //List<BWC_ProductSearchService.ServiceModel> services = BWC_ProductSearchService.getProductsGroupedByService(testAccount.Id);
            SyncCaseWithProducts sync = new SyncCaseWithProducts(caseId, ban);

            test.starttest();
            BWC_ApiMock.setTestApiMock(BWC_ProductSearchCallout.API_PRODUCT_SEARCH, 'UT_Product_Search_200');
            // 01-06-2020
            //system.enqueueJob(sync);
            sync.execute(null);
            test.stoptest();
        }
        parentCase = new Case();
        parentCase = [Select Product__c From Case Where Id =:caseId];
        system.assert(String.isNotBlank(parentCase.Product__c));
    }// method ends...

}