/* ================================================
* @author : Salesforce. inc
* @date :   09/05/2020
* @group : Case
* @description : Batch class to update Overdue Tasks flag on case and case action
*************************************************************
* Use to execute_anonymous_apex
* Database.executeBatch(new OverdueTasksBatch(), 200);
================================================*/
public without sharing class OverdueTasksBatch implements Database.Batchable<sObject> {
    public Iterable<sObject> start(Database.BatchableContext bc) {

        return Database.getQueryLocator(Case_Action_Constants.OverdueTaskCasesActionsBatch_Query);

    }

    public void execute(Database.BatchableContext bc, List<Task> overDueTaskList) {
        Boolean allOrNothing = false;

        //collect overdue tasks
        Map<Id,Task> overDueTaskMap = new Map<Id,Task>(overDueTaskList);

        //container to manager update record
        Map<Id,SObject> updateMap = new  Map<Id,SObject>();

        //record Ids to update
        set<Id> overDueTaskCaseId = new set<Id>();
        set<Id> overDueTaskCaseActionId = new set<Id>();


        for(Id key : overDueTaskMap.keySet()){
            if(overDueTaskMap.get(key).What.Type == Case_Action_Constants.Case_DEV_NAME){
                overDueTaskCaseId.add(overDueTaskMap.get(key).WhatId);
            }
            else if(overDueTaskMap.get(key).What.Type == Case_Action_Constants.Case_Action_DEV_NAME){
                overDueTaskCaseActionId.add(overDueTaskMap.get(key).WhatId);
            }
        }
        //pull parent cases to update
        for(Case c : [SELECT Id, OverdueTasks__c FROM Case WHERE Id IN :overDueTaskCaseId AND OverdueTasks__c = FALSE ]) {
            c.OverdueTasks__c = TRUE;
            updateMap.put(c.Id, c);
        }
        //pull parent case actions to update
        for(Case_Action__c cAction : [SELECT Id, Overdue_Tasks__c FROM Case_Action__c WHERE Id IN :overDueTaskCaseActionId AND Overdue_Tasks__c = FALSE]) {
            cAction.Overdue_Tasks__c = TRUE;
            updateMap.put(cAction.Id, cAction);
        }
        //update parent cases
        List<Database.SaveResult> saveResult = Database.update(updateMap.values(), allOrNothing);
    }

    public void finish(Database.BatchableContext bc) {
        // execute any post-processing operations
    }
}

/*





     public Iterable<sObject> start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
        	'SELECT Id,WhatId FROM Task WHERE IsClosed = FALSE AND ActivityDate <= TODAY AND What.Type = \'Case\' ' +
            'ORDER BY WhatId ASC NULLS FIRST'
        );

    }

    public void execute(Database.BatchableContext bc, List<Task> overdueTasks) {
        Set<String> overdueCaseIds = new Set<String>();
        for(Task t : overdueTasks) {
            overdueCaseIds.add(t.WhatId);
        }

        List<Case> casesToUpdate = new List<Case>();
        for(Case c : [SELECT Id,OverdueTasks__c FROM Case WHERE Id IN :overdueCaseIds]) {
       		c.OverdueTasks__c = TRUE;
            casesToUpdate.add(c);
        }

        Boolean allOrNothing = false;
      	List<Database.SaveResult> saveResult = Database.update(casesToUpdate, allOrNothing);
    }

    public void finish(Database.BatchableContext bc) {
    }

}*/