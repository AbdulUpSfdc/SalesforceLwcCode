/*
    Aura enabled methods for for API_CUSTOMER_PROFILE.
*/
public with sharing class BWC_CustomerProfileController {

    /*
        Method for calling from LWC. Returns serialized JSON.
    */
    @AuraEnabled
    public static String resetPassword(String requestJson) {

        if (String.isEmpty(requestJson)) {
            throw new BWC_Exception('Argument required: requestJson');
        }

        ResetPasswordResponseWrapper responseWrapper = new ResetPasswordResponseWrapper();

        try {

            BWC_CustomerProfile.PasswordResetRequest request = (BWC_CustomerProfile.PasswordResetRequest)JSON.deserialize(requestJson, BWC_CustomerProfile.PasswordResetRequest.class);
            BWC_CustomerProfile.PasswordResetResponse response = BWC_CustomerProfileService.resetPassword(request);
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

    public class ResetPasswordResponseWrapper extends BWC_ResponseWrapper {
        public BWC_CustomerProfile.PasswordResetResponse response;
    }

}