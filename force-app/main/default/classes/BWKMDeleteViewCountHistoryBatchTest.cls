@isTest
public class BWKMDeleteViewCountHistoryBatchTest {
	@TestSetup
    public static void testData(){
        Knowledge_View_Count_History__c knowledgeViewCountHistoryRecord = new Knowledge_View_Count_History__c();
        insert knowledgeViewCountHistoryRecord;
    }
    
    public static testMethod void deleteViewCountRecordsBatchRunTest () {
        Test.startTest();
        BWKMDeleteViewCountHistoryBatch batch = new BWKMDeleteViewCountHistoryBatch();
        Id jobId = Database.executeBatch(batch);
        Test.stopTest();
        System.debug('jobId=' + jobId);
        
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors FROM AsyncApexJob WHERE Id =: jobId ];
        List<Knowledge_View_Count_History__c> viewCountRecords= [SELECT Id FROM Knowledge_View_Count_History__c];
        
        System.assertEquals('Completed', job.Status);
        System.assertEquals(0, job.NumberOfErrors);
    }
    
    public static testMethod void deleteViewCountRecordsTest () {
        List<Knowledge_View_Count_History__c> knowledgeViewCountHistoryRecordList = [SELECT Id FROM Knowledge_View_Count_History__c];
        Test.startTest();
        BWKMDeleteViewCountHistoryBatch batch = new BWKMDeleteViewCountHistoryBatch();
        batch.execute(null, knowledgeViewCountHistoryRecordList);
        Test.stopTest();
        
        List<Knowledge_View_Count_History__c> viewCountRecords= [SELECT Id FROM Knowledge_View_Count_History__c];
        System.assert(viewCountRecords.size()==0);
    }
    
    public static testMethod void testExceptionScenario () {
        BWKMDeleteViewCountHistoryBatch batch = new BWKMDeleteViewCountHistoryBatch();
        Id jobId = Database.executeBatch(batch);
        List<Knowledge_View_Count_History__c> knowledgeViewCountHistoryRecordList = [SELECT Id  FROM Knowledge_View_Count_History__c];
        delete knowledgeViewCountHistoryRecordList;
        
        Test.startTest();
        batch = new BWKMDeleteViewCountHistoryBatch();
        batch.execute(new BatchableContextImplementation(jobId), knowledgeViewCountHistoryRecordList);
        Test.stopTest();
    }
    
    public class BatchableContextImplementation implements Database.BatchableContext
    {
        private Id job;
        public BatchableContextImplementation(ID job)
        {
            this.job = job;
        }
        public Id getChildJobID()
        {
            return null;
        }
        public Id getJobID()
        {
            return job;
        }
    }
    
     public static testMethod void scheduleBatchTest() {
        Test.startTest();
        Id jobId = BWKMDeleteViewCountHistoryBatchScheduler.schedule();
        Test.stopTest(); 
    }
}