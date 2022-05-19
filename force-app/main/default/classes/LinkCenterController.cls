/********
    Name            : LinkCenterController
    Dscription      : This is a controller class for the LinkCenterComponent.
*********/

public with sharing class LinkCenterController {
    
    @AuraEnabled(cacheable=true)
    public static ResponseHandler getLinkCenterArticles(String searchKey) {
        List<Knowledge__kav> linkCenterArticles = new List<Knowledge__kav>();
        List<Search.SearchResult> articlelist = new List<Search.SearchResult>();
        Search.SearchResults searchResults;
        String searchTextEscaped;
        
        /*String wildCardSearchKey = '%';
        System.debug('User searchkey: ' + searchkey);
        if (!String.isEmpty(searchkey)) {
           wildCardSearchKey = '%'+ searchKey + '%'; 
        }
        System.debug('Wildcard searchkey: ' + wildCardSearchKey);*/
        try{
            if(String.isNotBlank(searchKey) && searchKey.trim().length()>=3){
                searchTextEscaped = String.escapeSingleQuotes(searchKey);

                String searchQuery = 'FIND \'' + searchTextEscaped + '\' IN ALL FIELDS';
                searchQuery += ' RETURNING Knowledge__kav (Id, Title, BW_Article_Details__c, BW_Article_Summary__c, BW_ExternalLinkURL__c, InternalLinkURL__c';
                searchQuery += ' WHERE PublishStatus=\'Online\' AND BW_Link_Center_Article__c = true';
                searchQuery += ' ORDER BY LastPublishedDate)';
                
                searchResults = Search.find(searchquery);
                articlelist = searchResults.get('Knowledge__kav');
                for (Search.SearchResult searchResult : articlelist) {
                    Knowledge__kav kav = (Knowledge__kav) searchResult.getSObject();
                    linkCenterArticles.add(kav);
                }
            }
            else if(String.isBlank(searchKey)) {
                linkCenterArticles=[SELECT Id, Title, BW_Article_Details__c, BW_Article_Summary__c,BW_ExternalLinkURL__c,InternalLinkURL__c
                                    FROM Knowledge__kav
                                    WHERE BW_Link_Center_Article__c = True AND PublishStatus ='Online'
                                    ORDER BY LastPublishedDate
                                    LIMIT 10000];
            }
            /*return new ResponseHandler(getLinkCenterArticles([
                SELECT Id, Title, BW_Article_Details__c, BW_Article_Summary__c,BW_ExternalLinkURL__c,InternalLinkURL__c
                FROM Knowledge__kav
                WHERE BW_Link_Center_Article__c = True
                AND PublishStatus ='Online'
                //The code has been modified for adding the externalLinkUrl instead of the article title in the lwc
                AND (BW_ExternalLinkURL__c like :wildCardSearchKey
                //Fix for title search too
                OR Title like :wildCardSearchKey)
                AND (InternalLinkURL__c like :wildCardSearchKey
                OR Title like :wildCardSearchKey)
                //OR BW_Article_Details__c like :searchKey
                //OR BW_Article_Summary__c like :searchKey)*/
                /*ORDER BY Title
                LIMIT 10000
            ], searchKey));*/
            return new ResponseHandler(getLinkCenterArticles(linkCenterArticles, searchKey));
        }catch(Exception e){
            BWC_ExceptionUtils.handleException(e, true);
            return new ResponseHandler(e.getMessage());
        }
    }
    
    
    private static List<ArticleWrapper> getLinkCenterArticles(List<Knowledge__kav> lstKnw, String searchKey){
        System.debug('@@##lstKnw' + lstKnw);
        List<ArticleWrapper> linkCenterArticleList = new List<ArticleWrapper>();
        for(Knowledge__kav obj: lstKnw){
            ArticleWrapper cmp = new ArticleWrapper();
            cmp.compId = obj.Id;
            cmp.title = obj.Title;
            cmp.summary = trimSummary(obj.BW_Article_Details__c);
            //The code has been modified for adding the externalLinkUrl instead of the article title in the lwc
            cmp.externalLinkUrl = obj.BW_ExternalLinkURL__c;
            cmp.internalLinkUrl = obj.InternalLinkURL__c;
            
            linkCenterArticleList.add(cmp);
            /*if(STRING.ISNOTBLANK(searchKey)){
                if(obj.BW_Article_Details__c != NULL && obj.BW_Article_Details__c.containsIgnorecase(searchKey)){
                    linkCenterArticleList.add(cmp);
                }
                if(cmp.title.containsIgnorecase(searchKey)){
                    linkCenterArticleList.add(cmp);
                }
            }else{
                linkCenterArticleList.add(cmp);
            }*/
            System.debug('@@##' + cmp);
        }  
        
        return linkCenterArticleList;
    }

    private static String trimSummary(String summary){
        if(STRING.ISNOTBLANK(summary)){
            if(summary.length() > 150){
                return summary.subString(0,150);
            }
            return summary;
        }
        return '';
    }
    
    public class ResponseHandler{
        @AuraEnabled
        public Boolean isSuccess {get;set;}
        @AuraEnabled
        public String errorMessage {get;set;}
        
        @AuraEnabled
        public List<ArticleWrapper> linkCenterKwList {get;set;}
        
        public ResponseHandler(List<ArticleWrapper> linkCenterKwList){
            this.isSuccess = true;
            this.errorMessage = '';
            this.linkCenterKwList = linkCenterKwList;
        }
        
        public ResponseHandler(String errorMessage){
            this.isSuccess = false;
            this.errorMessage = errorMessage;
            this.linkCenterKwList = new List<ArticleWrapper>();
        }
    }
    public class ArticleWrapper {
        @AuraEnabled
        public Id compId {get;set;}
        @AuraEnabled
        public String title {get;set;}
        @AuraEnabled
        public String summary {get;set;}
        //The code has been modified for adding the externalLinkUrl instead of the article title in the lwc
        @AuraEnabled
        public String externalLinkUrl{get;set;}
        @AuraEnabled
        public String internalLinkUrl{get;set;}
    }
}