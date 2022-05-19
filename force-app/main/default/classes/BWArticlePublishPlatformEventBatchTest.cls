/**The corresponding batch class has been replaced by other mechanisms for publishing the event. It has been unscheduled 
and deprecated because it was touching articles after publication.*/
@isTest
private class BWArticlePublishPlatformEventBatchTest {}
/*
private class BWArticlePublishPlatformEventBatchTest {
    @testSetup
    static void testData(){
        List<Knowledge__kav> knowledgeArticles = new List<Knowledge__kav>();
        //200 articles with Urgent and Frontline flag checked (true)
        for(Integer i=0; i<200; i++){
            Knowledge__kav  ka = new Knowledge__kav(
            BW_Is_Urgent__c =  true,
            BW_FrontLine_Focus__c = true,
            BW_Home_Page_Display__c = false,
            Title = 'Frontline-Test-Article-' + i+1,
            UrlName = 'Frontline-Test-Article-' + i+1,
            ContentSponsor__c = 'ABCD'
            );
            knowledgeArticles.add(ka);
        }
        insert knowledgeArticles;
    }

    static testMethod void unpublishedArticlesTest(){
        Integer numUnpublishedArticles = [SELECT count() FROM Knowledge__kav WHERE PublishStatus = 'Draft'];
        //All articles should be in draft
        System.assertEquals(200, numUnpublishedArticles);
        Test.startTest();
        BWArticlePublishPlatformEventBatch batch = new BWArticlePublishPlatformEventBatch();
        Id batchId = Database.executeBatch(batch);
        Test.stopTest();
        System.assertEquals(0, BWArticlePublishPlatformEventHelper.numPublishedEvents, 'Platform events got published for unpublished articles');
    }

    static testMethod void publishedArticlesTest(){
        for(Knowledge__kav ka : [SELECT Id, KnowledgeArticleId FROM Knowledge__kav LIMIT 90] ){
            KbManagement.PublishingService.publishArticle(ka.KnowledgeArticleId, true);
        }
        Integer numPublishedArticles = [SELECT count() FROM Knowledge__kav WHERE PublishStatus = 'Online'];
        //90 articles should be online
        System.assertEquals(90, numPublishedArticles);
        Test.startTest();
        BWArticlePublishPlatformEventBatch batch = new BWArticlePublishPlatformEventBatch();
        Id batchId = Database.executeBatch(batch);
        Test.stopTest();
        System.assertEquals(90, BWArticlePublishPlatformEventHelper.numPublishedEvents, 'Platform events were not published for published articles');
    }

    static testMethod void archivedArticlesTest(){
        for(Knowledge__kav ka : [SELECT Id, KnowledgeArticleId FROM Knowledge__kav LIMIT 74] ){
            KbManagement.PublishingService.publishArticle(ka.KnowledgeArticleId, true);
            KbManagement.PublishingService.archiveOnlineArticle(ka.KnowledgeArticleId, null);
        }
        Integer numArchivedArticles = [SELECT count() FROM Knowledge__kav WHERE PublishStatus = 'Archived'];
        //74 articles should be archived
        System.assertEquals(74, numArchivedArticles);
        Test.startTest();
        BWArticlePublishPlatformEventBatch batch = new BWArticlePublishPlatformEventBatch();
        Id batchId = Database.executeBatch(batch);
        Test.stopTest();
        System.assertEquals(74, BWArticlePublishPlatformEventHelper.numPublishedEvents, 'Platform events were not published for archived articles');
    }

    static testMethod void unflagedPublishedArticlesTest(){
        List<Knowledge__kav> updatedArticles = new List<Knowledge__kav>();
        //Set the urgent and frontline flags to false
        for(Knowledge__kav ka : [SELECT Id, KnowledgeArticleId FROM Knowledge__kav LIMIT 90] ){
            ka.BW_Is_Urgent__c = false;
            ka.BW_FrontLine_Focus__c = false;
            updatedArticles.add(ka);
        }
        update updatedArticles;

        for(Knowledge__kav ka : updatedArticles){
            KbManagement.PublishingService.publishArticle(ka.KnowledgeArticleId, true);
        }
        Integer numUnflgPublishedArticles = [SELECT count() FROM Knowledge__kav WHERE PublishStatus = 'Online' AND BW_Is_Urgent__c=false AND BW_FrontLine_Focus__c=false AND BW_Home_Page_Display__c=false];
        //90 articles should be online
        System.assertEquals(90, numUnflgPublishedArticles);
        Test.startTest();
        BWArticlePublishPlatformEventBatch batch = new BWArticlePublishPlatformEventBatch();
        Id batchId = Database.executeBatch(batch);
        Test.stopTest();
        System.assertEquals(90, BWArticlePublishPlatformEventHelper.numPublishedEvents, 'Platform events were not published for non urgent/frontline/assigned articles');
    }

    static testMethod void manuallyPublishPlatformEventTest(){
        Knowledge__kav ka = [SELECT Id, KnowledgeArticleId FROM Knowledge__kav LIMIT 1];
        Test.startTest();
        BWArticlePublishPlatformEventHelper.publishPlatformEvent(ka.Id);
        Test.stopTest();
        System.assertEquals(1, BWArticlePublishPlatformEventHelper.numPublishedEvents, 'Platform event was not published when run manually from UI');
    }
}*/