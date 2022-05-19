@isTest
public with sharing class KnowledgeLandingPageDispatcherTest {
    
    public static testmethod void testgetEmailFormLinks() {
        Boolean getStats = false;
        Boolean isTrending= false;    
        Integer currentPage = 1;
        String requestSource = 'ViewAs';
        String market = '';
        String channel = '';
        String employeeRole  = 'Employee';
        String resourceType = 'Manager And above';
        
        KnowledgeLandingPageDispatcher.getFrontLineKnowledgeArticles();
        KnowledgeLandingPageDispatcher.getAssignedKnowledgeArticles();
        
        KnowledgeLandingPageDispatcher.getViewAsFrontLineKnowledgeArticles(channel, market,  
                                                                           employeeRole, resourceType,
                                                                           requestSource);
        
        KnowledgeLandingPageDispatcher.getViewAsAssignedKnowledgeArticles(channel, market,  
                                                                          employeeRole, resourceType,
                                                                          requestSource);
        
        KnowledgeLandingPageDispatcher.getViewAsTrendingArticles(channel, market,  
                                                                 employeeRole, resourceType,
                                                                 requestSource);
        KnowledgeLandingPageDispatcher.getTrendingArticles();  
        KnowledgeLandingPageDispatcher.getTrendingArticles();  
        
        
        
        
        
    }
    
    
}