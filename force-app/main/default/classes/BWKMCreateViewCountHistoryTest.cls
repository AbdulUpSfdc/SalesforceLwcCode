@isTest 
public class BWKMCreateViewCountHistoryTest {
    @TestSetup
    public static void testData(){
        List<Knowledge__kav> knowledgeArticles = new List<Knowledge__kav>();
        List<User> users = new List<User>();
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
        
        for(Knowledge__kav ka : [SELECT Id, KnowledgeArticleId FROM Knowledge__kav]){
            KbManagement.PublishingService.publishArticle(ka.KnowledgeArticleId, true);
        }
    }
    
    public static testMethod void createViewCountRecordsTest () {
        Test.startTest();
        BWKMCreateViewCountHistoryBatch batch = new BWKMCreateViewCountHistoryBatch();
        Id jobId = Database.executeBatch(batch);
        Test.stopTest();
        
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors FROM AsyncApexJob WHERE Id =: jobId ];
        List<Knowledge_View_Count_History__c> viewCountRecords= [SELECT Id FROM Knowledge_View_Count_History__c];
        List<Knowledge__kav> articles = [SELECT Id, KnowledgeArticleId FROM Knowledge__kav];
        
        System.assertEquals('Completed', job.Status);
        System.assertEquals(0, job.NumberOfErrors);
        System.assertEquals(viewCountRecords.size(), articles.size());
    }
    
    public static testMethod void createViewCountRecordsWithDateInputTest () {
        Test.startTest();
        BWKMCreateViewCountHistoryBatch batch = new BWKMCreateViewCountHistoryBatch('10142021');
        Id jobId = Database.executeBatch(batch);
        Test.stopTest();
        
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors FROM AsyncApexJob WHERE Id =: jobId ];
        List<Knowledge_View_Count_History__c> viewCountRecords= [SELECT Id FROM Knowledge_View_Count_History__c WHERE Unique_Id__c LIKE '10142021%'];
        List<Knowledge__kav> articles = [SELECT Id, KnowledgeArticleId FROM Knowledge__kav];
        
        System.assertEquals('Completed', job.Status);
        System.assertEquals(0, job.NumberOfErrors);
        System.assertEquals(viewCountRecords.size(), articles.size());
    }
    
    public static testMethod void scheduleBatchTest() {
        Test.startTest();
        Id jobId = BWKMCreateViewCountHistoryBatchScheduler.schedule();
        Test.stopTest();

        // Get the information from the CronTrigger API object
        CronTrigger ct=[SELECT Id, CronExpression, TimesTriggered, NextFireTime
                        FROM CronTrigger 
                        WHERE id = :jobId];
        BWKMCreateViewCountHistoryBatch batch = new BWKMCreateViewCountHistoryBatch();
        batch.makeLog(String.valueOf(jobId), 'test');

        System.assertEquals(batch.CRON_EXPR, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
    }

    public static testMethod void skipBatchTest(){
        BWKMCreateViewCountHistoryBatch batch = new BWKMCreateViewCountHistoryBatch();
        batch.STOP_CREATE_VIEW_COUNT_BATCH_RUN = true;
        
        Test.startTest();
        Id jobId = Database.executeBatch(batch);
        Test.stopTest();
        
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors FROM AsyncApexJob WHERE Id =: jobId ];
        List<Knowledge_View_Count_History__c> viewCountRecords= [SELECT Id FROM Knowledge_View_Count_History__c];
        List<Knowledge__kav> articles = [SELECT Id, KnowledgeArticleId FROM Knowledge__kav];
        
        System.assertEquals('Completed', job.Status);
        System.assertEquals(0, job.NumberOfErrors);
    }
    
}