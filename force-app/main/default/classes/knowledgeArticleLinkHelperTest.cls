@isTest
public class knowledgeArticleLinkHelperTest {
  
     public static testmethod void testUnitOne(){
      
       	Knowledge__kav  knowledgeAssigned = new Knowledge__kav(
            BW_Is_Urgent__c =  true,
            BW_FrontLine_Focus__c = true,
            BW_Home_Page_Display__c = true,
            Title = 'Assigned-Test',
            UrlName = 'Assigned-Test',
            ContentSponsor__c = 'ABCD',
            BW_Article_Summary__c = 'askdjfahksjdf askdjfahksjdf askdjfahksjdf askdjfahksjdf askdjfahksjdf askdjfahksjdf askdjfahksjdf askdjfahksjdf'
           
        );
         KM_TestDataFactory.createContentSponsorUser('ABCD');
        insert knowledgeAssigned;
        Knowledge__kav knAssign = [select KnowledgeArticleId from Knowledge__kav where Id = :knowledgeAssigned.Id];
        KbManagement.PublishingService.publishArticle(knAssign.KnowledgeArticleId, true);
        BWKnowledgeArticleLink__c articleLink = new BWKnowledgeArticleLink__c(
             ShareLinkURL__c = 'test URL',
            Knowledge_Article__c  = knowledgeAssigned.Id
        );
        INSERT articleLink;
         
         test.startTest();
         delete articleLink;
         test.stopTest();
         
    }
    
    
   public static testmethod void testUnitTwo(){
        
       Exception caughtException = null;   
       Knowledge__kav  knowledgeAssigned = new Knowledge__kav(
            BW_Is_Urgent__c =  true,
            BW_FrontLine_Focus__c = true,
            BW_Home_Page_Display__c = true,
            Title = 'Assigned-Test',
            UrlName = 'Assigned-Test',
            ContentSponsor__c = 'ABCD',
            BW_Article_Summary__c = 'askdjfahksjdf askdjfahksjdf askdjfahksjdf askdjfahksjdf askdjfahksjdf askdjfahksjdf askdjfahksjdf askdjfahksjdf'
           
        );
       KM_TestDataFactory.createContentSponsorUser('ABCD');
        insert knowledgeAssigned;
        Knowledge__kav knAssign = [select KnowledgeArticleId from Knowledge__kav where Id = :knowledgeAssigned.Id];
        KbManagement.PublishingService.publishArticle(knAssign.KnowledgeArticleId, true);
        BWKnowledgeArticleLink__c articleLink = new BWKnowledgeArticleLink__c(
            ShareLinkURL__c = 'test URL',
            Knowledge_Article__c  = knowledgeAssigned.Id
        );
        INSERT articleLink;
         
       try {		
        	test.startTest();
         delete articleLink;
         test.stopTest();
        } catch (Exception e) {
            caughtException =  e;
        }
      //  System.assertNotEquals(Null, caughtException);
         
    }
    
        
    

}