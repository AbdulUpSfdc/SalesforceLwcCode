public with sharing class BWC_InteractionTriggerHandler {
    public static void delegateProcessing() {
        if (Trigger.isBefore) {
            if (Trigger.isInsert) {
                // In Before Insert set the Customer__c field
                BWC_InteractionTriggerHelper.setCustomerUsingCTICallIdentifier();
            }
            if (Trigger.isUpdate) {
                // In Before Update mask the Notes field
                BWC_InteractionTriggerHelper.maskNotes();
            }

            if (Trigger.isInsert || Trigger.isUpdate) {
                // In Before Insert/Update set the Billing_Account__c field
                BWC_InteractionTriggerHelper.populateBillingAccount();
            }
        }
        
    }
}