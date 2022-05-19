@isTest
public class BWC_IMEISearchController_Test {

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
    static void testgethasRecordAccess() {
    String articleTitle = 'IMEI Search';
    String articleUrlName = 'IMEISearchToken';
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
        Boolean hasAccess = BWC_IMEISearchController.hasRecordAccess('IMEI Search');
        Test.stopTest();
    }
    
        @IsTest
    static void testgetimeiValue() {
        Test.startTest();
        String imeiValue = BWC_IMEISearchController.IMEISearch('012345678901234');
        Test.stopTest();
    }
}