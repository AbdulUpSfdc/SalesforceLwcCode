trigger BWC_Prefetch_StatusTrigger on BWC_Prefetch_Status__c (after insert, after update) {
    BWC_Prefetch_Status_TriggerHandler.delegateProcessing();
}