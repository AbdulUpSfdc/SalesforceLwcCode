@isTest
public class ArticleKeywordSearchBatchTest {
    public static final String ROLE_NAME = 'TestingTeam';
    private static final String DATE_FORMAT = 'ssSSS';


    public static testMethod void testBatch(){
        Knowledge__kav kav = ArticleGenerator.testPublishArticle();
        Group validGroup = ArticleKeywordSearchBatch.getGroupByName(ArticleKeywordSearchBatch.CONTENT_STRATEGY_GROUP_NAME);
        /*UserRole userRole;
        userRole = new UserRole(DeveloperName = ROLE_NAME, Name = ROLE_NAME);
        insert userRole;*/
        String  profileName = 'System Administrator';
        String emailName = generateEmail();
        Id sysAdminPRofileId = [SELECT Id FROM Profile WHERE Name = :profileName].Id;
        String searchTerm;
		String attId;
        attId = 'vk8702';
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
        profileName = 'System Administrator';
	    emailName = generateEmail();
        User requestUser = new User(
                ProfileId = sysAdminPRofileId,
                LastName = 'last',
                FirstName = 'first',
                Email = emailName,
                Username = emailName+2,
                Alias = emailName.substring(18, 23),
                CompanyName = 'Testing',
                FederationIdentifier = 'ABCDE',
                TimeZoneSidKey = 'America/Chicago',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                IsActive=true,
                UserPermissionsKnowledgeUser =true,
            	ATTUID__c = attid
                //UserRoleId = userRole.Id
            );
        
        System.runas(u) {
        insert requestUser; 
        GroupMember gm = new  GroupMember();
        gm.UserOrGroupId = requestUser.id;
        gm.GroupId = validGroup.Id;
        insert gm;
        }    
        List<Group> groupList = [SELECT id, name, developerName FROM GROUP WHERE type='Regular' AND DeveloperName=:ArticleKeywordSearchBatch.CONTENT_STRATEGY_GROUP_NAME]; 
		System.assertEquals(1, groupList.size());
        List<GroupMember> memberList = [SELECT Id, groupID, UserOrGroupId FROM GroupMember WHERE groupID = :grouplist[0].Id AND
                                        UserOrGroupId = : requestUser.Id];
        
        System.assertEquals(1, memberList.size());
        System.runas(requestUser) {
        
        searchTerm = 'HBO';
		
         Test.startTest();
        Id batchJobId = Database.executeBatch(new ArticleKeywordSearchBatch(searchTerm, attId), 200);
		Test.stopTest();
        }   
    }
    
           
 	public static String generateEmail() {
        String orgId = UserInfo.getOrganizationId();
        String seconds = system.now().format(DATE_FORMAT);
        return orgId + seconds + '@att.test.com';
    }    
    
}