/********
    Name            : KnowledgeAgentController
    Description     : 
********/

public with sharing class KnowledgeAgentController {
    private static String NEWS_ARTICLEID = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByDeveloperName().get('News_Article').getRecordTypeId();

    @AuraEnabled
    public static Integer getArticleViewCountForLast_N_Days(String articleId) {   
        Final Date TODAY = Date.today();
        Final Date LAST_N_DAYS = TODAY.addDays(-60);
        //system.debug('LAST_N_DAYS'+LAST_N_DAYS);
        Integer last_N_Days_ViewCount = 0;
        Integer numOfRecords = 0;
        Knowledge__kav article = new Knowledge__kav();
        List<Knowledge_View_Count_History__c> articleViewCountHistoryList = new List<Knowledge_View_Count_History__c>();
                  
        article = [SELECT ArticleNumber 
                   FROM Knowledge__kav 
                   WHERE Id = :articleId];
        articleViewCountHistoryList = [SELECT ArticleViewCount__c 
                                       FROM Knowledge_View_Count_History__c 
                                       WHERE ArticleNumber__c = :article.ArticleNumber AND (View_Count_Capture_Date__c <= :TODAY AND View_Count_Capture_Date__c >= :LAST_N_DAYS)
                                       ORDER BY View_Count_Capture_Date__c DESC];
        numOfRecords = articleViewCountHistoryList.size();
        if(numOfRecords > 1){
            last_N_Days_ViewCount = Integer.valueOf(articleViewCountHistoryList[0].ArticleViewCount__c - articleViewCountHistoryList[numOfRecords-1].ArticleViewCount__c);
        }
        return last_N_Days_ViewCount;
    }

    @AuraEnabled
    public static Decimal getDesktopImageWidth()
    {                                                         
        KM_Image_Width__mdt   KM_Image_Width_record =  [SELECT Desktop_width__c  FROM KM_Image_Width__mdt];
        Decimal TheDesktopImageWidth = KM_Image_Width_record.Desktop_width__c;

        return TheDesktopImageWidth;
    }

    @AuraEnabled
    public static String getCommunityURL()
    {
        Community_URL__mdt community_url_record =  [SELECT URL__c  FROM Community_URL__mdt];
        string TheCommunity_URL = community_url_record.URL__c;
        return TheCommunity_URL;
    }

    @AuraEnabled
    public static String getFavoriteslinksharingURL()
    {
        Learn_more_on__mdt linksharings_url_record =  [SELECT URL__c  FROM Learn_more_on__mdt];
        string LearnmoreonFavorites_URL = linksharings_url_record.URL__c;
        return LearnmoreonFavorites_URL;
    }

    @AuraEnabled
    public static String getPublicLink(Id ArticleId)
    {
        // get the KnowledgeArticleId (needs error checking?)

        list<Knowledge__kav> theArticle = [Select KnowledgeArticleId, IsVisibleInPkb, UrlName From Knowledge__kav WHERE Id =:ArticleId];
        
        String KnowledgeArticleId = theArticle[0].KnowledgeArticleId;
        Boolean  IsVisibleInPkb = theArticle[0].IsVisibleInPkb;
        String UrlName = theArticle[0].UrlName;
 
        String publicURL ='';
        Community_URL__mdt community_url_record =  [SELECT URL__c  FROM Community_URL__mdt];
        string community_url = community_url_record.URL__c;

        if( IsVisibleInPkb == true){
             publicURL = community_url + '/knowledgebase/s/article/' + UrlName + '?name=' + UrlName;
        }
        else{
            publicURL ='This article is not currently publicly  available, contact System Admin IsVisibleInPkb='+IsVisibleInPkb;
        }

        return publicURL;
    }

    @AuraEnabled
    public static String getPersistentLink(Id articleId)
    {
        System.debug('Article id: ' + articleId);
        Knowledge__kav theArticle = [SELECT UrlName
                                    FROM Knowledge__kav
                                    WHERE Id =:articleId];
        String persistentURL = URL.getSalesforceBaseUrl().toExternalForm() +'/lightning/articles/Knowledge/' + theArticle.UrlName;
        return persistentURL;
    }

    @AuraEnabled(cacheable=true)
    public static ResponseHandler getKnowledgeArticle(String kwId) {
        try{
            return new ResponseHandler(getfontLineKnowledgeList([
                SELECT Id, RecordTypeId, Title, BW_Article_Summary__c, BW_Preview_Image__c, 
                BW_Article_Details__c, BW_FrontLine_Focus__c, ArticleTotalViewCount, BW_Is_Urgent__c, 
                BW_myCSP_Article_Id__c, LastPublishedDate,BW_News_Start_Date__c, 
                Valid_Until_Date__c, BW_News_End_Date__c, KnowledgeArticleId,PublishStatus,
                BW_ExternalLinkURL__c, BW_External_URL__c, MyCSPArticleName__c, 
                IsVisibleInPkb, UrlName, Is_Pinnable__c,
                (SELECT id, BW_Article_Viewed__c 
                 FROM BW_KM_Lifecycle_Helper__r
                 WHERE BW_User__c = :Userinfo.getuserId()
                 AND BW_Article_Viewed__c = true
                 LIMIT 1)
                FROM Knowledge__kav
                WHERE Id = :kwId
                UPDATE VIEWSTAT
            ]));
        }catch(Exception e){
            return new ResponseHandler(e.getMessage());
        }
    }

    private static List<CompWrapper> getfontLineKnowledgeList(List<Knowledge__kav> lstKnw){
        List<CompWrapper> fronLinelstCompWrapper = new List<CompWrapper>();

        for(Knowledge__kav obj: lstKnw){
            CompWrapper cmp = new CompWrapper();
            cmp.compId = obj.Id;
            cmp.title = obj.Title;
            cmp.totalViewCount = obj.ArticleTotalViewCount;
            cmp.isPinnable = obj.Is_Pinnable__c;
            cmp.knowledgeArticleId = obj.KnowledgeArticleId;
            cmp.summary = obj.BW_Article_Summary__c;
            cmp.articleDetails = obj.BW_Article_Details__c;
            cmp.previewImageFull = obj.BW_Preview_Image__c;
            cmp.previewImage = (obj.BW_Preview_Image__c!=null) ? (obj.BW_Preview_Image__c).substringAfter('src="').replace('&amp;','&').substringBefore('"'):'';
            cmp.mycsparticleId = obj.BW_myCSP_Article_Id__c; 
            cmp.publishstatus = obj.PublishStatus;
            cmp.isRead = checkArticleIsReaded(obj);
            cmp.isUrgent = obj.BW_Is_Urgent__c;
            cmp.updateddate = obj.LastPublishedDate.format('MM.dd.YY');
            cmp.cspId = obj.MyCSPArticleName__c != null ? '' +obj.MyCSPArticleName__c.right(6).remove('_')+ ' ' : '';
            cmp.validity = caculateValidity(obj);
            cmp.externalLink = obj.BW_ExternalLinkURL__c;
            cmp.extrnalURL = obj.BW_External_URL__c;
            cmp.shareURL = URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/Knowledge__kav/' + cmp.compId + '/view';
            cmp.isPublicalyAvailable =  obj.IsVisibleInPkb;
            cmp.UrlName =  obj.UrlName;

            fronLinelstCompWrapper.add(cmp);
        }  
        return fronLinelstCompWrapper;
    }

    private static String caculateValidity(Knowledge__kav knowledgeObj){
        String valid = '';
        DateTime startTime;
        DateTime endTime;
        if(knowledgeObj.RecordTypeId == NEWS_ARTICLEID){
            startTime = knowledgeObj.BW_News_Start_Date__c;
            endTime = knowledgeObj.BW_News_End_Date__c;
        }else{
            startTime = knowledgeObj.LastPublishedDate;
            endTime = DateTime.newInstance(knowledgeObj.Valid_Until_Date__c, Time.newInstance(0, 0, 0, 0));
        }
        if(startTime != NULL){
            valid += startTime.format('MM.dd.YY');
        }else{
            valid += knowledgeObj.LastPublishedDate.format('MM.dd.YY');
        }
        
        valid += ' - ';
        if(endTime != NULL){
            valid += endTime.format('MM.dd.YY');
        }
        return valid;
    }
    
    private static boolean checkArticleIsReaded(Knowledge__kav knowledgeObject){
        if(knowledgeObject.BW_KM_Lifecycle_Helper__r.size() > 0){
            return true;
        }
        return false;
    }

    public class ResponseHandler{
        @AuraEnabled
        public Boolean isSuccess {get;set;}
        @AuraEnabled
        public String errorMessage {get;set;}
        
        @AuraEnabled
        public List<CompWrapper> frontLineKnwList {get;set;}
        
        public ResponseHandler(List<CompWrapper> frontLineKnwList){
            this.isSuccess = true;
            this.errorMessage = '';
            this.frontLineKnwList = frontLineKnwList;
        }
        
        public ResponseHandler(String errorMessage){
            this.isSuccess = false;
            this.errorMessage = errorMessage;
            this.frontLineKnwList = new List<CompWrapper>();
        }
        
        public ResponseHandler(Boolean isSuccess){
            this.isSuccess = isSuccess;
            this.errorMessage = '';
            this.frontLineKnwList = new List<CompWrapper>();
        }
    }

    public class CompWrapper{
        @AuraEnabled
        public Id compId {get;set;}
        @AuraEnabled
        public Id knowledgeArticleId {get;set;}
        @AuraEnabled
        public String title {get;set;}
        @AuraEnabled
        public String summary {get;set;}
        @AuraEnabled
        public Integer totalViewCount {get;set;}
        @AuraEnabled
        public Boolean isPinnable {get;set;}
        @AuraEnabled
        public String previewImage {get;set;}
        @AuraEnabled
        public String previewImageFull {get;set;}
        @AuraEnabled
        public String articleDetails {get;set;}
        @AuraEnabled
        public Boolean isRead {get;set;}
        @AuraEnabled
        public String publishstatus {get;set;}
        @AuraEnabled
        public String mycsparticleId {get;set;}
        @AuraEnabled
        public Boolean isUrgent {get;set;}
        @AuraEnabled
        public String externalLink {get;set;}
        @AuraEnabled
        public String extrnalURL {get;set;}
        @AuraEnabled
        public String cspId {get;set;}
        @AuraEnabled
        public String updateddate {get;set;}
        @AuraEnabled
        public String validity {get;set;}
        @AuraEnabled
        public String shareURL {get;set;}
        @AuraEnabled
        public Boolean isPublicalyAvailable {get;set;}
        @AuraEnabled
        public String UrlName {get;set;}
    }
}