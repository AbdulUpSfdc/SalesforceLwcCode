@isTest 
private class BWC_SLA_EntitlementTest {

    /*    @testSetup 
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
    }*/
    
    /*  */
    static testMethod void validate() {
        List<Account> lstOfAccount =new List<Account>();
        
        lstOfAccount.add(new Account(name='Inquiry'));
        lstOfAccount.add(new Account(name='Payment'));
        insert lstOfAccount;
        
        List<Entitlement> lstOfEntitlement=new List<Entitlement>();
        
        lstOfEntitlement.add(new Entitlement(Name='MSS SLA Billing Inquiry',AccountId=lstOfAccount[0].id));
        lstOfEntitlement.add(new Entitlement(Name='Product Service Entitlement',AccountId=lstOfAccount[1].id));
        
        insert lstOfEntitlement;
        
        
        System.assertNotEquals(null,BWC_SLA_Entitlement.handleSLA('Billing | Inquiry'));
        System.assertNotEquals(null,BWC_SLA_Entitlement.handleSLA('Product Service | Device | Upgrade'));
        System.assertNotEquals(null,BWC_SLA_Entitlement.handleSLA('Product Service | Feature | Add Change Remove'));
        System.assertNotEquals(null,BWC_SLA_Entitlement.handleSLA('Product Service | Rate Plan | Add Change Remove'));
       
        System.assertNotEquals(null,BWC_SLA_Entitlement.getEntitlement('MSS SLA Billing Inquiry'));
        System.assertNotEquals(null,BWC_SLA_Entitlement.getEntitlement('Product Service Entitlement'));
        
        Case parent = TestData_Case.generateCase();
        
        List<Id> caseIds=new List<Id>();
        caseIds.add(parent.id);
        
        BWC_SLA_Entitlement.completeOpenMilestones(caseIds);
        
         BWC_Constants.SLA_Data SLA_Data = new BWC_Constants.SLA_DATA();
        System.assert( [SELECT Id, CompletionDate FROM CaseMilestone WHERE CaseId = :parent.id AND IsCompleted = FALSE AND ( MilestoneType.Name = :SLA_Data.SLA_INTERNAL OR Case.IsClosed = TRUE )].size()==0);
    
    }
    
}