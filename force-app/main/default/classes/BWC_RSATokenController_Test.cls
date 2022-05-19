@isTest
public class BWC_RSATokenController_Test {
    
    public static final String ROLE_NAME = 'TestingTeam';
    private static final String DATE_FORMAT = 'ssSSS';

    @testSetup
    public static void testDataSetup(){
        User u = new User(); 
        Profile sysAdminProfile = [Select ID From Profile Where Name='System Administrator'];
        UserRole roleRec = [SELECT Id FROM UserRole WHERE DeveloperName='VPServices'];
        User adminUser1 =Utility_Test.createTestUserWithRole(sysAdminProfile.Id, 'testFirst1', 'testLast1', roleRec.Id);
        adminUser1.ATTUID__c ='Test';
        adminUser1.FederationIdentifier = 'Test';
        insert adminUser1; 
    }

    @IsTest
    static void testgetAuthCode() {
        Test.startTest();   
        BWC_RSATokenController.getAuthCode();
        Test.stopTest();
    }
    
    @IsTest
    static void testgethasRecordAccess() {
    String articleTitle = 'RSA Token';
    String articleUrlName = 'RSATokenArticle';
    String language = 'en_US';

    Knowledge__kav article = new Knowledge__kav(
      Title = articleTitle,
      UrlName = articleUrlName,
      Language = language,
      ContentSponsor__c = KM_TestDataFactory.createAuthorUser('abc123').attUId__c 
    );

    insert article;

    Knowledge__kav currentArticleDetail = [
      SELECT ArticleCreatedDate, ArticleNumber
      FROM Knowledge__kav
      WHERE Id = :article.Id
    ];

    KnowledgeArticle knowledgeArticle = [
      SELECT Id
      FROM KnowledgeArticle
      WHERE ArticleNumber = :currentArticleDetail.get('ArticleNumber').toString()
    ];

    KbManagement.PublishingService.publishArticle(knowledgeArticle.Id, true);
        Test.startTest();
        BWC_RSAToken.RSATokenResponse response = new BWC_RSAToken.RSATokenResponse();
        BWC_RSATokenController.hasRecordAccess('RSA Token');
        Test.stopTest();
    }
    
       @IsTest
    static void testgetCache() {
        Test.startTest();
        BWC_RSAToken.RSATokenResponse response = new BWC_RSAToken.RSATokenResponse();
        BWC_RSATokenController.CacheAuthCode(response);
        Test.stopTest();
    }
    
     @IsTest
    static void testgetRSAToken(){
		Test.startTest();
        String authToken = BWC_RSATokenController.getAuthCode();
        Boolean token = BWC_RSATokenController.generateNewToken('891700--90626450--2021-10-06T15:46:14.000Z');
        BWC_RSATokenController.getRSAToken();
        Test.stopTest();
	}
   
    static String generateEmail() {
        String orgId = UserInfo.getOrganizationId();
        String seconds = system.now().format(DATE_FORMAT);
        return orgId + seconds + '@att.test.com';
    }  
}