@isTest
public with sharing class UserSettingHelperTest {

    public static testmethod void testGetUserSetting() {
        String  profileName = 'System Administrator';
        String emailName = UserInfo.getOrganizationId() + system.now().format('ssSSS') + '@att.test.com';
        Id sysAdminPRofileId = [SELECT Id FROM Profile WHERE Name = :profileName].Id;

        User u = new User(
                ProfileId = sysAdminPRofileId,
                LastName = 'last',
                FirstName = 'first',
                Email = emailName,
                Username = emailName,
                Alias = emailName.substring(18, 23),
                CompanyName = 'Testing',
                FederationIdentifier = 'ABCD',
                TimeZoneSidKey = 'America/Chicago',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                IsActive=true,
                UserPermissionsKnowledgeUser =true
                //UserRoleId = userRole.Id
            );
        insert u;   
        User_Setting__c  userSetting = UserSettingHelper.getUserSetting(u.Id);
        System.assertEquals(null, userSetting);
        String userId = u.Id;
    	String searchText = 'testSearch1';
        String sortBy = 'sortBy';
        String filterBy = 'filterBy';
        Integer currentPage = 1;
        String startDate = '1/1/2021';
        String endDate = '12/31/2021';
     	ArticleSearchWrapper searchWrapper = new ArticleSearchWrapper(searchText, sortBy, filterBy, currentPage,
                        											startDate, endDate);
        UserSettingHelper.upsertUserSetting(userId, searchWrapper);
        userSetting = UserSettingHelper.getUserSetting(u.Id);
        System.assert(userSetting.Article_Search_JSON__c.contains(searchText));
        searchText = 'testSearch2';
        Test.startTest();
        UserSettingHelper.upsertUserSetting(userId, searchText, sortBy, filterBy, currentPage, startDate, endDate);
        Test.stopTest();
        userSetting = UserSettingHelper.getUserSetting(u.Id);
        System.assert(userSetting.Article_Search_JSON__c.contains(searchText));              
    } 
    
}