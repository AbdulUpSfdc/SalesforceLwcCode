@isTest
public class PublicFeedbackControllerTest {
    @testsetup
    public static void testData(){
        Knowledge__kav knowledgekav = KM_TestDataFactory.getKnowledKav(system.today(),'test','testurl',true, 'ABC');
    }
    
    public static testMethod void testUnitOne(){
        String searchString = '';
        String searchString2 = 'Test';
        
        Knowledge__kav knowledge = [
            SELECT id, KnowledgeArticleId 
            FROM Knowledge__kav 
            WHERE Title = 'test'
            LIMIT 1
        ];
        
        //Add the logged in user to the SME list
        BWKMArticleSME__c SME = new BWKMArticleSME__c(
            Knowledge_Article__c = knowledge.Id,
            Role__c = 'SME',
            User__c = UserInfo.getUserId()
        );
        insert SME;
        
        //Create a new thread on the article
        BWPublicFeedbackThread__c thread = new BWPublicFeedbackThread__c(
            Article_Version_Number__c=1,
            DisplayName__c = 'Expert',//UserInfo.getFirstName()+' '+UserInfo.getLastName(),
            Feedback__c = 'Test Feedback',
            Knowledge_Parent_Id__c = knowledge.KnowledgeArticleId,
            Knowledge__c = knowledge.Id);
        insert thread;
        
        //Create a new Thread comment on the above thread
        BWFeedbackThreadComment__c ThreadComment = new BWFeedbackThreadComment__c(
            DisplayName__c = 'Expert',//UserInfo.getFirstName()+' '+UserInfo.getLastName(),
            FeedbackComment__c = 'Test Feedback',
             Is_Deleted__c = true,
            KMPublicFeedbackThread__c = thread.Id);
        insert ThreadComment;
        
        PublicFeedbackController.getFeedbackThread(searchString,knowledge.Id);
    }
    
    public static testMethod void testIsFeedbackVisible(){
       Boolean isVisible = PublicFeedbackController.isFeedbackVisible();
        System.assertEquals(isVisible,false);
    }
    
     public static testMethod void testUnitTwo(){
         
        String searchString = '';
         Knowledge__kav knowledge = [
            SELECT id, KnowledgeArticleId 
            FROM Knowledge__kav 
            WHERE Title = 'test'
            LIMIT 1
        ];
        //Add the logged in user to the SME list
        BWKMArticleSME__c SME = new BWKMArticleSME__c(
            Knowledge_Article__c = knowledge.Id,
            Role__c = 'SME',
            User__c = UserInfo.getUserId()
        );
        insert SME;
        //Create a new thread on the article
        BWPublicFeedbackThread__c thread = new BWPublicFeedbackThread__c(
            Article_Version_Number__c=1,
            DisplayName__c = 'Expert',//UserInfo.getFirstName()+' '+UserInfo.getLastName(),
            Feedback__c = 'Test Feedback',
            Is_Deleted__c = true,
            Knowledge_Parent_Id__c = knowledge.KnowledgeArticleId,
            Knowledge__c = knowledge.Id);
        insert thread;
        
        PublicFeedbackController.getFeedbackThread(searchString,knowledge.Id);
    }
    
    public static testMethod void testUnitThree(){       
        String searchString2 = 'Test';
         Knowledge__kav knowledge = [
            SELECT id, KnowledgeArticleId 
            FROM Knowledge__kav 
            WHERE Title = 'test'
            LIMIT 1
        ];
        //Add the logged in user to the SME list
        BWKMArticleSME__c SME = new BWKMArticleSME__c(
            Knowledge_Article__c = knowledge.Id,
            Role__c = 'SME',
            User__c = UserInfo.getUserId()
        );
        insert SME;
        //Create a new thread on the article
        BWPublicFeedbackThread__c thread = new BWPublicFeedbackThread__c(
            Article_Version_Number__c=1,
            DisplayName__c = 'Expert',//UserInfo.getFirstName()+' '+UserInfo.getLastName(),
            Feedback__c = 'Test Feedback',
            Knowledge_Parent_Id__c = knowledge.KnowledgeArticleId,
            Knowledge__c = knowledge.Id);
        insert thread;
        
        //Create a new Thread comment on the above thread
        BWFeedbackThreadComment__c ThreadComment = new BWFeedbackThreadComment__c(
            DisplayName__c = 'Expert',//UserInfo.getFirstName()+' '+UserInfo.getLastName(),
            FeedbackComment__c = 'Test Feedback',
            Is_Deleted__c = true,
            KMPublicFeedbackThread__c = thread.Id);
        insert ThreadComment;
        
        PublicFeedbackController.getFeedbackThread(searchString2,knowledge.Id);
    }
    
