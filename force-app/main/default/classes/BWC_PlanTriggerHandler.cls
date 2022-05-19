public with sharing class BWC_PlanTriggerHandler {
    public static void delegateProcessing() {        
        if (Trigger.isAfter) {
            if (Trigger.isInsert || Trigger.isUpdate || Trigger.isDelete) {
                // In After Trigger update BillingAccount field Has_Only_Direct_TV__c
                BWC_PlanTriggerHelper.updateBillingAccountHasOnlyDirectTVOnly();
            }
        }
    }
}