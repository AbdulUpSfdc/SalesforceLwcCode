/*****
 Name             : BWKMCreateViewCountHistoryBatch
 Description      : This is the batch class for inserting the view count of published knowledge articles in Knowledge_View_Count_History__c custom object
 ****/
public without sharing class BWKMCreateViewCountHistoryBatch implements Database.Batchable<sObject>, Database.Stateful {
    public final String VIEW_COUNT_CAPTURE_DATE;
    public Integer BATCH_SIZE;
    @TestVisible 
    public String CRON_EXPR;
    @TestVisible public Boolean STOP_CREATE_VIEW_COUNT_BATCH_RUN;

    public BWKMCreateViewCountHistoryBatch(String viewCountCaptureDate){
        this.VIEW_COUNT_CAPTURE_DATE = viewCountCaptureDate;
        getBatchSettings();
    }
    public BWKMCreateViewCountHistoryBatch(){
        this.VIEW_COUNT_CAPTURE_DATE = Datetime.now().format('MMddYYYY');
        getBatchSettings();
    }

	public Database.QueryLocator start(Database.BatchableContext BC){
		String query = 'SELECT Id, ArticleNumber, ArticleTotalViewCount, Title, UrlName, VersionNumber';
		query += ' FROM Knowledge__kav';
		query += ' WHERE PublishStatus = \'Online\'';
        if(STOP_CREATE_VIEW_COUNT_BATCH_RUN){
            System.debug('Stop Create View Count Batch Run to avoid batch run is on in KM Article View Count Batch Setting.\n Skipping BWKMCreateViewCountHistoryBatch run');
            List<Object> params = new List<Object>{'Stop Create View Count Batch Run to avoid batch run is on in KM Article View Count Batch Setting.\n Skipping BWKMCreateViewCountHistoryBatch run'};
        
            LogMessage logMessage = new LogMessage(BWC_Constants.OPUS_NEBULA_MESSAGE_TEMPLATE, params);
            Logger.info(logMessage).setTopics(new List<String>{'KM Article View Count Batch Info'});
            Logger.saveLog();      
            query += ' LIMIT 0';
        }
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext BC, List<knowledge__kav> articles){
		System.debug('VIEW COUNT HISTORY BATCH - INITIALIZED');
		List<Knowledge_View_Count_History__c> viewCountHistoryList = new List<Knowledge_View_Count_History__c>();
        List<String> exceptionList = new List<String>();
        Integer i = 0;

		for (Knowledge__kav article : articles){
			Knowledge_View_Count_History__c viewCountHistory = new Knowledge_View_Count_History__c();
            viewCountHistory.ArticleNumber__c = article.ArticleNumber;
            viewCountHistory.ArticleViewCount__c = article.ArticleTotalViewCount;
            viewCountHistory.Title__c = article.Title;
            viewCountHistory.Unique_Id__c = VIEW_COUNT_CAPTURE_DATE + '-' + article.ArticleNumber;
            viewCountHistory.UrlName__c = article.UrlName;
            viewCountHistory.View_Count_Capture_Date__c = Date.newInstance(Integer.valueOf(VIEW_COUNT_CAPTURE_DATE.right(4)), Integer.valueOf(VIEW_COUNT_CAPTURE_DATE.left(2)), Integer.valueOf(VIEW_COUNT_CAPTURE_DATE.mid(2, 2)));
            viewCountHistoryList.add(viewCountHistory);
        }
        if(!viewCountHistoryList.isEmpty()){
            Database.UpsertResult[] results = Database.upsert(viewCountHistoryList, Knowledge_View_Count_History__c.Unique_Id__c, false);
            for (Database.UpsertResult ur : results){
				if (ur.isSuccess()){
					System.debug('View count saved successfully : ' + ur.getId());
				} 
                else{
					for (Database.Error err : ur.getErrors()){
                        String exceptionString = getExceptionString(err) + '; failed to capture view count of article: ' + viewCountHistoryList[i].ArticleNumber__c;
                        exceptionList.add(exceptionString);
                        System.debug('Exception caught in batch: ' + exceptionString);
                    }
                    makeLog(BC.getJobId(), JSON.serialize(exceptionList));
                }
                i++;
            }
        }
	}

	public void finish(Database.BatchableContext BC){
		System.debug('VIEW COUNT HISTORY BATCH - FINISHED');
	}

    //get batch settings from custom metadata type
    public void getBatchSettings() {
        KM_Article_View_Count_Batch_Setting__mdt batchSettings = new KM_Article_View_Count_Batch_Setting__mdt();
        batchSettings= [SELECT Batch_Size__c, Cron_Expression__c, Stop_Create_View_Count_Batch_Run__c
                        FROM KM_Article_View_Count_Batch_Setting__mdt 
                        WHERE DeveloperName = 'BWKMCreateViewCountHistoryBatch'];
        BATCH_SIZE = Integer.valueOf(batchSettings.Batch_Size__c);
        CRON_EXPR = batchSettings.Cron_Expression__c;
        STOP_CREATE_VIEW_COUNT_BATCH_RUN = batchSettings.Stop_Create_View_Count_Batch_Run__c;
    }

    public void makeLog(String jobId, String exceptionJson) {
        List<Object> params = new List<Object>{'KM Article View Count Batch Error',  null, 'Job Id: ' + jobId + '; Exception: ' + exceptionJSON};
        
        LogMessage logMessage = new LogMessage(BWC_Constants.OPUS_NEBULA_MESSAGE_TEMPLATE, params);
        Logger.error(logMessage).setTopics(new List<String>{'KM Article View Count Batch Error'});
        Logger.saveLog();      
    }  
    
	private String getExceptionString(Database.Error exceptionCaught) {
        String errorMsg = '';
        errorMsg += 'Message=' + exceptionCaught.getMessage() + ' ';
        errorMsg += 'Error Fields=' + exceptionCaught.getFields() + ' ';
        errorMsg += 'Status Code=' + exceptionCaught.getStatusCode() + ' ';
        return errorMsg;
    }
}