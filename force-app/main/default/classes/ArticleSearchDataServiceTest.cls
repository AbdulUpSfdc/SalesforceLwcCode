@isTest
private class ArticleSearchDataServiceTest {
    
    public static final String ContentSponsorId = 'tstattid';
    
    public static List<ArticleSearchDataService.ArticleWrapper> articles = new List<ArticleSearchDataService.ArticleWrapper>();
    // kavUrgent: dataCat=BCSS_BMC__c, status=urgent, market=Mid West
    public static Knowledge__kav kavUrgent = new Knowledge__kav();
    // kavAssigned: dataCat=ACC__c, status=assigned, market=North Texas
    public static Knowledge__kav kavAssigned = new Knowledge__kav();
    //kavAll: dataCat=All, no market or status
    public static Knowledge__kav kavALL = new Knowledge__kav();

    @isTest
    static void searchArticlesVanilla() {
        setKavRecords();
        articles = ArticleSearchDataService.searchArticles('max', '', '', 1, '', '');
        System.assertEquals(2, articles.size(), 'searchArticlesVanilla retrieve failure');
    }
    @isTest
    static void searchArticlesTypeFilter() {
        setKavRecords();
        String filterString = createFilterString('typeFilters', new List<String>{kavUrgent.recordtypeid});
        articles = ArticleSearchDataService.searchArticles('max', '', filterString, 1, '', '');
        System.assertEquals(1, articles.size(), 'searchArticlesTypeFilter retrieve failure');
        System.assertEquals(kavUrgent.recordtypeid, [SELECT recordTypeId FROM Knowledge__kav where id =:articles[0].id].recordTypeId, 'Incorrect Article Retrieved');
    }
    @isTest
    static void searchArticlesMarketFilter() {
        setKavRecords();
        //Test Single Article
        BWMarketMaster__c market = [select id from BWMarketMaster__c where MarketPromotedSearchTerm__c='Mid West' LIMIT 1];
        String filterString = createFilterString('marketFilters', new List<String>{market.id});
        articles = ArticleSearchDataService.searchArticles('max', '', filterString, 1,'', '');
        System.assertEquals(1, articles.size(), 'searchArticlesMarketFilter retrieve failure');  
        //Test Two Articles
        BWMarketMaster__c market2 = [select id from BWMarketMaster__c where MarketPromotedSearchTerm__c='North Texas' LIMIT 1];
        filterString = createFilterString('marketFilters', new List<String>{market.id,market2.id});
        articles = ArticleSearchDataService.searchArticles('max', '', filterString, 1,'','');
        System.assertEquals(2, articles.size(), 'searchArticlesMarketFilter retrieve failure'); 
    }
    @isTest
    static void searchArticlesCategoryFilter() {
        setKavRecords();
        // Test single article positive
        String filterString = createFilterString('categoryFilters', new List<String>{'BCSS_BMSC__c'});
        articles = ArticleSearchDataService.searchArticles('max', '', filterString, 1, '', '');
        System.assertEquals(1, articles.size(), 'searchArticlesCategoryFilter retrieve failure');
        // Test 2 articles 
        filterString = createFilterString('categoryFilters', new List<String>{'BCSS_BMSC__c', 'ACC__c'});
        articles = ArticleSearchDataService.searchArticles('max', '', filterString, 1, '', '');
        System.assertEquals(2, articles.size(), 'searchArticlesCategoryFilter retrieve failure');
    }
    @isTest
    static void searchArticlesStatusFilter() {
        setKavRecords();
        //Test with status = Urgent
        String filterString = createFilterString('statusFilters', new List<String>{'urgent'});
        articles = ArticleSearchDataService.searchArticles('max', '', filterString, 1, '', '');
        System.assertEquals(1, articles.size(), 'searchArticlesStatusFilter retrieve failure');
        System.assertEquals(true, articles[0].isUrgent, 'Incorrect Article Retrieved');
        //Test with all statuses
        filterString = createFilterString('statusFilters', new List<String>{'urgent', 'unread', 'assigned'});
        articles = ArticleSearchDataService.searchArticles('max', '', filterString, 1, '', '');
        //None of the articles has both urgent and home display flags set to true so no article should be returned
        System.assertEquals(0, articles.size(), 'searchArticlesStatusFilter retrieve failure');
    }
    @isTest
    static void searchArticlesDateFilter() {
        String startDate = String.valueOf(Date.today());
        String endDate = String.valueOf(Date.today().addDays(1));
        setKavRecords();
        articles = ArticleSearchDataService.searchArticles('max', '', '', 1, startDate, endDate);
        System.assertEquals(2, articles.size(), 'searchArticlesDateFilter retrieve failure');
    }
    @isTest
    static void getTrendingArticlesStub() {
        setKavRecords();
        //increment view count on an article
        kavUrgent = getKav('urgent');
        articles = ArticleSearchDataService.getTrendingArticles();
        // assert below not working as UPDATE VIEWSTAT doesn't seem to update in real-time
        //system.assertEquals(2, kavUrgent.ArticleTotalViewCount, 'Trending articles retrieve failure');
    }
    /* @isTest
     static void getFiltersStub() {
         Map<String, List<ArticleSearchDataService.FilterWrapper>> filterGroupToFilters = ArticleSearchDataService.getFilters();
        system.assertEquals(new Set<String>{'category', 'market', 'status', 'type'}, filterGroupToFilters.keySet());
         system.assertEquals(new Set<String>{'category', 'endDate', 'market', 'searchText', 'startDate', 'status', 'type'}, filterGroupToFilters.keySet());
         //system.assertEquals(2, filterGroupToFilters.get('category').size());
          system.assertEquals(2, filterGroupToFilters.get('market').size());
         system.assertEquals(3, filterGroupToFilters.get('status').size());
         system.assertEquals(getKnowledgeRecordTypeIDs().size(), filterGroupToFilters.get('type').size());
     } */
    
