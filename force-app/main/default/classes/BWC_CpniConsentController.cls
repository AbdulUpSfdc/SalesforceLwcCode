public with sharing class BWC_CpniConsentController {

    @AuraEnabled
    public static String updateCpniConsent(String requestJson, String ban, String accountType) {
        
        UpdateCpniConsentResponseWrapper responseWrapper = new UpdateCpniConsentResponseWrapper();

        try {

            BWC_CpniConsent.UpdateCpniConsentRequest request = (BWC_CpniConsent.UpdateCpniConsentRequest)JSON.deserialize(requestJson, BWC_CpniConsent.UpdateCpniConsentRequest.class);
            BWC_CpniConsent.UpdateCpniConsentResponse response = BWC_CpniConsentService.updateCpniConsent(request, ban, accountType);
            responseWrapper.success = true;
            responseWrapper.response = response;

        }
        catch (System.Exception e) {

            responseWrapper.success = false;
            responseWrapper.message = e.getMessage();
            BWC_ExceptionUtils.handleException(e, 'requestJson: ' + requestJson, null);

        }

        // Return the JSON, LWC will parse it.
        return responseWrapper.serialize();

    }

    /*
        Wrappers for returning response along with error information.
    */
    public class UpdateCpniConsentResponseWrapper extends BWC_ResponseWrapper {
        public BWC_CpniConsent.UpdateCpniConsentResponse response;
    }

}