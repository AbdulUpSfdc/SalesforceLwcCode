/*
    Call Mulesoft to make payment.
*/
public with sharing class BWC_MakePaymentCallout {

    public static BWC_MakePayment.MakePaymentResponse makePayment(BWC_MakePayment.MakePaymentRequest request) {

        if (request == null) {
            throw new BWC_Exception('Argument required: request');
        }

        // Serialize
        String requestBody = JSON.serialize(request, true);

        System.debug('Request Body:' + requestBody);
        
        // Make the call
        HttpResponse response = BWC_IntegrationUtility.makeHTTPCallout(BWC_Constants.API_MAKE_PAYMENT, requestBody);

        // Attempt deserialize
        BWC_MakePayment.MakePaymentResponse returnValue;
        try {
            returnValue = 
            (BWC_MakePayment.MakePaymentResponse)
            JSON.deserialize(response.getBody(), BWC_MakePayment.MakePaymentResponse.class);
        }
        catch (System.JSONException e) {
            throw new BWC_Exception('Failed to deserialize HTTP response body.', e);
        }

        return returnValue;
    }

    public static BWC_MakePayment.UpdatePaymentResponse updatePayment(BWC_MakePayment.UpdatePaymentRequest request) {

        if (request == null) {
            throw new BWC_Exception('Argument required: request');
        }

        // Serialize
        String requestBody = JSON.serialize(request, true);

        System.debug('Request Body:' + requestBody);
        
        // Make the call
        HttpResponse response = BWC_IntegrationUtility.makeHTTPCallout(BWC_Constants.API_UPDATE_PAYMENT, requestBody);

        // Attempt deserialize
        BWC_MakePayment.UpdatePaymentResponse returnValue;
        try {
            returnValue = (BWC_MakePayment.UpdatePaymentResponse)JSON.deserialize(response.getBody(), BWC_MakePayment.UpdatePaymentResponse.class);
        }
        catch (System.JSONException e) {
            throw new BWC_Exception('Failed to deserialize HTTP response body.', e);
        }

        return returnValue;
    }

    public static BWC_MakePayment.DeletePaymentResponse deletePayment(BWC_MakePayment.DeletePaymentRequest request) {

        if (request == null) {
            throw new BWC_Exception('Argument required: request');
        }

        // Serialize
        String requestBody = JSON.serialize(request, true);

        System.debug('Request Body:' + requestBody);
        
        // Make the call
        HttpResponse response = BWC_IntegrationUtility.makeHTTPCallout(BWC_Constants.API_DELETE_PAYMENT, requestBody);

        // Attempt deserialize
        BWC_MakePayment.DeletePaymentResponse returnValue;
        try {
            returnValue = (BWC_MakePayment.DeletePaymentResponse)JSON.deserialize(response.getBody(), BWC_MakePayment.DeletePaymentResponse.class);
            //System.debug('The response :'+returnValue);
        }
        catch (System.JSONException e) {
            throw new BWC_Exception('Failed to deserialize HTTP response body.', e);
        }

        return returnValue;
    }

    public static BWC_MakePayment.EpaEnrollResponse epaEnroll(BWC_MakePayment.EpaEnrollRequest request) {

        if (request == null) {
            throw new BWC_Exception('Argument required: request');
        }

        // Serialize
        String requestBody = JSON.serialize(request, true);

        System.debug('Request Body:' + requestBody);
        
        // Make the call
        HttpResponse response = BWC_IntegrationUtility.makeHTTPCallout(BWC_Constants.API_EPA_ENROLL, requestBody);

        // Attempt deserialize
        BWC_MakePayment.EpaEnrollResponse returnValue;
        try {
            returnValue = 
            (BWC_MakePayment.EpaEnrollResponse)
            JSON.deserialize(response.getBody(), BWC_MakePayment.EpaEnrollResponse.class);
        }
        catch (System.JSONException e) {
            throw new BWC_Exception('Failed to deserialize HTTP response body.', e);
        }

        return returnValue;
    }


}