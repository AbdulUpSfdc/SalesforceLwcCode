/**********
        Name            : ArticleNotificationBatchTest
        Description     : This is the test class for the ArticleNotificationBatch
**********/

@isTest
public class ArticleNotificationBatchTest{
    
    @testSetup
    public static void testData(){
        Knowledge__kav  knowledgeFrontline = new Knowledge__kav(
            BW_Is_Urgent__c =  true,
            BW_FrontLine_Focus__c = true,
            Title = 'Frontline-Test',
            UrlName = 'Frontline-Test',
            ContentSponsor__c = 'ABCD'
        );
        KM_TestDataFactory.createContentSponsorUser('ABCD');
        insert knowledgeFrontline;
        Knowledge__kav knFrnt = [SELECT KnowledgeArticleId FROM Knowledge__kav where Id = :knowledgeFrontline.Id];
        KbManagement.PublishingService.publishArticle(knFrnt.KnowledgeArticleId, true);
        
        Knowledge__kav  knowledgeAssigned = new Knowledge__kav(
            BW_Is_Urgent__c =  true,
            BW_FrontLine_Focus__c = true,
            BW_Home_Page_Display__c = true,
            Title = 'Assigned-Test',
            UrlName = 'Assigned-Test',
            ContentSponsor__c = 'ABCD',
            BW_Article_Summary__c = 'askdjfahksjdf askdjfahksjdf askdjfahksjdf askdjfahksjdf askdjfahksjdf askdjfahksjdf askdjfahksjdf askdjfahksjdf',
            RecordTypeId = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByDeveloperName().get('News_Article').getRecordTypeId()
        );
        KM_TestDataFactory.createContentSponsorUser('ABCD');
        insert knowledgeAssigned;
        Knowledge__kav knAssign = [select KnowledgeArticleId from Knowledge__kav where Id = :knowledgeAssigned.Id];
        KbManagement.PublishingService.publishArticle(knAssign.KnowledgeArticleId, true);
        
        BW_KM_Lifecycle_Helper__c KMhelper = new BW_KM_Lifecycle_Helper__c(
        BW_Knowledge__c=knowledgeAssigned.id,
        BW_Urgent_NoticationSent__c = false);
            insert KMhelper;
        
            
            
        KM_Article_Feedback__c feedback = new KM_Article_Feedback__c(
            knowledge__c = knowledgeAssigned.Id
        );
        INSERT feedback;
    }
    
    public static testMethod void testUnit(){
        test.startTest();
        Database.executeBatch(new ArticleNotificationBatch(), 1);
        test.stopTest();
    }
}