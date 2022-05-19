trigger PlanTrigger on Plan__c (after insert, after update, after delete) {
    BWC_PlanTriggerHandler.delegateProcessing();
}