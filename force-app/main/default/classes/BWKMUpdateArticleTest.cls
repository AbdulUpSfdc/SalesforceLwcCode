@isTest
public with sharing class BWKMUpdateArticleTest {
    
    
     @testsetup
      static void testData(){
        List<Knowledge__kav> knowledgeArticles = new List<Knowledge__kav>();
        List<BWKnowledgeArticleLink__c> articleLinks = new List<BWKnowledgeArticleLink__c>();
        User authorUser = KM_TestDataFactory.createContentSponsorUser('abcdef');
        String newsArticleRecordTypeId = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByName().get('News Article').getRecordTypeId();
        //50 articles with Urgent and Frontline flag checked (true)
        for(Integer i=0; i<5; i++){
            Knowledge__kav  ka = new Knowledge__kav(
                RecordTypeId = newsArticleRecordTypeId,
                BW_News_End_Date__c  = System.now().addMinutes(-i),
                BW_Is_Urgent__c =  true,
                BW_FrontLine_Focus__c = true,
                BW_Home_Page_Display__c = false,
                Title = 'Frontline-Test-Article-' + i+1,
                UrlName = 'Frontline-Test-Article-' + i+1,
                ContentSponsor__c = authorUser.attuid__c
            );
            knowledgeArticles.add(ka);
        }
        insert knowledgeArticles;
          for(Knowledge__kav ka : [SELECT Id, KnowledgeArticleId FROM Knowledge__kav LIMIT 5]){
            KbManagement.PublishingService.publishArticle(ka.KnowledgeArticleId, true);
          }
          list<BW_KM_Logs__c>listofkmlogs= new list<BW_KM_Logs__c>();
          for(Knowledge__kav ka : [SELECT Id, KnowledgeArticleId,ArticleNumber FROM Knowledge__kav where PublishStatus='online' LIMIT 5 ]){
          
              BW_KM_Logs__c Bw =new BW_KM_Logs__c();
         bw.Article_ID__c=ka.id;
         bw.Article_Number__c=ka.ArticleNumber;
         bw.NewContentSponsor__c='ABCD';
         bw.Status__c='Awaiting add content sponsor';
         listofkmlogs.add(bw);
              }
          insert listofkmlogs;
      }
 public static testMethod void testNewChannelMaster(){
        User u;
        PermissionSet ps;
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        System.runAs ( thisUser ) {
            Profile p = [select id from profile where name='System Administrator'];
            u = new User(alias = 'standt', email='standarduser@testorg.com', 
                         emailencodingkey='UTF-8', lastname='Testing', 
                         languagelocalekey='en_US', 
                         localesidkey='en_US', profileid = p.Id, 
                         timezonesidkey='America/Los_Angeles', IsActive=true,
                         UserPermissionsKnowledgeUser =true,
                         username='standarduser@testorg.com123');
            insert u;
        }
     system.runAs(u){
         
          test.startTest();
            BWKMUpdateArticle Arti = new BWKMUpdateArticle();
            Database.executeBatch(Arti);
            test.stopTest();
     }
     
     
    
         
}
}