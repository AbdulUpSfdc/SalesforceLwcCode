public with sharing class BWC_AccountDetailsController {

    @AuraEnabled(continuation = true)
    public static Object accountDetailsCont(String recordId, String billingAccountIdsJson, String individualId){

        BWC_Log.setRelatedRecordId(recordId);

        try {

            BWC_AccountDetailsService.AccountDetails service = new BWC_AccountDetailsService.AccountDetails(recordId, billingAccountIdsJson, individualId);

            Object response = service.callWithContinuation();

            if(response instanceOf Continuation){
                ((Continuation) response).continuationMethod = 'accountDetailsResp';
                return response;
            }

            BWC_AccountDetails.AccountDetailsResponse accountDetailsResponse = (BWC_AccountDetails.AccountDetailsResponse) response;

            return accountDetailsResponse.serialize();

        } catch (Exception e) {
            throw BWC_Controller.handleException(e, 'billingAccountIdsJson='+billingAccountIdsJson);
        }
    }

    @AuraEnabled
    public static String accountDetailsResp(List<String> labels, Object state){
        try {
            BWC_AccountDetailsService.AccountDetails service = (BWC_AccountDetailsService.AccountDetails) state;

            BWC_AccountDetails.AccountDetailsResponse response =
                (BWC_AccountDetails.AccountDetailsResponse) service.processContinuationResponse();

            return response.serialize();

        } catch (Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }
}