@isTest
public class BWPublicFeedbackEmailNotificationsTest{
	@testSetup
    static void testData(){
        List<Knowledge__kav> knowledgeArticles = new List<Knowledge__kav>();
        List<User> users = new List<User>();
        List<Employee__c> employees = new List<Employee__c>();
        List<BWKMArticleSME__c> experts = new List<BWKMArticleSME__c>();
        List<BWPublicFeedbackThread__c> feedbackThreads= new List<BWPublicFeedbackThread__c>();
        List<BWFeedbackThreadComment__c> feedbackComments = new List<BWFeedbackThreadComment__c>();

        // insert users 
        Profile p = [SELECT Id FROM Profile WHERE Name='Minimum Access Admin'];
        for(Integer i=0; i<2; i++){
            User u =new User(   ATTUID__c = 'Test' + i,
                                FederationIdentifier = 'Test' + i,
                                username = 'testatt' + i + '@att.com',
                                Email = 'testatt@att.com',
                                ProfileId = p.Id,
                                LastName = 'ATT' + i,
                                Alias = 'Test'+i,
                                TimeZoneSidKey='America/New_York', 
                                LocaleSidKey='en_US', 
                                EmailEncodingKey='UTF-8', 
                                LanguageLocaleKey='en_US',
                                UserPermissionsKnowledgeUser = True,
                                IsActive=true
                            );
            users.add(u);
        }
        insert users;

        //insert knowledge articles
        for(Integer i=0; i<10; i++){
            Knowledge__kav  ka = new Knowledge__kav(
                                                    BW_Is_Urgent__c =  true,
                                                    BW_FrontLine_Focus__c = true,
                                                    BW_Home_Page_Display__c = false,
                                                    Title = 'Frontline-Test-Article-' + i+1,
                                                    UrlName = 'Frontline-Test-Article-' + i+1,
                                                    ContentSponsor__c = 'Test1'
                                                    );
            knowledgeArticles.add(ka);
        }
        insert knowledgeArticles;

        for(User user : users){
            Employee__c employee = new Employee__c  (user__c = user.Id,
                                                    BWDefaultKMChannel__c = 'ACC'
                                                    );
            employees.add(employee);
        }
        insert employees;
        
        for(Knowledge__kav ka : [SELECT Id, KnowledgeArticleId FROM Knowledge__kav]){
            //publish articles
            KbManagement.PublishingService.publishArticle(ka.KnowledgeArticleId, true);

            //insert SMEs on articles
            for(User user : users){
                BWKMArticleSME__c expert = new BWKMArticleSME__c(User__c = user.Id,
                                                                Role__c = 'SME',
                                                                Knowledge_Article__c = ka.Id
                                                                );
                experts.add(expert);
            }

            //insert article feedback
            for(Integer i=0; i<5; i++){
                BWPublicFeedbackThread__c feedback = new BWPublicFeedbackThread__c (Feedback__c = 'Test Feedback ' + i,
                                                                                    Knowledge__c = ka.Id 
                                                                                    );
                feedbackThreads.add(feedback);
            }
        }
        insert experts;
        insert feedbackThreads;

        //create feedback thread comments list
        for(BWPublicFeedbackThread__c feedback : feedbackThreads){
            for(Integer i=0; i<2; i++){
                BWFeedbackThreadComment__c comment = new BWFeedbackThreadComment__c(FeedbackComment__c = 'Test Comment '+i, 
                                                                                    KMPublicFeedbackThread__c = feedback.Id
                                                                                    );
                feedbackComments.add(comment);
            }
        }
        insert feedbackComments;
    }

    public static testmethod void testNewFeedbackOrComments(){
        Test.startTest();
        BWPublicFeedbackEmailNotificationsBatch batch = new BWPublicFeedbackEmailNotificationsBatch();
        Id jobId = Database.executeBatch(batch);
        Test.stopTest();
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors 
                            FROM AsyncApexJob 
                            WHERE Id =: jobId ];
        System.assertEquals('Completed', job.Status);
        System.assertEquals(0, job.NumberOfErrors);
    } 
}