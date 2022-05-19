public with sharing class ArticleCacheBatch implements Database.Batchable<sObject>,Schedulable, Database.Stateful{

    public static final String marketSeparator = '|';
    
    public ArticleCacheBatch() {
    }

   
    public void execute(SchedulableContext SC) {
  		Id batchJobId = Database.executeBatch(new ArticleCacheBatch(), 200);

   }
    
    // Batch is marked as stateful, so the Map items below will keep filling in every batch iteration
    // Map of category to 1000 kaId
    Map<String, Set<ID>> categoryToKaIds = new Map<String, Set<ID>>();
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        
        String query = getNormalizedScoreQueryString();
        
        system.debug('final query=' + query);   
		System.debug('Start method completed from ArticleCacheBatch');
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Sobject> scope){
		Id Link_Center_ArticleID = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByDeveloperName()
		.get('Link_Center_Article')
		.getRecordTypeId();
		
		Id TP_AccessoryID = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByDeveloperName()
		.get('TP_Accessory')
		.getRecordTypeId(); 
		
       	System.debug('Execute method starting from ArticleCacheBatch; scope size: ' + scope.size());
		List<Knowledge__kav> globalArticles = new List<Knowledge__kav>();
        Integer cacheRecordNumberComparison = 12; //1000
        Set<Id> knowledgeIdSet = new Set<Id>();
        Set<ID> allKnowledgeIdSet = new Set<ID>(); 
        List<String> articleStringList;
        Map<Id, List<String>> knowledgeMarketMap = new Map<Id, List<String>>();
        Map<String, List<String>> categoryArticleMarketMap = new Map<String, List<String>>();
        Map<Id, String> articleMarketStringMap;
        for (SObject so : scope) {
         	 KnowledgeArticleViewStat kaViewStat = (KnowledgeArticleViewStat) so;
             knowledgeIdSet.add(kaViewStat.parentId);
        }
        
		String query = '';
        String globalQuery = '';
        List<Sobject> subObjectList;
        Map<Id, Id> knowledgeIdToKnowledgeArticleIdMap = new Map<Id, Id>();
        query += ' SELECT id, recordtypeid, knowledgearticleid, ';
 
        query += '  ( ';
        query += '      SELECT datacategorygroupname, datacategoryname, parent.knowledgearticleid ';
        query += '      FROM datacategoryselections ';
        query += '  )';
        query += ' FROM Knowledge__kav';
        query += ' WHERE publishstatus=\'Online\' AND knowledgearticleid in :knowledgeIdSet';
		query += ' AND recordtypeid NOT IN (\''+Link_Center_ArticleID+'\',\''+TP_AccessoryID+'\')';
        query += ' ORDER BY articletotalviewcount DESC'; 
		system.debug('query'+query);
        subObjectList = Database.query(query);
        System.debug('Number of knowledge articles found: ' + subObjectList.size());
        Integer categorysize;
        
        if (categoryToKaIds.get('Global') == null) {
        	categoryToKaIds.put('Global', new Set<Id>());        
        }
        
        if (categoryToKaIds.get('Global') != null &&  categoryToKaIds.get('Global').size() < cacheRecordNumberComparison) {
        	globalQuery += ' SELECT id, recordtypeid, knowledgearticleid ';
            globalQuery += ' FROM Knowledge__kav';
            globalQuery += ' WHERE publishstatus=\'Online\' AND knowledgearticleid in :knowledgeIdSet';
			globalQuery += ' AND recordtypeid NOT IN (\''+Link_Center_ArticleID+'\',\''+TP_AccessoryID+'\')';
            globalQuery +=  ' AND id NOT IN ';
            globalQuery += '  ( ';
            globalQuery  += '      SELECT parentid';
            globalQuery  += '      FROM Knowledge__datacategorySelection ';
            globalQuery  += '  )';
            
            
            globalQuery += ' ORDER BY articletotalviewcount DESC'; 
			System.debug('globalQuery'+globalQuery);
            globalArticles = Database.query(globalQuery);
            System.debug('Number of global knowledge articles found: ' + globalArticles.size());
        } 

        for (Knowledge__kav globalArticle : globalArticles) {
            if (categoryToKaIds.get('Global').size() < cacheRecordNumberComparison) {
            	categoryToKaIds.get('Global').add(globalArticle.knowledgearticleid); 
                knowledgeIdToKnowledgeArticleIdMap.put(globalArticle.Id, globalArticle.knowledgearticleid);
                allKnowledgeIdSet.add(globalArticle.Id);
                System.debug(globalArticle.knowledgearticleid + ' added to global list');
            } else {
                break;
            }    
        }
	        
        for(SObject sobj:subObjectList) {
            //System.debug('For loop in execute method from ArticleCacheBatchNoSub');
            Knowledge__kav kav = (Knowledge__kav)sobj;

            // Iterate through all data categories for article and fill until 1000 articles reached
            for(Knowledge__DataCategorySelection dataCategory: kav.DataCategorySelections) {
                String dataCatApiName = dataCategory.datacategoryname;
                
                /*
                if  (categoryToKaIds.containsKey(dataCatApiName)) {
                    categorysize = categoryToKaIds.get(dataCatApiName).size();
                } else {
                     categorysize = 0;
                }
                System.debug('Data category: ' + dataCatApiName + ' size: ' + categorysize);
				*/	
                if(dataCategory.datacategorygroupname != 'Channel' || 
                    (categoryToKaIds.get(dataCatApiName) != null && categoryToKaIds.get(dataCatApiName).size() == cacheRecordNumberComparison)) {
                  		//System.debug('not channel');
                        continue;
                }
                if(categoryToKaIds.containsKey(dataCatApiName)) {
                    categoryToKaIds.get(dataCatApiName).add(dataCategory.parent.knowledgearticleid);
                   
                   } else {
                    categoryToKaIds.put(dataCatApiName, new Set<ID>{dataCategory.parent.knowledgearticleid});
                }
            	allKnowledgeIdSet.add(dataCategory.parent.Id);
                knowledgeIdToKnowledgeArticleIdMap.put(dataCategory.parent.Id, dataCategory.parent.knowledgearticleiD);


                 //System.debug('Adding to catIdset: ' + dataCategory.parent.knowledgearticleid);
            }
            // Iterate through all data categories for article and fill until 12 articles reached
            for(Knowledge__DataCategorySelection dataCategory: kav.DataCategorySelections) {
                String dataCatApiName = dataCategory.datacategoryname + '__c';
                /*if  (categoryToKaIds.containsKey(dataCatApiName)) {
                    categorysize = categoryToKaIds.get(dataCatApiName).size();
                } else {
                     categorysize = 0;
                }*/
                //System.debug('Data category: ' + dataCatApiName + ' size: ' + categorysize);
                if(dataCategory.datacategorygroupname != 'Channel' || 
                    (categoryToKaIds.get(dataCatApiName) != null && categoryToKaIds.get(dataCatApiName).size() == cacheRecordNumberComparison)) {
                       //System.debug('not channel');

                        continue;
                }
                if(categoryToKaIds.containsKey(dataCatApiName)) {
                    categoryToKaIds.get(dataCatApiName).add(dataCategory.parent.knowledgearticleid);
                    
                } else {
                    categoryToKaIds.put(dataCatApiName, new Set<ID>{dataCategory.parent.knowledgearticleid});
                } 
                	 //System.debug('Adding to catIdset: ' + dataCategory.parent.knowledgearticleid);
                 allKnowledgeIdSet.add(dataCategory.parent.Id);
                knowledgeIdToKnowledgeArticleIdMap.put(dataCategory.parent.Id, dataCategory.parent.knowledgearticleiD);


            }
        }
        //ttl in seconds, 1h 5mins
        Integer cacheTtl = 3900;
		List<BWMarketAssociation__c> marketAssociationList = 
         	   [SELECT Id, BWMarketMaster__c, Knowledge__c  FROM BWMarketAssociation__c WHERE Knowledge__c IN :allKnowledgeIdSet];
	
        for (BWMarketAssociation__c marketAssociation : marketAssociationList) {
        	Id knowledgeArticleId = knowledgeIdToKnowledgeArticleIdMap.get(marketAssociation.Knowledge__c);
            if (knowledgeArticleId != null) {
            	addToMapOfLists(knowledgeMarketMap, knowledgeArticleId, marketAssociation.BWMarketMaster__c);
            }    
        }
        
        // Add data categories to cache
        Cache.OrgPartition orgPartCategory = Cache.Org.getPartition('local.KMCategory');
        System.debug('Number of keys: ' + categoryToKaIds.keyset().size());
        for(String categoryId: categoryToKaIds.keyset()) {
         	System.debug('Category: ' + categoryId);
            //articleMarketStringMap = new List<Id, String>();
            articleStringList = new List<String>();
            String hashedString = CacheHelper.getHashedKey(categoryId);
            //system.debug('Putting ids for category id ' + categoryToKaIds.get(categoryId)  + ';hash: ' + hashedString + '; ids: ' +  categoryToKaIds.get(categoryId));
             //system.debug('Putting ids for category  ' + categoryToKaIds.get(categoryId)  + ';hash: ' + hashedString);
            for (Id articleId: categoryToKaIds.get(categoryId)) {
                List<String> marketIdList = knowledgeMarketMap.get(articleId);
                
                if (marketIdList != null) {
                    System.debug('Market list size for article: ' + articleId + ': ' + marketIdList.size());
                    String joinedList =  String.join(marketIdList, '|');
                     articleStringList.add(articleId + ' = ' + joinedList);
                    //articleMarketStringMap.put(articleId, joinedList);
                } else {
                	System.debug('No markets for article: ' + articleId);

                    articleStringList.add(articleId + ' = ' );
                }
                categoryArticleMarketMap.put(categoryId, articleStringList);
                System.debug('Number of articles added for category: ' + categoryId + ': '+ articleStringList.size());
            }
            List<String> categoryValue = categoryArticleMarketMap.get(categoryId);
            //System.debug('categoryValue ' + categoryValue + ' for ' + categoryId);
            
	            //orgPartCategory.put(hashedString, categoryToKaIds.get(categoryId), cacheTtl);
            //if (categoryValue != null) {
	            orgPartCategory.put(hashedString, categoryArticleMarketMap.get(categoryId), cacheTtl);
            // }   
        }
        
        //System.debug('Execute method completed from ArticleCacheBatchNoSub; batch size: ' + scope.size());	
    }

    public void finish(Database.BatchableContext BC){
        
        if(!test.isRunningTest()){
            //System.scheduleBatch(new ArticleCacheBatch(),'ArticleCache' + String.valueOf(DateTime.now()), 60, 200);
            //System.debug('ArticleCacheBatchNoSub scheduled');

        }
        System.debug('Finish method completed from ArticleCacheBatch');

    }

    public static String getNormalizedScoreQueryString() {
        String query = '';
        
        query += ' SELECT id, parentId';
        query += ' FROM KnowledgeArticleViewStat';
        query += ' WHERE NormalizedScore >0';
        
        query += ' ORDER BY NormalizedScore DESC'; 
        //query += ' LIMIT 4000';
        return query;
    }
    
     public static void addToMapOfLists(Map<Id, List<String>> listMap, String key, String stringValue) {
        List<String> stringList = listMap.get(key);
        if(stringList == null){
            stringList = new List<String>();
        }
        stringList.add(stringValue);
        listMap.put(key, stringList);
    }

}