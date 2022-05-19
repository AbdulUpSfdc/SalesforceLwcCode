/*
    Call Mulesoft to get  Billing Details .
*/
public with sharing class BWC_BillingDetailsCallout {
    
    public static final String CALLING_SYSTEM_ID = 'SFDC';
    public static final String ORIGINATOR_SYSTEM_ID = 'SFDC';

    /*
        Callout to get Billing Statement JSON.
    */
    public static BWC_BillingDetails.BillingDetailsResponse getBillingDetails(String product, String statementId) {
        
        // Build request 
        String endPath = 'statements/' + statementId + '/details';

        // Make the call
        HttpResponse response = BWC_IntegrationUtility.makeHTTPCallout(BWC_Constants.API_BILLING_DETAILS, null , endPath);

        // Attempt deserialize
        BWC_BillingDetails.BillingDetailsResponse returnValue;

        try {
            returnValue = (BWC_BillingDetails.BillingDetailsResponse)JSON.deserialize(
                        response.getBody(), BWC_BillingDetails.BillingDetailsResponse.class);
        }
        catch (System.JSONException e) {
            throw new BWC_Exception('Failed to deserialize HTTP response body.', e);
        }

        return returnValue;
    
    }

    /*
        Callout to get Billing Statement JSON.
    */
    public static BWC_BillingDetails.ChargeCodesResponse getChargeCodes(BWC_BillingDetails.ChargeCodesRequest request) {

        // Serialize
        String requestBody = JSON.serialize(request, true);

        // Make the call
        HttpResponse response = BWC_IntegrationUtility.makeHTTPCallout(BWC_Constants.API_BILLING_CHARGES, requestBody);

        // Attempt deserialize
        BWC_BillingDetails.ChargeCodesResponse returnValue;

        try {
            returnValue = (BWC_BillingDetails.ChargeCodesResponse)JSON.deserialize(
                        response.getBody(), BWC_BillingDetails.ChargeCodesResponse.class);
        }
        catch (System.JSONException e) {
            throw new BWC_Exception('Failed to deserialize HTTP response body.', e);
        }

        return returnValue;
    
    }

    /*
        Callout to get Billing Statement as PDF.
    */
    public static BWC_BillingDetails.BillPdfResponse getBillPdf(String product, String statementId) {
        
        // Build request 
        String endPath = 'statements/' + statementId + '/pdf';

        // Make the call
        HttpResponse response = BWC_IntegrationUtility.makeHTTPCallout(BWC_Constants.API_BILLING_DETAILS, null , endPath);

        // Attempt deserialize
        BWC_BillingDetails.BillPdfResponse returnValue;

        try {
            returnValue = (BWC_BillingDetails.BillPdfResponse)JSON.deserialize(
                        response.getBody(), BWC_BillingDetails.BillPdfResponse.class);
        }
        catch (System.JSONException e) {

            throw new BWC_Exception('Failed to deserialize HTTP response body.', e);
        }

        return returnValue;
    
    }

}