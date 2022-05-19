public with sharing class UserAccessBatch implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext paramBatchContext) {
        String dtLastRun = String.valueof(Jobduty_Rollout_Indicator__c.getInstance().Last_Job_Run_Timestamp__c).replace(' ', 'T')+'Z';
        String strQuery = 'SELECT Employee__r.User__c from Employee_Jobduty_Assignment__c' +
            ' WHERE CreatedDate >= ' +  dtLastRun;
        system.debug(strQuery);
        // Initiate Logging
        Logger.info('Initiating Logging for new batch job', paramBatchContext.getJobId());
        return Database.getQueryLocator(strQuery);
    }
    
    public void execute (Database.BatchableContext paramBatchContext, list<Employee_Jobduty_Assignment__c> scope) {
        set<Id> setUserId = new set<Id>();
        if (scope <> null && scope.size() > 0) {
            for (Employee_Jobduty_Assignment__c iter : scope) {
                setUserId.add(iter.Employee__r.User__c);
            }
        }
        if (setUserId.size() > 0) {
            list<Id> listUserUpdateId = new list<Id>();
            listUserUpdateId.addAll(setUserId);
            UserAccessHandlerService.GrantEmployeeAccessByUserId(listUserUpdateId);
        }
    }
    
    public void finish (Database.BatchableContext paramBatchContext) {
        Jobduty_Rollout_Indicator__c objUserAccessJobControl = Jobduty_Rollout_Indicator__c.getInstance(userinfo.getOrganizationId());
        objUserAccessJobControl.Last_Job_Run_Timestamp__c = system.now();
        UPDATE objUserAccessJobControl;
        
        Logger.info('Processing Completed', paramBatchContext.getJobId());

        // calling EmployeeGroupAssignmentBatch to update employee's public groups/queue memberships
        try{
            if(User_Onboarding_Config__c.getInstance().Group_Assignment_Active__c){
                EmployeeGroupAssignmentBatch objEmpGrpAssign = new EmployeeGroupAssignmentBatch();
                Id BatchId = Database.executeBatch(objEmpGrpAssign);
            }
        }catch(Exception e){
            System.debug(e);
            Logger.error('an exception occured while updating the employee public group/queue membership ' + e.getMessage());
        }finally{
            Logger.saveLog();
        }
    }

}