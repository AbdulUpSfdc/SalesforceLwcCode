/*****
 Name             : BWKMCreateViewCountHistoryBatchScheduler
 Description      : This is to schedule the batch class BWKMCreateViewCountHistoryBatch
 ****/
global without sharing class BWKMCreateViewCountHistoryBatchScheduler implements Schedulable {

    public void execute(SchedulableContext SC) {
        BWKMCreateViewCountHistoryBatch batch = new BWKMCreateViewCountHistoryBatch();
        Database.executeBatch(batch, batch.BATCH_SIZE);
        System.debug('KM ARTICLE VIEW COUNT BATCH WILL START EXECUTION');
    }

    public static String schedule(){
        String jobName = '';
        if(!test.isRunningTest()){
            jobName = 'KM Article View Count Batch';
        }
        else{
            jobName = 'KM Article View Count Batch Test Execution';
        }

        BWKMCreateViewCountHistoryBatch batch = new BWKMCreateViewCountHistoryBatch();
        Id jobId = system.schedule(jobName, batch.CRON_EXPR, new BWKMCreateViewCountHistoryBatchScheduler());
        System.debug('KM ARTICLE VIEW COUNT BATCH IS SCHEDULED');
        return jobId;
    }
}