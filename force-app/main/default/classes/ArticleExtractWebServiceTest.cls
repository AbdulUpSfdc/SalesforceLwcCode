@isTest
public with sharing class ArticleExtractWebServiceTest {

    public static testMethod void testExtract(){
        Knowledge__kav kav = ArticleGenerator.testPublishArticle();
        String soqlQuery = 'SELECT Id FROM Knowledge__kav where publishstatus=\'Online\'';
        ArticleWebServiceWrapper wrapper = ArticleExtractWebService.buildWrapper(soqlQuery);
        
    }
    
    public static testMethod void testMaps(){
        Map<String, List<SObject>> listMap = new Map<String, List<SObject>>();
        Knowledge__kav kav = ArticleGenerator.testPublishArticle();
        ArticleExtractWebService.addToMapOfLists(listMap, kav.Id, kav);
        
        Map<Id, List<String>> listIdMap = new Map<Id, List<String>>();
        ArticleExtractWebService.addToMapOfLists(listIdMap, kav.Id, 'Test');

        
    }
    
}