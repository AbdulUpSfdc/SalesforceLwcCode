/*****
 Name             : BWKMDeleteViewCountHistoryBatch
 Description      : This is the batch class for deleting the view count of published knowledge articles in Knowledge_View_Count_History__c custom object after 75 days from its CreatedDate
 ****/
public without sharing class BWKMDeleteViewCountHistoryBatch implements Database.Batchable<sObject>{
    public Integer BATCH_SIZE;
    @TestVisible 
    public String CRON_EXPR;
    public static final String topicName = 'KM Delete ViewCount History Batch';

    public BWKMDeleteViewCountHistoryBatch(){
        getBatchSettings();
    }

	public Database.QueryLocator start(Database.BatchableContext BC){
		
        KM_Article_View_Count_Batch_Setting__mdt kmArticleViewCountBatchsettingRecord = KM_Article_View_Count_Batch_Setting__mdt.getInstance('BWKMCreateViewCountHistoryBatch');
        Integer daysToPurge = Integer.valueOf(kmArticleViewCountBatchsettingRecord.Days_To_Purge__c);
        String query = 'SELECT Id';
		query += ' FROM Knowledge_View_Count_History__c';
		query += ' WHERE CreatedDate < LAST_N_DAYS:'+daysToPurge;
        System.debug('query='+ query);
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext BC, List<Knowledge_View_Count_History__c> articleViewCounts){
        List<String> exceptionList = new List<string>();
        if(!articleViewCounts.isEmpty()){
            List<Database.DeleteResult> results = Database.delete(articleViewCounts, false);
            for (Database.DeleteResult ur : results){
				if (ur.isSuccess()){
					System.debug('View count deleted successfully : ' + ur.getId());
                }else{
					for (Database.Error err : ur.getErrors()){
                        String exceptionString = getExceptionString(err) + '; failed to delete articleViewCounts';
                        exceptionList.add(exceptionString);
                        System.debug('Exception caught in batch: ' + exceptionString);
                    }
                    makeLog(BC.getJobId(), JSON.serialize(exceptionList));
                }
            }
        }
	}

	public void finish(Database.BatchableContext BC){
		System.debug('DELETE VIEW COUNT HISTORY BATCH - FINISHED');
	}

    //get batch settings from custom metadata type
    public void getBatchSettings() {
        KM_Article_View_Count_Batch_Setting__mdt batchSettings= KM_Article_View_Count_Batch_Setting__mdt.getInstance('BWKMCreateViewCountHistoryBatch');
        BATCH_SIZE = Integer.valueOf(batchSettings.Batch_Size__c);
        CRON_EXPR = batchSettings.Cron_Expression__c;
    }

    public static void makeLog(String jobId, String exceptionJson) {
        List<Object> params = new List<Object>{topicName,  null, 'Job Id: ' + jobId + '; Exception: ' + exceptionJSON};
        KMErrorHandlingUtility.logError(exceptionJson, topicName, params);
    }  
    
	private String getExceptionString(Database.Error exceptionCaught) {
        String errorMsg = '';
        errorMsg += 'Message=' + exceptionCaught.getMessage() + ' ';
        errorMsg += 'Error Fields=' + exceptionCaught.getFields() + ' ';
        errorMsg += 'Status Code=' + exceptionCaught.getStatusCode() + ' ';
        return errorMsg;
    }
}