/*
    Common MuleSoft structures.
*/
public inherited sharing class BWC_Mulesoft {

    /*
        Common base for top level API response.
    */
    public virtual class Response {

        public MuleError error;      // Error details if isError == true

        // Additional context information that comes from our HTTP call
        public String transactionId;
        public String idpTraceId;
        public Integer statusCode;
        public Integer code;

        private transient HttpRequest httpRequestObject;
        private transient HttpResponse httpResponseObject;
        public String rawRequest = '';       // Actual full response sent to API after serialize
        public String rawResponse = '';      // Full response received from API before deserialize
        public String mockId;                // If a mock response was used, the ID of the BWC_Api_Mock__mdt metadata record
        public String mockName;              // If a mock response was used, the DeveloperName of the BWC_Api_Mock__mdt metadata record

        /*
            Copy key information from request and response.
        */
        public void setHttpInfo(HttpRequest request, HttpResponse response) {

            this.httpRequestObject = request;
            this.httpResponseObject = response;
            this.mockId = response.getHeader(BWC_ApiMock.BWC_MOCK_ID_HEADER);
            this.mockName = response.getHeader(BWC_ApiMock.BWC_MOCK_NAME_HEADER);

            if (request != null) {
                this.idpTraceId = request.getHeader(BWC_Constants.HTTP_TRACE_ID_HEADER);
                this.transactionId = request.getHeader(BWC_Constants.HTTP_TRANSACTION_ID_HEADER);
            }

            if (response != null) {
                this.code = response.getStatusCode();
            }
        }

        /*
            Serialize and include raw request and response.
        */
        public String serialize() {

            // Serialize current value to string
            String responseJson = JSON.serialize(this, true);

            if (FeatureManagement.checkPermission('BWC_Debug')) {
                // Add the raw request and response
                // This way it's part of JSON and not escaped string
                if (this.httpRequestObject != null) {
                    String requestBody = this.httpRequestObject.getBody();
                    if (!String.isEmpty(requestBody) && !Test.isRunningTest()) {
                        responseJson = responseJson.replace('"rawRequest":""', '"rawRequest":' + requestBody);
                    }
                }
                if (this.httpResponseObject != null) {
                    String responseBody = this.httpResponseObject.getBody();
                    if (!String.isEmpty(responseBody)) {
                        if ((responseBody.startsWith('{') || responseBody.startsWith('[')) && !Test.isRunningTest()) {
                            // Assume Response is JSON
                            responseJson = responseJson.replace('"rawResponse":""', '"rawResponse":' + responseBody);
                        }
                        else if (!Test.isRunningTest()) {
                            // Response is not JSON, serialize it as string
                            responseJson = responseJson.replace('"rawResponse":""', '"rawResponse":' + JSON.serialize(responseBody));
                        }
                    }
                }
            }

            return responseJson;

        }

    }

    /*
        Common base for components of an API response which might include error information.
    */
    public virtual class ResponseNode {

        public Boolean isError;                 // There's an associated error and "error" property has the details.
        public MuleError error;                 // Error details if isError == true

    }

    public class MuleError {
        public String node;
        public Integer code;
        public String message;
        public String description;
        public String transactionId;
        public String traceId;
        public String idpTraceId;
    
    }

}