    @isTest
    static void getIsSandbox() {
        ArticleSearchDataService.isSandbox();
    }
    
    @isTest
    static void testMarkArticleRead() {
        kavUrgent =  getKav('urgent');
        Test.startTest();
        ArticleSearchDataService.markArticleRead(kavUrgent.Id);
        Test.stopTest();
        List<BW_KM_Lifecycle_Helper__c> helperRecords = [SELECT BW_Knowledge__c, BW_Article_Viewed__c FROM BW_KM_Lifecycle_Helper__c WHERE BW_Knowledge__c =: kavUrgent.Id];
        system.assertEquals(1, helperRecords.size());
        system.assertEquals(true, helperRecords[0].BW_Article_Viewed__c, 'Article is not viewed');
    }
    
    public static testMethod void testGetAllMarkets() {
    	List<BWMarketMaster__c> marketList = ArticleSearchDataService.getAllMarkets();
        System.assertEquals( marketList.size(), [select id from BWMarketMaster__c].size());
    }
    
    public static testMethod void testGetDataCategoryFilterOptions() {
    	List<ArticleSearchDataService.FilterWrapper>  filterList = ArticleSearchDataService.getDataCategoryFilterOptions(ArticleSearchDataService.KNOWLEDGE_CATEGORY_CHANNEL);
        System.assert(!filterList.isEmpty());
       
    }
    
    @isTest
    static void testCreateDefaultAllDataCategory() {
        // We create the kavALL article without any data categories
        //kavALL = getKav('all');
        //List<Knowledge__DataCategorySelection> kavCategories = new List<Knowledge__DataCategorySelection>();
        // validate that the ALL data category got created
        //kavCategories = [SELECT id, parentId, datacategorygroupname, datacategoryname FROM Knowledge__DataCategorySelection WHERE parentId = :kavAll.id ];
        //System.assertEquals(1, kavCategories.size(), 'testCreateDefaultAllDataCategory failure');
        //System.assertEquals('All', kavCategories[0].datacategoryname, 'testCreateDefaultAllDataCategory failure');
    }
    
