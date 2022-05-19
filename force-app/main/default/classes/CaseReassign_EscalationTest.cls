/*
    Class Name # CaseReassign_EscalationTest 
    Purpose # Code coverage class for CaseReassign_Escalation 
    
*/    

@isTest 
private class CaseReassign_EscalationTest {

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

    
    
    

    
    
    static testmethod void testGetAssignedQueuesForUser() {
        // generate queue
        final String TEXT_QUEUE_NAME = 'Assigned Queue';
        Group testQueue = TestData_Queue.generateQueue('Case', TEXT_QUEUE_NAME);
        User testUser = TestData_User.generateUser(''); 
        List<User> testUsers = new List<User>();
        testUsers.add(testUser);
        TestData_Queue.addUsersToQueue(testUsers, TEXT_QUEUE_NAME);
        
        Test.startTest();
        CaseReassign_Escalation.getUserDetails(TEXT_QUEUE_NAME);
        Test.stopTest();
        
        //List<Object> assignedQueueNames = assignedQueues.values();        
        //System.assert(assignedQueueNames.size() > 0);
        
    }
    
    
    
    static testmethod void testUpdateCaseOwner() {
        final String TEXT_QUEUE_NAME = 'Assigned Queue';
        Group testQueue = TestData_Queue.generateQueue('Case', TEXT_QUEUE_NAME);
        User testUser = TestData_User.generateUser(''); 
        
        Case currentCase = TestData_Case.generateCase();
        
        CaseReassign_Escalation.updateCaseOwner(currentCase.Id,testUser.Id);
        
        //Case currentCase = TestData_Case.generateCase();
        //ResassignCase.updateCaseOwner(currentCase.Id,)
    }
    
    

}