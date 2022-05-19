/*****
 Name             : BWArticlePublishPlatformEventBatch
 Description      : This is the batch class for publishing a platform event for recently published/archived articles
 ****/

/**This batch class has been replaced by other mechanisms for publishing the event. It has been unscheduled 
and deprecated because it was touching articles after publication.*/
public class BWArticlePublishPlatformEventBatch {}

/*public class BWArticlePublishPlatformEventBatch implements Database.Batchable<sObject>{
    private final Integer BATCH_INTERVAL;
    private final Datetime DATETIME_VALUE;
    private final Integer BATCH_SIZE;
    
	public BWArticlePublishPlatformEventBatch(){
		//get filter criteria value for Article LastPublishedDate from custom metadata
		BatchSetting__mdt batchSettings = [SELECT BatchQueryFilterCondition__c, BatchSize__c
		                                   FROM BatchSetting__mdt
		                                   WHERE MasterLabel = 'BWArticlePublishPlatformEventBatch'];

		this.BATCH_INTERVAL = Integer.valueOf(batchSettings.BatchQueryFilterCondition__c);
        this.DATETIME_VALUE = System.now().addMinutes(BATCH_INTERVAL);
        this.BATCH_SIZE = Integer.valueOf(batchSettings.BatchSize__c);
	}

	public Database.QueryLocator start(Database.BatchableContext BC){
		String query = 'SELECT Id, Title';
		query += ' FROM Knowledge__kav';
		query += ' WHERE ((PublishStatus = \'Online\' AND IsLatestVersion = true AND LastPublishedDate > :DATETIME_VALUE)';
		query += ' OR (PublishStatus = \'Archived\' AND ArchivedDate > :DATETIME_VALUE))';
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext BC, List<sObject> scope){
		System.debug('PUBLISH PLATFORM EVENT BATCH - INITIALIZED');
        Set<Id> articleIdSet = new Set<Id>();
        String publishEventResult;

		for (sObject article : scope){
			articleIdSet.add(article.Id);
		}
		//publish platform events for the recently published/archived articles
		if (!articleIdSet.isEmpty()){
			publishEventResult = BWArticlePublishPlatformEventHelper.publishPlatformEvents(articleIdSet);
		}
	}

	public void finish(Database.BatchableContext BC){
        System.debug('PUBLISH PLATFORM EVENT BATCH - FINISHED');
        scheduleNextBatchJob(BATCH_INTERVAL * (-1), BATCH_SIZE);
	}

	private static void scheduleNextBatchJob(Integer batchInterval, Integer batchSize){
		if (!test.isRunningTest()){
                    System.scheduleBatch(new BWArticlePublishPlatformEventBatch(), 'ArticlePublishPlatformEventBatch', batchInterval, batchSize);
		}
	}
}*/