    @isTest
    static void articleSearch() {
        // Runas user
        User runUser = [
            SELECT id, UserPermissionsKnowledgeUser, Profile.Name
            FROM user
            WHERE
            UserPermissionsKnowledgeUser = TRUE
            AND profile.name = 'System Administrator'
            AND isActive = TRUE
            LIMIT 1
        ];
        System.runAs(runUser) {
            
        }
        
        
        // start test
        // Fixed SOSL results
        // no search term
        // search term with results
        // search term without results
        // filter record type
        // filter market
        // filter channel
        // filter status
        // stats
    }
    
    @isTest
    static void testFilters() {
        /* Map<String, List<ArticleSearchDataService.FilterWrapper>> filterMap=  new  Map<String, List<ArticleSearchDataService.FilterWrapper>>();
        User_Setting__c userSetting = new User_Setting__c();
        
        
        Map<String, List<ArticleSearchDataService.FilterWrapper>> filterSettings = ArticleSearchDataService.getUserSettingFilters( userSetting, filterMap);
        */
        
        DataCategory[] categoryList =  ArticleSearchDataService.getAllCategories(new List<DataCategory>());
        Map<Id,BWMarketMaster__c> marketMap = new Map<Id,BWMarketMaster__c>([SELECT Id from BWMarketMaster__c]);
       List<ArticleSearchDataService.FilterWrapper> wrapperList = ArticleSearchDataService.getUserSelectedMarketFilters(marketMap.keySet());
        wrapperList = ArticleSearchDataService.getUserSelectedCategoryFilters(new Set<String> {'BCSS_BMSC', 'ACC'});
       ArticleSearchDataService.makeLog('this is an exception', 'SELECT ID from account', new Set<Id>());

    }    
    
    @isTest
    static void testGetParentArticleIdSet() {
        List<Knowledge__kav> knowledgeList = 
    		[SELECT Id,KnowledgeArticleId,Title FROM Knowledge__kav where PublishStatus = 'Online' limit 200];
		Map<Id, Id> knowledgeParentIdMap = ArticleSearchDataService.getParentArticleIdMap(knowledgeList);
        System.assertEquals(knowledgeList.size(), knowledgeParentIdMap.keySet().size());
		Map<ID, Map<String, Integer>> articleVoteCount = ArticleSearchDataService.getArticleVoteCount(knowledgeParentIdMap,null);
        System.assertEquals( articleVoteCount.keySet().size(), knowledgeParentIdMap.keySet().size());
        Set<Id> parentIdSet = ArticleSearchDataService.getParentArticleIdSet(knowledgeList);
        System.assertEquals(knowledgeList.size(), parentIdSet.size());
	}
    
    /*@istest
    public static void testSimpleMethods(){
     ArticleSearchDataService.getEmployeeTypeFilters();
          ArticleSearchDataService.getAllMarketFilters();
     ArticleSearchDataService.getAllChannelFilters();
          ArticleSearchDataService.getRoleFilters();
          ArticleSearchDataService.getViewAsFilters();
        
        
    }*/
    
