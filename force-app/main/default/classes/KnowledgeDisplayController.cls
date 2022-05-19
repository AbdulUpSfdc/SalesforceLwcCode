public without sharing class KnowledgeDisplayController {
    //Values that specifies the Recortype of Knowledge Articles that are visible on the Knowledge Landing page.
    private static Set<String> recordTypeName = new Set<String>{
        'FAQs & Troubleshooting',
        'News Article',
        'Operations Support',
        'Promotions & Offers',
        'Sales & Support'
    };
    
    public KnowledgeDisplayController() {
        
    }
    //Method to get the Knowledge Articles for the Home page.
    @AuraEnabled(cacheable=true)
    public static ResponseHandler getKnowledgeArticle(String tabLabal){
        ResponseHandler responseObj = new ResponseHandler();
        try{
            List<Knowledge__kav> lstKnw;
            //Handle Article list for Trending Now Tab.
            if(String.isNotBlank(tabLabal) && tabLabal == 'Trending Now'){
                lstKnw = getTrendingArticles();
            
            //Handle Article list for Activity Stream Tab.
            }else if(String.isNotBlank(tabLabal) && tabLabal == 'Activity Stream'){
                lstKnw = getArticlesFromLastWeek();
            
            //Handle Article list for default Tab.
            }else{
                lstKnw = getKnowledgeArticles();
            }
            getKnowledgeViewResponse(responseObj, lstKnw, tabLabal);    
            
        }catch(System.Exception e){
            responseObj.isSuccess = false;
            responseObj.errorMessage = e.getMessage();
            responseObj.homePageKnwList = new Map<Integer, List<KnowledgeDisplayController.CompWrapper>>();
            responseObj.linkCentralKnwList = new List<CompWrapper>();
            responseObj.frontLineKnwList = new List<CompWrapper>();
            BWC_ExceptionUtils.handleException(e, true);
        }
        return responseObj;
    }
    
    //Method to get the Link Central Articles
    @AuraEnabled(cacheable=true)
    public static ResponseHandler getLinkCentralArticle(){
        ResponseHandler responseObj = new ResponseHandler();
        try{
            List<Knowledge__kav> lstKnw = getLinkCentralArticles();
            getKnowledgeViewResponse(responseObj, lstKnw, '');     
            
        }catch(System.Exception e){
            exceptionResponse(responseObj, e);
        }
        return responseObj;
    }
    
    @AuraEnabled(cacheable=true)
    public static ResponseHandler getFronLineArticle(){
        ResponseHandler responseObj = new ResponseHandler();
        try{
            List<Knowledge__kav> lstKnw = getFronLineArticles();
            getKnowledgeViewResponse(responseObj, lstKnw, '');   
            
        }catch(System.Exception e){
            exceptionResponse(responseObj, e);
        }
        return responseObj;
    }
    
    private static void exceptionResponse(ResponseHandler responseObj, System.Exception e){
        responseObj.isSuccess = false;
        responseObj.errorMessage = e.getMessage();
        responseObj.homePageKnwList = new Map<Integer, List<KnowledgeDisplayController.CompWrapper>>();
        responseObj.linkCentralKnwList = new List<CompWrapper>();
        responseObj.frontLineKnwList = new List<CompWrapper>();
        BWC_ExceptionUtils.handleException(e, true);
    }
    
    //Method that make the article readed per user.
    @AuraEnabled
    public static BW_KM_Lifecycle_Helper__c setArticleReaded(String articleId){
        BW_KM_Lifecycle_Helper__c kus = new BW_KM_Lifecycle_Helper__c();
        String currentUserId = UserInfo.getUserId();
        try{
            kus = [
                SELECT Id from BW_KM_Lifecycle_Helper__c
                WHERE BW_User__c = :currentUserId
                AND BW_Knowledge__c = :articleId
                LIMIT 1
            ];
            kus.BW_Article_Viewed__c = true;
            UPDATE kus;
        }catch(exception e){
            kus = new BW_KM_Lifecycle_Helper__c(
                BW_Article_Viewed__c = true,
                BW_User__c = currentUserId,
                BW_Knowledge__c = articleId
            );
            INSERT kus;
            // Log the exception
            BWC_ExceptionUtils.handleException(e, true);
        }
        return kus;
    }
    
    //Method to get the list of Knowledge articles.
    private static List<Knowledge__kav> getKnowledgeArticles(){
        List<Knowledge__kav> lstKnw = new List<Knowledge__kav>();
        try{
            lstKnw =  [
                SELECT Id,Title, BW_Article_Summary__c, BW_Preview_Image__c, KnowledgeArticleId, 
                BW_Home_Page_Display__c, BW_Link_Center_Article__c, ArticleTotalViewCount,
                BW_FrontLine_Focus__c,BW_Is_Urgent__c,
                (
                    SELECT BW_Article_Viewed__c, BW_User__c 
                    FROM BW_KM_Lifecycle_Helper__r
                    WHERE BW_User__c = :UserInfo.getUserId()
                    LIMIT 1
                )
                FROM Knowledge__kav 
                WHERE Language ='en_US' 
                AND PublishStatus ='Online'
                AND (
                    BW_Home_Page_Display__c = true
                    OR
                    BW_News_Article__c = true
                )
                AND RecordType.Name IN : recordTypeName
                ORDER BY BW_Is_Urgent__c DESC,
                LastModifiedDate DESC
                LIMIT 40
            ];
        }catch(System.Exception e){
            // Log the exception
            BWC_ExceptionUtils.handleException(e, true);
        }
        return lstKnw;
    }

    //Method to get the list of Trending articles.
    private static List<Knowledge__kav> getTrendingArticles(){
        List<Knowledge__kav> lstKnw = new List<Knowledge__kav>();
        Datetime trendingStartTime = System.Now().addHours(-24);
        Datetime trendingEndTime = System.Now();
        try{
            lstKnw =  [
                SELECT Id,Title, BW_Article_Summary__c, BW_Preview_Image__c, KnowledgeArticleId, 
                BW_Home_Page_Display__c, BW_Link_Center_Article__c,
                BW_FrontLine_Focus__c,BW_Is_Urgent__c, ArticleTotalViewCount,
                (
                   SELECT BW_Article_Viewed__c, BW_User__c 
                   FROM BW_KM_Lifecycle_Helper__r
                   WHERE BW_User__c = :UserInfo.getUserId()
                   LIMIT 1
                )
                FROM Knowledge__kav 
                WHERE Language ='en_US' 
                AND PublishStatus ='Online'
                AND (
                   BW_Home_Page_Display__c = true
                   OR
                   BW_News_Article__c = true
                )
                AND RecordType.Name IN :recordTypeName
                AND (
                    LastPublishedDate <= :trendingEndTime
                    AND
                    LastPublishedDate >= :trendingStartTime
                )
                ORDER BY BW_Is_Urgent__c DESC,
                LastModifiedDate DESC
                LIMIT 5
           ];
        }catch(System.Exception e){
            // Log the exception
            BWC_ExceptionUtils.handleException(e, true);
        }
        return lstKnw;
    }
    
    //Method to get the list of Link Central articles.
    //TDOO: Subjec to Change in this query.
    private static List<Knowledge__kav> getLinkCentralArticles(){
        List<Knowledge__kav> lstKnw = new List<Knowledge__kav>();
        try{
            lstKnw =  [SELECT Id, Title, BW_Article_Summary__c, BW_Preview_Image__c, 
                       BW_Link_Center_Article__c, BW_Is_Urgent__c, KnowledgeArticleId, ArticleTotalViewCount
                       FROM Knowledge__kav 
                       WHERE Language ='en_US' 
                       AND PublishStatus ='Online'
                       AND BW_Link_Center_Article__c = true
                       ORDER BY LastModifiedDate DESC
                       LIMIT 20];
        }catch(System.Exception e){
            // Log the exception
            BWC_ExceptionUtils.handleException(e, true);
        }
        return lstKnw;
    }
    
    //Method to get the list of Front Line articles.
    //TDOO: Subjec to Change in this query.
    private static List<Knowledge__kav> getFronLineArticles(){
        List<Knowledge__kav> lstKnw = new List<Knowledge__kav>();
        try{
            lstKnw =  [SELECT Id, Title, BW_Article_Summary__c, BW_Preview_Image__c, 
                       BW_FrontLine_Focus__c, BW_Link_Center_Article__c,
                       BW_Is_Urgent__c, KnowledgeArticleId, ArticleTotalViewCount
                       FROM Knowledge__kav 
                       WHERE Language ='en_US' 
                       AND PublishStatus ='Online'
                       AND BW_FrontLine_Focus__c = true
                       ORDER BY LastModifiedDate DESC
                       LIMIT 1];
        }catch(System.Exception e){
            // Log the exception
            BWC_ExceptionUtils.handleException(e, true);
        }
        return lstKnw;
    }
    
    //Method to get the list of Last Week articles.
    private static List<Knowledge__kav> getArticlesFromLastWeek(){
        List<Knowledge__kav> lstKnw = new List<Knowledge__kav>();
        try{
            lstKnw =  [
                 SELECT Id,Title, BW_Article_Summary__c, BW_Preview_Image__c, 
                 KnowledgeArticleId, BW_Home_Page_Display__c, BW_Link_Center_Article__c,
                 BW_FrontLine_Focus__c,BW_Is_Urgent__c, ArticleTotalViewCount,
                 (
                     SELECT Id, BW_Article_Viewed__c
                     FROM BW_KM_Lifecycle_Helper__r
                     WHERE BW_User__c = :UserInfo.getUserId()
                     AND CreatedDate = LAST_N_DAYS:7
                     AND BW_Article_Viewed__c = TRUE
                 )
                 FROM Knowledge__kav 
                 WHERE Language ='en_US' 
                 AND PublishStatus ='Online'
                 AND (
                    BW_Home_Page_Display__c = true
                    OR
                    BW_News_Article__c = true
                )
                AND RecordType.Name IN :recordTypeName
                AND LastPublishedDate = LAST_N_DAYS:7
                ORDER BY BW_Is_Urgent__c DESC,
                LastModifiedDate DESC
                
           ];
        }catch(System.Exception e){
            // Log the exception
            BWC_ExceptionUtils.handleException(e, true);
        }
        return lstKnw;
    }
    
    private static void getKnowledgeViewResponse(ResponseHandler responseObj, List<Knowledge__kav> lstKnw, String tabName){
        List<CompWrapper> homePageLstCompWrapper = new List<CompWrapper>();
        List<CompWrapper> linkCentrallstCompWrapper = new List<CompWrapper>();
        List<CompWrapper> fronLinelstCompWrapper = new List<CompWrapper>();
        List<CompWrapper> viewedAticleinLastWeekListWrapper = new List<CompWrapper>();
        List<CompWrapper> notViewedAticleinLastWeekListWrapper = new List<CompWrapper>();
        
        Set<id> articleIds = new Set<id>();
        //get the Article Ids which will be used in vote count caculation.
        for(Knowledge__kav obj: lstKnw){
            articleIds.add(obj.KnowledgeArticleId);
        }
        Map<id, Integer> voteListByArticleId = getVoteByArticleId(articleIds);
        
        for(Knowledge__kav obj: lstKnw){
            CompWrapper cmp = new CompWrapper();
            cmp.compId = obj.Id;
            cmp.title = obj.Title;
            cmp.summary = obj.BW_Article_Summary__c;
            cmp.urgentFlag = obj.BW_Is_Urgent__c;
            //Convert Image Rich text Area into previable Image.
            cmp.previewImage = (obj.BW_Preview_Image__c!=null)? (obj.BW_Preview_Image__c).substringAfter('src="').replace('&amp;','&').substringBefore('"'):'';
            cmp.articleReaded = false;
            cmp.previewCount = obj.ArticleTotalViewCount;
            
            //Caculate the vote count.
            if(voteListByArticleId.containsKey(obj.KnowledgeArticleId)){
                cmp.messageCount = voteListByArticleId.get(obj.KnowledgeArticleId);
            }else{
                cmp.messageCount = 0;
            }
            
            for(BW_KM_Lifecycle_Helper__c knowledgeStatus: obj.BW_KM_Lifecycle_Helper__r){
                cmp.articleReaded = knowledgeStatus.BW_Article_Viewed__c;
                break;
            }
            cmp.urgentArticleReaded = cmp.urgentFlag && cmp.articleReaded;
            if(obj.BW_Link_Center_Article__c){
                cmp.linkCentralArticleURL = '/lightning/r/Knowledge__kav/'+obj.Id+'/view';
                System.debug('@@## Link: '+cmp.linkCentralArticleURL);
                linkCentrallstCompWrapper.add(cmp);
            }else if(obj.BW_FrontLine_Focus__c){
                fronLinelstCompWrapper.add(cmp);
            }
            
            homePageLstCompWrapper.add(cmp);
            
            if(tabName == 'Activity Stream'){
                if(obj.BW_KM_Lifecycle_Helper__r.size() > 0){
                    viewedAticleinLastWeekListWrapper.add(cmp);
                }else{
                    notViewedAticleinLastWeekListWrapper.add(cmp);
                }
            } 
        }  
        responseObj.isSuccess = true;
        responseObj.errorMessage = '';
        responseObj.homePageKnwList = processResponse(homePageLstCompWrapper, tabName);
        responseObj.linkCentralKnwList = linkCentrallstCompWrapper;
        responseObj.frontLineKnwList = fronLinelstCompWrapper;
        responseObj.viewedAticleinLastWeekList = processResponse(viewedAticleinLastWeekListWrapper, '');
        responseObj.notViewedAticleinLastWeekList = processResponse(notViewedAticleinLastWeekListWrapper, '');
    }
    
    // Process the response such that it will show five columns properly.
    private static Map<Integer, List<CompWrapper>> processResponse(List<CompWrapper> responseObjList, String tabName){
        Map<Integer, List<CompWrapper>> dataListByIndex = new Map<Integer, List<CompWrapper>>();
        
        for(Integer i=0; i<responseObjList.size();){
            System.debug('@@##'+ i + responseObjList[i]);
            if(String.isNotBlank(tabName) && tabName == 'Trending Now'){
                system.debug('sort');
                responseObjList.sort();
                processDateListByIndex(dataListByIndex, 1, responseObjList, i);
                processDateListByIndex(dataListByIndex, 2, responseObjList, i+1);
                processDateListByIndex(dataListByIndex, 3, responseObjList, i+2);
                processDateListByIndex(dataListByIndex, 4, responseObjList, i+3);
                processDateListByIndex(dataListByIndex, 5, responseObjList, i+4);
                i=i+5;
            }else{
                system.debug('unsort');
                processDateListByIndex(dataListByIndex, 1, responseObjList, i);
                processDateListByIndex(dataListByIndex, 2, responseObjList, i+1);
                processDateListByIndex(dataListByIndex, 3, responseObjList, i+2);
                processDateListByIndex(dataListByIndex, 4, responseObjList, i+3);
                processDateListByIndex(dataListByIndex, 5, responseObjList, i+4);
                i=i+5;
            }                  
        }
        System.debug('@@##' + dataListByIndex);
        return dataListByIndex;
    }
    
    
    //Method to get process the map.
    private static void processDateListByIndex(Map<Integer, List<CompWrapper>> dataListByIndex, 
                                               Integer mapIndex, List<CompWrapper> responseObjList,
                                               Integer dataIndex){
        try{
           List<CompWrapper> tempResponseList = new List<CompWrapper>();
           if(dataListByIndex.containsKey(mapIndex)){
               tempResponseList = dataListByIndex.get(mapIndex);
           }
           tempResponseList.add(responseObjList[dataIndex]);
           dataListByIndex.put(mapIndex, tempResponseList);
        }catch(System.Exception e){
            // Log the exception
            BWC_ExceptionUtils.handleException(e, true);
        }
    }
    
    //Method to find out the count of vote on the basis of the Article id.
    private static Map<id, Integer> getVoteByArticleId(Set<id> articleIds){
        Map<id, Integer> voteListByArticleId = new Map<id, Integer>();
        try{
            for(Vote vote: [SELECT Id, ParentId, Type 
                            FROM Vote 
                            WHERE ParentId = :articleIds 
                            AND Type = '5']){
                Integer count = 0;
                if(voteListByArticleId.containsKey(vote.ParentId)){
                    count = voteListByArticleId.get(vote.ParentId);
                }
                count += 1;
                voteListByArticleId.put(vote.ParentId, count);
            }
        }catch(System.Exception e){
            // Log the exception
            BWC_ExceptionUtils.handleException(e, true);
        }
        RETURN voteListByArticleId;
    }
    
    
    public class ResponseHandler{
        @AuraEnabled
        public Boolean isSuccess {get;set;}
        @AuraEnabled
        public String errorMessage {get;set;}
        @AuraEnabled
        public Map<Integer, List<KnowledgeDisplayController.CompWrapper>> homePageKnwList {get;set;}
        @AuraEnabled
        public List<KnowledgeDisplayController.CompWrapper> linkCentralKnwList {get;set;}
        @AuraEnabled
        public List<KnowledgeDisplayController.CompWrapper> frontLineKnwList {get;set;}
        @AuraEnabled
        public Map<Integer, List<KnowledgeDisplayController.CompWrapper>> viewedAticleinLastWeekList {get;set;}
        @AuraEnabled
        public Map<Integer, List<KnowledgeDisplayController.CompWrapper>> notViewedAticleinLastWeekList {get;set;}
    }
    public class CompWrapper implements Comparable{
        @AuraEnabled
        public Id compId {get;set;}
        @AuraEnabled
        public String title {get;set;}
        
        @AuraEnabled
        public String summary {get;set;}
        @AuraEnabled
        public String previewImage {get;set;}
        
        @AuraEnabled
        public Integer previewCount {get;set;}
        @AuraEnabled
        public Integer likeCount {get;set;}
        @AuraEnabled
        public Integer messageCount {get;set;}
        
        @AuraEnabled
        public Boolean articleReaded {get;set;}
        @AuraEnabled
        public Boolean urgentArticleReaded {get;set;}
        @AuraEnabled
        public Boolean urgentFlag {get;set;}
        @AuraEnabled
        public String linkCentralArticleURL {get;set;}
        
        //Todo actual caculation
        public CompWrapper(){
            //this.previewCount = Integer.valueof((Math.random() * 1000));
            this.likeCount = Integer.valueof((Math.random() * 1000));
            //this.messageCount = Integer.valueof((Math.random() * 1000));
        }
        
        Public Integer compareTo (Object compareTo) {
            CompWrapper cmpObj = (CompWrapper)compareTo;
            Integer returnValue = 0;
            If (previewCount == cmpObj.previewCount) {
                returnValue = 0;
            } else if (previewCount > cmpObj.previewCount) {
                returnValue = -1;
            }else{
                returnValue = 1;
            }
            Return returnValue; 
        }
    }
}