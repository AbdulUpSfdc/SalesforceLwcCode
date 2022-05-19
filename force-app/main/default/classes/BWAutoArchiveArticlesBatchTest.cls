@isTest
private class BWAutoArchiveArticlesBatchTest {
    @testSetup
    static void testData(){
        List<Knowledge__kav> knowledgeArticles = new List<Knowledge__kav>();
        List<BWKnowledgeArticleLink__c> articleLinks = new List<BWKnowledgeArticleLink__c>();
        String newsArticleRecordTypeId = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByDeveloperName().get('News_Article').getRecordTypeId();
        
        //Create User
        User testUser = KM_TestDataFactory.createContentSponsorUser('rt12345');
        
        //50 articles with Urgent and Frontline flag checked (true)
        for(Integer i=0; i<50; i++){
            Knowledge__kav  ka = new Knowledge__kav(
                RecordTypeId = newsArticleRecordTypeId,
                BW_News_End_Date__c	= System.now().addMinutes(-i),
                BW_Is_Urgent__c =  true,
                BW_FrontLine_Focus__c = true,
                BW_Home_Page_Display__c = false,
                Title = 'Frontline-Test-Article-' + i+1,
                UrlName = 'Frontline-Test-Article-' + i+1,
                ContentSponsor__c = testUser.attuid__c
            );
            knowledgeArticles.add(ka);
        }
        insert knowledgeArticles;

        //publish 40 articles
        for(Knowledge__kav ka : [SELECT Id, KnowledgeArticleId FROM Knowledge__kav LIMIT 40]){
            KbManagement.PublishingService.publishArticle(ka.KnowledgeArticleId, true);
            for(Integer i=0; i<2; i++){
                BWKnowledgeArticleLink__c link = new BWKnowledgeArticleLink__c();
                link.Knowledge_Article__c = ka.Id;
                link.Status__c = 'Published';
                articleLinks.add(link);
            }
        }
        insert articleLinks;
    }

    static testMethod void publishedNewsArticlesTest(){
        BatchSetting__mdt batchSettings = [SELECT BatchQueryFilterCondition__c, BatchSize__c
		                                   FROM BatchSetting__mdt
		                                   WHERE MasterLabel = 'BWAutoArchiveArticlesBatch'];
        Datetime currentTime = System.now();
        Integer numPublishedArticles = [SELECT count() FROM Knowledge__kav WHERE PublishStatus='Online' AND BW_News_End_Date__c<=:currentTime];
        system.debug('Number of Published Articles ::: '+ numPublishedArticles);
        Integer numActiveArticleLinks = [SELECT count() FROM BWKnowledgeArticleLink__c WHERE Status__c<>'Archived'];
        system.debug('Number of Published Articles Links::: '+ numActiveArticleLinks);
        Test.startTest();
        BWAutoArchiveArticlesBatch batch = new BWAutoArchiveArticlesBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        Integer numArchivedArticles = [SELECT count() FROM Knowledge__kav WHERE PublishStatus='Archived'];
        system.debug('Number of Archived Articles ::: '+ numArchivedArticles);
        Integer numArchivedArticleLinks = [SELECT count() FROM BWKnowledgeArticleLink__c WHERE Status__c='Archived'];
        system.debug('Number of Archived Articles Links::: '+ numArchivedArticleLinks);
        System.assertEquals(numPublishedArticles, numArchivedArticles, 'Failed to archive the published articles');
        //System.assertEquals(numActiveArticleLinks, numArchivedArticleLinks, 'Links failed to archive');
    }

    static testMethod void draftNewsArticlesTest(){
        BatchSetting__mdt batchSettings = [SELECT BatchQueryFilterCondition__c, BatchSize__c
		                                   FROM BatchSetting__mdt
		                                   WHERE MasterLabel = 'BWAutoArchiveArticlesBatch'];
        Datetime currentTime = System.now();
        List<Knowledge__kav> updatedDraftArticles = new List<Knowledge__kav>();
        //update News End date of draft articles within the batch job range
        for(Knowledge__kav ka:[SELECT Id, BW_News_End_Date__c FROM Knowledge__kav WHERE PublishStatus='Draft']){
            ka.BW_News_End_Date__c = System.now().addMinutes(-5);
            updatedDraftArticles.add(ka);
        }
        update updatedDraftArticles;

        Integer numDraftArticles = [SELECT count() FROM Knowledge__kav WHERE PublishStatus='Draft' AND BW_News_End_Date__c<=:currentTime];
        Integer numPublishedArticles = [SELECT count() FROM Knowledge__kav WHERE PublishStatus='Online' AND BW_News_End_Date__c<=:currentTime];

        Test.startTest();
        BWAutoArchiveArticlesBatch batch = new BWAutoArchiveArticlesBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        Integer numArchivedArticles = [SELECT count() FROM Knowledge__kav WHERE PublishStatus='Archived'];
        Integer numFinalDraftArticles = [SELECT count() FROM Knowledge__kav WHERE PublishStatus='Draft'];
        System.assertEquals(numPublishedArticles, numArchivedArticles, 'Failed to archive the published articles');
        System.assertEquals(numDraftArticles, numFinalDraftArticles, 'Archived draft articles');
    }

    static testMethod void publishedNonNewsArticlesTest(){
        BatchSetting__mdt batchSettings = [SELECT BatchQueryFilterCondition__c, BatchSize__c
		                                   FROM BatchSetting__mdt
		                                   WHERE MasterLabel = 'BWAutoArchiveArticlesBatch'];
        Datetime currentTime = System.now();
        List<Knowledge__kav> updatedArticles = new List<Knowledge__kav>();
        String nonNewsArticleRecordTypeId = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByDeveloperName().get('BW_Operations_Support').getRecordTypeId();
        //update record type to non news of all articles
        for(Knowledge__kav ka:[SELECT Id, KnowledgeArticleId, RecordTypeId FROM Knowledge__kav WHERE PublishStatus='Draft']){
            ka.RecordTypeId = nonNewsArticleRecordTypeId;
            ka.BW_News_End_Date__c = System.now().addMinutes(-5);
            updatedArticles.add(ka);
        }
        update updatedArticles;
        //publish draft articles
        for(Knowledge__kav ka: updatedArticles){
            KbManagement.PublishingService.publishArticle(ka.KnowledgeArticleId, true);
        }
        Integer numPublishedNonNewsArticles = [SELECT count() FROM Knowledge__kav WHERE PublishStatus='Online' AND BW_News_End_Date__c<=:currentTime AND RecordType.Name <> 'News Article'];
        Integer numPublishedNewsArticles = [SELECT count() FROM Knowledge__kav WHERE PublishStatus='Online' AND BW_News_End_Date__c<=:currentTime AND RecordType.Name = 'News Article'];

        Test.startTest();
        BWAutoArchiveArticlesBatch batch = new BWAutoArchiveArticlesBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        Integer numArchivedArticles = [SELECT count() FROM Knowledge__kav WHERE PublishStatus='Archived'];
        Integer numNonNewsArticlesRemainPublished = [SELECT count() FROM Knowledge__kav WHERE PublishStatus='Online' AND RecordType.Name <> 'News Article'];
        System.assertEquals(numPublishedNewsArticles, numArchivedArticles, 'Published articles were not archived');
        System.assertEquals(numPublishedNonNewsArticles, numNonNewsArticlesRemainPublished, 'Non-news published articles got archived');
    }
}