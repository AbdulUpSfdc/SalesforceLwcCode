public with sharing class BWC_BillingAccountController {


    @AuraEnabled
    public static string getBillingAccountSummary(Id interactionId){

        BWC_Log.setRelatedRecordId(interactionId);

        try {

            List<Billing_Account__c> billingAccounts = BWC_BillingAccountService.getBillingAccountSummary(interactionId);
            return JSON.serialize(billingAccounts, true);

        } catch (Exception e) {

            throw BWC_Controller.handleException(e, 'interactionId='+interactionId);

        }

    }
}