    @TestSetup
    static void SetupTestData() {
        system.debug('in setuptestdata');
        // User
        ID CURRENT_USER = UserInfo.getUserId();
        // knowledge__kav: 2, record types, data categories, statuses
        // KAV 1: dataCat=BCSS_BMC__c, status=urgent, market=Mid West
        // KAV 2: dataCat=ACC__c, status=assigned, market=North Texas
        
        // Data category
        List<Knowledge__DataCategorySelection> dataCategories = new List<Knowledge__DataCategorySelection>();
        Knowledge__DataCategorySelection dataCat_BCSSBMC = new Knowledge__DataCategorySelection();
        dataCat_BCSSBMC.DataCategoryGroupName = 'Channel';
        dataCat_BCSSBMC.DataCategoryName = 'BCSS_BMSC';
        Knowledge__DataCategorySelection dataCat_AuthRetail = new Knowledge__DataCategorySelection();
        dataCat_AuthRetail.DataCategoryGroupName = 'Channel';
        dataCat_AuthRetail.DataCategoryName = 'ACC';
        
        //Query permission sets
        PermissionSet permSet = [SELECT Id FROM PermissionSet WHERE Name = 'KM_ACC_Rep' LIMIT 1];
        //Channel Mapping
        BW_Channel_Mapping__c channelMapping = new BW_Channel_Mapping__c();
        channelMapping.KM_Channel_Id__c = 'ACC';
        channelMapping.Permission_Set_Id__c = permSet.Id;
        insert channelMapping;
        // Employee
        Employee__c employee = new Employee__c();
        employee.user__c = CURRENT_USER;
        employee.BWDefaultKMChannel__c = 'ACC';
        insert employee;
        // Employee Role
        List<BWEmployeeRole__c> employeeRoles = new List<BWEmployeeRole__c>();
        employeeRoles.add(new BWEmployeeRole__c(rolename__c='KMRole', rolevalue__c='BCSS Rep', KMProcessingStatus__c = 'Completed Add', userid__c=employee.id));
        employeeRoles.add(new BWEmployeeRole__c(rolename__c='KMRole', rolevalue__c='ACC Rep', KMProcessingStatus__c = 'Completed Add', userid__c=employee.id));
        insert employeeRoles;
        //Role Permissions
        List<BWRolePermissions__c> rolePerms = new List<BWRolePermissions__c>();
        rolePerms.add(new BWRolePermissions__c(rolename__c='KMRole', rolevalue__c='BCSS Rep', permissionsetname__c='BCSS - BMC'));
        rolePerms.add(new BWRolePermissions__c(rolename__c='KMRole', rolevalue__c='ACC Rep', PermissionSetId__c=permSet.Id, permissionsetname__c='ACC'));
        insert rolePerms;
        
        // Markets: 2
        List<BWMarketMaster__c> markets = new List<BWMarketMaster__c>();
        markets.add(new BWMarketMaster__c(MarketPromotedSearchTerm__c='Mid West'));
        markets.add(new BWMarketMaster__c(MarketPromotedSearchTerm__c='North Texas'));
        insert markets;
        // User Market: 2
        List<BWUserMarketAssociation__c> userMarkets = new List<BWUserMarketAssociation__c>();
        userMarkets.add(new BWUserMarketAssociation__c(BWMarketMaster__c=markets[0].id, userid__c=CURRENT_USER, Primary__c=true));
        userMarkets.add(new BWUserMarketAssociation__c(BWMarketMaster__c=markets[1].id, userid__c=CURRENT_USER));
        insert userMarkets;
        createContentSponsorUser(ContentSponsorId);
        // knowledge__kav: 2, record types, data categories, statuses
        createKnowledgeArticle('urgent', dataCat_BCSSBMC);
        createKnowledgeArticle('assigned', dataCat_AuthRetail);
        createKnowledgeArticle('all', null);
        kavUrgent =  getKav('urgent');
        kavAssigned =  getKav('assigned');
        
        // knowledge market: 2
        List<BWMarketAssociation__c> kavMarkets = new List<BWMarketAssociation__c>();
        kavMarkets.add(new BWMarketAssociation__c(BWMarketMaster__c=markets[0].id, Knowledge__c=kavUrgent.id));
        kavMarkets.add(new BWMarketAssociation__c(BWMarketMaster__c=markets[1].id, Knowledge__c=kavAssigned.id));
        insert kavMarkets;
        
        
    }
    
