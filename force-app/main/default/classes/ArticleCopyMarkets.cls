@RestResource(urlMapping='/ArticleCopyMarkets/*')
global with sharing class ArticleCopyMarkets {
    @HttpPost
    global Static void doPost(String ArticleId) {
    String Status;
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
                Status='Success';
            }catch(System.Exception e){
                    system.debug('CloneMarkets:'+e);
                    // Log the exception
                    BWC_ExceptionUtils.handleException(e, true);
                    Status=e.getMessage();
                } 
           }
           else{
           /*System Notification*/
              //new attException('This article already has Markets assigned to it.');
              System.debug('This article already has Markets assigned to it.');
              Status='This article already has Markets assigned to it.';
           }
           Map<String, String> obj = new Map<String, String>();
           obj.put('Status', Status);
           RestContext.response.addHeader('Content-Type', 'application/json');
           RestContext.response.responseBody = Blob.valueOf(JSON.Serialize(obj));
}
}