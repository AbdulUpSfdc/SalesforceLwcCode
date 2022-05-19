public with sharing class ArticleSearchDataService {
        
    public static final String CATEGORY_OBJECT_TYPE = 'KnowledgeArticleVersion';
    public static final String KNOWLEDGE_CATEGORY_CHANNEL = 'Channel';
    public static final String KNOWLEDGE_CATEGORY_ROLE = 'Role';
    public static final String KNOWLEDGE_CATEGORY_RESOURCE_TYPE = 'Resource_Type';
    
  private static String NEWS_ARTICLEID = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByDeveloperName()
    .get('News_Article')
    .getRecordTypeId();
	
  private static String QUERY_FIELDS = ' Id,KnowledgeArticleId,Title, Summary, BW_Article_Summary__c, BW_Preview_Image__c, LastPublishedDate, ArticleTotalViewCount, BW_myCSP_Article_Id__c, BW_News_Start_Date__c, BW_News_End_Date__c, Valid_Until_Date__c, RecordTypeId, MyCSPArticleName__c, BW_Is_Urgent__c, BW_FrontLine_Focus__c, BW_Home_Page_Display__c ';
       public static List<BWMarketMaster__c> getAllMarkets() {
        return [SELECT Id, MarketPromotedSearchTerm__c FROM BWMarketMaster__c ORDER BY MarketPromotedSearchTerm__c];
    }
    
    public static List<FilterWrapper> getDataCategoryFilterOptions(String categoryName) {
        List<FilterWrapper> categoryFilters = new List<FilterWrapper>();
        List<Schema.DataCategory> childCategories = getChildDataCategories(CATEGORY_OBJECT_TYPE, categoryName);
        System.debug('Category: ' + categoryName + '; Number of children: ' + childCategories.size());  
        for (Schema.DataCategory childcategory :  childCategories) {
            System.debug('Label: ' + childcategory.getLabel() + '; Name: ' + childcategory.getName());  
            categoryFilters.add(new FilterWrapper(childcategory.getLabel(), childcategory.getName()));   
        }
        return categoryFilters;
        
    }    
    public static List<Schema.DataCategory> getChildDataCategories(String objectType, String categoryName) {
        List<Schema.DataCategory> topCategories;
        List<Schema.DataCategory> childCategories;
        List<Schema.DescribeDataCategoryGroupStructureResult> results;
        List<DataCategoryGroupSobjectTypePair> pairs;
        DataCategoryGroupSobjectTypePair pair1 = new DataCategoryGroupSobjectTypePair();
        
        pairs = new List<DataCategoryGroupSobjectTypePair>();
        
        pair1.setSobject(objectType);
        pair1.setDataCategoryGroupName(categoryName);
        pairs.add(pair1);
        
        
        results = Schema.describeDataCategoryGroupStructures(pairs, false); //the false is important here or you just get 'All'
        for (Schema.DescribeDataCategoryGroupStructureResult result : results) {
            topCategories = result.getTopCategories();
            
            for (Schema.DataCategory category : topCategories ) {
                System.debug(category.getName());
                childCategories = category.getChildCategories();
                System.debug('Child Categories retreived for ' + category.getName() + ': ' + childCategories.size());
            }
        }
        return childCategories;
    }    
 
    public static List<FilterWrapper> getEmployeeTypeFilters() {
        List<FilterWrapper> wrapperList = getDataCategoryFilterOptions(KNOWLEDGE_CATEGORY_RESOURCE_TYPE);
        return wrapperList;
    }
    
    public static List<FilterWrapper> getAllMarketFilters() {
     List<FilterWrapper> wrapperList = new List<FilterWrapper>(); 
     List<BWMarketMaster__c> marketList = getAllMarkets();
        for (BWMarketMaster__c market : marketList) {
            wrapperList.add(new FilterWrapper(market.MarketPromotedSearchTerm__c, market.MarketPromotedSearchTerm__c));    
        }
        return wrapperList;
    }
    
    public static List<FilterWrapper> getAllChannelFilters() {
       List<FilterWrapper> wrapperList = getDataCategoryFilterOptions(KNOWLEDGE_CATEGORY_CHANNEL);
       return wrapperList;  
    }
    
    public static List<FilterWrapper> getRoleFilters() {
       List<FilterWrapper> wrapperList = getDataCategoryFilterOptions(KNOWLEDGE_CATEGORY_ROLE);
       return wrapperList;    
    }
    
    
    @AuraEnabled(cacheable=true)
    public static Map<String, List<FilterWrapper>> getViewAsFilters() {
        Boolean userHasViewAsPermission = FeatureManagement.checkPermission('KM_View_As');
        System.debug('User has view as permission ' + userHasViewAsPermission);
        Map<String, List<FilterWrapper>> filterGroupToFilters = new Map<String, List<FilterWrapper>>();
        if (userHasViewAsPermission == false) {
            return filterGroupToFilters;
        }
        system.debug('start getViewAsFilters');
        filterGroupToFilters.put('employeetype', new List<FilterWrapper>());
        filterGroupToFilters.put('market', new List<FilterWrapper>());
        filterGroupToFilters.put('channel', new List<FilterWrapper>());
        filterGroupToFilters.put('role', new List<FilterWrapper>());
        try {
            filterGroupToFilters.get('employeetype').addAll(getEmployeeTypeFilters());
            filterGroupToFilters.get('market').addAll(getAllMarketFilters());
            filterGroupToFilters.get('channel').addAll(getAllChannelFilters());
            filterGroupToFilters.get('role').addAll(getRoleFilters());
        } catch (Exception e) {
            // Removing exception class call as it is failing with too many DML statements and subsequently doesn't send back an error to the UI
            // BWC_ExceptionUtils.handleException(e, true);
            System.debug(LoggingLevel.ERROR, getExceptionString(e));
            throw new LandingPageException('Filter Error: ' + getExceptionString(e));
        } finally {
            system.debug('end getViewAsFilters');
        }
        return filterGroupToFilters;
    }  
    
    
  // START AuraEnabled Methods
  @AuraEnabled(cacheable=true)
  public static List<ArticleWrapper> getTrendingArticles() {
    system.debug('start getTrendingArticles');
    try {
	Set<ID> recTypeIds = getUserRecTypes().keySet();
    Set<String> statuses = new Set<String>();
    Set<ID> marketIds = new Set<ID>();
      // Filter by (Primary) category
      /* String primaryMarket = getPrimary('market');
       Set<ID> marketIds = primaryMarket==null ? new Set<ID>() : new Set<ID>{(ID)primaryMarket}; */
      String primaryCategory = getPrimary('category');
      System.debug('category' +primaryCategory);
      Set<String> categoryIds = primaryCategory == null
        ? new Set<String>()
        : new Set<String>{ primaryCategory };
      return createArticleWrapper(
        marketIds,
        recTypeIds,
        categoryIds,
        statuses,
        '',
        null,
        null,
        false,
        true,
        1
      );
    } catch (Exception e) {
      // Removing exception class call as it is failing with too many DML statements and subsequently doesn't send back an error to the UI
      // BWC_ExceptionUtils.handleException(e, true);
      System.debug(LoggingLevel.ERROR, getExceptionString(e));
      throw new LandingPageException(
        'Trending Articles Error: ' + getExceptionString(e)
      );
    } finally {
      system.debug('end getTrendingArticles');
    }
  }
  @AuraEnabled(cacheable=true)
  public static List<ArticleWrapper> searchArticles(
    String searchText,
    String sortBy,
    String filterBy,
    Integer currentPage,
    String startDate,
    String endDate
  ) {
    system.debug('start searchArticles');
    try {
      ArticleSearchWrapper searchWrapper = new ArticleSearchWrapper(searchText, sortBy, filterBy, currentPage,
                                              startDate, endDate);
      /*if (!String.isEmpty(searchText)) {    
      UserSettingHelper.upsertUserSetting(UserInfo.getUserId(), searchText, sortBy, filterBy, currentPage,
                                              startDate, endDate);
      }  else {
          System.debug('No search terms selected');
      }       
      System.debug('Search Wrapper: ' + searchWrapper);  
      User_Setting__c userSetting = UserSettingHelper.getUserSetting(UserInfo.getUserId());
      System.debug('User Setting: ' + userSetting);*/
      Map<String, List<String>> filterGroupToFiltersChecked = new Map<String, List<String>>();
      Set<ID> recTypeIds = new Set<ID>();
      Set<ID> marketIds = new Set<ID>();
      Set<String> categoryIds = new Set<String>();
      Set<String> statuses = new Set<String>();
      Date fromDate;
      Date toDate;
      if (filterBy != '') {
        filterGroupToFiltersChecked = (Map<String, List<String>>) json.deserialize(
          filterBy,
          Map<String, List<String>>.class
        );
      }
      // Get type filters which are kav record types
      if (
        filterGroupToFiltersChecked.get('typeFilters') != null &&
        filterGroupToFiltersChecked.get('typeFilters').size() > 0
      )
        recTypeIds = new Set<ID>(
          (List<ID>) filterGroupToFiltersChecked.get('typeFilters')
        );
      else {
        recTypeIds = getUserRecTypes().keySet();
      }
      // Get user markets (we only use markets for filters not original search query)
      if (
        filterGroupToFiltersChecked.get('marketFilters') != null &&
        filterGroupToFiltersChecked.get('marketFilters').size() > 0
      )
        marketIds = new Set<ID>(
          (List<ID>) filterGroupToFiltersChecked.get('marketFilters')
        );
      // Get channel filter
      if (
        filterGroupToFiltersChecked.get('categoryFilters') != null &&
        filterGroupToFiltersChecked.get('categoryFilters').size() > 0
      )
        categoryIds = new Set<String>(
          filterGroupToFiltersChecked.get('categoryFilters')
        );
      //Get Status Filters
      if (
        filterGroupToFiltersChecked.get('statusFilters') != null &&
        filterGroupToFiltersChecked.get('statusFilters').size() > 0
      )
        statuses = new Set<String>(
          filterGroupToFiltersChecked.get('statusFilters')
        );    
      //Get dates filter
      if(!String.isBlank(startDate) && !String.isBlank(endDate)){
         fromDate= Date.valueOf(startDate);
         toDate = Date.valueOf(endDate);
      }
      return createArticleWrapper(
        marketIds,
        recTypeIds,
        categoryIds,
        statuses,
        searchText,
        fromDate,
        toDate,
        true,
        false,
        currentPage
      );
      
    } catch (Exception e) {
      // Removing exception class call as it is failing with too many DML statements and subsequently doesn't send back an error to the UI
      // BWC_ExceptionUtils.handleException(e, true);
        System.debug(LoggingLevel.ERROR, getExceptionString(e));
        System.debug('SearchException: ' + e.getLineNumber() + e.getStackTraceString() + e.getCause() + e.getTypeName() + e.getMessage())
            ;
        makeLog(getExceptionString(e), null, null); 
        /*List<Object> params = new List<Object>{'KMSearch',  null, JSON.serialize(e)};
		LogMessage logMessage = new LogMessage(BWC_Constants.OPUS_NEBULA_MESSAGE_TEMPLATE, params);
        Logger.error(logMessage).setTopics(new List<String>{'KMSearch'});
		Logger.saveLog();*/
      throw new AuraHandledException(
        'Error searching articles.  Please contact support and provide details of your search criteria.'
      );
    } finally {
      system.debug('end searchArticles');
    }
  }
  @AuraEnabled(cacheable=true)
   public static Map<String, List<FilterWrapper>> getFilters() {
    System.debug('Get Filters called');
    //User_Setting__c userSetting = UserSettingHelper.getUserSetting(UserInfo.getUserId());
    Map<String, List<FilterWrapper>> filterGroupToFilters = new Map<String, List<FilterWrapper>>();
    system.debug('start getFilters');
    filterGroupToFilters.put('type', new List<FilterWrapper>());
    filterGroupToFilters.put('market', new List<FilterWrapper>());
    filterGroupToFilters.put('category', new List<FilterWrapper>());
    filterGroupToFilters.put('status', new List<FilterWrapper>());  
    filterGroupToFilters.put('searchText', new List<FilterWrapper>());  
    filterGroupToFilters.put('startDate', new List<FilterWrapper>());  
    filterGroupToFilters.put('endDate', new List<FilterWrapper>());  
    /*System.debug('UserSetting: ' + userSetting);  
    if (userSetting != null) {
      System.debug('User Setting ' + userSetting); 
        try {
            filterGroupToFilters = getUserSettingFilters(userSetting, filterGroupToFilters);
            System.debug(filterGroupToFilters);
        } catch (Exception e) {
          // Removing exception class call as it is failing with too many DML statements and subsequently doesn't send back an error to the UI
          // BWC_ExceptionUtils.handleException(e, true);
          System.debug(LoggingLevel.ERROR, getExceptionString(e));
          throw new LandingPageException('UserSettingFilter Error: ' + getExceptionString(e));
        } finally {
          system.debug('end getUserSettingFilters');
        }  
    } else {
        System.debug('No user setting found');
        */try {
          filterGroupToFilters.get('type').addAll(getTypeFilters());
          filterGroupToFilters.get('market').addAll(getMarketFilters());
          filterGroupToFilters.get('category').addAll(getCategoryFilters());
          filterGroupToFilters.get('status').addAll(getStatusFilters());
        } catch (Exception e) {
          // Removing exception class call as it is failing with too many DML statements and subsequently doesn't send back an error to the UI
          // BWC_ExceptionUtils.handleException(e, true);
          System.debug(LoggingLevel.ERROR, getExceptionString(e));
          throw new LandingPageException('Filter Error: ' + getExceptionString(e));
        } finally {
          system.debug('end getFilters');
        }
    //}  
    System.debug('filterGroupToFilters: ' + filterGroupToFilters);    
    return filterGroupToFilters;
  }
    
    public static String getPrimary(String filterGroup) {
    if (filterGroup == 'market') {
      for (FilterWrapper fw : getMarketFilters()) {
        if (fw.label.contains('(Primary)')) {
          return fw.value;
        }
      }
    }
    if (filterGroup == 'category') {
      for (FilterWrapper fw : getCategoryFilters()) {
        if (fw.label.contains('(Primary)')) {
          return fw.value;
        }
      }
    }
    return null;
  }
  @AuraEnabled(cacheable=true)
  public static Boolean isSandbox() {
    Organization org = [SELECT isSandbox FROM Organization];
    system.debug('isSandbox=' + org.isSandbox);
    return org.IsSandbox;
  }
  @AuraEnabled
  public static void markArticleRead(String kavId) {
    Knowledge__kav article = [SELECT BW_Home_Page_Display__c FROM Knowledge__kav WHERE Id =: kavId];
    //Empty session cache when an article is read
    if(article.BW_Home_Page_Display__c == true){
      Cache.SessionPartition sessionAssignedPart = Cache.Session.getPartition('local.KMAssignedSession');
      if (sessionAssignedPart.contains('assignedArticle')){
        sessionAssignedPart.remove('assignedArticle');
      }
      if (sessionAssignedPart.contains('frontLineArticle')){
        sessionAssignedPart.remove('frontLineArticle');
      }
    }
    futureMarkArticleRead(kavId);
  }
  //Future method
  @future
  public static void futureMarkArticleRead(String kavId) {
    try {
      upsert new BW_KM_Lifecycle_Helper__c(
        Id = getKMHelper(kavId),
        BW_Article_Viewed__c = true,
        BW_Knowledge__c = kavId,
        BW_User__c = Userinfo.getuserId()
      );
    } catch (Exception e) {
      // Removing exception class call as it is failing with too many DML statements and subsequently doesn't send back an error to the UI
      // BWC_ExceptionUtils.handleException(e, true);
      System.debug(LoggingLevel.ERROR, getExceptionString(e));
      throw new LandingPageException('markArticleRead Error: ' + getExceptionString(e));
    }
  }
  private static String getKMHelper(String knowledgeId){
    try{
      BW_KM_Lifecycle_Helper__c helperRecord = [SELECT Id 
                                                FROM BW_KM_Lifecycle_Helper__c 
                                                WHERE BW_User__c = :Userinfo.getuserId() AND BW_Knowledge__c = :knowledgeId
                                                LIMIT 1];
      return helperRecord.Id;
    }catch(exception e){
      return null;
    } 
  }
  // END AuraEnabled Methods

  // START Aura Helpers
  /* This method finds articles in 4 steps: Search.SuggestedResults, SOQL (filters, stats), SOSL and SOQL (filters, stats)
If suggestedResults is less than 12 or the SOQL filters reduce suggestedResults to less than, fill the rest with SOSL 
We needed to use SOQL filters as market and status filters go against child tables which can only be achieved with SOQL 
This COULD be refactored to get all the filters beforehand and then use raw IDs in SOSL filter */
  private static List<ArticleWrapper> createArticleWrapper(
    Set<ID> marketIds,
    Set<ID> recTypeIds,
    Set<String> categoryIds,
    Set<String> statuses,
    String searchText,
    Date startDate,
    Date endDate,
    Boolean getStats,
    Boolean isTrending,
    Integer currentPage
  ) {
      if (searchText != null && searchText.trim().length() < 3) {
          searchText = searchText.trim();
      }
      if ((String.isBlank(searchText) || searchText.length() < 3) && !isTrending && !statuses.contains('assigned')){
      	return null;
      }
    List<ArticleWrapper> articleItems = new List<ArticleWrapper>();
    Set<Knowledge__kav> kavArticles = new Set<Knowledge__kav>();
    Set<Id> suggestedArticlesId = new Set<Id>();
    Set<Id> searchedArticlesId = new Set<Id>();
    // Suggest and Search Collections
    Map<ID, Knowledge__kav> suggestedResultsToBeSorted = new Map<ID, Knowledge__kav>();
    List<ID> kavIdsFromSearch = new List<ID>();
    Map<ID, Map<String, Integer>> kaIdToStatsMap = new Map<ID, Map<String, Integer>>();
    ID currentUserId = UserInfo.getUserId();
    String categoryString = '';
    if (!categoryIds.isEmpty()) {
      //convert set to raw string to use with data category filter
      categoryString = String.join(new List<String>(categoryIds), ',');
    }
    //Base SOQL query base recType filters START
    String baseQuery = '';
    baseQuery += ' select ' + getArticleWrapperFields();
    baseQuery += ', (select id from BW_KM_Lifecycle_Helper__r where BW_Article_Viewed__c = true and BW_User__c = :currentUserId )';
    baseQuery += ' FROM Knowledge__kav where publishstatus=\'Online\'';
    if (marketIds.size() > 0) {
      baseQuery += ' AND Id IN (select knowledge__c from bwmarketassociation__c where bwmarketmaster__c IN :marketIds)';
    }
    if(!recTypeIds.isEmpty()){
      baseQuery += ' AND RecordTypeId IN :recTypeIds';
    }
    //Base SOQL query with base recType filters END
    // Status Filters START
    if (!statuses.isEmpty()) {
      baseQuery += statuses.contains('urgent')
        ? ' AND BW_Is_Urgent__c = true'
        : '';
      baseQuery += statuses.contains('assigned')
        ? ' AND BW_Home_Page_Display__c = true'
        : '';
      if (statuses.contains('unread')) {
        baseQuery += ' AND id NOT IN (select BW_Knowledge__c from BW_KM_Lifecycle_Helper__c where BW_Article_Viewed__c = true and BW_User__c = :currentUserId )';
      }
    }
    //Base SOQL query with Date filters
    if(startDate != null && endDate != null){
      baseQuery += ' AND DAY_ONLY(LastPublishedDate) >= :startDate AND DAY_ONLY(LastPublishedDate) <= :endDate';
    }
    // Get Suggested Results and keep track of kavIds returned
    if (searchText != '' && searchText != null && searchText.length() > 2){
            suggestedArticlesId = getSuggestedArticles(searchText, categoryIds, currentPage);
            baseQuery += ' AND Id IN :suggestedArticlesId';
        }
    //Data category filters
    if (categoryString != '') {
      baseQuery += ' WITH DATA CATEGORY Channel__c ABOVE (' + categoryString + ')';
    }
    //Commenting Order by clause as it is putting the relevant articles at the bottom of a list if publish date is months ago
    //baseQuery += ' ORDER BY LastPublishedDate DESC';
    // We expand the query results as they click view more / increment currentPAge
    baseQuery += ' LIMIT ' + (12 * currentPage);
    // Trending Articles
    if (isTrending) {
      // Build a stripped down query for trending articles
      kavArticles = getTrendingArticles(marketIds, recTypeIds, categoryString);
    } else {
      system.debug('BASE QUERY :::' + baseQuery);
        // Ensure results from SOQL are sorted by original suggested order
      try {
      suggestedResultsToBeSorted.putAll((List<Knowledge__kav>)Database.query(baseQuery));
      } catch (Exception e) {
          System.debug('suggestedResultsToBeSortedError: ' + getExceptionString(e));
          throw e;
      }
          kavArticles.addAll(suggestedResultsToBeSorted.values());
    }
    //Sort articles by recommended first
    if (searchText != ''){
      kavArticles = new Set<Knowledge__kav>();
      for (ID articleId : suggestedArticlesId){
          // Checking for null as search results may be larger than soql results (due to filters)
          if (suggestedResultsToBeSorted.get(articleId) != null){
              kavArticles.add(suggestedResultsToBeSorted.get(articleId));
          }
      }
    }
    // We want to get additional SOSL results, if any
      if (searchText != null && searchText.length() >= 2) {
        if (searchText != '' &&   (kavArticles.size() < (12 * currentPage))) {
          searchedArticlesId = searchSOSL(
            searchText,
            categoryString,
            currentPage,
            suggestedArticlesId
          );
          //Replacing base query with SOSL results and appending
          baseQuery = baseQuery.replace(
            ' AND Id IN :suggestedArticlesId',
            ' AND Id IN :searchedArticlesId'
          );
    }   
      baseQuery = baseQuery.replace(
        ' LIMIT ' + (12 * currentPage),
        ' LIMIT ' + ((12 * currentPage) - kavArticles.size())
      );
      baseQuery += ' UPDATE TRACKING';
      system.debug('SOSL Base Query ::: '+ baseQuery);
      System.debug('Running query in createArticleWrapper ');
      try {
      	kavArticles.addAll((List<Knowledge__kav>) Database.query(baseQuery));
      } catch (Exception e) {
          
          System.debug('createArticleWrapperError: ' + getExceptionString(e));
          throw e;
      }    
    }
    // Gather the concrete ka IDs to use for child/count queries for vote and comment
    if (kavArticles.size() > 0) {
      Map<Id, Id> kaIds = getParentArticleIdMap(new List<Knowledge__kav>(kavArticles));
     
      kaIdToStatsMap = getArticleStats(kaIds, baseQuery);
    }
    // Main loop to hydrate ArticleWrapper to send back to UI
    for (Knowledge__kav kav : kavArticles) {
      ArticleWrapper aw = new ArticleWrapper();
      aw.id = kav.id;
      aw.title = kav.Title;
      aw.summary = kav.BW_Article_Summary__c != null
        ? StripHTML(kav.BW_Article_Summary__c)
        : '';
      aw.previewImage = (kav.BW_Preview_Image__c != null)
        ? (kav.BW_Preview_Image__c)
            .substringAfter('src="')
            .replace('&amp;', '&')
            .substringBefore('"')
        : '';
      aw.likeCount = kaIdToStatsMap.get(kav.knowledgearticleid).get('votes');
      aw.commentCount = kaIdToStatsMap.get(kav.knowledgearticleid)
        .get('comments');
      aw.viewCount = kav.ArticleTotalViewCount;
      aw.lastPublishedDate = kav.LastPublishedDate;
      aw.lastPublishedDateString = kav.LastPublishedDate.format('MM.dd.YY');
      aw.myCspName = kav.MyCSPArticleName__c != null
        ? '#' + kav.MyCSPArticleName__c.right(6).remove('_') + ' '
        : '';
      aw.validDates = calculateValidity(kav);
      if (suggestedArticlesId.contains(kav.Id)){
                aw.recommended = true;
            }
      aw.isUrgent = kav.BW_Is_Urgent__c;
      aw.isRead = (kav.BW_KM_Lifecycle_Helper__r.size() > 0 ||
        (!kav.BW_Home_Page_Display__c && !kav.BW_FrontLine_Focus__c))
        ? true
        : false;
      articleItems.add(aw);
    }
    return articleItems;
  }
  private static Set<Knowledge__kav> getTrendingArticles(
    Set<ID> marketIds,
    Set<ID> recTypeIds,
    String categoryString
  ) {
    String hashedCategory = '';
    String primaryMarket = '';
    Set<ID> cachedIds = new Set<ID>();
    List<Knowledge__kav> articlesList = new List<Knowledge__kav>();
    Set<Knowledge__kav> finalArticles = new Set<Knowledge__kav>();
    ID currentUserId = UserInfo.getUserId();

    // getting primary markets here instead of from the passed in parameter (as the passed in parameter is null because we removed ALL market filtering in 12/15 release)
    primaryMarket = getPrimary('market');
    String primaryCategory = getPrimary('category');
    // Need to hash string as cache keys CAN ONLY contain alphanumeric (data cat names contain '_')
    if(String.isNotBlank(primaryCategory)){
      hashedCategory = CreateHashedString(primaryCategory);
    }
    String hashedGlobalCategory = CreateHashedString('All');

    cachedIds = getTrendingCacheData(primaryMarket, hashedCategory, hashedGlobalCategory);
    System.debug('cachedIds'+cachedIds);
    if (!cachedIds.isEmpty()){
      // Start query builder
      String baseQuery = '';
      baseQuery += ' SELECT ' + getArticleWrapperFields();
      baseQuery += ' FROM Knowledge__kav ';
      baseQuery += ' WHERE publishstatus=\'Online\'';
      baseQuery += ' AND knowledgearticleid IN :cachedIds';
      articlesList = Database.query(baseQuery);
        finalArticles.addAll(articlesList);
    }
    System.debug('finalArticles'+finalArticles);
    return finalArticles;
  }

  private static Set<Id> searchSOSL(
    String searchText,
    String categoryString,
    Integer currentPage,
    Set<Id> idsFromSuggestedAlready
  ) {
    Search.SearchResults searchResults;
    Set<Id> searchedArticlesId = new Set<Id>();
    Map<ID, Search.SearchResult> kavIdToSearchResult = new Map<ID, Search.SearchResult>();
    
    String searchTextEscaped = String.escapeSingleQuotes(searchText);
    String searchQuery = 'FIND \'' + searchTextEscaped + '\' IN ALL FIELDS';
    searchQuery += ' RETURNING Knowledge__kav(Id, KnowledgeArticleId, Title ';
    searchQuery += ' WHERE PublishStatus=\'Online\' AND Language = \'en_US\'';
    
    if (!idsFromSuggestedAlready.isEmpty()){
            searchQuery += ' AND ID NOT IN :idsFromSuggestedAlready';
    }
    //Commenting Order by clause as it is putting the relevant articles at the bottom of a list if publish date is months ago
    //searchQuery += ' ORDER BY LastPublishedDate DESC)';
    searchQuery += ')';
    if (String.isNotBlank(categoryString)){
            searchQuery += ' WITH DATA CATEGORY Channel__c ABOVE (' + categoryString + ')';
        }
    //searchQuery += ' WITH SNIPPET (target_length=300)';
    searchQuery += ' LIMIT ';
    searchQuery += (12 * currentPage);
    //searchQuery += ' UPDATE TRACKING ';
    system.debug('SOSL QUERY ::: '+ searchQuery);
    searchResults = Search.find(searchquery);
    List<Search.SearchResult> articlelist = searchResults.get('Knowledge__kav');
    for (Search.SearchResult searchResult : articlelist) {
      Knowledge__kav kav = (Knowledge__kav) searchResult.getSObject();
      searchedArticlesId.add(kav.Id);
      system.debug('SOSL ARTICLE ::: ' + kav.Id + ':: '+kav.Title);
    }
    system.debug('SEARCH Results ::: '+ searchedArticlesId.size());
    return searchedArticlesId;
  }
  private static Set<Id> getSuggestedArticles(String searchText, Set<String> channelIds, Integer currentPage){
        //No need to escape quotation marks as suggested search has in-built capability to take care of it
        //String searchTextEscaped = String.escapeSingleQuotes(searchText);
        Set<Id> suggestedArticleIds = new Set<Id>();
        Search.SuggestionOption options = new Search.SuggestionOption();
        Search.KnowledgeSuggestionFilter filters = new Search.KnowledgeSuggestionFilter();
        Search.SuggestionResults suggestionResults;

        filters.setLanguage('en_US');
        filters.setPublishStatus('Online');
        for (String channel : channelIds){
            filters.addDataCategory('Channel', channel.replace('__c', ''));
        }
        options.setFilter(filters);
        options.setLimit(12 * currentPage);
        suggestionResults = Search.suggest(searchText, 'KnowledgeArticleVersion', options);
        for (Search.SuggestionResult sr : suggestionResults.getSuggestionResults()){
            KnowledgeArticleVersion kav = new KnowledgeArticleVersion();
            kav = (KnowledgeArticleVersion)sr.getSObject();
            suggestedArticleIds.add(kav.Id);
            system.debug('SUGGESTED ARTICLE ::: '+ kav.Id + ':: ' +kav.Title);
        }
        if (!Test.isRunningTest()){
          System.debug('TOTAL SUGGESTED RESULTS ::: '+ suggestedArticleIds.size());
            return suggestedArticleIds;
        } else{
            return new Set<Id>();
        }
    }
  private static String getArticleWrapperFields() {
    return QUERY_FIELDS;
  }
  private static Map<ID, Map<String, Integer>> getArticleStats(Map<Id, Id> parentIdMap, String soqlString) {
    Map<ID, Map<String, Integer>> kaIdToStatsMap = new Map<ID, Map<String, Integer>>();
    Set<Id> kaIds = parentIdMap.keySet();
    System.debug('Article ids for votes: ' + parentIdMap.keySet());
      
      for (ID kaId : kaIds) {
      kaIdToStatsMap.put(kaId, new Map<String, Integer>());
      // setting everything to 0
      kaIdToStatsMap.get(kaid).put('votes', 0);
      kaIdToStatsMap.get(kaid).put('views', 0);
      kaIdToStatsMap.get(kaid).put('comments', 0);
    } 
      
      Boolean hasCustomPermission = FeatureManagement.checkPermission('KM_Old_Vote');
      System.debug(Userinfo.getName() + ' has permission to run oldvotecode: ' + hasCustomPermission);
      
      try {
          if (!hasCustomPermission) {
          	kaIdToStatsMap = ArticleSearchDataService.getArticleVoteCount(parentIdMap,kaIdToStatsMap);    
          } else if ( hasCustomPermission) {
              for (Knowledge__ka ka : [
                  SELECT
                    id,
                    (
                      SELECT type, parentid
                      FROM votes
                      WHERE parentid IN :kaIds AND type IN ('1', '5')
                    )
                  FROM Knowledge__ka
                  WHERE id IN :kaIds
                ]) {
                  if (!ka.votes.isEmpty()) {
                    Integer overallVotes = 0;
                    for (Vote v : ka.votes) {
                      overallVotes += v.type == '5' ? 1 : -1;
                    }
                    overallVotes = overallVotes < 0 ? 0 : overallVotes;
                    kaIdToStatsMap.get(ka.id).put('votes', overallVotes);
                    System.debug('Overall vote map: ' + kaIdToStatsMap);
                  }
                }
 			} 
              
      } catch (Exception e) {
         
          System.debug('getArticleStatsException: Overall votes' + getExceptionString(e));
          makeLog(getExceptionString(e), soqlString, kaIds);
          //throw e;
      }
    for (Knowledge__ViewStat viewstat : [
      SELECT parentid, viewcount
      FROM knowledge__viewstat
      WHERE parentid IN :kaids AND channel = 'AllChannels'
    ]) {
      kaIdToStatsMap.get(viewstat.parentid).put('views', viewstat.viewcount);
    }
      try{
      for (AggregateResult aggr : [
      SELECT knowledge__r.knowledgearticleid kaid, count(id) articleComments
      FROM KM_Article_Feedback__c
      WHERE knowledge__r.knowledgearticleid IN :kaIds
      GROUP BY knowledge__r.knowledgearticleid
    ]) {
      Integer commentCount = Integer.valueOf(
          (Decimal) aggr.get('articleComments')
        ) == null
        ? 0
        : Integer.valueOf((Decimal) aggr.get('articleComments'));
      if ((Id) aggr.get('kaid') != null) {
        kaIdToStatsMap.get((Id) aggr.get('kaid')).put('comments', commentCount);
      }
    }} catch (Exception e) {
          System.debug('getArticleStatsException: comment counts' + getExceptionString(e));
        throw e;
      }
      
    return kaIdToStatsMap;
  }
  private static string StripHTML(String htmlString) {
    String backlash = '\n';
    String backlashReplacement = '---n';
    htmlString = htmlString.replaceAll(backlash, backlashReplacement);
    htmlString = htmlString.stripHtmlTags();
    htmlString = htmlString.replaceAll(backlashReplacement, backlash);
    return htmlString;
  }
  private static String calculateValidity(Knowledge__kav knowledgeObj) {
    String valid = '';
    DateTime startTime;
    DateTime endTime;
    if (knowledgeObj.RecordTypeId == NEWS_ARTICLEID) {
      startTime = knowledgeObj.BW_News_Start_Date__c;
      endTime = knowledgeObj.BW_News_End_Date__c;
    } else {
      startTime = knowledgeObj.LastPublishedDate;
      endTime = DateTime.newInstance(
        knowledgeObj.Valid_Until_Date__c,
        Time.newInstance(0, 0, 0, 0)
      );
    }
    if (startTime != null) {
      valid += startTime.format('MM.dd.YY');
      //TODO: REMOVE IT.
    } else {
      valid += knowledgeObj.LastPublishedDate.format('MM.dd.YY');
    }
    valid += ' - ';
    if (endTime != null) {
      valid += endTime.format('MM.dd.YY');
    }
    return valid;
  }
  private static String getExceptionString(Exception exceptionCaught) {
    String errorMsg = '';
    errorMsg += 'Cause=' + String.valueOf(exceptionCaught.getCause()) + ' ';
    errorMsg += 'Line Number=' + exceptionCaught.getLineNumber() + ' ';
    errorMsg += 'Message=' + exceptionCaught.getMessage() + ' ';
    errorMsg += 'Stack Trace=' + exceptionCaught.getStackTraceString() + ' ';
    errorMsg += 'Type Name=' + exceptionCaught.getTypeName() + ' ';
    return errorMsg;
  }
  // END Aura Helpers

  // START Filter Helpers
  private static List<FilterWrapper> getTypeFilters() {
    List<FilterWrapper> typeFilters = new List<FilterWrapper>();
    Map<Id, Schema.RecordTypeInfo> rtMapById = getUserRecTypes();
    for (Id rtId : rtMapById.keySet()) {
      if (
        //rtMapById.get(rtId).isAvailable() &&
        rtMapById.get(rtId).getName() != 'Master'
      ) {
        FilterWrapper fw = new FilterWrapper();
        fw.label = rtMapById.get(rtId).getName();
        fw.value = rtMapById.get(rtId).getRecordTypeId();
        typeFilters.add(fw);
      }
    }
    return typeFilters;
  }
  private static List<FilterWrapper> getMarketFilters() {
    List<FilterWrapper> marketFilters = new List<FilterWrapper>();
    List<FilterWrapper> marketFiltersPrimary = new List<FilterWrapper>();
    for (BWUserMarketAssociation__c userMarket : getUserMarkets().values()) {
      FilterWrapper filter = new FilterWrapper(
        userMarket.BWMarketMaster__r.MarketPromotedSearchTerm__c,
        userMarket.BWMarketMaster__c
      );
      if (userMarket.primary__c && !marketFilters.isEmpty()) {
        filter.label += ' (Primary)';
        filter.checked = true;
        marketFilters.add(0, filter); 
      } else if(userMarket.primary__c && marketFilters.isEmpty()){
        filter.label += ' (Primary)';
        filter.checked = true;
        marketFilters.add(filter);
      } else {
        marketFilters.add(filter);
      }
    }
    return marketFilters;
  }
  /*private static List<FilterWrapper> getMarketFilters() {
    List<FilterWrapper> marketFilters = new List<FilterWrapper>();
    List<FilterWrapper> marketFiltersPrimary = new List<FilterWrapper>();
    for (BWUserMarketAssociation__c userMarket : getUserMarkets().values()) {
      if (userMarket.primary__c) {
        marketFiltersPrimary.add(
          new FilterWrapper(
            userMarket.BWMarketMaster__r.MarketPromotedSearchTerm__c +
            ' (Primary)',
            userMarket.BWMarketMaster__c
          )
        );
      } else {
        marketFilters.add(
          new FilterWrapper(
            userMarket.BWMarketMaster__r.MarketPromotedSearchTerm__c,
            userMarket.BWMarketMaster__c
          )
        );
      }
    }
    for (Integer i = marketFiltersPrimary.size() - 1; i >= 0; i--) {
      if (!marketFilters.isEmpty()) {
        marketFilters.add(
          0,
          new FilterWrapper(
            marketFiltersPrimary[i].label,
            marketFiltersPrimary[i].value
          )
        );
      } else {
        marketFilters.add(
          new FilterWrapper(
            marketFiltersPrimary[i].label,
            marketFiltersPrimary[i].value
          )
        );
      }
    }
    return marketFilters;
  }*/
  private static List<FilterWrapper> getCategoryFilters() {
    List<FilterWrapper> categoryFilters = getUserCategories();
    return categoryFilters;
  }
  private static List<FilterWrapper> getStatusFilters() {
    List<FilterWrapper> statusFilters = new List<FilterWrapper>();
    statusFilters.add(new FilterWrapper('Assigned', 'assigned'));
    statusFilters.add(new FilterWrapper('Unread', 'unread'));
    statusFilters.add(new FilterWrapper('Urgent', 'urgent'));
    return statusFilters;
  }
  private static Map<Id, Schema.RecordTypeInfo> getUserRecTypes() {
    Schema.DescribeSObjectResult d = Schema.SObjectType.Knowledge__kav;
    Map<Id, Schema.RecordTypeInfo> rtMapById = new Map<Id, Schema.RecordTypeInfo>();
    rtMapById = d.getRecordTypeInfosById();
    return rtMapById;
  }
  private static Map<ID, BWUserMarketAssociation__c> getUserMarkets() {
    Map<ID, BWUserMarketAssociation__c> marketIdUserMarket = new Map<ID, BWUserMarketAssociation__c>();
    for (BWUserMarketAssociation__c userMarket : [
      SELECT
        Primary__c,
        BWMarketMaster__c,
        BWMarketMaster__r.MarketPromotedSearchTerm__c
      FROM BWUserMarketAssociation__c
      WHERE UserId__c = :UserInfo.getUserId()
      ORDER BY BWMarketMaster__r.MarketPromotedSearchTerm__c
    ]) {
      //Below check is to handle duplicate markets issue
      if(!marketIdUserMarket.containsKey(userMarket.BWMarketMaster__c) || userMarket.Primary__c == true){
        marketIdUserMarket.put(userMarket.BWMarketMaster__c, userMarket);
      }
    }
    return marketIdUserMarket;
  }
  private static List<FilterWrapper> getUserCategories() {
    // Roles and channels are confusing to me right now but they both seem to be housed in the same table after a lot of rework of data categories
    // Just to add more confusion we are calling these categories in the UI :)
    List<FilterWrapper> userCategories = new List<FilterWrapper>();
    String defaultChannelId = '';
    Set<String> uniqueCategories = new Set<String>();
    // Get Employee Roles
    Map<String, List<String>> roleNameToRoleValue = new Map<String, List<String>>();
    List<String> flattenedRoleValues = new List<String>();
    for (BWEmployeeRole__c er : [
      SELECT rolename__c, rolevalue__c, userid__r.BWDefaultKMChannel__c
      FROM BWEmployeeRole__c
      WHERE KMProcessingStatus__c = 'Completed Add' AND userid__r.user__r.Id = :UserInfo.getUserId()
    ]) {
      if (!roleNameToRoleValue.containsKey(er.rolename__c)) {
        roleNameToRoleValue.put(
          er.rolename__c,
          new List<String>{ er.rolevalue__c }
        );
      } else {
        roleNameToRoleValue.get(er.rolename__c).add(er.rolevalue__c);
      }
      flattenedRoleValues.add(er.rolevalue__c);
     
     if (er.userid__c != null && er.userid__r.BWDefaultKMChannel__c != '')
        defaultChannelId = er.userid__r.BWDefaultKMChannel__c;
    }
    //Get BWEmployee Roles
    String primaryPermSetID = '';
    List<BW_Channel_Mapping__c> channelMapping = new List<BW_Channel_Mapping__c>();
    channelMapping = [
      SELECT KM_Channel_ID__c, Permission_Set_Id__c
      FROM BW_Channel_Mapping__c
      WHERE KM_Channel_ID__c = :defaultChannelId
    ];
    if (!channelMapping.isEmpty()) {
      primaryPermSetID = channelMapping[0].Permission_Set_Id__c;
    }

    List<BWRolePermissions__c> employeeRolePerms = new List<BWRolePermissions__c>();
    BWRolePermissions__c primaryPerm = new BWRolePermissions__c();
    Map<String, String> channelLabeltoApiName = getAllChannelCategoriesMap();
    employeeRolePerms = [
      SELECT
        id,
        rolename__c,
        rolevalue__c,
        permissionsetname__c,
        PermissionSetId__c
      FROM BWRolePermissions__c
      WHERE
        (rolename__c IN :roleNameToRoleValue.keySet()
        AND rolevalue__c IN :flattenedRoleValues
        AND systempermissionset__c = FALSE)
        OR PermissionSetId__c =: primaryPermSetID
      ORDER BY permissionsetname__c ASC
    ];
    // TODO: change this to group by perm set name
    for (BWRolePermissions__c perm : employeeRolePerms) {
      system.debug(perm.permissionsetname__c);
      String filterValue = channelLabeltoApiName.get(perm.permissionsetname__c);
      if (filterValue == null)
        continue;
      //filterValue = filterValue.replaceAll('[^a-zA-Z0-9\\s+]', '_').replaceAll('__', '_').replaceAll(' ', '_');
      if (perm.PermissionSetId__c != primaryPermSetID) {
        if (!uniqueCategories.contains(perm.permissionsetname__c)) {
          userCategories.add(
            new FilterWrapper(perm.permissionsetname__c, filterValue + '__c')
          );
        }
        uniqueCategories.add(perm.permissionsetname__c);
      } else {
        primaryPerm = perm;
      }
    }
    if (primaryPerm.permissionsetname__c != null) {
      String filterValue = channelLabeltoApiName.get(
        primaryPerm.permissionsetname__c
      );
      if (!userCategories.isEmpty()) {
        userCategories.add(
          0,
          new FilterWrapper(
            primaryPerm.permissionsetname__c + ' (Primary)',
            filterValue + '__c', true
          )
        );
      } else {
        userCategories.add(
          new FilterWrapper(
            primaryPerm.permissionsetname__c + ' (Primary)',
            filterValue + '__c', true
          )
        );
      }
    }
    return userCategories;
  }
  public static Map<String, String> getAllChannelCategoriesMap() {
    Map<String, String> channelLabeltoApiName = new Map<String, String>();
    List<DescribeDataCategoryGroupResult> describeCategoryResult;
    List<DescribeDataCategoryGroupStructureResult> describeCategoryStructureResult;
    try {
      //Creating the list of sobjects to use for the describe
      //call
      List<String> objType = new List<String>();
      objType.add('KnowledgeArticleVersion');
      //Describe Call
      describeCategoryResult = Schema.describeDataCategoryGroups(objType);
      //Using the results and retrieving the information
      for (
        DescribeDataCategoryGroupResult singleResultGroup : describeCategoryResult
      ) {
        //Getting the name of the category
        if (singleResultGroup.getName() == 'Channel') {
          List<DataCategoryGroupSobjectTypePair> pairs = new List<DataCategoryGroupSobjectTypePair>();
          DataCategoryGroupSobjectTypePair p = new DataCategoryGroupSobjectTypePair();
          p.setSobject(singleResultGroup.getSobject());
          p.setDataCategoryGroupName(singleResultGroup.getName());
          pairs.add(p);
          //describeDataCategoryGroupStructures()
          describeCategoryStructureResult = Schema.describeDataCategoryGroupStructures(
            pairs,
            false
          );
          //Getting data from the result
          for (
            DescribeDataCategoryGroupStructureResult singleResult : describeCategoryStructureResult
          ) {
            //Get the top level categories
            DataCategory[] toplevelCategories = singleResult.getTopCategories();
            //Recursively get all the categories
            List<DataCategory> allCategories = getAllCategories(
              toplevelCategories
            );
            for (DataCategory category : allCategories) {
              //Get the name of the category
              category.getName();
              //system.debug('adding datacategory master data: label='+category.getLabel() +' apiName='+category.getName());
              channelLabeltoApiName.put(
                category.getLabel(),
                category.getName()
              );
              //Get the label of the category
              category.getLabel();
            }
          }
        }
      }
    } catch (Exception e) {
      return channelLabeltoApiName;
    }
    return channelLabeltoApiName;
  }
   @testVisible
  private static DataCategory[] getAllCategories(DataCategory[] categories) {
    if (categories.isEmpty()) {
      return new List<DataCategory>{};
    } else {
      DataCategory[] categoriesClone = categories.clone();
      DataCategory category = categoriesClone[0];
      DataCategory[] allCategories = new List<DataCategory>{ category };
      categoriesClone.remove(0);
      categoriesClone.addAll(category.getChildCategories());
      allCategories.addAll(getAllCategories(categoriesClone));
      return allCategories;
    }
  }
  // END Filter Helpers
  // 
 /*
   public static Map<String, List<FilterWrapper>> getUserSettingFilters(User_Setting__c userSetting, Map<String, List<FilterWrapper>> filterGroupToFilters) {
      ArticleSearchWrapper wrapper = (ArticleSearchWrapper) JSON.deserialize(userSetting.article_Search_JSON__c, ArticleSearchWrapper.class);
      String filterBy = wrapper.filterBy;
      //  rticle_Search_JSON__c={"startDate":"2021-06-09","sortBy":"","searchText":"kerens","filterBy":"{\"typeFilters\":[\"0126g000000XB76AAG\",\"0120U000001kst6QAA\"],\"marketFilters\":[\"a2G0U0000017BMfUAM\",\"a2G0U0000017BN7UAM\",\"a2G0U0000017BMrUAM\"],\"categoryFilters\":[\"Direct_Sales__c\",\"AT_T_Retail__c\",\"Authorized_Retail__c\"],\"statusFilters\":[\"unread\",\"urgent\"]}","endDate":"2021-06-15","currentPage":1}}
        Map<String, List<String>> filterGroupToFiltersChecked = new Map<String, List<String>>();
      Set<ID> recTypeIds = new Set<ID>();
      Set<ID> marketIds = new Set<ID>();
      Set<String> categoryIds = new Set<String>();
      Set<String> statuses = new Set<String>();
      Date fromDate;
      Date toDate;
      if (filterBy != '') {
        filterGroupToFiltersChecked = (Map<String, List<String>>) json.deserialize(
          filterBy,
          Map<String, List<String>>.class
        );
      }
      // Get type filters which are kav record types
      if (
        filterGroupToFiltersChecked.get('typeFilters') != null &&
        filterGroupToFiltersChecked.get('typeFilters').size() > 0
      ) {
        recTypeIds = new Set<ID>(
          (List<ID>) filterGroupToFiltersChecked.get('typeFilters')
        );
        System.debug('Selected Record type Ids:' + recTypeIds);  
         filterGroupToFilters.get('type').addAll(getUserSelectedTypeFilters(recTypeIds));
    } else {
          filterGroupToFilters.get('type').addAll(getTypeFilters());
          
      }
      // Get user markets (we only use markets for filters not original search query)
      if (
        filterGroupToFiltersChecked.get('marketFilters') != null &&
        filterGroupToFiltersChecked.get('marketFilters').size() > 0
      ) {
        marketIds = new Set<ID>(
          (List<ID>) filterGroupToFiltersChecked.get('marketFilters')
        );
       System.debug('Selected Market Ids:' + marketIds);    
       filterGroupToFilters.get('market').addAll(getUserSelectedMarketFilters(marketIds));

    } else {
        filterGroupToFilters.get('market').addAll(getMarketFilters());
    
      }    
          // Get channel filter
      if (
        filterGroupToFiltersChecked.get('categoryFilters') != null &&
        filterGroupToFiltersChecked.get('categoryFilters').size() > 0
      ) {
        categoryIds = new Set<String>(
          filterGroupToFiltersChecked.get('categoryFilters')
        );
         System.debug('Selected Category Ids:' + categoryIds);    
        filterGroupToFilters.get('category').addAll(getUserSelectedCategoryFilters(categoryIds));
  
      } else {
        filterGroupToFilters.get('category').addAll(getCategoryFilters());
  
      }    
      //Get Status Filters
      if (
        filterGroupToFiltersChecked.get('statusFilters') != null &&
        filterGroupToFiltersChecked.get('statusFilters').size() > 0
      ) {
        statuses = new Set<String>(
          filterGroupToFiltersChecked.get('statusFilters')
        );
        filterGroupToFilters.get('status').addAll(getUserSelectedStatusFilters(statuses));
        System.debug('Selected Status filtes:' + statuses);    
 
      } else {
        filterGroupToFilters.get('status').addAll(getStatusFilters());
      }    
      //Get dates filter
      if(!String.isBlank(wrapper.startDate) && !String.isBlank(wrapper.endDate)){
         fromDate= Date.valueOf(wrapper.startDate);
         toDate = Date.valueOf(wrapper.endDate);
      }
      return filterGroupToFilters;
    }  
  */
  @testVisible  
  private static List<FilterWrapper> getUserSelectedStatusFilters(Set<String> userSelectedStatusFilters) {
    List<FilterWrapper> statusFilters = new List<FilterWrapper>();
    Boolean checked = userSelectedStatusFilters.contains('assigned');   
    statusFilters.add(new FilterWrapper('Assigned', 'assigned', checked));
    checked = userSelectedStatusFilters.contains('unread');    
    statusFilters.add(new FilterWrapper('Unread', 'unread', checked));
    checked = userSelectedStatusFilters.contains('urgent');    
    statusFilters.add(new FilterWrapper('Urgent', 'urgent', checked));
    return statusFilters;
  }
   @testVisible
  private static List<FilterWrapper> getUserSelectedTypeFilters(Set<Id> userselectedRecordTypeIdSet) {
    List<FilterWrapper> typeFilters = new List<FilterWrapper>();
    Map<Id, Schema.RecordTypeInfo> rtMapById = getUserRecTypes();
    System.debug('User Selected Record Types:' + userselectedRecordTypeIdSet);
      for (Id rtId : rtMapById.keySet()) {
     System.debug('Record Type Id: ' +  rtId); 
     if (
        rtMapById.get(rtId).isAvailable() &&
        rtMapById.get(rtId).getName() != 'Master' 
      ) {
        FilterWrapper fw = new FilterWrapper();
        fw.label = rtMapById.get(rtId).getName();
        fw.value = rtMapById.get(rtId).getRecordTypeId();
        System.debug('Record type selected: ' +  userselectedRecordTypeIdSet.contains(rtId));  
        fw.checked = userselectedRecordTypeIdSet.contains(rtId);
        typeFilters.add(fw);
      }
    }
    return typeFilters;
  }  
  
   @testVisible
   private static List<FilterWrapper> getUserSelectedMarketFilters(Set<Id> userSelectedMarketIds) {
    List<FilterWrapper> marketFilters = new List<FilterWrapper>();
    List<FilterWrapper> marketFiltersPrimary = new List<FilterWrapper>();
    for (BWUserMarketAssociation__c userMarket : getUserMarkets().values()) {
        
            Boolean checked = userSelectedMarketIds.contains(userMarket.Id);
            
            FilterWrapper filter = new FilterWrapper(
            userMarket.BWMarketMaster__r.MarketPromotedSearchTerm__c,
            userMarket.BWMarketMaster__c, checked);
                
         
          if (userMarket.primary__c && !marketFilters.isEmpty()) {
            filter.label += ' (Primary)';
            marketFilters.add(0, filter); 
          } else if(userMarket.primary__c && marketFilters.isEmpty()){
            filter.label += ' (Primary)';
            marketFilters.add(filter);
          } else {
            marketFilters.add(filter);
          }
            
    }
    return marketFilters;
  }    
   @testVisible 
   private static List<FilterWrapper> getUserSelectedCategoryFilters(Set<String> userSelectedCategorySet) {
    // Roles and channels are confusing to me right now but they both seem to be housed in the same table after a lot of rework of data categories
    // Just to add more confusion we are calling these categories in the UI :)
    List<FilterWrapper> userCategories = new List<FilterWrapper>();
    String defaultChannelId = '';
    Set<String> uniqueCategories = new Set<String>();
    Boolean checked;
    // Get Employee Roles
    Map<String, List<String>> roleNameToRoleValue = new Map<String, List<String>>();
    List<String> flattenedRoleValues = new List<String>();
    for (BWEmployeeRole__c er : [
      SELECT rolename__c, rolevalue__c, userid__r.BWDefaultKMChannel__c
      FROM BWEmployeeRole__c
      WHERE KMProcessingStatus__c = 'Completed Add' AND userid__r.user__r.Id = :UserInfo.getUserId()
    ]) {
      if (!roleNameToRoleValue.containsKey(er.rolename__c)) {
        roleNameToRoleValue.put(
          er.rolename__c,
          new List<String>{ er.rolevalue__c }
        );
      } else {
        roleNameToRoleValue.get(er.rolename__c).add(er.rolevalue__c);
      }
      flattenedRoleValues.add(er.rolevalue__c);
      if (er.userid__c != null && er.userid__r.BWDefaultKMChannel__c != '')
        defaultChannelId = er.userid__r.BWDefaultKMChannel__c;
    }
    //Get BWEmployee Roles
    String primaryPermSetID = '';
    List<BW_Channel_Mapping__c> channelMapping = new List<BW_Channel_Mapping__c>();
    channelMapping = [
      SELECT KM_Channel_ID__c, Permission_Set_Id__c
      FROM BW_Channel_Mapping__c
      WHERE KM_Channel_ID__c = :defaultChannelId
    ];
    if (!channelMapping.isEmpty()) {
      primaryPermSetID = channelMapping[0].Permission_Set_Id__c;
    }
    List<BWRolePermissions__c> employeeRolePerms = new List<BWRolePermissions__c>();
    BWRolePermissions__c primaryPerm = new BWRolePermissions__c();
    Map<String, String> channelLabeltoApiName = getAllChannelCategoriesMap();
    employeeRolePerms = [
      SELECT
        id,
        rolename__c,
        rolevalue__c,
        permissionsetname__c,
        PermissionSetId__c
      FROM BWRolePermissions__c
      WHERE
        rolename__c IN :roleNameToRoleValue.keySet()
        AND rolevalue__c IN :flattenedRoleValues
        AND systempermissionset__c = FALSE
      ORDER BY permissionsetname__c ASC
    ];
    // TODO: change this to group by perm set name
    for (BWRolePermissions__c perm : employeeRolePerms) {
      String filterValue = channelLabeltoApiName.get(perm.permissionsetname__c);
      if (filterValue == null)
        continue;
      //filterValue = filterValue.replaceAll('[^a-zA-Z0-9\\s+]', '_').replaceAll('__', '_').replaceAll(' ', '_');
      checked = userSelectedCategorySet.contains(filterValue);
      if (perm.PermissionSetId__c != primaryPermSetID) {
        if (!uniqueCategories.contains(perm.permissionsetname__c)) {
          userCategories.add(
            new FilterWrapper(perm.permissionsetname__c, filterValue + '__c', checked)
          );
        }
        uniqueCategories.add(perm.permissionsetname__c);
      } else {
        primaryPerm = perm;
      }
    }
    if (primaryPerm.permissionsetname__c != null) {
      String filterValue = channelLabeltoApiName.get(
        primaryPerm.permissionsetname__c
      );
      checked = userSelectedCategorySet.contains(filterValue);  
      if (!userCategories.isEmpty()) {
        userCategories.add(
          0,
          new FilterWrapper(
            primaryPerm.permissionsetname__c + ' (Primary)',
            filterValue + '__c', checked
          )
        );
      } else {
        checked = userSelectedCategorySet.contains(filterValue);
          userCategories.add(
          new FilterWrapper(
            primaryPerm.permissionsetname__c + ' (Primary)',
            filterValue + '__c', checked
          )
        );
      }
    }
    return userCategories;
  }   
    
    public static Set<Id> getParentArticleIdSet(List<Knowledge__kav> articleList) {
        Set<Id> parentIdSet = new Set<Id>();
        for (Knowledge__kav kav : articleList) {
        	parentIdSet.add(kav.KnowledgeArticleId);
      	}
        return parentIdSet;
    }
    
    public static Map<Id, Id> getParentArticleIdMap(List<Knowledge__kav> articleList) {
        Map<Id, Id> parentIdMap = new Map<Id, Id>();
        for (Knowledge__kav kav : articleList) {
        	parentIdMap.put(kav.KnowledgeArticleId, kav.Id);
      	}
        return parentIdMap;
    }
   
      public static Map<ID, Map<String, Integer>> getArticleVoteCount(Map<Id, Id> parentArticleIdMap, Map<Id, Map<String, Integer>> articleStatsMap) {
        articleStatsMap =  getArticleVoteCount(parentArticleIdMap.keySet(), articleStatsMap);
        Id articleId;
        Integer votes;
        Map<String, Integer> voteMap;
            for (Id parentArticleId : parentArticleIdMap.keySet()) {
            	articleId =  parentArticleIdMap.get( parentArticleId);
                votes = articleStatsMap.get(parentArticleId).get('votes');
                System.debug('Article Id: ' + articleId + '; votes: ' + votes);
            }  
        return articleStatsMap;
    }
    
    public static Map<ID, Map<String, Integer>> getArticleVoteCount(Set<Id> kaParentArticleIdSet, Map<Id, Map<String, Integer>> articleStatsMap) {
        Id parentId;
        Integer voteCount;
        if ( kaParentArticleIdSet == null ||  kaParentArticleIdSet.isEmpty()) {
            System.debug('No articles for vote count');
            return articleStatsMap;
        }
        
        if (articleStatsMap == null) {
            System.debug('No map passed in; creating new map');
            articleStatsMap = new Map<ID, Map<String, Integer>>();
            for (ID kaId : kaParentArticleIdSet) {
              articleStatsMap.put(kaId, new Map<String, Integer>());
              // setting everything to 0
              articleStatsMap.get(kaid).put('votes', 0);
    		} 
        }
        
        AggregateResult[] upvoteCount = [SELECT count(id) upvotes, parentid from Vote
          WHERE type = '5'and parent.type = 'Knowledge__ka' and parentId in: kaParentArticleIdSet  GROUP BY parentid order by count(id) limit 200];
  
        for (AggregateResult ar : upvoteCount)  {
            parentId = (Id)ar.get('parentid');
            voteCount = (Integer) ar.get('upvotes');
            System.debug('Knowledge Parent Id' +  parentId + ': ' + voteCount );
            articleStatsMap.put(parentId, new Map<String, Integer>());
            articleStatsMap.get(parentId).put('votes', voteCount);
            //System.debug('Average amount' + ar.get('expr0'));
        }
		System.debug('Vote map: ' + articleStatsMap);         
        return articleStatsMap;
    }
    
    
  // START Platform Cache Helpers
  public static Set<ID> getTrendingCacheData(String marketId, String categoryAPIName, String globalCategory){
        Set<Id> trendingArticleIds = new Set<Id>();
        // get articles from cache
    if(String.isNotBlank(categoryAPIName)){
    System.debug('categoryAPIName'+categoryAPIName);
      List<String> primaryCategoryArticles = getCategoryCache(categoryAPIName);
      System.debug('marketId'+marketId);
      System.debug('primaryCategoryArticles'+primaryCategoryArticles);
          if(String.isNotBlank(marketId)){
        for (String cacheString : primaryCategoryArticles){
          if (cacheString.contains(marketId)){
            trendingArticleIds.add(Id.valueOf(cacheString.deleteWhitespace().left(18)));
            System.debug('trendingArticleIds----->1'+trendingArticleIds);
          }
        }
     }
    }
    if(String.isNotBlank(globalCategory)){
      List<String> globalArticles = getCategoryCache(globalCategory);
      System.debug('globalArticles'+globalArticles);
      for (String cacheString : globalArticles){
        trendingArticleIds.add(Id.valueOf(cacheString.deleteWhitespace().left(18)));
        System.debug('trendingArticleIds------> 2'+trendingArticleIds);
      }
    }
        return trendingArticleIds;
    }

  public static List<String> getCategoryCache(String categoryName){
  System.debug('categoryName'+categoryName);
        Cache.OrgPartition op = Cache.Org.getPartition('local.KMCategory');
        System.debug('op'+op);
        List<String> categoryCache = op.get(categoryName) != null ? (List<String>)op.get(categoryName) : new List<String>();
        System.debug('categoryCache'+categoryCache);
        return categoryCache;
    }

  public static String CreateHashedString(String inputStr){
        // Need to hash string as cache keys CAN ONLY contain alphanumeric (data cat names contain '_')
        Blob targetBlob = Blob.valueOf(inputStr);
        Blob hash = Crypto.generateDigest('MD5', targetBlob);
        String hashedCategory = EncodingUtil.convertToHex(hash);
        System.debug('hashedCategory'+hashedCategory);
        return hashedCategory;
    }
  // END Platform Cache Helpers

  // START Wrapper Classes
  public class ArticleWrapper {
    @AuraEnabled
    public Id id { get; set; }
    @AuraEnabled
    public String title { get; set; }
    @AuraEnabled
    public String summary { get; set; }
    @AuraEnabled
    public String previewImage { get; set; }
    @AuraEnabled
    public Boolean recommended { get; set; }
    @AuraEnabled
    public Boolean hasMore { get; set; }
    @AuraEnabled
    public Integer viewCount { get; set; }
    @AuraEnabled
    public Integer likeCount { get; set; }
    @AuraEnabled
    public Integer commentCount { get; set; }
    @AuraEnabled
    public Boolean isUrgent { get; set; }
    @AuraEnabled
    public Boolean isRead { get; set; }
    @AuraEnabled
    public Datetime lastPublishedDate { get; set; }
    @AuraEnabled
    public String lastPublishedDateString { get; set; }
    @AuraEnabled
    public String myCspArticleId { get; set; }
    @AuraEnabled
    public String myCspName { get; set; }
    @AuraEnabled
    public String validDates { get; set; }
    @AuraEnabled
    public String url { get; set; }
  }
 
  public class FilterWrapper {
    @AuraEnabled
    public String label { get; set; }
    @AuraEnabled
    public String value { get; set; }
    @AuraEnabled
    public Boolean checked { get; set; }
    public FilterWrapper() {
    }
    public FilterWrapper(String label, String value) {
      this.label = label;
      this.value = value;
      this.checked = false;
    }
      
   public FilterWrapper(String label, String value, Boolean checked) {
      this.label = label;
      this.value = value;
      this.checked = checked;
    }   
  }  
    
  public class LandingPageException extends Exception {
  }
    
    public static void makeLog(String serializedException, String soqlString, Set<Id> foundArticles) {
        //JSON.serialize(e)
        
        if (serializedException.contains('Your search term must have 3 or more characters')) {
            System.debug('Not enough search characters. Nothing logged');
            return;
        }
        
        String foundArticlesString = '';
        if (foundArticles != null && !foundArticles.isEmpty()) {
            foundArticlesString = JSON.serialize(foundArticles);
        }
        List<Object> params = new List<Object>{'KMSearchException',  null, serializedException + '; SOQL: ' + soqlString + '; Found articles: ' +foundArticlesString};
        
        if (checkLogging()) {
            System.debug('The KM_Logging_Setting__mdt logging setting is turned on.');
            LogMessage logMessage = new LogMessage(BWC_Constants.OPUS_NEBULA_MESSAGE_TEMPLATE, params);
            Logger.error(logMessage).setTopics(new List<String>{'KMSearchException'});
            Logger.saveLog(); 
        } else {
            System.debug('The KM_Logging_Setting__mdt logging setting is turned off.');
        }    
   }  
    
     public static Boolean checkLogging() {
        List<KM_Logging_Setting__mdt> loggingSettingList = getLoggingSettings();
         if (!loggingSettingList.isEmpty()) {
             if (loggingSettingList[0].SearchErrorLogging__c == true) {
                 return true;
             }
         } else {
             return false;
         }
        

       return false;
    }
    
    @testVisible
    private static List<KM_Logging_Setting__mdt> getLoggingSettings() {
        String settingMasterLabel = 'KM Logging Setting'; 
        List<KM_Logging_Setting__mdt> loggingSettingList = [SELECT  Id,
                                SearchErrorLogging__c
                        FROM KM_Logging_Setting__mdt
                        WHERE MasterLabel = :settingMasterLabel];
        System.debug(loggingSettingList.size() + ' rows found for ' + settingMasterLabel);
        return loggingSettingList;
                
    }

    @AuraEnabled(cacheable = true)
    public static string getSearchExecutionType() {
        String searchExecType = 'Explicit Search';
        String searchExecTypeSetting = 'KM_Search_Execution_Type';
        try {
            for (KM_Settings__mdt mdt: [Select DeveloperName, Search_Execution_Type__c from KM_Settings__mdt]) {
                if (searchExecTypeSetting.equals(mdt.DeveloperName)) {
                    return mdt.Search_Execution_Type__c;
                }
            }
            return searchExecType;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    
}