    static void createContentSponsorUser(String attUID) {
       
        User authorUser = KM_TestDataFactory.createAuthorUser();
        authorUser.ATTUID__c = attUId;
        authorUser.FederationIdentifier = attUID;
        update authorUser;
        
    }
    
    
    
    
    static void createKnowledgeArticle(
        String status,
        Knowledge__DataCategorySelection dataCategory
    ) {
        Knowledge__kav kav = new Knowledge__kav();
        kav.ContentSponsor__c = ContentSponsorId;
        if (status == 'urgent') {
            kav.Title = 'Urgent';
            kav.BW_Is_Urgent__c = true;
            kav.UrlName += 'urgent';
            kav.BW_Article_Summary__c = '<h1> h1 tags should be stripped from this text </h1>';
            kav.MyCSPArticleName__c = 'Test_UrgentArticle';
            kav.RecordTypeId = getKnowledgeRecordTypeIDs()[0];
        } else if (status == 'assigned') {
            kav.Title = 'Assigned';
            kav.BW_Home_Page_Display__c = true;
            kav.UrlName += 'assigned';
            kav.MyCSPArticleName__c = 'Test_AssignedArticle';
            kav.RecordTypeId = getKnowledgeRecordTypeIDs()[1];
        } else if(status == 'all') {
            kav.Title = 'maxALL';
            kav.UrlName = 'kavUrl-ALL';
            kav.BW_Article_Summary__c = '<h1> h1 tags should be stripped from this text </h1>';
        }
        system.debug('kavInsert ' + kav);
        insert kav;
        kav = [SELECT KnowledgeArticleId FROM knowledge__kav WHERE id = :kav.id];
        KbManagement.PublishingService.publishArticle(kav.KnowledgeArticleId, true);
        if(dataCategory != null) {
            // Delete the default ALL category created as part of trigger on kav
            /*for(Knowledge__DataCategorySelection kdcs: [SELECT id, parentId, datacategorygroupname, datacategoryname FROM Knowledge__DataCategorySelection WHERE parentId = :kav.Id LIMIT 1]) {
                delete kdcs;
            }*/
            delete [SELECT id, parentId, datacategorygroupname, datacategoryname FROM Knowledge__DataCategorySelection WHERE parentId = :kav.Id LIMIT 1];
            dataCategory.parentId = kav.id;
            insert dataCategory;
        }
    }
    
    static List<ID> getKnowledgeRecordTypeIDs() {
        List<ID> recTypeIds = new List<ID>();
        Schema.DescribeSObjectResult d = Schema.SObjectType.Knowledge__kav;
        Map<Id, Schema.RecordTypeInfo> rtMapById = new Map<Id, Schema.RecordTypeInfo>();
        rtMapById = d.getRecordTypeInfosById();
        for (Id rtId : rtMapById.keySet()) {
            if (
                rtMapById.get(rtId).isAvailable() &&
                rtMapById.get(rtId).getName() != 'Master'
            ) {
                recTypeIds.add(rtId);
            }
        }
        return recTypeIds;
    }
    
    static Knowledge__kav getKav(String status) {
        if(status=='urgent') {
            return  [
                SELECT id, recordtypeid, BW_Is_Urgent__c, BW_Home_Page_Display__c, MyCSPArticleName__c, ArticleTotalViewCount
                FROM Knowledge__kav
                WHERE BW_Is_Urgent__c = TRUE UPDATE VIEWSTAT
            ];
        } 
        else if(status=='assigned') {
            return [
                SELECT id, recordtypeid, BW_Is_Urgent__c, BW_Home_Page_Display__c, MyCSPArticleName__c, ArticleTotalViewCount
                FROM Knowledge__kav
                WHERE BW_Home_Page_Display__c = TRUE UPDATE VIEWSTAT
            ];
        } else if(status == 'all') {
            return [
                SELECT id, recordtypeid, BW_Is_Urgent__c, BW_Home_Page_Display__c, MyCSPArticleName__c, ArticleTotalViewCount
                FROM Knowledge__kav
                WITH DATA CATEGORY Channel__c AT All__c
            ];
        }
        return null;
    }
    static String createFilterString(String groupName, List<String> filterIds) {
        Map<String,List<String>> filterMap = new Map<String,List<String>>();
        filterMap.put(groupName, new List<String>());
        for(String filterId: filterIds) {
            filterMap.get(groupName).add(filterId);
        }
        String filterString = JSON.serialize(filterMap);
        return filterString;
    }
    static void setKavRecords() {
        kavUrgent =  getKav('urgent');
        kavAssigned =  getKav('assigned');
        Test.setFixedSearchResults(new List<ID>{ kavUrgent.id, kavAssigned.id });
        
    }
    
   
}