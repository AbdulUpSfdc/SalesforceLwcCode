/*
Description: Batch class to clone markets to the new version of the article.
Status: In Progress
Test Class: Pending
*/

public without sharing class CloneMarkets {
    public static void cloneMarkets(Id ArticleId)
    {
      
        knowledge__kav parentArticle=[Select Id,PublishStatus,UrlName,VersionNumber, KnowledgeArticleId
                                      from knowledge__kav 
                                      where Id=:ArticleId];
        knowledge__kav publishedArticle= [Select Id,PublishStatus,UrlName,VersionNumber, KnowledgeArticleId
                                      from knowledge__kav 
                                      where KnowledgeArticleId=:parentArticle.KnowledgeArticleId AND PublishStatus='Online' 
                                          order by versionnumber desc limit 1]; 
                                                                
        List<BWMarketAssociation__c> lstMarkets=[SELECT BWMarketMaster__c,Id,Knowledge__c 
                                                 FROM BWMarketAssociation__c
                                                 where Knowledge__r.Id =:publishedArticle.Id];
        system.debug('markets');
        system.debug(json.serialize(lstMarkets));
        /*knowledge__kav revisedArticle=[Select Id,PublishStatus,UrlName,VersionNumber 
                                       from knowledge__kav where UrlName=:parentArticle.UrlName 
                                       order by versionnumber desc limit 1];*/
        List<BWMarketAssociation__c> lstCloneMarkets= new List<BWMarketAssociation__c>();
        system.debug(json.serialize(lstMarkets));
        
        lstCloneMarkets = [SELECT BWMarketMaster__c,Id,Knowledge__c 
                                                 FROM BWMarketAssociation__c
                                                 Where Knowledge__r.Id =:parentArticle.Id];
                                                 
        if(lstCloneMarkets.size() == 0){                                  
            for(BWMarketAssociation__c market:lstMarkets)
            {
                BWMarketAssociation__c clonemarket= new BWMarketAssociation__c();
                clonemarket.BWMarketMaster__c=market.BWMarketMaster__c;
                clonemarket.Knowledge__c=ArticleId;
                lstCloneMarkets.add(clonemarket);
            }
           
            system.debug(json.serialize(lstCloneMarkets));
            try{
                database.insert(lstCloneMarkets);
            }catch(System.Exception e){
                    system.debug('CloneMarkets:'+e);
                    // Log the exception
                    BWC_ExceptionUtils.handleException(e, true);
                } 
           }
           else{
           /*System Notification*/
              //new attException('This article already has Markets assigned to it.');
              System.debug('This article already has Markets assigned to it.');
           }
    }
}