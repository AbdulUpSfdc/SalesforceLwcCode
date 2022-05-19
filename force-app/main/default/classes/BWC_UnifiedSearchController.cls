public with sharing class BWC_UnifiedSearchController {

    @AuraEnabled(continuation = true)
    public static Object customerSearchCont(String recordId, String requestJson){

        BWC_Log.setRelatedRecordId(recordId);

        try {

            BWC_UnifiedSearch.UnifiedSearchRequest request =
                (BWC_UnifiedSearch.UnifiedSearchRequest) JSON.deserialize(requestJson, BWC_UnifiedSearch.UnifiedSearchRequest.class);

            BWC_UnifiedSearchService.CustomerSearch service =
                new BWC_UnifiedSearchService.CustomerSearch(recordId, request);

            Object response = service.callWithContinuation();

            if(response instanceof Continuation){
                ((Continuation)response).continuationMethod = 'customerSearchResp';
                return response;
            }

            BWC_UnifiedSearch.UnifiedSearchResponse customerSearchResponse =
                (BWC_UnifiedSearch.UnifiedSearchResponse) response;

            return customerSearchResponse.serialize();

        } catch (Exception e) {
            throw BWC_Controller.handleException(e, 'requestJson=' + requestJson);
        }
    }

    @AuraEnabled
    public static String customerSearchResp(List<String> labels, Object state){
        try {
            BWC_UnifiedSearchService.CustomerSearch service = (BWC_UnifiedSearchService.CustomerSearch) state;

            BWC_UnifiedSearch.UnifiedSearchResponse response =
                (BWC_UnifiedSearch.UnifiedSearchResponse) service.processContinuationResponse();

            return response.serialize();

        } catch (Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }

    @AuraEnabled
    public static void linkInteractionWithAccount(Id interactionId, Id accountId, Boolean hasUverseAccount){
        try {
            BWC_UnifiedSearchService.linkInteractionWithAccount(interactionId, accountId, hasUverseAccount);
        } catch (Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }
}