/*
    Exposes methods to allow LWC to call Notes Search service.
*/
public with sharing class BWC_NotesSearchController {
    /*
        Method for calling from LWC. Returns serialized JSON using Continuation
    */
    @AuraEnabled(Continuation = true)
    public static Object getNotesSearchCont(Id recordId, String requestJson) {
        
        try {

            BWC_NotesSearch.NotesSearchRequest request = 
                (BWC_NotesSearch.NotesSearchRequest) JSON.deserialize(requestJson, BWC_NotesSearch.NotesSearchRequest.class);

            BWC_NotesSearchService.GetNotesSearchService service = new BWC_NotesSearchService.GetNotesSearchService(recordId, request);
            Object response = service.callWithContinuation();

            if (response instanceof Continuation) {
                // It's a continuation, so need to set the method to call when continuation returns
                ((Continuation)response).continuationMethod = 'getNotesSearchResp';
                return response;
            }

            // No continuation needed, so return it directly
            BWC_NotesSearch.NotesSearchResponse NotesSearchResponse = (BWC_NotesSearch.NotesSearchResponse)response;
            return NotesSearchResponse.serialize();
        } 
        catch (System.Exception e) {
             // Turn into an AuraHandledException containing embedded JSON that client can parse.
             throw BWC_Controller.handleException(e, 'Record Id:' + recordId);
            }
    }

    @AuraEnabled
    public static String getNotesSearchResp(List<String> labels, Object state) {
        try {
            BWC_NotesSearchService.GetNotesSearchService service = (BWC_NotesSearchService.GetNotesSearchService)state;
            BWC_NotesSearch.NotesSearchResponse NotesSearchResponse = (BWC_NotesSearch.NotesSearchResponse)service.processContinuationResponse();
            return NotesSearchResponse.serialize();
        }
        catch (System.Exception e) {
            // Turn into an AuraHandledException containing embedded JSON that client can parse.
            throw BWC_Controller.handleException(e);
        }
    }
   
}