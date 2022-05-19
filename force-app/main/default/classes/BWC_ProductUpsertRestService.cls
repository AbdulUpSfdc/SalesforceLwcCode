@RestResource(urlMapping='/products/upsertFromSearch')
global without sharing class BWC_ProductUpsertRestService {

    /*
        Process POST to upsert asset and plan records based on product search results. Payload expected is UpsertRequest.
    */
    @HttpPost
    global static void doPost() {

        RestRequest requestRequest = RestContext.request;

        // Prepare response
        if (RestContext.response == null) {
            RestContext.response = new System.RestResponse();
        }
        RestContext.response.addHeader('Content-Type', 'application/json');
        UpsertResponse response = new UpsertResponse();
        String requestBody;

        try {

            requestBody = requestRequest.requestBody.toString();

            if (String.isEmpty(requestBody)) {
                throw new BWC_Exception('No request body was provided.');
            }

            // Deserialize request
            UpsertRequest request;
            try {

                request = (UpsertRequest)JSON.deserialize(requestBody, UpsertRequest.class);

            }
            catch(JSONException je) {

                throw new BWC_Exception('Unable to deserialize request body: ' + je.getMessage());

            }

            if (String.isEmpty(request.accountId)) {
                throw new BWC_Exception('accountId is required.');
            }

            if (String.isEmpty(request.ctiCallIdentifier)) {
                throw new BWC_Exception('ctiCallIdentifier is required.');
            }

            if (request.productSearchResponse == null) {
                throw new BWC_Exception('productSearchResponse is required.');
            }

            try {
                BWC_ProductSearchService.upsertPlansAndEquipments(request.accountId, request.productSearchResponse);
            }
            catch (System.Exception e) {
                BWC_ExceptionUtils.handleException(e, JSON.serialize(request, true), null);
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

    /*
        Request structure expected.
    */
    public class UpsertRequest {

        public String accountId;
        public String ctiCallIdentifier;
        public BWC_ProductSearch.ProductSearchResponse productSearchResponse;

    }

    /*
        Response returned from success/failure of the post.
    */
    public class UpsertResponse {

        public String message;

    }

}