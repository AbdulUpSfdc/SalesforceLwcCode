/*
Test Class for MetadataSelector
*/
@isTest
private class MetadataSelector_Test {
    @testSetup
    private static void testSetup(){
        Profile oopAdminProfile = [Select ID From Profile Where Name='Minimum Access OOP Admin'];
        UserRole oopAdminRole = [Select ID From UserRole Where DeveloperName='OOPAdmin' Limit 1];
        List<User> userList = new List<User>();
        User oppAdministratorUser = Utility_Test.createTestUser(oopAdminProfile.ID, 'firstName_oopAdmin', 'lastName_oopAdmin');
        oppAdministratorUser.UserRoleId = oopAdminRole.ID;
        userList.add(oppAdministratorUser);
        
        oppAdministratorUser = Utility_Test.createTestUser(oopAdminProfile.ID, 'firstName_oopAdmin2', 'lastName_oopAdmin2');
        userList.add(oppAdministratorUser);
        
        oppAdministratorUser = Utility_Test.createTestUser(oopAdminProfile.ID, 'firstName_oopAdmin3', 'lastName_oopAdmin3');
        userList.add(oppAdministratorUser);
        
        oppAdministratorUser = Utility_Test.createTestUser(oopAdminProfile.ID, 'firstName_oopAdmin4', 'lastName_oopAdmin4');
        oppAdministratorUser.UserRoleId = MetadataSelector.rolesToDeveloperName_Map.get('OOPAgent').ID; 
        userList.add(oppAdministratorUser);

        insert userList;
        
        List<GroupMember> groupMember_List = new List<GroupMember>();
        Group intakeQueue = [Select ID From Group Where DeveloperName='IntakeQueue' And Type='Queue' Limit 1];
        GroupMember member = new GroupMember();
        member.UserOrGroupId = userList[1].ID;
        member.GroupId = intakeQueue.ID;
        groupMember_List.add(member);
        
        member = new GroupMember();
        member.GroupId = intakeQueue.ID;
        member.UserOrGroupId = [Select ID From Group Where relatedId = :oopAdminRole.ID and Type='Role'].ID;
        groupMember_List.add(member);
        
        ID publicGroupID = [Select ID From Group Where DeveloperName = 'OOPAdmins' And Type='Regular' Limit 1][0].ID;
        member = new GroupMember();
        member.GroupId = publicGroupID;
        member.UserOrGroupId = userList[2].ID;
        groupMember_List.add(member);
        
        member = new GroupMember();
        member.GroupId = publicGroupID;
        member.UserOrGroupId = [Select ID From Group Where Type='Role' And RelatedID = :MetadataSelector.rolesToDeveloperName_Map.get('OOPAgent').ID][0].ID;
        groupMember_List.add(member);
        
        member = new GroupMember();
        member.GroupId = intakeQueue.ID;
        member.UserOrGroupId = publicGroupID;
        groupMember_List.add(member);
        
        system.runAs(new User(ID=UserInfo.getUserId())){
            insert groupMember_List;
        }
    }
    
    @isTest
    private static void fetchUsers_test(){
       User oppAdministratorUser = [Select ID From User Where LastName='lastName_oopAdmin'];
        system.runAs(oppAdministratorUser){
            Set<ID> userId_Set = new Set<ID>();
            test.startTest();
                userId_Set = MetadataSelector.fetchUsers('IntakeQueue');
            test.stopTest();
            system.assert(userId_Set.size()>0);
        }
    }
}