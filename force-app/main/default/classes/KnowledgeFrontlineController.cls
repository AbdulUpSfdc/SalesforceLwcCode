/*****
        Name             : KnowledgeFrontlineController
    Description      : This is the controller class for the FrontlineArticleComponent.
****/ 

public with sharing class KnowledgeFrontlineController {
   private static String FRONTLINE_TYPE = 'frontline';
	private static String ASSIGNED_ARTICLE_TYPE = 'assignedarticle';
	private static Integer cacheTtl = 1800; // 30 minutes
	private static String cachedArticle;
	Map<String, Knowledge__kav> cacheToKaId;
	private static String JSONStringFrontline;
	private static String JSONStringAssigned;
	private static String NEWS_RECORDTYPEID = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByDeveloperName().get('News_Article').getRecordTypeId();
	
    
    /*@AuraEnabled(cacheable=true)
    public static ResponseHandler getFrontLineKnowledgeArticlesOLD() {
        try{
            ID userId = UserInfo.getUserId();
            String primaryCategory = ArticleSearchDataService.getPrimary('category');
            String categoryString = getCategoryString(primaryCategory);
            List<Knowledge__kav> articles = new List<Knowledge__kav>();
            String baseQuery = getFullQueryString(FRONTLINE_TYPE, categoryString,  false, null, null, null);
 			System.debug(FRONTLINE_TYPE + ' base query: ' + baseQuery);

            //String baseQuery = getBaseKnowledgeQuery(true);
            //baseQuery += ' AND BW_FrontLine_Focus__c= True';
            //baseQuery += getChannelCondition(categoryString);
            //baseQuery += ' ORDER BY LastPublishedDate DESC';
            //baseQuery += ' LIMIT 5';
            //system.debug('final FL query: '+baseQuery);
            
            articles = Database.query(baseQuery);
            System.debug('Number of '  + FRONTLINE_TYPE + ' articles found: ' + articles.size());


            return new ResponseHandler(getfrontLineKnowledgeList(articles, FRONTLINE_TYPE));
        }catch(Exception e){
            //BWC_ExceptionUtils.handleException(e, true);
            return new ResponseHandler(e.getMessage());
        }
    }
    */

    @AuraEnabled(cacheable = true)
	public static ResponseHandler getFrontLineKnowledgeArticles(){
		try{
			ID userId = UserInfo.getUserId();
			String primaryCategory = ArticleSearchDataService.getPrimary('category');
			Set<String> categoryIds = primaryCategory == null ? new Set<String>() : new Set<String>{primaryCategory};
			String categoryString = '';
			if (categoryIds.size() > 0){
				//convert set to raw string to use with data category filter
				categoryString = String.join(new List<String>(categoryIds), ',');
			}
			List<Knowledge__kav> articles = new List<Knowledge__kav>();
			
			// Get Session Partition
			Cache.SessionPartition sessionPart = Cache.Session.getPartition('local.KMAssignedSession');
			if (sessionPart.contains('frontLineArticle')){
				String cachedArticle = (String)sessionPart.get('frontLineArticle');
				articles = (List<Knowledge__kav>)JSON.deserialize(cachedArticle, List<Knowledge__kav>.class);
			}
			else{
				String baseQuery = 'SELECT Id, Is_Pinnable__c, RecordTypeId, Title, BW_Article_Summary__c, BW_Preview_Image__c,';
				baseQuery += ' BW_FrontLine_Focus__c, ArticleTotalViewCount, BW_Is_Urgent__c,';
				baseQuery += ' MyCSPArticleName__c, LastPublishedDate,BW_News_Start_Date__c,';
				baseQuery += ' Valid_Until_Date__c,RecordType.Name,';
				baseQuery += ' BW_News_End_Date__c, KnowledgeArticleId,';
				baseQuery += ' (SELECT id, BW_Article_Viewed__c ';
				baseQuery += ' FROM BW_KM_Lifecycle_Helper__r';
				baseQuery += ' WHERE BW_User__c = :userId';
				baseQuery += ' AND BW_Article_Viewed__c = true';
				baseQuery += ' LIMIT 1)';
				baseQuery += ' FROM Knowledge__kav';
				baseQuery += ' WHERE BW_FrontLine_Focus__c= True';
				baseQuery += ' AND PublishStatus =\'Online\'';
				if (categoryString != ''){
					baseQuery += ' WITH DATA CATEGORY Channel__c AT (' + categoryString + ')';
				}
				baseQuery += ' ORDER BY LastPublishedDate DESC';
				baseQuery += ' LIMIT 5';
				system.debug('final FL query: ' + baseQuery);
				articles = Database.query(baseQuery);
                if(!articles.isEmpty()){
                    JSONStringFrontline = JSON.serialize(articles);
                    // Frontline articles should take less than or equal to 3 kb per user
                    // 3*1024*256 = 786432 characters
                    if(JSONStringFrontline.length() <= 786432){
                        for (Knowledge__kav articleID : articles){
                            // Add cache value to the partition
                            sessionPart.put('frontLineArticle', JSONStringFrontline, cacheTtl);
                        }
                    }
                }
			}

			return new ResponseHandler(getfrontLineKnowledgeList(articles, FRONTLINE_TYPE));
		} catch (Exception e){
			//BWC_ExceptionUtils.handleException(e, true);
			return new ResponseHandler(e.getMessage());
		}
	}


    @AuraEnabled(cacheable = true)
    public static ResponseHandler getAssignedKnowledgeArticles(){
		try{
			ID userId = UserInfo.getUserId();
			String primaryCategory = ArticleSearchDataService.getPrimary('category');
            String primaryMarket = ArticleSearchDataService.getPrimary('market');
			Set<String> categoryIds = primaryCategory == null ? new Set<String>() : new Set<String>{primaryCategory};
			String categoryString = '';
			if (!categoryIds.isEmpty()){
				//convert set to raw string to use with data category filter
				categoryString = String.join(new List<String>(categoryIds), ',');
			}
			List<Knowledge__kav> articles = new List<Knowledge__kav>();
		
			// Get Session Partition
			Cache.SessionPartition sessionAssignedPart = Cache.Session.getPartition('local.KMAssignedSession');
			if (sessionAssignedPart.contains('assignedArticle')){
				String cachedAssignedArticle = (String)sessionAssignedPart.get('assignedArticle');
				articles = (List<Knowledge__kav>)JSON.deserialize(cachedAssignedArticle, List<Knowledge__kav>.class);
                system.debug('Getting data from session cache');
                if (articles != null && !articles.isEmpty()) {
                	system.debug('CACHE BLOCK IS READ::' + articles[0].BW_KM_Lifecycle_Helper__r);
                }    
			}
			else{
				String baseQuery = 'SELECT Id, RecordTypeId, Title, BW_Article_Summary__c, BW_Preview_Image__c,';
				baseQuery += ' BW_FrontLine_Focus__c, ArticleTotalViewCount, BW_Is_Urgent__c, Is_Pinnable__c,';
				baseQuery += ' MyCSPArticleName__c, LastPublishedDate,BW_News_Start_Date__c,';
				baseQuery += ' Valid_Until_Date__c,RecordType.Name,';
				baseQuery += ' BW_News_End_Date__c, KnowledgeArticleId,';
				baseQuery += ' (SELECT id, BW_Article_Viewed__c ';
				baseQuery += ' FROM BW_KM_Lifecycle_Helper__r';
				baseQuery += ' WHERE BW_User__c = :userId';
				baseQuery += ' AND BW_Article_Viewed__c = true';
				baseQuery += ' LIMIT 1)';
				baseQuery += ' FROM Knowledge__kav';
				baseQuery += ' WHERE (BW_Home_Page_Display__c = true OR RecordTypeId=:NEWS_RECORDTYPEID)';
				baseQuery += ' AND PublishStatus =\'Online\'';
				if(String.isNotBlank(primaryMarket)){
                    baseQuery += ' AND Id IN (SELECT Knowledge__c FROM BWMarketAssociation__c WHERE BWMarketMaster__c = :primaryMarket)';
                }
                if (String.isNotBlank(categoryString)){
					baseQuery += ' WITH DATA CATEGORY Channel__c AT (' + categoryString + ')';
				}
				baseQuery += ' ORDER BY Is_Pinnable__c DESC, BW_Is_Urgent__c DESC, LastPublishedDate DESC, Title ASC';
				baseQuery += ' LIMIT 1000';
				system.debug('final AA query: ' + baseQuery);
				articles = Database.query(baseQuery);
                if(!articles.isEmpty()){
                	system.debug('IS READ::' + articles[0].BW_KM_Lifecycle_Helper__r);
                    JSONStringAssigned = JSON.serialize(articles);
                    // Assigned articles should take less than or equal to 17kb per user
                    //17*1024*256 = 4456448 characters
                    if(JSONStringAssigned.length() <= 4456448){
                        for (Knowledge__kav articleID : articles){
                            // Add cache value to the partition
                            sessionAssignedPart.put('assignedArticle', JSONStringAssigned, cacheTtl);
                        }
                    }
                }
			}
			return new ResponseHandler(getfrontLineKnowledgeList(articles, ASSIGNED_ARTICLE_TYPE));
		} catch (Exception e){
			System.debug('Exception caught getting assigned articles: ' + e.getMessage() + e.getStackTraceString() + 'Line Number: ' + e.getLineNumber());
			///BWC_ExceptionUtils.handleException(e, true);
			return new ResponseHandler(e.getMessage());
		}
	}

   /* 
    	@AuraEnabled(cacheable=true)
    public static ResponseHandler getAssignedKnowledgeArticlesOLD() {
        try{
            ID userId = UserInfo.getUserId();
            String primaryMarket = ArticleSearchDataService.getPrimary('market');
            Set<ID> marketIds = primaryMarket==null ? new Set<ID>() : new Set<ID>{(ID)primaryMarket};
            String primaryCategory = ArticleSearchDataService.getPrimary('category');
            Set<String> categoryIds = primaryCategory==null ? new Set<String>() : new Set<String>{primaryCategory};
            //categoryIds.add('All__c');
             String categoryString = '';
            if(categoryIds.size() > 0) {
                //convert set to raw string to use with data category filter
                categoryString = String.join(new List<String>(categoryIds), ',');
            }
            List<Knowledge__kav> articles = new List<Knowledge__kav>();
            String baseQuery = 'SELECT Id, RecordTypeId, Title, BW_Article_Summary__c, BW_Preview_Image__c,'; 
            baseQuery += ' BW_FrontLine_Focus__c, ArticleTotalViewCount, BW_Is_Urgent__c,';
            baseQuery += ' MyCSPArticleName__c, LastPublishedDate,BW_News_Start_Date__c,';
            baseQuery += ' Valid_Until_Date__c,RecordType.Name,';
            baseQuery += ' BW_News_End_Date__c, KnowledgeArticleId,';
            baseQuery += ' (SELECT id, BW_Article_Viewed__c ';
            baseQuery += ' FROM BW_KM_Lifecycle_Helper__r';
            baseQuery += ' WHERE BW_User__c = :userId';
            baseQuery += ' AND BW_Article_Viewed__c = true';
            baseQuery += ' LIMIT 1)';
            baseQuery += ' FROM Knowledge__kav';
            baseQuery += ' WHERE (BW_Home_Page_Display__c = true OR RecordTypeId=:NEWS_RECORDTYPEID)';
            baseQuery += ' AND PublishStatus =\'Online\'';
            baseQuery += ' AND Id IN (';
            baseQuery += ' SELECT knowledge__c'; 
            baseQuery += ' FROM bwmarketassociation__c'; 
            baseQuery += ' WHERE bwmarketmaster__c '; 
            baseQuery += ' IN :marketIds';
            baseQuery += ' )';
            baseQuery += ' WITH DATA CATEGORY Channel__c AT ('+categoryString+')';
            baseQuery += ' ORDER BY BW_Is_Urgent__c DESC, LastPublishedDate DESC, Title ASC';
            baseQuery += ' LIMIT 1000';
            system.debug('final AA query: '+baseQuery);
            articles = Database.query(baseQuery);
            System.debug('Number of assigned articles found: ' + articles.size());

            return new ResponseHandler(getfrontLineKnowledgeList(articles, ASSIGNED_ARTICLE_TYPE));
        }catch(Exception e){
            //BWC_ExceptionUtils.handleException(e, true);
            System.debug('Exception caught in assigned articles: ' + e.getMessage());
            return new ResponseHandler(e.getMessage());
        }
    }
   */
    
    @AuraEnabled(cacheable=true)
    public static ResponseHandler getAssignedKnowledgeArticlesNew() {
        try{
            ID userId = UserInfo.getUserId();
            String primaryCategory = ArticleSearchDataService.getPrimary('category');
            String categoryString = getCategoryString(primaryCategory);
            List<Knowledge__kav> articles = new List<Knowledge__kav>();
            String baseQuery = getFullQueryString(ASSIGNED_ARTICLE_TYPE, categoryString,  false, null, null, null);

            
            /*String baseQuery = getBaseKnowledgeQuery(true);
            baseQuery += ' AND (BW_Home_Page_Display__c = true OR RecordTypeId=:NEWS_RECORDTYPEID)';
            baseQuery += getChannelCondition(categoryString);
            baseQuery += ' ORDER BY BW_Is_Urgent__c DESC, LastPublishedDate DESC, Title ASC';
            baseQuery += ' LIMIT 1000';
            system.debug('final AA query: '+baseQuery);*/
            articles = Database.query(baseQuery);
            return new ResponseHandler(getfrontLineKnowledgeList(articles, ASSIGNED_ARTICLE_TYPE));
        }catch(Exception e){
            BWC_ExceptionUtils.handleException(e, true);
            return new ResponseHandler(e.getMessage());
        }
    }
    
    
    public static ResponseHandler getViewAsAssignedKnowledgeArticles(String channel, String market,  
                                                                String employeeRole, String resourceType,
                                                                String requestSource) {
  		 try{
            
            String categoryString = getCategoryString(channel);
            List<Knowledge__kav> articles = new List<Knowledge__kav>();
            String baseQuery = getBaseKnowledgeQuery(false);
            baseQuery += ' AND (BW_Home_Page_Display__c = true OR RecordTypeId=:NEWS_RECORDTYPEID)';
            baseQuery += getViewAsConditions(market,categoryString, employeeRole, resourceType);
            baseQuery += getOrderByString(ASSIGNED_ARTICLE_TYPE);        
            system.debug('final AA query: '+baseQuery);
            articles = Database.query(baseQuery);
            return new ResponseHandler(getfrontLineKnowledgeList(articles, ASSIGNED_ARTICLE_TYPE));
        }catch(Exception e){
            System.debug('Exception caught: ' + e);
            
            BWC_ExceptionUtils.handleException(e, true);
            return new ResponseHandler(e.getMessage());
        }

                                                                }
    public static ResponseHandler getFrontLineKnowledgeArticles(String channel, String market,  
                                                                String employeeRole, String resourceType,
                                                                String requestSource) {
        try{
           
            String categoryString = getCategoryString(channel);
            List<Knowledge__kav> articles = new List<Knowledge__kav>();
            String baseQuery = getBaseKnowledgeQuery(false);
            baseQuery += ' AND BW_FrontLine_Focus__c= True';
            baseQuery += getViewAsConditions(market,categoryString, employeeRole, resourceType);
            baseQuery += ' ORDER BY LastPublishedDate DESC';
            baseQuery += ' LIMIT 5';
            system.debug('final FL query: '+baseQuery);
            articles = Database.query(baseQuery);

            return new ResponseHandler(getfrontLineKnowledgeList(articles, FRONTLINE_TYPE));
        }catch(Exception e){
            //BWC_ExceptionUtils.handleException(e, true);
            return new ResponseHandler(e.getMessage());
        }
    }
    
    public static String getCategoryString(String category) {
        Set<String> categorySet = category==null ? new Set<String>() : new Set<String>{category};
        String categoryString = '';
        if(categorySet.size() > 0) {
            //convert set to raw string to use with data category filter
            categoryString = String.join(new List<String>(categorySet), ',');
        }
        return categoryString;
    }
    
     public static String getFullQueryString(String queryType, String categoryString, Boolean isViewAsQuery, String market,  
                                                                String employeeRole, String resourceType) {
        String queryString = '';
        queryString += getBaseKnowledgeQuery(!isViewAsQuery);
        queryString += getWhereCondition(queryType);
         if (isViewAsQuery) {
         	queryString += getViewAsConditions(market, categoryString, employeeRole,resourceType); 
         }    else {
         	queryString +=  getChannelCondition(categoryString);
         }
	       
         queryString +=  getOrderByString(queryType);
        return queryString;
    }
    
    
     public static String getWhereCondition(String queryType) {
        String whereCondition = '';
        if (queryType.equals(ASSIGNED_ARTICLE_TYPE)) {
            whereCondition = ' AND (BW_Home_Page_Display__c = true OR RecordTypeId=:NEWS_RECORDTYPEID)';
          
        }
        if (queryType.equals(FRONTLINE_TYPE)) {
            whereCondition = ' AND BW_FrontLine_Focus__c= True';
        }
        return whereCondition;
    }
    
    
    public static String getOrderByString(String queryType) {
        String orderString = '';
        if (queryType.equals(ASSIGNED_ARTICLE_TYPE)) {
            orderString = ' ORDER BY BW_Is_Urgent__c DESC, LastPublishedDate DESC, Title ASC LIMIT 1000';
          
        }
        if (queryType.equals(FRONTLINE_TYPE)) {
            orderString =' ORDER BY LastPublishedDate DESC LIMIT 5';
        }
        return orderString;
    }
    
    @AuraEnabled
    public static ResponseHandler markArticleReaded(String knowledgeId){
        try{
            UPSERT new BW_KM_Lifecycle_Helper__c(
                Id = getKMHelper(knowledgeId),
                BW_Article_Viewed__c = true,
                BW_Knowledge__c = knowledgeId,
                BW_User__c = Userinfo.getuserId()
            );
            //Empty session cache when an article is read
          	emptySessionCache();
            return new ResponseHandler(true);
        }catch(Exception e){
            BWC_ExceptionUtils.handleException(e, true);
            return new ResponseHandler(e.getMessage());
        }
    }
    
    public static Boolean emptySessionCache() {
        Cache.SessionPartition sessionAssignedPart = Cache.Session.getPartition('local.KMAssignedSession');
        if (sessionAssignedPart.contains('assignedArticle')){
            sessionAssignedPart.remove('assignedArticle');
        }
        if (sessionAssignedPart.contains('frontLineArticle')){
            sessionAssignedPart.remove('frontLineArticle');
        }
        return true;
    }
    
    private static String getKMHelper(String knowledgeId){
        try{
            return [
                SELECT id 
                FROM BW_KM_Lifecycle_Helper__c
                WHERE BW_User__c = :Userinfo.getuserId()
                AND BW_Knowledge__c = :knowledgeId
                LIMIT 1
            ].Id;
        }catch(exception e){}
        return null; 
    }
    
    private static Map<Id, Integer> getChatCountByArticleId(Set<Id> knowledgeArticleIds){
        Map<Id, Integer> chatCountByArticleId = new Map<Id, Integer>();
       for(AggregateResult aggr: [
            SELECT knowledge__r.knowledgearticleid kaid, count(id) chatcount 
            from KM_Article_Feedback__c 
            WHERE knowledge__r.knowledgearticleid IN :knowledgeArticleIds
            GROUP BY knowledge__r.knowledgearticleid]){
            chatCountByArticleId.put((Id)aggr.get('kaid'), Integer.valueOf((Decimal)aggr.get('chatcount')));
        }
        return chatCountByArticleId;
    }
    
    private static List<CompWrapper> getfrontLineKnowledgeList(List<Knowledge__kav> lstKnw, String requestType){
        system.debug(requestType+ ' ARTICLES SIZE ::: '+lstKnw.size());
        List<CompWrapper> fronLinelstCompWrapper = new List<CompWrapper>();
        Set<id> artileIds = new Set<id>();
        for(Knowledge__kav kw: lstKnw){
            artileIds.add(kw.KnowledgeArticleId);
        }
        //Map<id, Integer> scoreByKwId = getLikeNormalizeScore(artileIds);
        Map<Id, Integer> chatCountByArticleId = getChatCountByArticleId(artileIds);
        
        for(Knowledge__kav obj: lstKnw){
            CompWrapper cmp = new CompWrapper();
            cmp.compId = obj.Id;
            cmp.title = obj.Title;
            cmp.summary = removeHTML(obj.BW_Article_Summary__c);// trimSummary(removeHTML(obj.BW_Article_Summary__c), requestType);
            cmp.previewImage = (obj.BW_Preview_Image__c!=null) ? (obj.BW_Preview_Image__c).substringAfter('src="').replace('&amp;','&').substringBefore('"'):'';
            
            cmp.isRead = checkArticleIsReaded(obj);
            cmp.isReadNumber = cmp.isRead ? 1 : 0;
            cmp.isUrgent = obj.BW_Is_Urgent__c;
            cmp.isPinned = obj.Is_Pinnable__c;
            cmp.updateddate = obj.LastPublishedDate.format('MM.dd.YY');

            cmp.recordTypeName = obj.RecordType.Name;
            
            if(requestType == FRONTLINE_TYPE){
                cmp.previewCount = obj.ArticleTotalViewCount;

                Map<String, Integer> voteByCount = VotingComponentController.getVoteByCount(obj.KnowledgeArticleId, new Set<String>{'5'});
                if(voteByCount.size() > 0){
                    cmp.likeCount = voteByCount.get('5');
                }else{
                    cmp.likeCount = 0;
                }
                
                cmp.messageCount = chatCountByArticleId.containsKey(obj.KnowledgeArticleId) ? chatCountByArticleId.get(obj.KnowledgeArticleId) : 0;
                cmp.cspId = (obj.MyCSPArticleName__c != null && obj.MyCSPArticleName__c.length() > 6) ? '#' +obj.MyCSPArticleName__c.right(6).remove('_')+ ' ' : '';
                cmp.validity = caculateValidity(obj);
                fronLinelstCompWrapper.add(cmp);
            }
            
            if(requestType == ASSIGNED_ARTICLE_TYPE && (!cmp.isRead || cmp.isPinned)){
                fronLinelstCompWrapper.add(cmp);
            }
        }  
        //Ashish - Commented below block to keep unread pinned articles on the top
        /*if(requestType == ASSIGNED_ARTICLE_TYPE){
            fronLinelstCompWrapper.sort();
        }*/
        system.debug('ASSIGNED ARTICLES SIZE ::: '+fronLinelstCompWrapper.size());
        return fronLinelstCompWrapper;
    }
    
    private static String removeHTML(String bodystr){
        if(STRING.ISBLANK(bodystr)){
            return '';
        }
        return bodystr.replaceAll('<[^>]+>',' ');
    }
/*
    private static String trimSummary(String summary, String requestType){
        Integer trimLength = 800;
        if(requestType == FRONTLINE_TYPE){
            trimLength = 100;
        }
        if(STRING.ISNOTBLANK(summary)){
            if(summary.length() > trimLength){
                return summary.subString(0,trimLength);
            }
            return summary;
        }
        return '';
    }
    */
    private static String caculateValidity(Knowledge__kav knowledgeObj){
        String valid = '';
        DateTime startTime;
        DateTime endTime;
        if(knowledgeObj.RecordTypeId == NEWS_RECORDTYPEID){
            startTime = knowledgeObj.BW_News_Start_Date__c;
            endTime = knowledgeObj.BW_News_End_Date__c;
        }else{
            startTime = knowledgeObj.LastPublishedDate;
            endTime = DateTime.newInstance(knowledgeObj.Valid_Until_Date__c, Time.newInstance(0, 0, 0, 0));
        }
        if(startTime != NULL){
            valid += startTime.format('MM.dd.YY');
        //TODO: REMOVE IT.
        }else{
            valid += knowledgeObj.LastPublishedDate.format('MM.dd.YY');
        }
        
        valid += ' - ';
        if(endTime != NULL){
            valid += endTime.format('MM.dd.YY');
        }
        return valid;
    }
    
    /*
    private static Map<id, Integer> getLikeNormalizeScore(Set<Id> knowledgeIds){
        Map<id, Integer> scoreByKwId = new Map<id, Integer>();
        For(Knowledge__VoteStat voteState: [
            SELECT Id, NormalizedScore, Channel, ParentId 
            FROM Knowledge__VoteStat
            WHERE ParentId IN :knowledgeIds
            AND Channel = 'AllChannels']){
            scoreByKwId.put(voteState.ParentId, Integer.valueOf(voteState.NormalizedScore));
        }
        return scoreByKwId;
    }
    */
    public static String getCSPId(String cspId){
        if(STRING.ISNOTBLANK(cspId)){
            String cspIdstr = cspId.substringAfterLast('_');
            if(STRING.ISNOTBLANK(cspIdstr)){
                return cspIdstr;
            }
            return cspId;
        }
        return '';
    }
    
    private static boolean checkArticleIsReaded(Knowledge__kav knowledgeObject){
        if(knowledgeObject.BW_KM_Lifecycle_Helper__r.size() > 0){
            return true;
        }
        return false;
    }

    public static String getBaseKnowledgeQuery(Boolean includeArticleViewedByUser) {
        String baseQuery = 'SELECT Id, Is_Pinnable__c, RecordTypeId, Title, BW_Article_Summary__c, BW_Preview_Image__c,'; 
            baseQuery += ' BW_FrontLine_Focus__c, ArticleTotalViewCount, BW_Is_Urgent__c,';
            baseQuery += ' MyCSPArticleName__c, LastPublishedDate,BW_News_Start_Date__c,';
            baseQuery += ' Valid_Until_Date__c,RecordType.Name,';
            baseQuery += ' BW_News_End_Date__c, KnowledgeArticleId';
        if (includeArticleViewedByUser) {
            baseQuery += ' , (SELECT id, BW_Article_Viewed__c ';
            baseQuery += ' FROM BW_KM_Lifecycle_Helper__r';
            baseQuery += ' WHERE BW_User__c = :userId';
            baseQuery += ' AND BW_Article_Viewed__c = true';
            baseQuery += ' LIMIT 1)';
        }    
            baseQuery += ' FROM Knowledge__kav';
       		baseQuery += ' WHERE PublishStatus =\'Online\'' ;
        return baseQuery;   
    }
    
    public static String getChannelCondition(String categoryString) {
        String channelCondition = '';
        if(!String.isEmpty( categoryString)) {
                channelCondition += ' WITH DATA CATEGORY Channel__c AT ('+categoryString+ ')';
        }
        return channelCondition;
    }
    
    public static String getViewAsConditions(String market, String categoryString, 
                                             String employeeRole, String resourceType) {
        String viewAsCondition = '';
        viewasCondition += getMarketCondition(market);
        viewasCondition += getChannelCondition(categoryString);
        viewAsCondition += ' AND Resource_Type__c AT ('+resourceType+'__c)';  
        viewAsCondition += ' AND Role__c AT ('+employeeRole+'__c)';                                             
        return viewAsCondition;
    }
    
    public static String getMarketCondition(String marketName) {
       List<BWMarketMaster__c> marketList = [SELECT Id, MarketPromotedSearchTerm__c FROM BWMarketMaster__c WHERE MarketPromotedSearchTerm__c = :marketName];
       String marketCondition = ''; 
       Id marketId = null;
        if (!marketList.isEmpty()) {
            marketId =  marketList[0].Id;
            marketCondition = ' AND Id IN (SELECT Knowledge__c FROM BWMarketAssociation__c WHERE BWMarketMaster__c = ' + '\'' + marketId + '\')';
        }
        return marketCondition;
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
    
    public class CompWrapper implements Comparable {
        @AuraEnabled
        public Id compId {get;set;}
        @AuraEnabled
        public String title {get;set;}
        @AuraEnabled
        public String summary {get;set;}
        @AuraEnabled
        public String previewImage {get;set;}
        @AuraEnabled
        public Boolean isRead {get;set;}
        @AuraEnabled
        public Integer isReadNumber {get;set;}
        @AuraEnabled
        public Boolean isUrgent {get;set;}
        @AuraEnabled
        public Boolean isPinned {get;set;}
        @AuraEnabled
        public String cspId {get;set;}
        @AuraEnabled
        public String updateddate {get;set;}
        @AuraEnabled
        public String validity {get;set;}

        @AuraEnabled
        public Integer previewCount {get;set;}
        @AuraEnabled
        public Integer likeCount {get;set;}
        @AuraEnabled
        public Integer messageCount {get;set;}

        @AuraEnabled
        public String recordTypeName {get;set;}

        public CompWrapper(){

        }
        
        //Implement the compareTo() method
        public Integer compareTo(Object compareTo) {
            CompWrapper compareToEmp = (CompWrapper)compareTo;
            if (isReadNumber == compareToEmp.isReadNumber) return 0;
            if (isReadNumber > compareToEmp.isReadNumber) return 1;
            return -1;        
        }
    }
 
}