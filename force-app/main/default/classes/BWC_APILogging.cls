public with sharing class BWC_APILogging {

    // Specific request headers to log since you cannot get all request keys, plus avoid logging secrets.
    private static final List<String> REQUEST_HEADERS_TO_LOG = new List<String> {
        BWC_Constants.HTTP_TRACE_ID_HEADER,
        BWC_Constants.HTTP_TRANSACTION_ID_HEADER,
        BWC_Constants.HTTP_CORRELATION_ID_HEADER,
        'Content-Type'
    }; 

    /*
        Log an attempted API call to Nebula log.
    */
    public static void log(String apiName, NamedCredential namedCredential, HttpRequest request, HttpResponse response, System.Exception except) {

        // Construct pipe-delimited message
        String logMessage =
            'category=' + 'Callout' +
            '|namedCredential=' + namedCredential?.DeveloperName +
            '|apiName=' + apiName +
            '|apiMethod=' + request.getMethod() +
            '|uri=' + getFullEndpoint(namedCredential, request.getEndpoint()) +
            getRequestHeaders(request);

        if (response != null) {
            logMessage += '|statusCode=' + response.getStatusCode() +
            getResponseHeaders(response);
        }

        if (except == null) {

            if (response.getStatusCode() >= 400) {
                Logger.error(logMessage, BWC_Log.relatedRecordId);
            }
            else {
                Logger.info(logMessage, BWC_Log.relatedRecordId);
            }

        }
        else {

            Logger.error(logMessage, BWC_Log.relatedRecordId, except);

        }

    }

    /*
        Convert named credential into the actual endpoint.
    */
    private static String getFullEndpoint(NamedCredential namedCredential, String endpointString) {

        if (!endpointString.startsWith('callout:')) {
            return endpointString;
        }

        // Extract named credential developer name
        Integer indexOfSlash = endpointString.indexOf('/');
        return namedCredential.Endpoint + endpointString.substring(indexOfSlash);

    }

    /*
        Provide pipe-delimited message string for specific request headers.
    */
    private static String getRequestHeaders(HttpRequest request) {

        // Log specific headers
        String result = '';
        for (String headerKey : REQUEST_HEADERS_TO_LOG) {
            result += '|' + headerKey + '=' + request.getHeader(headerKey);
        }

        return result;

    }

    /*
        Provide pipe-delimited message string for all response headers.
    */    
    private static String getResponseHeaders(HttpResponse response) {


        // Log all headers
        String result = '';
        for (String headerKey : response.getHeaderKeys()) {
            result += '|' + headerKey + '=' + response.getHeader(headerKey);
        }

        return result;

    }

}