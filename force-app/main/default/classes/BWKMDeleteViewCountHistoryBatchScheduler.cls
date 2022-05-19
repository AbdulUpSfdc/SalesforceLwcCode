/*****
 Name             : BWKMDeleteViewCountHistoryBatchScheduler
 Description      : This is to schedule the batch class BWKMDeleteViewCountHistoryBatch
 ****/
global without sharing class BWKMDeleteViewCountHistoryBatchScheduler implements Schedulable {

    public void execute(SchedulableContext SC) {
        BWKMDeleteViewCountHistoryBatch batch = new  BWKMDeleteViewCountHistoryBatch();
        Database.executeBatch(batch, batch.BATCH_SIZE);
        System.debug('KM ARTICLE DELETE VIEW COUNT BATCH WILL START EXECUTION');
    }

    public static String schedule(){
        String jobName = '';
        if(!test.isRunningTest()){
            jobName = 'KM Article Delete View Count Batch';
        }
        else{
            jobName = 'KM Article Delete View Count Batch Test Execution';
        }

         BWKMDeleteViewCountHistoryBatch batch = new  BWKMDeleteViewCountHistoryBatch();
        Id jobId = system.schedule(jobName, batch.CRON_EXPR, new BWKMDeleteViewCountHistoryBatchScheduler());
        System.debug('KM ARTICLE DELETE VIEW COUNT BATCH IS SCHEDULED');
        return jobId;
    }
}