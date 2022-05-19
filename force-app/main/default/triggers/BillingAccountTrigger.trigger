trigger BillingAccountTrigger on Billing_Account__c (before insert, before update) {
    BWC_BillingAccountTriggerHandler.delegateProcessing();
}