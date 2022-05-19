@isTest
public with sharing class KnowledgeUtilityTest {

    public static testMethod void testFormatException(){
       ArticleSearchDataService.LandingPageException lpexception = new ArticleSearchDataService.LandingPageException('Error');
       System.assertNotEquals(null, KnowledgeUtility.formatExceptionMessage(lpexception));
    }
    
     
    public static testMethod void testMaps(){
        Map<String, List<SObject>> listMap = new Map<String, List<SObject>>();
        Map<Id, List<SObject>> listIdMap = new Map<Id, List<SObject>>();
        Knowledge__kav kav = ArticleGenerator.testPublishArticle();
        KnowledgeUtility.addToMapOfLists(listIdMap, kav.Id, kav);
        System.assertEquals(1, listIdMap.size());
        System.assertEquals(1, listIdMap.get(kav.Id).size());
        
        KnowledgeUtility.addToMapOfLists(listMap, 'Test', kav);
        System.assertEquals(1, listMap.size());
        System.assertEquals(1, listMap.get('Test').size());
        
    }
    
    
}