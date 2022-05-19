@isTest
public class BWPublicFeedbackThreadCommentTgrHlprTst {
    
    
    //Define testmethod
    @isTest
    static void testData(){
        String newsArticleRecordTypeId = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByDeveloperName().get('News_Article').getRecordTypeId();
        User testUser = KM_TestDataFactory.createContentSponsorUser('rt12345'); 
        List<Knowledge__kav> knowledgeArticles = new List<Knowledge__kav>();
        Knowledge__kav  ka = new Knowledge__kav(
            RecordTypeId = newsArticleRecordTypeId,
            BW_News_End_Date__c	= System.now().addMinutes(-1),
            BW_Is_Urgent__c =  true,
            BW_FrontLine_Focus__c = true,
            BW_Home_Page_Display__c = false,
            Title = 'Frontline-Test-Article-' + 1,
            UrlName = 'Frontline-Test-Article-' + 1,
            ContentSponsor__c = testUser.attuid__c
        );
        insert ka ;
        
        BWPublicFeedbackThread__c feedback = new BWPublicFeedbackThread__c();
        feedback.Knowledge__c = ka.id;
        feedback.Feedback__c = 'test';
        insert feedback;
        
        BWFeedbackThreadComment__c threadComment = new BWFeedbackThreadComment__c();
        threadComment.FeedbackComment__c = 'test 123';
        threadComment.KMPublicFeedbackThread__c = feedback.id;
        insert threadComment;
        //To cover catch block to cover log method 
        //BWPublicFeedbackThreadCommentTgrHelper.sendFeedbackNotifications(null); 
        
    }
    
    
    public static testmethod void testsetDisplayNameValues(){
        Profile p = [Select Id from Profile where Name='System Administrator'];
        User u = new User(ATTUID__c = 'test',
                          username = 'testatt@att.com',
                          Email = 'testatt@att.com',
                          ProfileId = p.Id,
                          LastName = 'att',
                          Alias = 'test',
                          TimeZoneSidKey='America/New_York', 
                          LocaleSidKey='en_US', 
                          EmailEncodingKey='UTF-8', 
                          LanguageLocaleKey='en_US',
                          UserPermissionsKnowledgeUser = True,
                          FederationIdentifier = 'test'
                         );
        
        insert u;
        
        User testUser = KM_TestDataFactory.createContentSponsorUser('rt12345'); 
        
        Employee__c e = new Employee__c( BWDefaultKMChannel__c = '99' ,
                                        EmployeeId__c = 'test',
                                        User__c = u.Id);
        insert e;
        
        
        PermissionSet permset = [ Select Id from PermissionSet where Name='ACC' limit 1];
        String permsetString = String.valueOf(permset.Id);
        
        BW_Channel_Mapping__c channel = new BW_Channel_Mapping__c(KM_Channel_ID__c='99',
                                                                  Permission_Set_Id__c=permsetString);
        insert channel;
        
        List<BW_Channel_Mapping__c> channelMapping = new List<BW_Channel_Mapping__c>();
        channelMapping = [SELECT Permission_Set_Id__c FROM BW_Channel_Mapping__c where KM_Channel_ID__c =:'99' LIMIT 1];
        
        System.RunAs(u){
            System.debug('Employee Record Created:'+e);
            
            System.debug('Channel Record Created:'+channel);
            Knowledge__kav article = new Knowledge__kav(
                Title = 'Test Article for Masking',
                UrlName = 'Test-Article-for-Masking',
                ContentSponsor__c = testUser.attuid__c);
            insert article;
            
            //check if the article was inserted
            Knowledge__kav currentArticleDetail = [
                SELECT ArticleCreatedDate, ArticleNumber
                FROM Knowledge__kav
                WHERE Id = :article.Id];
            
            //System.debug('currentArticleDetail'+currentArticleDetail);
            
            //publish the knowledge article
            KnowledgeArticle knowledgeArticle = [
                SELECT Id
                FROM KnowledgeArticle
                WHERE ArticleNumber = :currentArticleDetail.get('ArticleNumber').toString()];
            
            KbManagement.PublishingService.publishArticle(knowledgeArticle.Id, true);
            
            Knowledge__kav checkStatus = [
                SELECT ArticleCreatedDate, ArticleNumber, PublishStatus, Id, KnowledgeArticleId
                FROM Knowledge__kav
                WHERE Id = :article.Id];
            //System.debug('Article Status: '+checkStatus);
            //Article is online
            
            //Add the logged in user to the SME list
            
            BWKMArticleSME__c SME = new BWKMArticleSME__c(
                Knowledge_Article__c = article.Id,
                Role__c = 'SME',
                User__c = u.Id
            );
            insert SME;
            
            //Create a new thread on the article
            BWPublicFeedbackThread__c thread = new BWPublicFeedbackThread__c(
                Article_Version_Number__c=1,
                DisplayName__c = UserInfo.getFirstName()+' '+UserInfo.getLastName(),
                Feedback__c = 'Test Feedback',
                Knowledge_Parent_Id__c = article.KnowledgeArticleId,
                Knowledge__c = article.Id);
            insert thread;
            
            //Create a new Thread comment on the above thread
            List<BWFeedbackThreadComment__c> comments = new List<BWFeedbackThreadComment__c>();
            BWFeedbackThreadComment__c ThreadComment1 = new BWFeedbackThreadComment__c(
                DisplayName__c = UserInfo.getFirstName()+' '+UserInfo.getLastName(),
                FeedbackComment__c = 'Test Feedback',
                KMPublicFeedbackThread__c = thread.Id);
            comments.add(ThreadComment1);
            BWFeedbackThreadComment__c ThreadComment2 = new BWFeedbackThreadComment__c(
                DisplayName__c = UserInfo.getFirstName()+' '+UserInfo.getLastName(),
                FeedbackComment__c = 'Test Feedback',
                KMPublicFeedbackThread__c = thread.Id);
            comments.add(ThreadComment2);
            insert comments;
        }
    }
    
    
    public static testmethod void elsetestsetDisplayNameValues(){
        User testUser = KM_TestDataFactory.createContentSponsorUser('rt12345'); 

        Profile p = [Select Id from Profile where Name='System Administrator'];
        User u1 = new User(ATTUID__c = 'test',
                           username = 'testatt@att.com',
                           Email = 'testatt@att.com',
                           ProfileId = p.Id,
                           LastName = 'att',
                           Alias = 'test',
                           TimeZoneSidKey='America/New_York', 
                           LocaleSidKey='en_US', 
                           EmailEncodingKey='UTF-8', 
                           LanguageLocaleKey='en_US',
                           UserPermissionsKnowledgeUser = True,
                           FederationIdentifier = 'test'
                          );
        
        insert u1;
        
        
        Employee__c e1 = new Employee__c( BWDefaultKMChannel__c = '99' ,
                                         EmployeeId__c = 'test', 
                                         User__c = u1.Id );
        insert e1;
        
        
        PermissionSet permset = [ Select Id from PermissionSet where Name='ACC' limit 1];
        
        String permsetString = String.valueOf(permset.Id);
        
        
        
        BW_Channel_Mapping__c channel = new BW_Channel_Mapping__c(KM_Channel_ID__c='99',
                                                                  Permission_Set_Id__c=permsetString);
        insert channel;
        
        
        System.RunAs(u1){
            System.debug('Employee Record Created:'+e1);
            
            System.debug('Channel Record Created:'+channel);
            
            Knowledge__kav article = new Knowledge__kav(
                Title = 'Test Article for Masking1',
                UrlName = 'Test-Article-for-Masking1',
                ContentSponsor__c = testUser.attUId__c);
            insert article;
            
            //check if the article was inserted
            Knowledge__kav currentArticleDetail1 = [
                SELECT ArticleCreatedDate, ArticleNumber
                FROM Knowledge__kav
                WHERE Id = :article.Id];
            
            System.debug('currentArticleDetail1::::'+currentArticleDetail1);
            
            
            
            //Create a new thread on the article
            BWPublicFeedbackThread__c thread1 = new BWPublicFeedbackThread__c(
                Article_Version_Number__c=1,
                DisplayName__c = 'ABC',
                Unmasked_Display_Name__c = 'ABC',
                Feedback__c = 'Test Feedback',
                Knowledge_Parent_Id__c = article.KnowledgeArticleId,
                Knowledge__c = article.Id);
            insert thread1;
            
            
            BWFeedbackThreadComment__c ThreadComment1 = new BWFeedbackThreadComment__c(
                DisplayName__c = 'GHI',
                Unmasked_Display_Name__c = 'ABC',
                FeedbackComment__c = 'Test Feedback',
                KMPublicFeedbackThread__c = thread1.Id);
            insert ThreadComment1;
            
            
            
        }
        
    }
    
}