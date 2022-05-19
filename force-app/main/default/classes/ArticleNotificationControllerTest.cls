/*******
Name            : ArticleNotificationControllerTest
Description     : This is the test class for ArticleNotificationController
*******/

@isTest
public with sharing class ArticleNotificationControllerTest {
    @testSetup
    private static void testSetup(){
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
        insert knowledgeAssigned;
        Knowledge__kav knAssign = [select KnowledgeArticleId from Knowledge__kav where Id = :knowledgeAssigned.Id];
        KbManagement.PublishingService.publishArticle(knAssign.KnowledgeArticleId, true);
        
        KM_Article_Feedback__c feedback = new KM_Article_Feedback__c(
            knowledge__c = knowledgeAssigned.Id
        );
        INSERT feedback;
        
        //Notification task
        Task tk = new Task(
            Subject = 'Test Subject',
            status = 'New'
        );
        INSERT tk;
    }
    
    public static testMethod void testUnit(){
        test.startTest();
        Database.executeBatch(new ArticleNotificationBatch(), 1);
        test.stopTest();
        Task tk = [Select Id,Subject,Status,OwnerId,WhatId From Task LIMIT 1];
        /* [START] 05/02/2021 - US# 5564 - Commenting the code as notification feature is not in use currently. Additionally, it will increase the code coverage 
        ArticleNotificationController.markTaskCompleted(tk.Id);
        ArticleNotificationController.getRelatedTask();
        [END]*/
    }
    public static testMethod void testUnitOne(){
        /* [START] 05/02/2021 - US# 5564 - Commenting the code as notification feature is not in use currently. Additionally, it will increase the code coverage 
        ArticleNotificationController.markTaskCompleted('test');
        ArticleNotificationController.getRelatedTask();
        [END] */
    }
}