//@isTest (seeAllData=true)
@isTest 
private class ReassignCaseTest {

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

    // test retreiving the role for a user
    static testmethod void testRoleInfoForUser() {
        User testUser = TestData_User.generateUser(''); 
        Test.startTest();
        Map<Id,String> roleInfo = ReassignCase.roleInfoForUser(testUser.Id);
        Test.stopTest();
        
        List<String> roleNames = roleInfo.values();
        System.assert(roleNames.contains(TestData_User.ROLE_NAME));
    }
    
    static testmethod void testAutoAssignedQueueForRole() {
        Case currentCase = TestData_Case.generateCase();
        Test.startTest();
        ReassignCase.autoAssignedQueueForRole(currentCase.Id, 'OOP Agent');
        Test.stopTest();
        List<Case> cases = [SELECT Id,OwnerId FROM Case WHERE Id = :currentCase.Id];
        String caseOwnerId = cases[0].OwnerId;
       // System.assert(caseOwnerId.startsWith('00G'), 'Auto-assigned Case owner should be a Queue');
    }

    static testmethod void testAutoAssignmentForFieldAgent() {
        // generate queue
        final String TEST_QUEUE_NAME = 'UserQueue';
        Group testQueue = TestData_Queue.generateQueue('Case', TEST_QUEUE_NAME);
        Case currentCase = TestData_Case.generateCase();
        TestData_Case.generateChildCaseAssignmentConfigForQueue(TEST_QUEUE_NAME);
        
        Test.startTest();
        Id reassignment = ReassignCase.autoAssignmentForFieldAgentFix(currentCase.Id, TEST_QUEUE_NAME);
        Test.stopTest();
        
        Group theQueue = [SELECT Id, OwnerId FROM Group WHERE Id = :testQueue.Id];
        
        ReassignCase.retrieveGroupDetails('Case');
        
        //System.assertEquals(theQueue.OwnerId, reassignment, 'Auto assignment for Field Agent should be Queue Owner');
        System.assertEquals(theQueue.Id, reassignment, 'Auto assignment for Field Agent failed');
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
        Map<Id,Object> assignedQueues = ReassignCase.getAssignedQueuesForUser(testUser.Id);
        Test.stopTest();
        
        List<Object> assignedQueueNames = assignedQueues.values();        
        System.assert(assignedQueueNames.size() > 0);
    }
    
    static testmethod void testGetUsersForQueue() {
        // generate queue
        final String TEXT_QUEUE_NAME = 'User Queue';
        Group testQueue = TestData_Queue.generateQueue('Case', TEXT_QUEUE_NAME);
        User testUser = TestData_User.generateUser(''); 
        List<User> testUsers = new List<User>();
        testUsers.add(testUser);
        TestData_Queue.addUsersToQueue(testUsers, TEXT_QUEUE_NAME);
        
        Test.startTest();
        Map<Id,String> assignedUsers = ReassignCase.getUsersForQueue(testQueue.Id);
        Test.stopTest();
        
        List<String> assignedUserNames = assignedUsers.values();        
        System.assert(assignedUserNames.contains('last')); 
    }
    
    static testmethod void testUpdateCaseOwner() {
        Case currentCase = TestData_Case.generateCase();
        ReassignCase.updateCaseOwner(currentCase.Id,[select id from user limit 1].id);
        ReassignCase.updateOwner('Case',currentCase,[select id from user limit 1].id,'New');
        
    }
    
    static testmethod void testEnableAssignButton() {
        Case currentCase = TestData_Case.generateCase();
        User testUser = TestData_User.generateUser(''); 
        Boolean shouldEnable = ReassignCase.enableAssignButton(currentCase.Id, testUser.Id);
        System.assertEquals(true, shouldEnable, 'Assign button should be enabled');
    }

}