/*
    Allows an LWC to retrieve account details including related lists.
*/
public with sharing class BWC_AccountServiceController {

    /*
        Return list of billing accounts associated with the specified account.
        Parameter recordId passed can be Person Account Id or Interaction__c Id
    */
    @AuraEnabled
    public static String getBillingAccounts(Id recordId, Boolean onlyL1, Boolean excludeUnified, List<String> requestedTypes, List<String> requestedBans, Boolean maskUnauthorized) {

        BillingAccountsResponseWrapper responseWrapper = new BillingAccountsResponseWrapper();
        try {

            List<Billing_Account__c> billingAccounts = BWC_AccountService.getBillingAccounts(
                recordId, 
                requestedTypes != null ? new Set<String>(requestedTypes) : null, 
                requestedBans != null ? new Set<String>(requestedBans) : null, 
                onlyL1, 
                excludeUnified,
                maskUnauthorized);

            // Return success with data
            responseWrapper.success = true;
            responseWrapper.billingAccounts = billingAccounts;

        }
        catch (System.Exception e) {

            // Log
            BWC_ExceptionUtils.handleException(e, 'recordId: ' + recordId, null);

            // Return failure with message
            responseWrapper.success = false;
            responseWrapper.message = e.getMessage();

        }

        return responseWrapper.serialize();

    }

    public class BillingAccountsResponseWrapper extends BWC_ResponseWrapper {
     
        public List<Billing_Account__c> billingAccounts;

    }

    @AuraEnabled
    public static String getBillingAccountForBan(String ban) {

        BillingAccountResponseWrapper responseWrapper = new BillingAccountResponseWrapper();
        try {

            Billing_Account__c billingAccount = BWC_AccountService.getBillingAccountForBan(ban);

            // Return success with data
            responseWrapper.success = true;
            responseWrapper.billingAccount = billingAccount;

        }
        catch (System.Exception e) {

            // Log
            BWC_ExceptionUtils.handleException(e, 'ban: ' + ban, null);

            // Return failure with message
            responseWrapper.success = false;
            responseWrapper.message = e.getMessage();

        }

        return responseWrapper.serialize();

    }

    @AuraEnabled
    public static String getBillingAccountForId(String billingAccountId) {

        BillingAccountResponseWrapper responseWrapper = new BillingAccountResponseWrapper();
        try {

            Billing_Account__c billingAccount = BWC_AccountService.getBillingAccountForId(billingAccountId);

            // Return success with data
            responseWrapper.success = true;
            responseWrapper.billingAccount = billingAccount;

        }
        catch (System.Exception e) {

            // Log
            BWC_ExceptionUtils.handleException(e, 'billingAccountId: ' + billingAccountId, null);

            // Return failure with message
            responseWrapper.success = false;
            responseWrapper.message = e.getMessage();

        }

        return responseWrapper.serialize();

    }

    public class BillingAccountResponseWrapper extends BWC_ResponseWrapper {
     
        public Billing_Account__c billingAccount;

    }

    /*
        Wraps BWC_AccountService.getInteractionBillingAccount.
    */
    @AuraEnabled
    public static String getInteractionBillingAccount(Id interactionId, Id billingAccountId) {

        try {

            Billing_Account__c billingAccount = BWC_AccountService.getInteractionBillingAccount(interactionId, billingAccountId);
            return JSON.serialize(billingAccount, true);

        }
        catch (System.Exception e) {
            throw BWC_Controller.handleException(e, 'billingAccountId=' + billingAccountId, interactionId);
        }

    }

    @AuraEnabled
    public static String getSortedBillingAccounts(Id recordId, Boolean onlyL1, Boolean excludeUnified, List<String> requestedTypes, List<String> requestedBans, Boolean maskUnauthorized, String customPermission){

        BillingAccountsResponseWrapper responseWrapper;
        try {

            String responseString = getBillingAccounts(recordId, onlyL1, excludeUnified, requestedTypes, requestedBans, maskUnauthorized);

            responseWrapper = (BillingAccountsResponseWrapper) JSON.deserialize(responseString, BillingAccountsResponseWrapper.class);
            responseWrapper.billingAccounts = BWC_BillingAccountService.sortAccountsByServiceName(responseWrapper.billingAccounts, customPermission);

        } catch (Exception e) {
            // Log
            BWC_ExceptionUtils.handleException(e, 'recordId: ' + recordId, null);

            // Return failure with message
            responseWrapper.success = false;
            responseWrapper.message = e.getMessage();
        }

        return responseWrapper.serialize();
    }

    /*
        Returns Customer Account related to the interaction
    */
    @AuraEnabled
    public static String getCustomerAccount(Id recordId) {

        Account customerAccount = new Account();
        try {

            customerAccount = BWC_AccountService.getCustomerAccount(recordId);

        }
        catch (System.Exception e) {

            // Log
            throw BWC_Controller.handleException(e, 'interactionId=' + recordId);

        }

        return JSON.serialize(customerAccount, true);

    }

}