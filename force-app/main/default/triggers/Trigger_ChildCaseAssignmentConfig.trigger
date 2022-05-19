//PBCNTRSENT-520
trigger Trigger_ChildCaseAssignmentConfig on ChildCaseAssignmentConfig__c (before insert,before update) {
    ChildCaseAssignmentConfigTriggerHandler.handler();
}