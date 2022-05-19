@isTest
public without sharing class ArticleScheduledPublishBatchTest {
    
    public static testMethod void testBatch(){
        Knowledge__kav  knowledgeNoScheduledDate = new Knowledge__kav(
            BW_Is_Urgent__c =  false,
            BW_FrontLine_Focus__c = true,
            Title = 'Frontline-Test-fromline',
            UrlName = 'Frontline-No-Scheduled-Date',
            CustomValidationStatus__c = TRUE,
            CustomPublicationStatus__c = 'Ready for Publication',
            ContentSponsor__c = 'ABCD'
        );
        KM_TestDataFactory.createContentSponsorUser('ABCD');
        insert knowledgeNoScheduledDate;
        
        Knowledge__kav  knowledgeGoodScheduledDate = new Knowledge__kav(
            BW_Is_Urgent__c =  false,
            BW_FrontLine_Focus__c = true,
            Title = 'Frontline-Test-fromline',
            UrlName = 'Frontline-Good-Scheduled-Date',
            ContentSponsor__c = 'ABCD',
             CustomValidationStatus__c = TRUE,
            CustomPublicationStatus__c = 'Ready for Publication',
            BWScheduledArticlePublicationDate__c = System.Now().addMinutes(1)
        );
        insert knowledgeGoodScheduledDate;
        System.assertEquals(0, getExistingArticles('Online').size());
        System.assertEquals(2, getExistingArticles('Draft').size());
        
        test.startTest();
        Database.executeBatch(new ArticleScheduledPublishBatch(), 200);
        test.stopTest();
        System.assertEquals(1, getExistingArticles('Online').size());
        System.assertEquals(1, getExistingArticles('Draft').size());
        
        
    }
    
    public static  List<Knowledge__kav> getExistingArticles(String publishStatus) {
        List<Knowledge__kav> existingPublishedArticles = 
            [SELECT Id, versionnumber,CustomPublicationStatus__c,CustomValidationStatus__c, createddate, ArticleNumber, publishstatus, KnowledgeArticleId, 
             BWScheduledArticlePublicationDate__c FROM Knowledge__kav WHERE publishstatus = :publishStatus];
        return existingPublishedArticles;
        
    }
}