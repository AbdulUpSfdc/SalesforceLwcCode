trigger InteractionTrigger on Interaction__c (before insert, before update, after insert, after update) {
    BWC_InteractionTriggerHandler.delegateProcessing();
}