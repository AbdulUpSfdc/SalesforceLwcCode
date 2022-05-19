public with sharing class JobdutyAccessGrantSchedulable implements Schedulable {
    
    public void execute (System.SchedulableContext paramScheduleCtx) {
        UserAccessBatch newJobInstance = new UserAccessBatch();
        Integer jobsize = Integer.valueof(Jobduty_Rollout_Indicator__c.getInstance().Job_Batch_Size__c <> null ? Jobduty_Rollout_Indicator__c.getInstance().Job_Batch_Size__c : 50);
        Database.executeBatch(newJobInstance, jobsize);
    }

}