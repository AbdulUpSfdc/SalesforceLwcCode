@RestResource(urlMapping='/ArticleExtract/*')

global with sharing class ArticleExtractWebService {
 
     @HttpPost
    global static ArticleWebServiceWrapper doPost(String soqlString) {
     	return  buildWrapper(soqlString);
    }

    global static ArticleWebServiceWrapper buildWrapper(String soqlString) {
        
        ArticleWebServiceWrapper responseWrapper = new ArticleWebServiceWrapper();
        Map<Id, Map<String, List<String>>> knowledgeCategorySelectionMap;
        Map<String, List<String>> articleCategoryMap;
        List<ArticleDataWrapper> articleWrapperList = new List<ArticleDataWrapper>();
   		Knowledge__kav clonedKnowledgeArticle;
        ArticleDataWrapper articleWrapper;
        List<Knowledge__kav> knowledgeList;
        Map<Id, Knowledge__kav> knowledgeMap;
        List<Id> articleIdList;   
        List<BWMarketAssociation__c> marketAssociationList;
        Map<Id, List<String>> associatedMarketMap;
        List<Knowledge__datacategorySelection> dataCategoryList;
        List<String> articleMarketList;
        
        try {
            knowledgeList = Database.query(soqlString);
            knowledgeMap = new Map<Id, Knowledge__kav>(knowledgeList);
            articleIdList = new List<Id>(knowledgeMap.keySet());   
            marketAssociationList = getAssociatedMarketList(articleIdList);
            associatedMarketMap = getAssociatedMarketMap(marketAssociationList);
            dataCategoryList = getDataCategories(articleIdList);
            knowledgeCategorySelectionMap = getCategorySelectionMap(dataCategoryList);
            
            for (Knowledge__kav knowledgeArticle: knowledgeList) {
                clonedKnowledgeArticle = knowledgeArticle.clone();
                articleCategoryMap =  knowledgeCategorySelectionMap.get(knowledgeArticle.Id);
                if (articleCategoryMap  == null) {
                    articleCategoryMap = new Map<String, List<String>>();  
                }
                articleMarketList = associatedMarketMap.get(knowledgeArticle.Id);
                articleWrapper = new ArticleDataWrapper(clonedKnowledgeArticle, articleCategoryMap, articleMarketList);
                articleWrapperList.add(articleWrapper);
              
                
                
            }
            responseWrapper.articleDataWrapperList = articleWrapperList;
            responseWrapper.articleIdList = articleIdList;
            responseWrapper.extractSandboxName = '.' + UserInfo.getUserName().substringAfterLast('.').toLowerCase();
            responseWrapper.articleQuantity = articleWrapperList.size();
    	} catch (Exception e) {
        	responseWrapper = new ArticleWebServiceWrapper('Error exporting articles: ' + KnowledgeUtility.formatExceptionMessage(e));
            responseWrapper.extractSandboxName = '.' + UserInfo.getUserName().substringAfterLast('.').toLowerCase();
            return responseWrapper;

        }
        
        return responseWrapper;
    }
       
  
    public static Map<Id, Map<String, List<String>>> getCategorySelectionMap(List<Knowledge__datacategorySelection> categorySelectionList) {
        Map<Id, Map<String, List<String>>> catSelectionMap = new Map<Id, Map<String, List<String>>>();
        for (Knowledge__datacategorySelection catSelection : categorySelectionList) {
            addToMapOfMaps(catSelectionMap, catSelection.parentId, catSelection.datacategorygroupname, catSelection.datacategoryname);
        }
        return catSelectionMap;
    }
    
    public static List<Knowledge__datacategorySelection> getDataCategories(List<Id> articleIdList) {
        return [SELECT datacategorygroupname, datacategoryname, parentid FROM Knowledge__datacategorySelection
                WHERE parentId IN :articleIdList ORDER by parentId];
    }    
    
    public static void addToMapOfMaps(Map<Id, Map<String, List<String>>> outerMap, Id outerKey, String innerkey, String innerValue){
        Map<String, List<String>> innerMap = outerMap.get(outerKey);
        if (innerMap == null) {
            innerMap = new Map<String, List<String>>();
        }
        addToMapOfLists(innerMap, innerKey, innerValue);
        
        outerMap.put(outerKey, innerMap);
    }
    
    public static void addToMapOfLists(Map<Id, List<String>> listMap, Id key, String stringValue) {
        List<String> stringList = listMap.get(key);
        if(stringList == null){
            stringList = new List<String>();
        }
        stringList.add(stringValue);
        listMap.put(key, stringList);
    }
    
    public static void addToMapOfLists(Map<String, List<String>> listMap, String key, String stringValue) {
        List<String> stringList = listMap.get(key);
        if(stringList == null){
            stringList = new List<String>();
        }
        stringList.add(stringValue);
        listMap.put(key, stringList);
    }
    
    public static void addToMapOfLists(Map<String, List<SObject>> listMap, String key, SObject sobj) {
        List<SObject> sobjList = listMap.get(key);
        if(sobjList == null){
            sobjList = new List<SObject>();
        }
        sobjList.add(sobj);
        listMap.put(key, sobjList);
    }
     
    public static Map<Id, List<String>> getAssociatedMarketMap(List<BWMarketAssociation__c> marketAssociationList) {
     	Map<Id, List<String>> associatedMarketMap = new Map<Id, List<String>>();
        for (BWMarketAssociation__c marketAssociation :  marketAssociationList) {
       		addToMapOfLists(associatedMarketMap, marketAssociation.Knowledge__c, marketAssociation.BWMarketMaster__r.MarketPromotedSearchTerm__c);  
        }
        return associatedMarketMap;
    }
    
    public static List<BWMarketAssociation__c> getAssociatedMarketList(List<Id> articleIdList) {
 	   return [SELECT Id, Knowledge__c, BWMarketMaster__r.MarketPromotedSearchTerm__c FROM BWMarketAssociation__c WHERE Knowledge__c IN :articleIdList];
    }
    
   
}