public with sharing class ArticleFilterDataService {
    
    public static final String CATEGORY_OBJECT_TYPE = 'KnowledgeArticleVersion';
    public static final String KNOWLEDGE_CATEGORY_CHANNEL = 'Channel';
    public static final String KNOWLEDGE_CATEGORY_ROLE = 'Role';
    public static final String KNOWLEDGE_CATEGORY_RESOURCE_TYPE = 'Resource_Type';
    
    private static String NEWS_ARTICLEID = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByDeveloperName()
        .get('News_Article')
        .getRecordTypeId();

    private static String QUERY_FIELDS = ' Id,KnowledgeArticleId,Title, Summary, BW_Article_Summary__c, BW_Preview_Image__c, LastPublishedDate, ArticleTotalViewCount, BW_myCSP_Article_Id__c, BW_News_Start_Date__c, BW_News_End_Date__c, Valid_Until_Date__c, RecordTypeId, MyCSPArticleName__c, BW_Is_Urgent__c, BW_FrontLine_Focus__c, BW_Home_Page_Display__c ';
    
    
    
    public static List<ArticleWrapper> getViewAsTrendingArticles(String channel, String market,  
                                                                String employeeRole, String resourceType,
                                                                String requestSource) {
                                                                    
        system.debug('start getViewAsTrendingArticles');
        try {
            Set<ID> recTypeIds = getUserRecTypes().keySet();
            Set<String> statuses = new Set<String>();
            Set<ID> marketIds = new Set<ID>();
            // Filter by (Primary) category
            /* String primaryMarket = getPrimary('market');
Set<ID> marketIds = primaryMarket==null ? new Set<ID>() : new Set<ID>{(ID)primaryMarket}; */
            String primaryCategory = getPrimary('category');
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
        System.debug('User has view as permission ' + FeatureManagement.checkPermission('KM_View_As'));
        Map<String, List<FilterWrapper>> filterGroupToFilters = new Map<String, List<FilterWrapper>>();
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
        /*try {
upsert new BW_KM_Lifecycle_Helper__c(
BW_Article_Viewed__c = true,
BW_Knowledge__c = kavId,
BW_User__c = Userinfo.getuserId()
);
} catch (Exception e) {
// Removing exception class call as it is failing with too many DML statements and subsequently doesn't send back an error to the UI
// BWC_ExceptionUtils.handleException(e, true);
System.debug(LoggingLevel.ERROR, getExceptionString(e));
throw new LandingPageException(
'markArticleRead Error: ' + getExceptionString(e)
);
}*/
    }
    // END AuraEnabled Methods
    
    // START Aura Helpers
    /* This method finds articles in 4 steps: Search.SuggestedResults, SOQL (filters, stats), SOSL and SOQL (filters, stats)
If suggestedResults is less than 12 or the SOQL filters reduce suggestedResults to less than, fill the rest with SOSL 
We needed to use SOQL filters as market and status filters go against child tables which can only be achieved with SOQL 
This COULD be refactored to get all the filters beforehand and then use raw IDs in SOSL filter */
    public static List<ArticleWrapper> createArticleWrapper(
        Set<ID> marketIds,
        Set<ID> recTypeIds,
        Set<String> categoryIds,
        Set<String> statuses,
        String searchText,
        Date startDate,
        Date endDate,
        String employeeType,
        String roleName,
        Boolean getStats,
        Boolean isTrending,
        Integer currentPage
    ) {
        List<ArticleWrapper> articleItems = new List<ArticleWrapper>();
        List<Knowledge__kav> kavArticles = new List<Knowledge__kav>();
        // Suggest and Search Collections
        Map<ID, Knowledge__kav> suggestedResultsToBeSorted = new Map<ID, Knowledge__kav>();
        Map<ID, KnowledgeArticleVersion> kavIdToKavSuggestionResult = new Map<ID, KnowledgeArticleVersion>();
        List<ID> kavIdsFromSuggestion = new List<ID>();
        Map<ID, Search.SearchResult> kavIdToSearchResult = new Map<ID, Search.SearchResult>();
        List<ID> kavIdsFromSearch = new List<ID>();
        Map<ID, Map<String, Integer>> kaIdToStatsMap = new Map<ID, Map<String, Integer>>();
        ID currentUserId = UserInfo.getUserId();
        String categoryString = '';
        System.debug('Market ids: ' +  marketIds);
        if (!categoryIds.isEmpty()) {
            //convert set to raw string to use with data category filter
            categoryString = String.join(new List<String>(categoryIds), ',');
        }
        //Base SOQL query base recType filters START
        String baseQuery = '';
        baseQuery += ' select ' + getArticleWrapperFields();
        baseQuery += ', (select id from BW_KM_Lifecycle_Helper__r where BW_Article_Viewed__c = true and BW_User__c = :currentUserId)';
        baseQuery += ' FROM Knowledge__kav where publishstatus=\'Online\'';
        if (marketIds.size() > 0) {
            baseQuery += ' AND Id IN (select knowledge__c from bwmarketassociation__c where bwmarketmaster__c IN :marketIds)';
        }
        /*
* recordtypes, dates, and status are not considered for filtering
* baseQuery += ' AND recordtypeid IN :recTypeIds';
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
baseQuery += ' AND id NOT IN (select BW_Knowledge__c from BW_KM_Lifecycle_Helper__c where BW_Article_Viewed__c = true and BW_User__c = :currentUserId)';
}
}
//Base SOQL query with Date filters
if(startDate != null && endDate != null){
baseQuery += ' AND DAY_ONLY(LastPublishedDate) >= :startDate AND DAY_ONLY(LastPublishedDate) <= :endDate';
}
*/
        // Get Suggested Results and keep track of kavIds returned
        if (searchText != '') {
            kavIdToKavSuggestionResult = getSuggestedArticles(
                searchText,
                categoryIds,
                currentPage
            );
            for (KnowledgeArticleVersion kav : kavIdToKavSuggestionResult.values()) {
                kavIdsFromSuggestion.add(kav.id);
            }
            baseQuery += ' AND ID IN :kavIdsFromSuggestion';
        }
        //Data category filters
        if (categoryString != '') {
            baseQuery += ' WITH DATA CATEGORY Channel__c AT (' + categoryString + ')';
        }/*
if (!String.isEmpty(employeeType)) {
baseQuery += ' WITH DATA CATEGORY EmployeeType__c AT (' + employeeType + ')';
}
if (!String.isEmpty(roleName)) {
baseQuery += ' WITH DATA CATEGORY EmployeeType__c AT (' + rolename + ')';
}  
*/  
        baseQuery += ' ORDER BY LastPublishedDate DESC';
        // We expand the query results as they click view more / increment currentPAge
        baseQuery += ' LIMIT ' + (12 * currentPage);
        // Trending Articles
        if (isTrending) {
            // Build a stripped down query for trending articles
    
            kavArticles = getTrendingArticles(marketIds, recTypeIds, categoryString);
        } else {
            system.debug('BASE QUERY :::' + baseQuery);
            // Ensure results from SOQL are sorted by original suggested order
            kavArticles = Database.query(baseQuery);
            suggestedResultsToBeSorted.putAll(kavArticles);
        }
        //Reset articles and hydrate with sort order from original search
        if (searchText != '') {
            kavArticles = new List<Knowledge__kav>();
            for (ID sortedId : kavIdsFromSuggestion) {
                // Checking for null as search results may be larger than soql results (due to filters)
                if (suggestedResultsToBeSorted.get(sortedId) != null)
                    kavArticles.add(suggestedResultsToBeSorted.get(sortedId));
            }
        }
        // We want to get additional SOSL results, if any
        if (searchText != '' && (kavArticles.size() < (12 * currentPage))) {
            kavIdToSearchResult = searchSOSL(
                searchText,
                categoryString,
                currentPage,
                kavIdsFromSuggestion
            );
            for (Search.SearchResult searchResult : kavIdToSearchResult.values()) {
                Knowledge__kav kav = (Knowledge__kav) searchResult.getSObject();
                kavIdsFromSearch.add(kav.id);
            }
            //Replacing base query with SOSL results and appending
            baseQuery = baseQuery.replace(
                ' AND ID IN :kavIdsFromSuggestion',
                ' AND ID IN :kavIdsFromSearch'
            );
            baseQuery = baseQuery.replace(
                ' LIMIT ' + (12 * currentPage),
                ' LIMIT ' + ((12 * currentPage) - kavArticles.size())
            );
            system.debug('SOSL Base Query ::: '+ baseQuery);
            kavArticles.addAll((List<Knowledge__kav>) Database.query(baseQuery));
        }
        // Gather the concrete ka IDs to use for child/count queries for vote and comment
        if (kavArticles.size() > 0) {
            Set<ID> kaIds = new Set<ID>();
            for (Knowledge__kav kav : kavArticles) {
                kaIds.add(kav.KnowledgeArticleId);
            }
            kaIdToStatsMap = getArticleStats(kaIds);
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
            if (kavIdToKavSuggestionResult.get(kav.Id) != null) {
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
    private static List<Knowledge__kav> getTrendingArticles(
        Set<ID> marketIds,
        Set<ID> recTypeIds,
        String categoryString
    ) {
        Set<ID> cachedIds = new Set<ID>();
        List<Knowledge__kav> initialArticles = new List<Knowledge__kav>();
        Map<ID, Knowledge__kav> kaIdToKav = new Map<ID, Knowledge__kav>();
        List<Knowledge__ViewStat> viewStats = new List<Knowledge__ViewStat>();
        List<Knowledge__kav> finalArticles = new List<Knowledge__kav>();
        ID currentUserId = UserInfo.getUserId();
        
       
        
        // Start query builder
        String baseQuery = '';
        baseQuery += ' SELECT ' + getArticleWrapperFields();
        baseQuery += ' FROM Knowledge__kav ';
        baseQuery += ' WHERE publishstatus=\'Online\'';
        if (cachedIds.isEmpty()) {
            baseQuery += ' AND recordtypeid IN :recTypeIds';
            //Data category filters
            if (categoryString != '') {
                baseQuery +=
                    ' WITH DATA CATEGORY Channel__c AT (' +
                    categoryString +
                    ')';
            }
        }
        baseQuery += ' ORDER BY ArticleTotalViewCount DESC';
        baseQuery += ' LIMIT 1000';
        system.debug('trending query= ' + baseQuery);
        initialArticles = Database.query(baseQuery);
        
        for (Knowledge__kav kav : initialArticles) {
            kaIdToKav.put(kav.KnowledgeArticleId, kav);
        }
        
        // Get the normalized scores for the articles
        viewStats = [
            SELECT parentid, normalizedscore
            FROM knowledge__viewstat
            WHERE channel = 'AllChannels' AND parentId IN :kaIdToKav.keySet()
            ORDER BY normalizedScore DESC
        ];
        for (Knowledge__ViewStat viewStat : viewStats) {
            if (kaIdToKav.containsKey(viewStat.parentId)) {
                finalArticles.add(kaIdToKav.get(viewStat.parentId));
            }
            if (finalArticles.size() == 12)
                break;
        }
        return finalArticles;
    }
    
    private static Map<ID, Search.SearchResult> searchSOSL(
        String searchText,
        String categoryString,
        Integer currentPage,
        List<ID> idsFromSuggestedAlready
    ) {
        Search.SearchResults searchResults;
        Map<ID, Search.SearchResult> kavIdToSearchResult = new Map<ID, Search.SearchResult>();
        String searchTextEscaped = String.escapeSingleQuotes(searchText);
        String searchQuery = 'FIND \'' + searchTextEscaped + '\' IN ALL FIELDS';
        searchQuery += ' RETURNING Knowledge__kav(Id,KnowledgeArticleId ';
        searchQuery += ' WHERE PublishStatus=\'Online\' AND Language = \'en_US\'';
        if (idsFromSuggestedAlready.size() > 0)
            searchQuery += ' AND ID NOT IN :idsFromSuggestedAlready ';
        searchQuery += ' )';
        if (categoryString != '')
            searchQuery +=
            ' WITH DATA CATEGORY Channel__c AT (' +
            categoryString +
            ')';
        //searchQuery += ' WITH SNIPPET (target_length=300)';
        searchQuery += ' LIMIT ';
        searchQuery += (12 * currentPage);
        searchQuery += ' UPDATE TRACKING ';
        searchResults = Search.find(searchquery);
        List<Search.SearchResult> articlelist = searchResults.get('Knowledge__kav');
        for (Search.SearchResult searchResult : articlelist) {
            Knowledge__kav kav = (Knowledge__kav) searchResult.getSObject();
            kavIdToSearchResult.put(kav.Id, searchResult);
        }
        return kavIdToSearchResult;
    }
    private static Map<ID, KnowledgeArticleVersion> getSuggestedArticles(
        String searchText,
        Set<String> channelIds,
        Integer currentPage
    ) {
        String searchTextEscaped = String.escapeSingleQuotes(searchText);
        Map<ID, KnowledgeArticleVersion> kavIdToSuggestedKav = new Map<Id, KnowledgeArticleVersion>();
        Search.SuggestionOption options = new Search.SuggestionOption();
        Search.KnowledgeSuggestionFilter filters = new Search.KnowledgeSuggestionFilter();
        Search.SuggestionResults suggestionResults;
        filters.setLanguage('en_US');
        filters.setPublishStatus('Online');
        for (String channel : channelIds) {
            filters.addDataCategory('Channel', channel.replace('__c', ''));
        }
        options.setFilter(filters);
        options.setLimit(12 * currentPage);
        suggestionResults = Search.suggest(
            searchTextEscaped,
            'KnowledgeArticleVersion',
            options
        );
        for (
            Search.SuggestionResult sr : suggestionResults.getSuggestionResults()
        ) {
            KnowledgeArticleVersion kav = new KnowledgeArticleVersion();
            kav = (KnowledgeArticleVersion) sr.getSObject();
            kavIdToSuggestedKav.put(kav.id, kav);
        }
        if (!Test.isRunningTest()) {
            return kavIdToSuggestedKav;
        } else {
            return new Map<Id, KnowledgeArticleVersion>();
        }
    }
    public static String getArticleWrapperFields() {
        return QUERY_FIELDS;
    }
    public static Map<ID, Map<String, Integer>> getArticleStats(Set<ID> kaIds) {
        Map<ID, Map<String, Integer>> kaIdToStatsMap = new Map<ID, Map<String, Integer>>();
        for (ID kaId : kaIds) {
            kaIdToStatsMap.put(kaId, new Map<String, Integer>());
            // setting everything to 0
            kaIdToStatsMap.get(kaid).put('votes', 0);
            kaIdToStatsMap.get(kaid).put('views', 0);
            kaIdToStatsMap.get(kaid).put('comments', 0);
        } 
        for (Knowledge__ka ka : [
            SELECT
            id,
            (
                SELECT type, parentid
                FROM votes
                WHERE parentid IN :kaids AND type IN ('1', '5')
            )
            FROM Knowledge__ka
            WHERE id IN :kaids
        ]) {
            if (!ka.votes.isEmpty()) {
                Integer overallVotes = 0;
                for (Vote v : ka.votes) {
                    overallVotes += v.type == '5' ? 1 : -1;
                }
                overallVotes = overallVotes < 0 ? 0 : overallVotes;
                kaIdToStatsMap.get(ka.id).put('votes', overallVotes);
            }
        }
        for (Knowledge__ViewStat viewstat : [
            SELECT parentid, viewcount
            FROM knowledge__viewstat
            WHERE parentid IN :kaids AND channel = 'AllChannels'
        ]) {
            kaIdToStatsMap.get(viewstat.parentid).put('views', viewstat.viewcount);
        }
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
        }
        return kaIdToStatsMap;
    }
    public static string StripHTML(String htmlString) {
        String backlash = '\n';
        String backlashReplacement = '---n';
        htmlString = htmlString.replaceAll(backlash, backlashReplacement);
        htmlString = htmlString.stripHtmlTags();
        htmlString = htmlString.replaceAll(backlashReplacement, backlash);
        return htmlString;
    }
    public static String calculateValidity(Knowledge__kav knowledgeObj) {
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
    public static String getExceptionString(Exception exceptionCaught) {
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
    public static List<FilterWrapper> getTypeFilters() {
        List<FilterWrapper> typeFilters = new List<FilterWrapper>();
        Map<Id, Schema.RecordTypeInfo> rtMapById = getUserRecTypes();
        for (Id rtId : rtMapById.keySet()) {
            if (
                rtMapById.get(rtId).isAvailable() &&
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
    public static List<FilterWrapper> getMarketFilters() {
        List<FilterWrapper> marketFilters = new List<FilterWrapper>();
        List<FilterWrapper> marketFiltersPrimary = new List<FilterWrapper>();
        for (BWUserMarketAssociation__c userMarket : getUserMarkets().values()) {
            FilterWrapper filter = new FilterWrapper(
                userMarket.BWMarketMaster__r.MarketPromotedSearchTerm__c,
                userMarket.BWMarketMaster__c
            );
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
    public static List<FilterWrapper> getCategoryFilters() {
        List<FilterWrapper> categoryFilters = getUserCategories();
        return categoryFilters;
    }
    public static List<FilterWrapper> getStatusFilters() {
        List<FilterWrapper> statusFilters = new List<FilterWrapper>();
        statusFilters.add(new FilterWrapper('Assigned', 'assigned'));
        statusFilters.add(new FilterWrapper('Unread', 'unread'));
        statusFilters.add(new FilterWrapper('Urgent', 'urgent'));
        return statusFilters;
    }
    
    public static List<FilterWrapper> getEmployeeRoleFilters() {
        List<FilterWrapper> statusFilters = new List<FilterWrapper>();
        
        statusFilters.add(new FilterWrapper('Assigned', 'assigned'));
        statusFilters.add(new FilterWrapper('Unread', 'unread'));
        statusFilters.add(new FilterWrapper('Urgent', 'urgent'));
        return statusFilters;
    }  
    
    public static Map<Id, Schema.RecordTypeInfo> getUserRecTypes() {
        Schema.DescribeSObjectResult d = Schema.SObjectType.Knowledge__kav;
        Map<Id, Schema.RecordTypeInfo> rtMapById = new Map<Id, Schema.RecordTypeInfo>();
        rtMapById = d.getRecordTypeInfosById();
        return rtMapById;
    }
    
    public static List<BWMarketMaster__c> getAllMarkets() {
        return [SELECT Id, MarketPromotedSearchTerm__c FROM BWMarketMaster__c ORDER BY MarketPromotedSearchTerm__c];
    }
    
    public static Map<ID, BWUserMarketAssociation__c> getUserMarkets() {
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
            marketIdUserMarket.put(userMarket.BWMarketMaster__c, userMarket);
        }
        return marketIdUserMarket;
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
    
    public static List<FilterWrapper> getUserCategories() {
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
            WHERE userid__r.user__r.Id = :UserInfo.getUserId()
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
                        filterValue + '__c'
                    )
                );
            } else {
                userCategories.add(
                    new FilterWrapper(
                        primaryPerm.permissionsetname__c + ' (Primary)',
                        filterValue + '__c'
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
    public static DataCategory[] getAllCategories(DataCategory[] categories) {
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
   
    public static Set<ID> getCategoryCache(String categoryName) {
        Cache.OrgPartition op = Cache.Org.getPartition('local.KMCategory');
        Set<ID> categoryCache = op.get(categoryName) != null
            ? (Set<ID>) op.get(categoryName)
            : new Set<ID>();
        return categoryCache;
    }
    /*
    public static Set<ID> getRecTypeCache(String recTypeId) {
        Cache.OrgPartition op = Cache.Org.getPartition('local.KMRecordType');
        Set<ID> recTypeCache = op.get(recTypeId) != null
            ? (Set<ID>) op.get(recTypeId)
            : new Set<ID>();
        return recTypeCache;
    }*/
    public static String createHashedString(String inputStr) {
        // Need to hash string as cache keys CAN ONLY contain alphanumeric (data cat names contain '_')
        Blob targetBlob = Blob.valueOf(inputStr);
        Blob hash = Crypto.generateDigest('MD5', targetBlob);
        String hashedCategory = EncodingUtil.convertToHex(hash);
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
    }
    public class LandingPageException extends Exception {
    }
    
}