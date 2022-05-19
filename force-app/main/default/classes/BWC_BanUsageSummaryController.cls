/*
    Exposes methods to allow LWC to call Wireless Usage Summary.
*/
public with sharing class BWC_BanUsageSummaryController {

    @AuraEnabled
    public static String getUsageSummary(String requestJson, String recordId) {

        UsageSummaryResponseWrapper responseWrapper = new UsageSummaryResponseWrapper();
        responseWrapper.success = false;

        try {

            BWC_BanUsageSummary.UsageSummaryRequest request = (BWC_BanUsageSummary.UsageSummaryRequest)JSON.deserialize(requestJson, BWC_BanUsageSummary.UsageSummaryRequest.class);
            
            // Call the service
            BWC_BanUsageSummary.UsageSummaryResponse returnValue = BWC_BanUsageSummaryService.getCustomerUsageSummary(request);

            // Initialize response to the LWC
            BWC_BanUsageSummary.CustomerUsageSummary customerUsageSummary = new BWC_BanUsageSummary.CustomerUsageSummary();
            customerUsageSummary = BWC_BanUsageSummaryService.generateUsageSummary(recordId, returnValue.response);
            System.debug('generateUsageSummaryS1: ' + returnValue.response);

            // Add response to wrapper to be sent to UI
            responseWrapper.response = customerUsageSummary;
            responseWrapper.success = true;

        }
        catch (System.Exception e) {

            System.debug('Controller getUsageSummary exception: ' + e.getMessage());

            responseWrapper.success = false;
            responseWrapper.message = e.getMessage();
            BWC_ExceptionUtils.handleException(e, null, null);

        }

        return responseWrapper.serialize();

    }

    /**
     * Get interaction authorization json and return the authorization method for interaction activity
     */
    @AuraEnabled
    public static String getInteractionAuthentication(String interactionId, String billingAccountId) {
        // Get interaction
        Interaction__c interaction = BWC_Interaction.getInteraction(interactionId);
        if (interaction == null) {
            throw new BWC_Exception('Couldn\'t retrieve interaction');
        }

        // Get authentication method for billing account
        BWC_AuthorizationCallout.AuthorizationStatusContent authorizationContent = 
            (BWC_AuthorizationCallout.AuthorizationStatusContent)JSON.deserialize(interaction.Authorization_Json__c, BWC_AuthorizationCallout.AuthorizationStatusContent.class);
        
        String custAuthorization;
        if (authorizationContent.associatedAccounts != null) {
            for (BWC_AuthorizationCallout.AssociatedAccount associatedAccount : authorizationContent.associatedAccounts) {
                if (associatedAccount.billingAccountId == billingAccountId) {
                    if (associatedAccount.authenticationMethod != null) {
                        custAuthorization = associatedAccount.accountType + ' - ' + associatedAccount.authenticationMethod;
                    } else {
                        custAuthorization = associatedAccount.accountType + ' - ' + associatedAccount.authorizationLevel;
                    }
                }
            }
        }

        return custAuthorization;
    }

    /*
        Wrapper for returning response along with error information.
    */
    public class UsageSummaryResponseWrapper extends BWC_ResponseWrapper {
        public BWC_BanUsageSummary.CustomerUsageSummary response;
    }

}