public with sharing class BWC_CommunicationHistoryService {

    public static BWC_CommunicationHistory.ResendResponse requestResend(String externalId, String category){

        if(String.isBlank(externalId)){
            throw new BWC_Exception('Argument externalId is required');
        }

        if(String.isBlank(category)){
            throw new BWC_Exception('Argument category is required');
        }

        BWC_CommunicationHistory.ResendRequest request = new BWC_CommunicationHistory.ResendRequest();
        BWC_CommunicationHistory.ResendDetails details = new BWC_CommunicationHistory.ResendDetails();

        details.uniqueId = externalId;
        details.category = category;

        request.resendDetails = details;

        return BWC_CommunicationHistoryCallout.requestResend(request);
    }

}