/*
Call Mulesoft to add, update, or delete a payment profile.
*/
public with sharing class BWC_PaymentProfileCallout { 
    
    public static BWC_PaymentProfile.PaymentProfileResponse postPaymentProfile(
        BWC_PaymentProfile.PaymentProfile paymentProfile, 
        String mode
    ) {
        return postPaymentProfile( paymentProfile, mode, false );
    }
    
    public static BWC_PaymentProfile.PaymentProfileResponse postPaymentProfile(
        BWC_PaymentProfile.PaymentProfile paymentProfile, 
        String mode,
        Boolean isTempProfile
    ) {
        
        BWC_PaymentProfile.PaymentProfileRequest request = baseOfExistingMethod(paymentProfile,mode );
        
        // Serialize
        String requestBody = JSON.serialize(request, true);
        
        System.debug('Request Body:' + requestBody);
        
        String queryStr = 
            'mode=' + EncodingUtil.urlEncode(mode, 'UTF-8')
            + ((isTempProfile) ? '&isTemporaryProfile=true' : '');
        
        // Make the call
        HttpResponse response = BWC_IntegrationUtility.makeHTTPCallout(
            BWC_Constants.API_PAYMENT_PROFILE, 
            requestBody, 
            null, queryStr
        );
        
        // Attempt deserialize
        BWC_PaymentProfile.PaymentProfileResponse returnValue;
        try {
            returnValue = 
                (BWC_PaymentProfile.PaymentProfileResponse)JSON.deserialize(response.getBody(), BWC_PaymentProfile.PaymentProfileResponse.class);
        }
        catch (System.JSONException e) {
            throw new BWC_Exception('Failed to deserialize HTTP response body.', e);
        }
        
        return returnValue;
        
    }
    
    public static BWC_PaymentProfile.PaymentProfileRequest baseOfExistingMethod(
        BWC_PaymentProfile.PaymentProfile paymentProfile,                                        
        String mode){
            if (paymentProfile == null) {
                throw new BWC_Exception('Argument required: paymentProfile');
            }
            
            if (mode == null) {
                throw new BWC_Exception('Argument required: mode');
            }
            
            // Build full request
            BWC_PaymentProfile.PaymentProfileRequest request = new BWC_PaymentProfile.PaymentProfileRequest();
            if (mode == BWC_PaymentProfile.MODE_ADD) {
                request.addRequest = paymentProfile;
            }
            else if (mode == BWC_PaymentProfile.MODE_UPDATE) {
                request.updateRequest = paymentProfile;
            }
            else if (mode == BWC_PaymentProfile.MODE_DELETE) {
                request.deleteRequest = paymentProfile;
            }
            else {
                throw new BWC_Exception('Unknown mode: ' + mode);
            }
            
            return request;
        }
    
    public static BWC_PaymentProfile.PaymentProfileResponse postPaymentProfile(
        BWC_PaymentProfile.PaymentProfile paymentProfile, 
        String mode,
        Boolean isTempProfile,
        Boolean isReturnProfiles
    ) {
        BWC_PaymentProfile.PaymentProfileRequest request = baseOfExistingMethod(paymentProfile,mode );
        String requestBody = JSON.serialize(request, true);
        
        System.debug('Request Body:' + requestBody);
        
        String queryStr = 
            'mode=' + EncodingUtil.urlEncode(mode, 'UTF-8')
            + ((isTempProfile) ? '&isTemporaryProfile=true' : '') + ((isReturnProfiles) ? '&returnProfiles=true' : '');
        
        // Make the call
        HttpResponse response = BWC_IntegrationUtility.makeHTTPCallout(
            BWC_Constants.API_PAYMENT_PROFILE, 
            requestBody, 
            null, queryStr
        );
        
        // Attempt deserialize
        BWC_PaymentProfile.PaymentProfileResponse returnValue;
        try {
            returnValue = 
                (BWC_PaymentProfile.PaymentProfileResponse)JSON.deserialize(response.getBody(), BWC_PaymentProfile.PaymentProfileResponse.class);
        }
        catch (System.JSONException e) {
            throw new BWC_Exception('Failed to deserialize HTTP response body.', e);
        }
        
        return returnValue;
        

    }
}