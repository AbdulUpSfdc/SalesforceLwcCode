public with sharing class BWC_BillingEnrollmentCallout {
    
    public static List<BWC_BillingEnrollment.BillingEnrollmentStatusResponse> getPaperlessStatus(List<BWC_BillingEnrollment.BillingEnrollmentStatusRequest> request){

        if(request.isEmpty()){
            throw new BWC_Exception('Request is empty');
        }

        String requestBody = JSON.serialize(request, true);

        HttpResponse response = BWC_IntegrationUtility.makeHTTPCallout(BWC_Constants.API_BILLING_ENROLLMENT_STATUS, requestBody);
        
        List<BWC_BillingEnrollment.BillingEnrollmentStatusResponse> returnValue;

        try{
            returnValue = (List<BWC_BillingEnrollment.BillingEnrollmentStatusResponse>)JSON.deserialize(response.getBody(), List<BWC_BillingEnrollment.BillingEnrollmentStatusResponse>.class);
        }
        catch(JSONException e){
            throw new BWC_Exception('Failed to deserialze HTTP response body.', e);
        }

        return returnValue;
    }
}