public with sharing class BWC_CpniConsentCallout {

    public static BWC_CpniConsent.UpdateCpniConsentResponse updateCpniConsent(BWC_CpniConsent.UpdateCpniConsentRequest request, String ban, String accountType) {

        BWC_CpniConsent.UpdateCpniConsentResponse returnValue;

        if (request == null) {
            throw new BWC_Exception('Argument required: request');
        }

        // Serialize
        String requestBody = JSON.serialize(request, true);

        // Make the call
        try {

            HttpResponse response = BWC_IntegrationUtility.makeHTTPCallout(BWC_Constants.API_UPDATE_CONSENT, requestBody, ban + '/consents', 'accountType=' + accountType);

            // Attempt deserialize
            try {
                returnValue = (BWC_CpniConsent.UpdateCpniConsentResponse)JSON.deserialize(response.getBody(), BWC_CpniConsent.UpdateCpniConsentResponse.class);
            }
            catch (System.JSONException e) {
                throw new BWC_Exception('Failed to deserialize HTTP response body.', e);
            }

        }
        catch (BWC_HttpException e) {

            throw e;

        }

        return returnValue;

    }

}