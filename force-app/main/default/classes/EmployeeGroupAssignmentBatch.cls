public with sharing class EmployeeGroupAssignmentBatch implements Database.Batchable<sObject>{
    public Database.QueryLocator start(Database.BatchableContext paramBatchContext){
        String lastJobRunTime =  String.valueOf(Jobduty_Rollout_Indicator__c.getInstance().Last_Group_Assignment_Job_Timestamp__c).replace(' ', 'T') + 'Z';
        String empQueueQuery = 'SELECT Employee__r.User__c, Group_Type__c, Public_Group_Queue_Name__c, Activity__c, Group_ID__c ' + 
                                'FROM Employee_Group_Assignment__c ' +
                                'WHERE LastModifiedDate >= ' + lastJobRunTime;
        System.debug(empQueueQuery);
        Logger.info('Batch job to update employees in public groups/queues started', paramBatchContext.getJobId());
        return Database.getQueryLocator(empQueueQuery);
    }

    public void execute(Database.BatchableContext paramBatchContext, List<Employee_Group_Assignment__c> scope){
        if(scope <> null && scope.size() >0){
            UserAccessHandlerService.ManageEmployeeGroupMembership(scope);
        }
    }

    public void finish (Database.BatchableContext paramBatchContext) {
        Jobduty_Rollout_Indicator__c objEmpGrpAssignJobControl = Jobduty_Rollout_Indicator__c.getInstance(userinfo.getOrganizationId());
        objEmpGrpAssignJobControl.Last_Group_Assignment_Job_Timestamp__c = System.now();
        UPDATE objEmpGrpAssignJobControl;
        
        Logger.info('Batch job to update employees in public groups/queues completed', paramBatchContext.getJobId());
    }
}