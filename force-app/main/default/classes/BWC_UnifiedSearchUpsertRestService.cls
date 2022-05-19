@RestResource(urlMapping='/customers/v1/upsertFromUnifiedSearch')
global with sharing class BWC_UnifiedSearchUpsertRestService {

    @HttpPost
    global static void doPost(){

        RestRequest restRequest =  RestContext.request;

        if(RestContext.response == null ){
            RestContext.response = new System.RestResponse();
        }

        RestContext.response.addHeader('Content-Type', 'application/json');
        UpsertResponse response = new UpsertResponse();
        String requestBody;

        try {
            requestBody = restRequest.requestBody.toString();

            if (String.isEmpty(requestBody)) {
                throw new BWC_Exception('No request body was provided.');
            }

            // Deserialize request
            UpsertRequest upsertRequest;
            try {

                upsertRequest = (UpsertRequest)JSON.deserialize(requestBody, UpsertRequest.class);

            }
            catch(JSONException je) {

                throw new BWC_Exception('Unable to deserialize request body: ' + je.getMessage());

            }

            if (upsertRequest.customerSearchResponse == null) {
                throw new BWC_Exception('customerSearchResponse is required.');
            }

            if(upsertRequest.customerSearchResponse.individuals.size() > 1){
                throw new BWC_Exception('customerSearchResponse has more than one individual');
            }

            try {
                BWC_UnifiedSearch.UnifiedSearchResponse upsertResponse = BWC_UnifiedSearchService.upsertRecordsForCustomer(upsertRequest.customerSearchResponse, upsertRequest.ctiCallIdentifier);
                response.accounts = upsertResponse.individualsFound;
            }
            catch (System.Exception e) {
                BWC_ExceptionUtils.handleException(e, JSON.serialize(upsertRequest, true), null);
                throw new BWC_Exception('An error occurred while attempting to upsert records: ' + e.getMessage());
            }

            RestContext.response.statusCode = 200;
            response.message = 'Records successfully upserted.';

        }
        catch(System.Exception e) {

            RestContext.response.statusCode = 400;
            response.message = e.getMessage();
            BWC_ExceptionUtils.handleException(e, requestBody, null);

        }

        // Set response body
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response, true));
    }

    public class UpsertRequest {
        public String ctiCallIdentifier;
        public BWC_UnifiedSearch.UnifiedSearchResponse customerSearchResponse;
    }

    public class UpsertResponse {
        public String message;
        public List<BWC_UnifiedSearch.IndividualFound> accounts;
    }


}