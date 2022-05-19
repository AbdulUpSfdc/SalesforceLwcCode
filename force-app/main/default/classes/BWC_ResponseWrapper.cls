/*
    Generic wrapper to return result to LWC along with status and error information.
*/
public with sharing abstract class BWC_ResponseWrapper {

    public Boolean success;
    public String message;
    public String details;
    public String rawRequest = '';       // Actual full response sent to API after serialize
    public String rawResponse = '';      // Full response received from API before deserialize
    public String mockId;                // If a mock response was used, the ID of the BWC_Api_Mock__mdt metadata record
    public String mockName;              // If a mock response was used, the DeveloperName of the BWC_Api_Mock__mdt metadata record

    public String serialize() {

        if (BWC_IntegrationUtility.lastApiMock != null) {
            this.mockId = BWC_IntegrationUtility.lastApiMock.Id;
            this.mockName = BWC_IntegrationUtility.lastApiMock.DeveloperName;
        }

        // Serialize current value to string
        String responseWrapperJson = JSON.serialize(this, true);

        // Add the raw request and response from BWC_IntegrationUtility
        // This way it's part of JSON and not escaped string
        if (BWC_IntegrationUtility.lastRequest != null) {
            String requestBody = BWC_IntegrationUtility.lastRequest.getBody();
            if (!String.isEmpty(requestBody) && !Test.isRunningTest()) {
                responseWrapperJson = responseWrapperJson.replace('"rawRequest":""', '"rawRequest":' + requestBody);
            }
        }
        if (BWC_IntegrationUtility.lastResponse != null) {
            String responseBody = BWC_IntegrationUtility.lastResponse.getBody();
            if (!String.isEmpty(responseBody)) {
                if ((responseBody.startsWith('{') || responseBody.startsWith('[')) && !Test.isRunningTest()) {
                    // Assume Response is JSON
                    responseWrapperJson = responseWrapperJson.replace('"rawResponse":""', '"rawResponse":' + responseBody);
                }
                else if (!Test.isRunningTest()) {
                    // Response is not JSON, serialize it as string
                    responseWrapperJson = responseWrapperJson.replace('"rawResponse":""', '"rawResponse":' + JSON.serialize(responseBody));
                }
            }
        }

        return responseWrapperJson;

    }

}