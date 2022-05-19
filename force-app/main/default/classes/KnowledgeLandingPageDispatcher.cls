public with sharing class KnowledgeLandingPageDispatcher {
    
    @AuraEnabled(cacheable=true)
    public static KnowledgeFrontlineController.ResponseHandler getFrontLineKnowledgeArticles() {
        return KnowledgeFrontlineController.getFrontLineKnowledgeArticles();
    }  
    
    @AuraEnabled(cacheable=true)
    public static KnowledgeFrontlineController.ResponseHandler getAssignedKnowledgeArticles() {
    	 return KnowledgeFrontlineController.getAssignedKnowledgeArticles();
    }  
      
    @AuraEnabled(cacheable=true)
    public static KnowledgeFrontlineController.ResponseHandler getViewAsFrontLineKnowledgeArticles(String channel, String market,  
                                                                String employeeRole, String resourceType,
                                                                String requestSource) {
    	return KnowledgeFrontlineController.getFrontLineKnowledgeArticles(channel, market, employeeRole, resourceType, requestSource);
	}  
    
    @AuraEnabled(cacheable=true)
    public static KnowledgeFrontlineController.ResponseHandler getViewAsAssignedKnowledgeArticles(String channel, String market,  
                                                                String employeeRole, String resourceType,
                                                                String requestSource) {
    	return KnowledgeFrontlineController.getViewAsAssignedKnowledgeArticles(channel, market, employeeRole, resourceType, requestSource);
	} 
    
    @AuraEnabled(cacheable=true)
    public static List<ArticleSearchDataService.ArticleWrapper> getTrendingArticles() {
    	return ArticleSearchDataService.getTrendingArticles();
    }    
    
    @AuraEnabled(cacheable=true)
    public static List<ArticleFilterDataService.ArticleWrapper> getViewAsTrendingArticles(String channel, String market,  
                                                                String employeeRole, String resourceType,
                                                                String requestSource) {
    	return ArticleFilterDataService.getViewAsTrendingArticles(channel, market, employeeRole, resourceType, requestSource);
	} 
    
    @AuraEnabled
    public static KnowledgeFrontlineController.ResponseHandler markArticleRead(String knowledgeId){
        return KnowledgeFrontlineController.markArticleReaded(knowledgeId);
    }
    
    @AuraEnabled
    public static Boolean emptySessionCache() {
        return KnowledgeFrontlineController.emptySessionCache();
    }
  
    
}