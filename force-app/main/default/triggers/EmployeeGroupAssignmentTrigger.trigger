trigger EmployeeGroupAssignmentTrigger on Employee_Group_Assignment__c (before insert, before update, after insert, after update) {
    EmployeeGroupAssignmentTriggerHandler.updateGroupIdHandler();
}