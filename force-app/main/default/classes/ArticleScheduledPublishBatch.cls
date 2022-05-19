/********
Name         : ArticleScheduledPublishBatch 
Description  : Batch class to publish articles with a scheduled publish time in the next fifteen minutes.
****/


public without sharing class ArticleScheduledPublishBatch implements Database.Batchable<sObject>, Database.Stateful{
    
    public ArticleScheduledPublishBatch(){
        
       
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        DateTime nextFifteenMinutes = System.Now().addMinutes(15); // not doing 15 minutes back since handled by scheduler
        DateTime currentTime = System.Now();
        if (Test.isRunningTest()) {
         	currentTime = System.Now().addMinutes(15);   
        }
        return Database.getQueryLocator([SELECT Id, ArticleNumber, KnowledgeArticleId FROM Knowledge__kav WHERE PublishStatus = 
                                         'Draft' and BWScheduledArticlePublicationDate__c <= :currentTime
                                         and CustomValidationStatus__c = TRUE
                                         and CustomPublicationStatus__c = 'Ready for Publication'
                                        ]);
    }
    
    public void execute(Database.BatchableContext BC, List<Sobject> scope){
        System.debug('Number of scheduled draft articles located: ' + scope.size());
        Integer numPublishedArticles= 0; 
        Integer numExceptions = 0;
        numExceptions = 0;
        for(Sobject ka: scope){
            Knowledge__kav article = (Knowledge__kav) ka;
            try {
                System.debug('Publishing article: ' + article.ArticleNumber + 
                           '; knowledge article id: ' + article.KnowledgeArticleId);
                KbManagement.PublishingService.publishArticle(article.KnowledgeArticleId, true);
                numPublishedArticles++;
            } catch(System.Exception e){
                System.debug('Exception Publishing article: ' + article.ArticleNumber + ': ' + e);
                BWC_ExceptionUtils.handleException(e, true);
                numExceptions++;
            }    
        }
       System.debug('@@## Number of articles Published ' + numPublishedArticles + '; Exceptions: ' + numExceptions);

    }
    
    public void finish(Database.BatchableContext BC){
        System.debug('@@## Finished Publishing scheduled articles ');
        
    }
    
}