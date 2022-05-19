/* ================================================
* @class name: OverdueCasesActionsBatch
* @author: Salesforce Inc.
* @purpose: update parent cases when overdue case_actions__c are present
* @created date (mm/dd/yyyy) :  6/03/202
*************************************************************
* Use to execute_anonymous_apex
* Database.executeBatch(new OverdueCasesActionsBatch(), 200);
================================================*/
public without sharing class OverdueCasesActionsBatch implements Database.Batchable<sObject> {
    public Iterable<sObject> start(Database.BatchableContext bc) {

        return Database.getQueryLocator(Case_Action_Constants.OverdueCasesActionsBatch_Query);

    }

    public void execute(Database.BatchableContext bc, List<Case_Action__c> overdueChildCasesAction) {
        Boolean allOrNothing = false;
        //container to manager update record
        Map<Id,SObject> upDateMap = new  Map<Id,SObject>();
        //record Ids to update
        Set<id> parentCaseIds = new Set<id>();

        //collect case ids of parent case
        for(Case_Action__c cAction : overdueChildCasesAction) {
            parentCaseIds.add(cAction.Case__c);
        }
        //pull parent cases to update
        for(Case c : [SELECT Id, OverdueChildCases__c FROM Case WHERE Id IN :parentCaseIds AND OverdueChildCases__c = FALSE]) {
            c.OverdueChildCases__c = TRUE;
            upDateMap.put(c.Id, c);
        }
        //update parent cases
        List<Database.SaveResult> saveResult = Database.update(upDateMap.values(), allOrNothing);
    }
    public void finish(Database.BatchableContext bc) {

    }
}