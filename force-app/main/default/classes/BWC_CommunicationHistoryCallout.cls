public with sharing class BWC_CommunicationHistoryCallout {

    public static BWC_CommunicationHistory.ResendResponse requestResend(BWC_CommunicationHistory.ResendRequest request){

        if(request==null){
            throw new BWC_Exception('Request cannot be null');
        }

        String requestBody = JSON.serialize(request, true);

        try {

            HttpResponse httpResponse = BWC_IntegrationUtility.makeHTTPCallout(BWC_Constants.API_COMMUNICATION_RESEND, requestBody);
            BWC_CommunicationHistory.ResendResponse response = (BWC_CommunicationHistory.ResendResponse)JSON.deserialize(httpResponse.getBody(), BWC_CommunicationHistory.ResendResponse.class);
            return response;

        } catch (Exception ex) {
            throw new BWC_Exception(ex.getMessage());
        }

    }
}