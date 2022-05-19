/*************
    Name            : ArticleFeedbackControllerTest
    Controller      : This is the test class for the ArticleFeedbackController.
*************/

@isTest
public class ArticleFeedbackControllerTest {
    
    @testsetup
    public static void testData(){
        Knowledge__kav knowledgekav = KM_TestDataFactory.getKnowledKav(system.today(),'test','testurl',true, 'ABC');
        
        //Get RecordTypeId.
        Id newsArticleRecordTypeId = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByDeveloperName().get('News_Article').getRecordTypeId();  
        //Create Record for RecordTypeName 'News Article'.
        Knowledge__kav knowledge = KM_TestDataFactory.getKnowledKavTest(
            newsArticleRecordTypeId, 
            System.Now().AddDays(5), 
            'testone', 
            'testing', 
            true,
            'ABC'
        );
        Knowledge__kav knowledge_fontline = KM_TestDataFactory.getKnowledKavfronlinefocus(
            newsArticleRecordTypeId ,
            System.Now().AddDays(5),
            'testonefontline',
            'testingfontline',
            true,
            'ABC'
        );       
    }
    
    public static testMethod void testUnitOne(){
        //Get RecordTypeId.
        Id newsArticleRecordTypeId = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByDeveloperName().get('News_Article').getRecordTypeId();
        Knowledge__kav knowledge = [
            SELECT id, KnowledgeArticleId 
            FROM Knowledge__kav 
            WHERE RECORDTYPEID = :newsArticleRecordTypeId 
            LIMIT 1
        ];
        KM_Article_Feedback__c articleFeedback = new KM_Article_Feedback__c(
            Feedback_Status__c = 'Replied',
            Feedback_Response__c = 'Improvement',
            Knowledge__c = knowledge.Id
        );
        INSERT articleFeedback; 
        ArticleFeedbackController.getArticleFeedbacks(knowledge.KnowledgeArticleId);
    }
    
    public static testMethod void testUnitTwo(){
        
         ArticleFeedbackController.getArticleFeedbacks(NULL);
        ArticleFeedbackController.ResponseHandler obj = new ArticleFeedbackController.ResponseHandler('Test');
    }

}