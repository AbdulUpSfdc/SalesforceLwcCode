/*****
 Name             : BWAutoArchiveArticlesBatch
 Description      : This is the batch class for archiving all news articles whose end date and time has passed
 ****/
public without sharing class BWAutoArchiveArticlesBatch implements Database.Batchable<sObject>{
	private final String NEWS_ARTICLE = 'News_Article';
    public static final String topicName = 'KM_Auto_Archive_Articles_Batch';

	public Database.QueryLocator start(Database.BatchableContext BC){
		Datetime currentTime = System.now();
		Id newsArticleRecordTypeId = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByDeveloperName().get(NEWS_ARTICLE).getRecordTypeId();

		String query = 'SELECT Id, KnowledgeArticleId';
		query += ' FROM Knowledge__kav';
		query += ' WHERE PublishStatus = \'Online\' AND IsLatestVersion = true';
		query += ' AND BW_News_End_Date__c <= :currentTime';
		query += ' AND RecordTypeId = :newsArticleRecordTypeId';
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext BC, List<sObject> scope){
		System.debug('AUTO ARCHIVE ARTICLES BATCH - INITIALIZED');
		Integer numArchivedArticles = 0;
		Integer numExceptions = 0;
		Set<Id> articleIds = new Set<Id>();

		for (Sobject ka : scope){
			Knowledge__kav article = (Knowledge__kav)ka;
			articleIds.add(article.Id);
			try{
				KbManagement.PublishingService.archiveOnlineArticle(article.KnowledgeArticleId, null);
				numArchivedArticles++;
			} catch (System.Exception e){
                System.debug('Exception Archiving article: ' + article.Id + ': ' + e);
                String errorMessage = 'This article cannot be archived due to draft article exists.'+e;
				makeLog(article.Id, JSON.serialize(errorMessage));
				numExceptions++;
			}
		}
        // US# 11770 - Associated article links don't need to be archived 
		//archive associated knowledge article links
		//BWArchiveKnowledgeArticleLinks.archiveArticleLinks(articleIds);

		System.debug('NUMBER OF ARTICLES ARCHIVED::: ' + numArchivedArticles + '; EXCEPTIONS::: ' + numExceptions);
	}

	public void finish(Database.BatchableContext BC){
		System.debug('AUTO ARCHIVE ARTICLES BATCH - FINISHED');
		scheduleNextBatchJob();
	}

	private static void scheduleNextBatchJob(){
		//get filter criteria value from custom metadata
		BatchSetting__mdt batchSettings = [SELECT BatchQueryFilterCondition__c, BatchSize__c
		                                   FROM BatchSetting__mdt
		                                   WHERE MasterLabel = 'BWAutoArchiveArticlesBatch'];

		Integer batchInterval = Integer.valueOf(batchSettings.BatchQueryFilterCondition__c);
		Integer batchSize = Integer.valueOf(batchSettings.BatchSize__c);
		if (!test.isRunningTest()){
			System.scheduleBatch(new BWAutoArchiveArticlesBatch(), 'AutoArchiveArticlesBatch', batchInterval, batchSize);
		}
	}
    
     public static void makeLog(String articleId, String exceptionJson) {
         List<Object> params = new List<Object>{topicName,  null, 'Article Id: ' + articleId + '; Message: ' + exceptionJson};  
         LogMessage logMessage = new LogMessage(BWC_Constants.OPUS_NEBULA_MESSAGE_TEMPLATE, params);
         Logger.error(logMessage).setTopics(new List<String>{topicName});
         Logger.saveLog();
     }  
    
}