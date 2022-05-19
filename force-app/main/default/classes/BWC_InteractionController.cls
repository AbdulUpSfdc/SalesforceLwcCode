public with sharing class BWC_InteractionController {

    /**************************************************************************
     getInteractionNotifications
    **************************************************************************/

    @AuraEnabled(continuation = true)
    public static Object getInteractionNotificationsCont(Id interactionId) {
        
        try {

            // Call service with continuation
            BWC_InteractionService.GetInteractionNotificationsService service = new BWC_InteractionService.GetInteractionNotificationsService(interactionId);
            Object response = service.callWithContinuation();

            if (response instanceof Continuation) {
                // It's a continuation, so need to set the method to call when continuation returns
                ((Continuation)response).continuationMethod = 'getInteractionNotificationsResp';
                return response;
            }

            // No continuation needed, so return it directly
            BWC_InteractionService.GetInteractionNotificationsResponse notificationsResponse = (BWC_InteractionService.GetInteractionNotificationsResponse)response;
            return notificationsResponse.serialize();

        }
        catch (System.Exception e) {
            // Turn into an AuraHandledException containing embedded JSON that client can parse.
            throw BWC_Controller.handleException(e, 'interactionId:' + interactionId);
        }

    }

    @AuraEnabled
    public static String getInteractionNotificationsResp(List<String> labels, Object state) {

        try {

            BWC_InteractionService.GetInteractionNotificationsService service = (BWC_InteractionService.GetInteractionNotificationsService)state;
            BWC_InteractionService.GetInteractionNotificationsResponse notificationsResponse = (BWC_InteractionService.GetInteractionNotificationsResponse)service.processContinuationResponse();
            return notificationsResponse.serialize();

        }
        catch (System.Exception e) {
            // Turn into an AuraHandledException containing embedded JSON that client can parse.
            throw BWC_Controller.handleException(e);
        }

    }

    /**************************************************************************
    **************************************************************************/

    /**************************************************************************
     autoSearchInteractionForCustomer
    **************************************************************************/

    @AuraEnabled(continuation = true)
    public static Object autoSearchInteractionForCustomerCont(Id interactionId) {
        
        try {

            // Call service with continuation
            BWC_InteractionService.AutoSearchInteractionForCustomerService service = new BWC_InteractionService.AutoSearchInteractionForCustomerService(interactionId);
            Object response = service.callWithContinuation();

            if (response instanceof Continuation) {
                // It's a continuation, so need to set the method to call when continuation returns
                ((Continuation)response).continuationMethod = 'autoSearchInteractionForCustomerResp';
                return response;
            }

            // No continuation needed, so return it directly
            BWC_InteractionService.AutosearchResponse autoSearchResponse = (BWC_InteractionService.AutosearchResponse)response;
            return autoSearchResponse.serialize();

        }
        catch (System.Exception e) {
            // Turn into an AuraHandledException containing embedded JSON that client can parse.
            throw BWC_Controller.handleException(e, 'interactionId:' + interactionId);
        }

    }

    @AuraEnabled
    public static String autoSearchInteractionForCustomerResp(List<String> labels, Object state) {

        try {

            BWC_InteractionService.AutoSearchInteractionForCustomerService service = (BWC_InteractionService.AutoSearchInteractionForCustomerService)state;
            BWC_InteractionService.AutosearchResponse notificationsResponse = (BWC_InteractionService.AutosearchResponse)service.processContinuationResponse();
            return notificationsResponse.serialize();

        }
        catch (System.Exception e) {
            // Turn into an AuraHandledException containing embedded JSON that client can parse.
            throw BWC_Controller.handleException(e);
        }

    }

    /**************************************************************************
    **************************************************************************/

    /*
        Allows imperative retrieve of interaction record.
    */
    @AuraEnabled
    public static String getInteraction(String interactionId) {

        try {

            Interaction__c interaction = BWC_Interaction.getInteraction(interactionId);

            // Mask auth data
            if (String.isNotEmpty(interaction.Authorization_Json__c)) {

                BWC_AuthorizationCallout.AuthorizationStatusContent authorizationContent = 
                    (BWC_AuthorizationCallout.AuthorizationStatusContent)JSON.deserialize(interaction.Authorization_Json__c, BWC_AuthorizationCallout.AuthorizationStatusContent.class);

                authorizationContent.maskCommunicationMethods();
                interaction.Authorization_Json__c = JSON.serialize(authorizationContent, true);

            }

            return JSON.serialize(interaction, true);

        }
        catch (System.Exception e) {

            // Turn into an AuraHandledException containing embedded JSON that client can parse.
            throw BWC_Controller.handleException(e);

        }

    }

    /*
        Used by client to poll to find customer and billing account which have been prefetched by external process.
    */
    @AuraEnabled
    public static String checkPrefetchStatus(String ctiCallIdentifier) {

        try {

            BWC_InteractionService.PrefetchStatusResult result = BWC_InteractionService.checkPrefetchStatus(ctiCallIdentifier);
            return result.serialize();

        }
        catch (System.Exception e) {
            throw BWC_Controller.handleException(e);
        }

    }

    /*
        Tell whether the agent needs to ask the customer for CPNI Consent, based upon authentication and billing account preference.
    */
    @AuraEnabled
    public static Boolean checkCpniConsent(Id interactionId) {

        try {

            Interaction__c interaction = [
                SELECT
                    Id, RecordType.DeveloperName, Authentication_Method_Used__c, Billing_Account__r.CPNI_Preference__c, Cpni_Consent__c
                FROM
                    Interaction__c
                WHERE
                    Id = :interactionId
            ];

            // CPNI Consent was already set for this interaction
            if (interaction.Cpni_Consent__c != null) {
                return false;
            }

            Boolean isBypass = interaction.Authentication_Method_Used__c == BWC_Authentication.AUTHENTICATION_METHOD_BYPASS;
            Boolean isOffline = interaction.RecordType.DeveloperName == BWC_Interaction.RECORD_TYPE_OFFLINE;
            String cpniPreference = interaction.Billing_Account__r.CPNI_Preference__c;

            if (isOffline || isBypass || cpniPreference == 'Permanent/Yes' || cpniPreference == 'Implied') {

                // Will not ask agent, set preference on interaction
                interaction.Cpni_Consent__c = cpniPreference;
                update interaction;
    
                // CPNI consent not needed
                return false;

            }

            // Consent needed
            return true;

        }
        catch (System.Exception e) {
            // Turn into an AuraHandledException containing embedded JSON that client can parse.
            throw BWC_Controller.handleException(e);
        }

    }

    @AuraEnabled
    public static void setCpniConsent(Id interactionId, String cpniConsent, Id billingAccountId) {

        try {
            BWC_InteractionService.setCpniConsent(interactionId, cpniConsent, billingAccountId);
        }
        catch (System.Exception e) {
            // Turn into an AuraHandledException containing embedded JSON that client can parse.
            throw BWC_Controller.handleException(e);
        }

    }


}