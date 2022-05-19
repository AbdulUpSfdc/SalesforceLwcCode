public with sharing class BWC_AddressValidationController {

    @AuraEnabled( continuation = true )
    public static Object addressValidationCont(String recordId, String requestJson){

        BWC_Log.setRelatedRecordId(recordId);

        try {
            BWC_AddressValidation.AddressValidationRequest request =
                (BWC_AddressValidation.AddressValidationRequest) JSON.deserialize(requestJson, BWC_AddressValidation.AddressValidationRequest.class);

            BWC_AddressValidationService.AddressValidation service =
                new BWC_AddressValidationService.AddressValidation(recordId, request);

            Object response = service.callWithContinuation();

            if(response instanceOf Continuation){
                ((Continuation) response).ContinuationMethod = 'addressValidationResp';
                return response;
            }

            BWC_AddressValidation.AddressValidationResponse addressResponse =
                (BWC_AddressValidation.AddressValidationResponse) response;

            return addressResponse.serialize();

        } catch (Exception e) {
            throw BWC_Controller.handleException(e, 'requestJson='+requestJson);
        }

    }

    @AuraEnabled
    public static String addressValidationResp(List<String> labels, Object state){

        try {

            BWC_AddressValidationService.AddressValidation service =
                (BWC_AddressValidationService.AddressValidation) state;

            BWC_AddressValidation.AddressValidationResponse response =
                (BWC_AddressValidation.AddressValidationResponse) service.processContinuationResponse();

            return response.serialize();

        } catch (Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }
}