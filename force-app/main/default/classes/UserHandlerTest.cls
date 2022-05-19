@isTest
public without sharing class UserHandlerTest {
    private static TestDataFactory.TestWrapper dataFactoryWrap = new TestDataFactory.TestWrapper();
    private static TestDataFactory dataFactory = new TestDataFactory();
    
    @isTest
    static void testProcessUserPermissions() {
        dataFactoryWrap = dataFactory.createTestData(1, 'UHT');

        List<User> repUsersList = dataFactoryWrap.mapRoleVsUsers.get(RetailConstants.REP_POSITION);
        User repUser = repUsersList.get(0);
        
        Map<Id,Map<String,List<Employee__c>>> mapStoreVsMapRoleEmployee = dataFactory.getHomeStoreEmployeesByRole(dataFactoryWrap.mapRoleVsUsers, dataFactoryWrap.lstStore);
        Map<String,List<Employee__c>> mapRoleToEmps = mapStoreVsMapRoleEmployee.get(dataFactoryWrap.lstStore.get(0).Id);
        List<Employee__c> repEmpsList = mapRoleToEmps.get(TestDataFactory.mapProfileToSfProfile.get(TestDataFactory.REP_PROFILE));
        
        List<Employee__c> employeesToUpdate = New List<Employee__c>();
        for (Employee__c emp : [SELECT Id, isActive__c, User__c, SFProfileId__c, RecordTypeId FROM Employee__c WHERE isActive__c =: TRUE AND User__c IN: repUsersList]) {
            Employee__c e = New Employee__c(Id = emp.Id);
            e.RecordTypeId = RetailConstants.RETAIL_RECORDTYPEID;
            employeesToUpdate.add(e);
        }
        update employeesToUpdate;
        
        System.runAs(New User(Id=UserInfo.getUserId())) {
            list <GroupMember> listCurrGrpMemBefore = [SELECT Id, UserOrGroupId, GroupId, Group.DeveloperName  FROM GroupMember WHERE UserOrGroupId =: repUsersList.get(0).Id];
            System.assert(listCurrGrpMemBefore.size() == 0);
            
            map<Id, map<Id, GroupMember>> mapGrpMemByGrpByUser = RetailGroupMemberBatch.getGrpMemByGrpByUser(New Set<Id>{repUsersList.get(0).Id});
            UserHandler.processUserPermissions(New Set<Id>{employeesToUpdate.get(0).Id}, mapGrpMemByGrpByUser);
            
            list <GroupMember> listCurrGrpMemAfter = [SELECT Id, UserOrGroupId, GroupId, Group.DeveloperName  FROM GroupMember WHERE UserOrGroupId =: repUsersList.get(0).Id];
            System.assert(listCurrGrpMemAfter.size() != 0);
        }
        
    }
    
}