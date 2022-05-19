@isTest
public class ArticleCacheBatchTest {
     // kavUrgent: dataCat=BCSS_Adv_Tech_Support__c, status=urgent, market=Mid West
    public static Knowledge__kav kavUrgent = new Knowledge__kav();
    // kavAssigned: dataCat=ACC__c, status=assigned, market=North Texas
    public static Knowledge__kav kavAssigned = new Knowledge__kav();

    public ArticleCacheBatchTest() {

    } 

     @TestSetup
    static void SetupTestData() {
        system.debug('in setuptestdata');
        // User
        User testUser = KM_TestDataFactory.createContentSponsorUser('rt12345');
        ID CURRENT_USER = testUser.Id;
               
        // Data category
        List<Knowledge__DataCategorySelection> dataCategories = new List<Knowledge__DataCategorySelection>();
        Knowledge__DataCategorySelection dataCat_AdvTechSupport = new Knowledge__DataCategorySelection();
        dataCat_AdvTechSupport.DataCategoryGroupName = 'Channel';
        dataCat_AdvTechSupport.DataCategoryName = 'BCSS_Adv_Tech_Support';
        Knowledge__DataCategorySelection dataCat_AuthRetail = new Knowledge__DataCategorySelection();
        dataCat_AuthRetail.DataCategoryGroupName = 'Channel';
        dataCat_AuthRetail.DataCategoryName = 'ACC';
        
        
        // Employee
        Employee__c employee = new Employee__c();
        employee.user__c = CURRENT_USER;
        employee.BWDefaultKMChannel__c = 'ACC';
        insert employee;
        // Employee Role
        List<BWEmployeeRole__c> employeeRoles = new List<BWEmployeeRole__c>();
        employeeRoles.add(new BWEmployeeRole__c(rolename__c='KMRole', rolevalue__c='BCSS Rep', userid__c=employee.id));
        employeeRoles.add(new BWEmployeeRole__c(rolename__c='KMRole', rolevalue__c='ACC Rep', userid__c=employee.id));
        insert employeeRoles;
        List<BWRolePermissions__c> rolePerms = new List<BWRolePermissions__c>();
        rolePerms.add(new BWRolePermissions__c(rolename__c='KMRole', rolevalue__c='BCSS Rep', permissionsetname__c='BCSS'));
        rolePerms.add(new BWRolePermissions__c(rolename__c='KMRole', rolevalue__c='ACC Rep', permissionsetname__c='ACC'));
        insert rolePerms;
        
        // Markets: 2
        List<BWMarketMaster__c> markets = new List<BWMarketMaster__c>();
        markets.add(new BWMarketMaster__c(MarketPromotedSearchTerm__c='Mid West'));
        markets.add(new BWMarketMaster__c(MarketPromotedSearchTerm__c='North Texas'));
        insert markets;
        // User Market: 2
        List<BWUserMarketAssociation__c> userMarkets = new List<BWUserMarketAssociation__c>();
        userMarkets.add(new BWUserMarketAssociation__c(BWMarketMaster__c=markets[0].id, userid__c=CURRENT_USER));
        userMarkets.add(new BWUserMarketAssociation__c(BWMarketMaster__c=markets[1].id, userid__c=CURRENT_USER));
        insert userMarkets;
        // knowledge__kav: 2, record types, data categories, statuses
        createKnowledgeArticle('urgent', dataCat_AdvTechSupport, testUser.attuid__c);
        createKnowledgeArticle('assigned', dataCat_AuthRetail, testUser.attuid__c);
        createKnowledgeArticle('all', null, testUser.attuid__c);
        kavUrgent =  getKav('urgent');
        kavAssigned =  getKav('assigned');
         // dataCat_AdvTechSupport.parentid =kavUrgent.id;
         // insert dataCat_AdvTechSupport;

        // knowledge market: 2
        List<BWMarketAssociation__c> kavMarkets = new List<BWMarketAssociation__c>();
        kavMarkets.add(new BWMarketAssociation__c(BWMarketMaster__c=markets[0].id, Knowledge__c=kavUrgent.id));
        kavMarkets.add(new BWMarketAssociation__c(BWMarketMaster__c=markets[1].id, Knowledge__c=kavAssigned.id));
        insert kavMarkets;
        
        
    }
    
     @isTest
    static void testArticleCacheCreation() {
        setKavRecords();
        test.startTest();
        Database.executeBatch(new ArticleCacheBatch(), 1000);
        test.stopTest();

        // kavUrgent: dataCat=BCSS_Adv_Tech_Support__c, status=urgent, market=Mid West
        Knowledge__DataCategorySelection BCSSDataCat = [SELECT id, parentId, datacategorygroupname, datacategoryname FROM Knowledge__DataCategorySelection WHERE parentId = :kavUrgent.Id];
        BWMarketAssociation__c midWestMarket = [SELECT id, bwmarketmaster__r.MarketPromotedSearchTerm__c, bwmarketmaster__c FROM BWMarketAssociation__c WHERE Knowledge__c=:kavUrgent.id];
       
        // Need to hash string as cache keys CAN ONLY contain alphanumeric (data cat names contain '_')
        String BCSSHashedCategory = ArticleSearchDataService.CreateHashedString(BCSSDataCat.DataCategoryName + '__c');
        
       // List<ID> categoryKaIds = ArticleSearchDataService.getCategoryCache(BCSSHashedCategory);
    
        //system.assertEquals(1, categoryKaIds.size(), 'Category cache test failed');
        //system.assertEquals(kavUrgent.knowledgearticleid, new List<ID>(categoryKaIds)[0], 'Category cache test failed');
    }

   
    
    static void createKnowledgeArticle(
        String status,
        Knowledge__DataCategorySelection dataCategory,
        String attuid
    ) {
        Knowledge__kav kav = new Knowledge__kav();
        kav.ContentSponsor__c = attuid;
        if (status == 'urgent') {
            kav.Title += ' urgent';
            kav.BW_Is_Urgent__c = true;
            kav.UrlName += 'urgent';
            kav.RecordTypeId = getKnowledgeRecordTypeIDs()[0];
        } else if (status == 'assigned') {
            kav.Title += ' assigned';
            kav.BW_Home_Page_Display__c = true;
            kav.UrlName += 'assigned';
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
            List<Knowledge__DataCategorySelection> knwDatalst = [SELECT id, parentId, datacategorygroupname, datacategoryname FROM Knowledge__DataCategorySelection WHERE parentId = :kav.Id LIMIT 1];
            /*for(Knowledge__DataCategorySelection kdcs: [SELECT id, parentId, datacategorygroupname, datacategoryname FROM Knowledge__DataCategorySelection WHERE parentId = :kav.Id LIMIT 1]) {
                delete kdcs;
            }*/
            delete knwDatalst;
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
                SELECT id, knowledgearticleid, recordtypeid, BW_Is_Urgent__c, BW_Home_Page_Display__c, ArticleTotalViewCount
                FROM Knowledge__kav
                WHERE BW_Is_Urgent__c = TRUE UPDATE VIEWSTAT
            ];
        } 
        else if(status=='assigned') {
            return [
                SELECT id, knowledgearticleid, recordtypeid, BW_Is_Urgent__c, BW_Home_Page_Display__c, ArticleTotalViewCount
                FROM Knowledge__kav
                WHERE BW_Home_Page_Display__c = TRUE UPDATE VIEWSTAT
            ];
        } else if(status == 'all') {
            return [
                SELECT id, knowledgearticleid, recordtypeid, BW_Is_Urgent__c, BW_Home_Page_Display__c, ArticleTotalViewCount
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