    public static testMethod void testUnitFour(){
        
       
        String searchString2 = 'Test';
         Knowledge__kav knowledge = [
            SELECT id, KnowledgeArticleId 
            FROM Knowledge__kav 
            WHERE Title = 'test'
            LIMIT 1
        ];
        //Add the logged in user to the SME list
        BWKMArticleSME__c SME = new BWKMArticleSME__c(
            Knowledge_Article__c = knowledge.Id,
            Role__c = 'SME',
            User__c = UserInfo.getUserId()
        );
        insert SME;
        //Create a new thread on the article
        BWPublicFeedbackThread__c thread = new BWPublicFeedbackThread__c(
            Article_Version_Number__c=1,
            DisplayName__c = 'Expert',//UserInfo.getFirstName()+' '+UserInfo.getLastName(),
            Feedback__c = 'Test Feedback',
            Is_Deleted__c = true,
            Knowledge_Parent_Id__c = knowledge.KnowledgeArticleId,
            Knowledge__c = knowledge.Id);
        insert thread;
        
        //Create a new Thread comment on the above thread
       /* BWFeedbackThreadComment__c ThreadComment = new BWFeedbackThreadComment__c(
            DisplayName__c = 'Expert',//UserInfo.getFirstName()+' '+UserInfo.getLastName(),
            FeedbackComment__c = 'Test Feedback',
            Is_Deleted__c = true,
            KMPublicFeedbackThread__c = thread.Id);
        insert ThreadComment;*/
        
        PublicFeedbackController.getFeedbackThread(searchString2,knowledge.Id);
    }
    
     public static testMethod void testUnitFive(){
        
       
        String searchString = '';
         Knowledge__kav knowledge = [
            SELECT id, KnowledgeArticleId 
            FROM Knowledge__kav 
            WHERE Title = 'test'
            LIMIT 1
        ];
        //Add the logged in user to the SME list
        BWKMArticleSME__c SME = new BWKMArticleSME__c(
            Knowledge_Article__c = knowledge.Id,
            Role__c = 'SME',
            User__c = UserInfo.getUserId()
        );
        insert SME;
        //Create a new thread on the article
        BWPublicFeedbackThread__c thread = new BWPublicFeedbackThread__c(
            Article_Version_Number__c=1,
            DisplayName__c = 'Expert',//UserInfo.getFirstName()+' '+UserInfo.getLastName(),
            Feedback__c = 'Test Feedback',
            Is_Deleted__c = false,
            Knowledge_Parent_Id__c = knowledge.KnowledgeArticleId,
            Knowledge__c = knowledge.Id);
        insert thread;
        
        //Create a new Thread comment on the above thread
        BWFeedbackThreadComment__c ThreadComment = new BWFeedbackThreadComment__c(
            DisplayName__c = 'Expert',//UserInfo.getFirstName()+' '+UserInfo.getLastName(),
            FeedbackComment__c = 'Test Feedback',
            Is_Deleted__c = false,
            KMPublicFeedbackThread__c = thread.Id);
        insert ThreadComment;
        
        PublicFeedbackController.getFeedbackThread(searchString,knowledge.Id);
    }
    
     public static testMethod void testUnitSix(){
        
       
        String searchString2 = 'Test';
         Knowledge__kav knowledge = [
            SELECT id, KnowledgeArticleId 
            FROM Knowledge__kav 
            WHERE Title = 'test'
            LIMIT 1
        ];
        //Add the logged in user to the SME list
        BWKMArticleSME__c SME = new BWKMArticleSME__c(
            Knowledge_Article__c = knowledge.Id,
            Role__c = 'SME',
            User__c = UserInfo.getUserId()
        );
        insert SME;
        //Create a new thread on the article
        BWPublicFeedbackThread__c thread = new BWPublicFeedbackThread__c(
            Article_Version_Number__c=1,
            DisplayName__c = 'Expert',//UserInfo.getFirstName()+' '+UserInfo.getLastName(),
            Feedback__c = 'Test Feedback',
            Is_Deleted__c = false,
            Knowledge_Parent_Id__c = knowledge.KnowledgeArticleId,
            Knowledge__c = knowledge.Id);
        insert thread;
        
        //Create a new Thread comment on the above thread
        BWFeedbackThreadComment__c ThreadComment = new BWFeedbackThreadComment__c(
            DisplayName__c = 'Expert',//UserInfo.getFirstName()+' '+UserInfo.getLastName(),
            FeedbackComment__c = 'Test Feedback',
            Is_Deleted__c = false,
            KMPublicFeedbackThread__c = thread.Id);
        insert ThreadComment;
        
        PublicFeedbackController.getFeedbackThread(searchString2,knowledge.Id);
    }
     
      
   


}