@isTest
public with sharing class ArticleFilterDataServiceTest {
    
    public static List<ArticleSearchDataService.ArticleWrapper> articles = new List<ArticleSearchDataService.ArticleWrapper>();
    // kavUrgent: dataCat=BCSS_BMC__c, status=urgent, market=Mid West
    public static Knowledge__kav kavUrgent = new Knowledge__kav();
    // kavAssigned: dataCat=ACC__c, status=assigned, market=North Texas
    public static Knowledge__kav kavAssigned = new Knowledge__kav();
    //kavAll: dataCat=All, no market or status
    public static Knowledge__kav kavALL = new Knowledge__kav();
    
    
    
    public static testmethod void testFilter() {
        
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
        // knowledge__kav: 2, record types, data categories, statuses
        KM_TestDataFactory.createContentSponsorUser('');
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
        Knowledge__kav newArticle = ArticleGenerator.testPublishArticle();
        
        
        
        
        Set<ID> marketIds = new Set<ID>();
        marketIds.add(markets[0].id);
        Set<ID> recTypeIds = null;
        Set<String> categoryIds = new Set<String>();
        Set<String> statuses = null;
        String searchText = '';
        Date startDate  = null;
        Date endDate = null;
        String employeeType = 'Employee';
        String roleName  = 'Employee';
        Boolean getStats = false;
        Boolean isTrending= false;    
        Integer currentPage = 1;
        String requestSource = 'ViewAs';
        String market = '';
        String channel = '';
        
        List<ArticleFilterDataService.ArticleWrapper> wrapperList;
        wrapperlist = articleFilterdataService.createArticleWrapper(
            marketIds,
            recTypeIds,
            categoryIds,
            statuses,
            searchText,
            startDate,
            EndDate,
            employeeType,
            RoleName,
            getStats,
            isTrending,
            currentPage);
            
         
        System.debug(wrapperlist.size() + ' articles returned');
        searchText = 'HBO';
         wrapperlist = articleFilterdataService.createArticleWrapper(
            marketIds,
            recTypeIds,
            categoryIds,
            statuses,
            searchText,
            startDate,
            EndDate,
            employeeType,
            RoleName,
            getStats,
            isTrending,
            currentPage);
        
        
        wrapperList = ArticleFilterDataService.getViewAsTrendingArticles(channel, market,  
                                                                         employeeType, roleName,
                                                                         requestSource);
        wrapperList = ArticleFilterDataService.getTrendingArticles();
        
        Map<String, List<ArticleFilterDataService.FilterWrapper>> filterWrapper = ArticleFilterDataService.getViewAsFilters();
        Map<String, String> categoryMap = ArticleFilterDataService.getAllChannelCategoriesMap();
        recTypeIds = ArticleFilterDataService.getUserRecTypes().keySet();
        
         List<ArticleFilterDataService.FilterWrapper> filterWrappers = ArticleFilterDataService.getMarketFilters();
        
        filterWrappers = ArticleFilterDataService.getStatusFilters();
        filterWrappers = ArticleFilterDataService.getTypeFilters();
        filterWrappers = ArticleFilterDataService.getEmployeeRoleFilters();

        String hashString = 'hash'; 
        String testString = ArticleFilterDataService.createHashedString(hashString);
        Boolean isSandbox = ArticleFilterDataService.isSandbox();
        ArticleFilterDataService.LandingPageException lpe = new ArticleFilterDataService.LandingPageException('Test');
        ArticleFilterDataService.getExceptionString(lpe);
        newArticle = [SELECT Id, RecordTypeId, BW_News_Start_Date__c, BW_News_End_Date__c, LastPublishedDate, Valid_Until_Date__c FROM
                     Knowledge__kav where Id = :newArticle.Id ];
        
         ArticleFilterDataService.calculateValidity(newArticle);
        
        
        /*String NEWS_ARTICLEID = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByName()
        .get('News Article')
        .getRecordTypeId();
        
        
         Set<ID> recIds = ArticleFilterDataService.getRecTypeCache(NEWS_ARTICLEID);*/
         
        ArticleFilterDataService.StripHTML('Header1');
        
        List<Knowledge__kav> knowledgekav = [SELECT Id, RecordTypeId, BW_News_Start_Date__c, BW_News_End_Date__c, LastPublishedDate, Valid_Until_Date__c FROM
                     Knowledge__kav];
         set<ID> kavids = new set<ID>();
         for( Knowledge__kav  knowledge :    knowledgekav){
             kavids.add(knowledge.id);
         }
        
        ArticleFilterDataService.getArticleStats(kavids);
        
    
    }
    
    
    
     static void createKnowledgeArticle(
        String status,
        Knowledge__DataCategorySelection dataCategory
    ) {
     String NEWS_ARTICLEID = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByDeveloperName().get('News_Article').getRecordTypeId();
        Knowledge__kav kav = new Knowledge__kav();
        kav.ContentSponsor__c = 'rc1234r';
        if (status == 'urgent') {
            kav.Title = 'Urgent';
            kav.BW_Is_Urgent__c = true;
            kav.UrlName += 'urgent';
            kav.BW_Article_Summary__c = '<h1> h1 tags should be stripped from this text </h1>';
            kav.MyCSPArticleName__c = 'Test_UrgentArticle';
            kav.RecordTypeId = NEWS_ARTICLEID;
        } else if (status == 'assigned') {
            kav.Title = 'AssignedHBO';
            kav.BW_Home_Page_Display__c = true;
            kav.UrlName += 'assigned';
            kav.MyCSPArticleName__c = 'HBOTest_AssignedArticle';
            kav.RecordTypeId = getKnowledgeRecordTypeIDs()[1];
        } else if(status == 'all') {
            kav.Title = 'maxALLHBO';
            kav.UrlName = 'kavUrl-ALL';
            kav.BW_Article_Summary__c = '<h1> h1 tags should be stripped from this text </h1>';
        }
        KM_TestDataFactory.createContentSponsorUser('rc1234r');
        system.debug('kavInsert ' + kav);
        insert kav;
        kav = [SELECT KnowledgeArticleId FROM knowledge__kav WHERE id = :kav.id];
        KbManagement.PublishingService.publishArticle(kav.KnowledgeArticleId, true);
        if(dataCategory != null) {
            // Delete the default ALL category created as part of trigger on kav
            List<Knowledge__DataCategorySelection> knwDatalst = [SELECT id, parentId, datacategorygroupname, datacategoryname FROM Knowledge__DataCategorySelection WHERE parentId = :kav.Id LIMIT 1];
            /*for(Knowledge__DataCategorySelection kdcs: [SELECT id, parentId, datacategorygroupname, datacategoryname FROM Knowledge__DataCategorySelection WHERE parentId = :kav.Id LIMIT 1]) {
                delete kdcs;
            }*/
           if(knwDatalst.size()>0){
              delete knwDatalst;  
            }
            
            dataCategory.parentId = kav.id;
            insert dataCategory;
        }
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
    
    public static testmethod void testArticleWrapper() {
        ArticleFilterDataService.ArticleWrapper wrapper = new ArticleFilterDataService.ArticleWrapper();
        wrapper.id = null;
        wrapper.title = null;
        wrapper.summary = null;
        wrapper.previewImage =null;
       
        wrapper.recommended = false;
        wrapper.hasMore = false;
        wrapper.viewCount = 0;
        wrapper.likeCount = 0;
        wrapper.commentCount = 0;
        wrapper.isRead = false;
        wrapper.isUrgent = false;
        wrapper.lastPublishedDate = null;
        wrapper.lastPublishedDateString = null;
        wrapper.myCspArticleId = null;
        wrapper.myCspName = null;
        
    }
    
    public static testmethod void testGetCategoryCache() {
        String dataCategoryName = 'ACC';
        Set<ID> categoryCacheIdSet =  ArticleFilterDataService.getCategoryCache(dataCategoryName);
    }
}