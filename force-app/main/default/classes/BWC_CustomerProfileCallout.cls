/*
    API calls for API_CUSTOMER_PROFILE.
*/
public with sharing class BWC_CustomerProfileCallout {

    /*
        Reset MyAT&T password and/or security question.
    */
    public static BWC_CustomerProfile.PasswordResetResponse resetPassword(BWC_CustomerProfile.PasswordResetRequest request) {

        // Serialize
        String requestBody = JSON.serialize(request, true);

        // Make the call
        HttpResponse response = BWC_IntegrationUtility.makeHTTPCallout(BWC_Constants.API_CUSTOMER_PROFILE, requestBody, 'password/reset', null, 'POST');

        // Attempt deserialize
        BWC_CustomerProfile.PasswordResetResponse returnValue;
        try {
            returnValue = (BWC_CustomerProfile.PasswordResetResponse)JSON.deserialize(response.getBody(), BWC_CustomerProfile.PasswordResetResponse.class);
        }
        catch (System.JSONException e) {
            throw new BWC_Exception('Failed to deserialize HTTP response body.', e);
        }

        return returnValue;

    }

}