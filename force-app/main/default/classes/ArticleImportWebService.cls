@RestResource(urlMapping='/ArticleImport/*')
global with sharing class ArticleImportWebService {
    
    public static final Map<String, Id> marketMasterNameMap = new Map<String, Id>();
    
    static {
        List<BWMarketMaster__c> marketList = [SELECT Id, MarketPromotedSearchTerm__c FROM BWMarketMaster__c ORDER BY MarketPromotedSearchTerm__c];
        for (BWMarketMaster__c market : marketList) {
            marketMasterNameMap.put( market.MarketPromotedSearchTerm__c, market.Id);    
        }
    }
    
    @HttpPost
    global static ArticleWebServiceWrapper doPost(ArticleWebServiceWrapper requestWrapper) {
    	return buildResponse(requestWrapper);
    }    
    
    global static ArticleWebServiceWrapper buildResponse(ArticleWebServiceWrapper requestWrapper) {
        ArticleWebServiceWrapper responseWrapper;
        Map<Id, Map<String, List<String>>> knowledgeCategorySelectionMap;
        Map<String, List<String>> articleCategoryMap;
        ArticleDataWrapper relatedArticleWrapper;
        List<String> articleMarketList;
        List<String> dataCategoryNameList;
        List<BWMarketAssociation__c> marketAssociationList = new List<BWMarketAssociation__c>();
        List<Knowledge__kav> knowledgeList = new List<Knowledge__kav>();
        List<Knowledge__datacategorySelection> dataCategoryList = new List<Knowledge__datacategorySelection>();
        Map<Id, Knowledge__kav> knowledgeIdMap;
        List<Id> articleIdList;
        Knowledge__kav clonedKnowledgeArticle;
        Integer articleCounter = 0;
        List<ArticleDataWrapper> articleWrapperList = null;
        
        try {
            articleWrapperList = requestWrapper.articleDataWrapperList;
            
            
            for (ArticleDataWrapper articleWrapper : articleWrapperList) {
                clonedKnowledgeArticle = articleWrapper.knowledgeArticle;
                clonedKnowledgeArticle.RecordTypeId = ArticleDataWrapper.getRecordTypeId(articleWrapper.recordTypeName);
                knowledgeList.add(clonedKnowledgeArticle);
                System.debug('Record type id for ' + articleWrapper.recordTypeName +  ': ' + clonedKnowledgeArticle.RecordTypeId);
            }
            insert knowledgeList;
            knowledgeIdMap = new Map<Id, Knowledge__kav>(knowledgeList);
            articleIdList = new List<Id>(knowledgeIdMap.keySet());
            //refresh the articles to get KnowledgeArticleId
            knowledgeList = [SELECT Id, KnowledgeArticleId FROM Knowledge__kav WHERE Id IN :articleIdList];
            for (Knowledge__kav knowledgeArticle: knowledgeList) {
                
                relatedArticleWrapper = articleWrapperList[articleCounter];
                articleCategoryMap = relatedArticleWrapper.dateCategoryMap;
                articleMarketList = relatedArticleWrapper.marketNameList;
                if (articleCategoryMap != null && !articleCategoryMap.isEmpty()) {
                    for (String datacategorygroupname: articleCategoryMap.keySet()) {
                        dataCategoryNameList = articleCategoryMap.get(datacategorygroupname);
                        if (!dataCategoryNameList.isEmpty()) {
                            for (String datacategoryname : dataCategoryNameList) {
                                dataCategoryList.add(createArticleDataCategory(knowledgeArticle.Id, datacategorygroupname, datacategoryname));    
                            }
                        }    
                    }    
                }
                if (articleMarketList != null && !articleMarketList.isEmpty()) {
                    for (String marketName: articleMarketList) {
                        Id marketId = marketMasterNameMap.get(marketName);
                        if (marketId !=null) {
                        	marketAssociationList.add(createMarketAssociation(knowledgeArticle.Id, marketId));	  
                        }
                    }    
                }
                
                articleCounter++;
                
            }
            
            System.debug('Market association List: ' + marketAssociationList);
            System.debug('Data category List: ' + dataCategoryList);
            insert marketAssociationList;
            insert dataCategoryList;
            responseWrapper = new ArticleWebServiceWrapper();
            responseWrapper.articleQuantity = knowledgeList.size();
            responseWrapper.articleIdList = articleIdList;
            if (responseWrapper.publishArticles == true) {
                for (Knowledge__kav knowledgeArticle: knowledgeList) {
                    KbManagement.PublishingService.publishArticle(knowledgeArticle.KnowledgeArticleId, true);
                }    
            }
            
            /*for (Knowledge__kav knowledgeArticle: knowledgeList) {
				KbManagement.PublishingService.archiveOnlineArticle(knowledgeArticle.KnowledgeArticleId, null);
				KbManagement.PublishingService.deleteArchivedArticle(knowledgeArticle.KnowledgeArticleId);
            }
            */
        } catch (Exception e) {
        	responseWrapper = new ArticleWebServiceWrapper('Error importing articles: ' + KnowledgeUtility.formatExceptionMessage(e));
        }
        
        return responseWrapper;
    }
    
    public static Knowledge__datacategorySelection createArticleDataCategory(Id articleId, String datacategoryGroupName, String dataCategoryName) {
        Knowledge__datacategorySelection articleDataCategory = new Knowledge__datacategorySelection();
        articleDataCategory.parentId = articleId;
        articleDataCategory.datacategoryGroupName = datacategoryGroupName;
        articleDataCategory.dataCategoryName = dataCategoryName;
        return articleDataCategory;
    }
    
    public static BWMarketAssociation__c createMarketAssociation(Id articleId, Id marketId) {
        BWMarketAssociation__c marketAssociation = new BWMarketAssociation__c();    
        marketAssociation.Knowledge__c = articleId;
        marketAssociation.BWMarketMaster__c = marketId;
        return marketAssociation;
    } 
    
 
}