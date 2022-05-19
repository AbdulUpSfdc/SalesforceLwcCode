/**********
    
    Name            : KnowledgeArticleFollowUpdateTest
    Description     : This is the test class for KnowledgeArticleFollowUpdate.
    
***********/

@isTest
public class KnowledgeArticleFollowUpdateTest{
    
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
            false,
            'ABC'
        );
        knowledge.ContentSponsor__c = 'ABC';
        INSERT knowledge;
         
        KM_Article_Feedback__c articleFeedback = new KM_Article_Feedback__c(
            Feedback_Status__c = 'Replied',
            Feedback_Response__c = 'Improvement',
            Knowledge__c = knowledge.Id
        );
        INSERT articleFeedback;
        
        KM_Article_Feedback__c articleFeedback1 = new KM_Article_Feedback__c(
            Feedback_Status__c = 'Replied',
            Feedback_Response__c = 'Improvement',
            Knowledge__c = knowledge.Id
        );
        INSERT articleFeedback1;
        
        KM_Article_Feedback__c articleFeedback2 = new KM_Article_Feedback__c(
            Feedback_Status__c = 'Replied',
            Feedback_Response__c = 'Improvement',
            Knowledge__c = knowledge.Id
        );
        INSERT articleFeedback2;
    }
    
    public static testmethod void testunitone(){
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User']; 
        User u = new User(Alias = 'standt', Email='standarduser112@testorg.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='standarduser112@testorg.com',
        ATTUID__c = 'ABC');
        INSERT u;
        
        KnowledgeArticleFollowUpdate obj = new KnowledgeArticleFollowUpdate();
        obj.createEntitySubscription();
    }
    
}