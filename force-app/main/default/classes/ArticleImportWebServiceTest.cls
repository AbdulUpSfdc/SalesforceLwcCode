@isTest
public with sharing class ArticleImportWebServiceTest {

    public static testMethod void testImport(){
       
        ArticleWebServiceWrapper responseWrapper;
        ArticleWebServiceWrapper requestWrapper = new ArticleWebServiceWrapper();
        requestWrapper.publishArticles = true;
        requestWrapper.extractSandboxName = 'PERF3';
        requestWrapper.articleQuantity = 0;
        requestWrapper.articleIdlist = null;
        
        responseWrapper = ArticleImportWebService.doPost(requestWrapper);
        Id marketId;
        Id articleId;
        ArticleImportWebService.createMarketAssociation(articleId, marketId);
        String datacategoryGroupName = 'Channel';
        String dataCategoryName = 'OOC';
        ArticleImportWebService.createArticleDataCategory(articleId, datacategoryGroupName, dataCategoryName);   
    }
    
}