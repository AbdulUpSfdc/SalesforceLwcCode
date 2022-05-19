/* 
  Test class for CaseOOPProductsToFlow apex class
*/   


@isTest
public class CaseOOPProductsToFlowTest {
    @testSetup
    private static void testSetup(){
       
        Profile oopAdminProfile = [Select ID From Profile Where Name='Minimum Access OOP Admin'];
        Profile oopAgentProfile = [Select ID From Profile Where Name='Minimum Access OOP Agent'];

        UserRole oopAdminRole = [SELECT Id FROM UserRole WHERE DeveloperName='OOPAdmin'];
        UserRole fieldAdminRole = [SELECT Id FROM UserRole WHERE DeveloperName='FieldAdmin'];
        UserRole fieldAgentRole = [SELECT Id FROM UserRole WHERE DeveloperName='FieldAgent'];
        List<User> userList = new List<User>();

        User oppAdministratorUser = Utility_Test.createTestUserWithRole(oopAdminProfile.ID, 'firstName_oopAdmin', 'lastName_oopAdmin', oopAdminRole.Id);
        userList.add(oppAdministratorUser);
        //insert oppAdministratorUser;

        oppAdministratorUser = Utility_Test.createTestUser(oopAdminProfile.ID, 'firstName_oopAdmin2', 'lastName_oopAdmin2');
        oppAdministratorUser.UserRoleId = fieldAdminRole.ID;
        userList.add(oppAdministratorUser);

        //Agent
        User oopAgent = Utility_Test.createTestUser(oopAgentProfile.ID, 'firstName_oppAgent', 'lastName_oopAgent');
        oppAdministratorUser.UserRoleId = fieldAgentRole.ID;
        userList.add(oopAgent);
        insert userList;

        List<GroupMember> groupMember_List = new List<GroupMember>();
        Group intakeQueue = [Select ID From Group Where DeveloperName='IntakeQueue' And Type='Queue' Limit 1];
        GroupMember member = new GroupMember();
        member.UserOrGroupId = userList[0].ID;
        member.GroupId = intakeQueue.ID;
        groupMember_List.add(member);

        member = new GroupMember();
        member.UserOrGroupId = userList[1].ID;
        member.GroupId = intakeQueue.ID;
        groupMember_List.add(member);

        member = new GroupMember();
        member.UserOrGroupId = oopAgent.ID;
        member.GroupId = intakeQueue.ID;
        groupMember_List.add(member);

        member = new GroupMember();
        member.UserOrGroupId = oopAgent.ID;
        member.GroupId = [Select ID From Group Where DeveloperName='OOPAgents' And Type='Regular'][0].ID;
        groupMember_List.add(member);

        List<Utility_Test.UserPermissionSetWrapper> wrapperList = new List<Utility_Test.UserPermissionSetWrapper>();
        
        // oopAdmin
        Utility_Test.UserPermissionSetWrapper wrapper = new Utility_Test.UserPermissionSetWrapper();
        wrapper.user = userList[0];
        wrapper.permissionSetNames.add('OOPCaseAdmin');
        wrapper.permissionSetNames.add('OOPCaseTransfer');
        wrapper.permissionSetNames.add('OOPCaseFullPermission');
        wrapperList.add(wrapper);

        //oopAdmin2
        wrapper = new Utility_Test.UserPermissionSetWrapper();
        wrapper.user = userList[1];
        wrapper.permissionSetNames.add('OOPCaseAdmin');
        wrapper.permissionSetNames.add('OOPCaseTransfer');
        wrapper.permissionSetNames.add('OOPCaseFullPermission');
        wrapperList.add(wrapper);

        wrapper = new Utility_Test.UserPermissionSetWrapper();
        wrapper.user = oopAgent;
        wrapper.permissionSetNames.add('OOPCaseCreate');
        wrapper.permissionSetNames.add('OOPCaseTransfer');
        wrapperList.add(wrapper);

        system.runAs(new User(Id=UserInfo.getUserId())){
            Utility_Test.assignPermissionSet(wrapperList);
            insert groupMember_List;
        }
        Utility_Test.createCaseAdminRecords();

    }
     @isTest
    private static void testHandlePendingClosure() {
        Case testCase = TestData_Case.generateCase();
        List<case> lstOfCases=[select id ,product__c from case];
        for(case cs:lstOfCases){
            cs.product__c='DIRECTV STREAM;DIRECTV';
        }
        update lstOfCases;
        try {
            Test.startTest();
            //Case childCase = TestData_Case.generateChildCase(testCase.Id);
            // close all child cases
            //TestData_Case.closeCase(childCase, 'Closed');
            // set parent to Pending Closed
            TestData_Case.closeCase(testCase, 'Pending Closed');
            Test.stopTest();
        }
        catch(Exception e) {
            System.debug('===?'+e.getMessage() );
            Boolean exceptionThrown = e.getMessage().contains('Parent Case cannot be set to Pending Closed') ? true : false;
            //System.assertEquals(exceptionThrown, true);
        }
        
        CaseOOPProductsToFlow.retrieveQueueId('IntakeQueue');
        CaseOOPProductsToFlow.checkProductsOOP(new List<Id>{lstOfCases[0].id});

    }
    @isTest
    private static void testHandlePendingClosureNoProducts() {
        Case testCase = TestData_Case.generateCase();        
        CaseOOPProductsToFlow.checkProductsOOP(new List<ID>{testCase.id});

    }
    @isTest
    private static void testHandlePendingClosureProductsNoDescription() {
        Case testCase = TestData_Case.generateCase(); 
        List<case> lstOfCases=[select id,product__c,Description from case];
        for(case cs:lstOfCases){
            cs.Description='';
            cs.product__c='DIRECTV STREAM;DIRECTV';
        }
        update lstOfCases;
        CaseOOPProductsToFlow.checkProductsOOP(new List<ID>{lstOfCases[0].id});

    }
     public static testMethod void testParentChildCase() {
        Id oopCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(CaseConstants.OOP_RECORD_TYPE).getRecordTypeId();
        //Id childCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(CaseConstants.OOP_FIELD_RECORD_TYPE).getRecordTypeId();

        ChildCaseAssignmentConfig__c cac = new ChildCaseAssignmentConfig__c();
        cac.Action1__c ='Billing';
        cac.Action2__c ='Simple';
        cac.Action3__c ='West';
        cac.Product__c ='DIRECTV STREAM';
        cac.CustomerType__c ='Consumer';
        cac.Queue__c='FieldAdmin';
        insert cac;

        // Create OOP Case Record
        Case c= new Case();
        c.RecordTypeId = oopCaseRecordTypeId;
        c.Status = CaseConstants.PENDING_CLOSED_STATUS;
        //c.ExpectedResponseDate__c = Date.today()+30;
        c.CloseNotes__c = 'Test';
        c.Resolution__c = 'Corrected';
        c.Resolution2__c ='Adjustment';
        c.SatisfactionIndicator__c = 'Satisfied';
        c.ProblemCode__c ='DTV - Billing';
        c.ProblemCode2__c = 'Recurring Monthly Charges';
        c.ProblemCode3__c = 'Disputing taxes/fees';
        //c.CustomerType__c ='Consumer';
        c.Product__c ='DIRECTV STREAM';
        insert c;
        
         Account testAccount = BWC_TestDataFactory.createAccount();
         Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount('Wireless', testAccount);
         billingAccount.Customer_Type__c = 'Consumer';
         update billingAccount;
         // Create OOP Child Cases

        
        // Create OOP Case Record
        Case c1= new Case();
        c1.RecordTypeId = oopCaseRecordTypeId;
        c1.Status = CaseConstants.NEW_STATUS;
        //c1.CustomerType__c ='Consumer';
        insert c1;

    }
    
}