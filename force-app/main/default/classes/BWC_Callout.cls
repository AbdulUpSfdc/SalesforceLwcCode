/*
    Base class for all API callouts, supporting synchronous or using Continuations.
*/
public inherited sharing abstract class BWC_Callout {

    // Special HTTP Headers
    public static final String HTTP_TRACE_ID_HEADER = 'idp-trace-id';    
    public static final String HTTP_TRANSACTION_ID_HEADER = 'x-transaction-id';
    public static final String HTTP_CORRELATION_ID_HEADER = 'x-correlation-id';
    public static final String HTTP_ATT_TRANSACTION_ID_HEADER = 'X-ATT-UniqueTransactionId';

    // Specific request headers to log since you cannot get all request keys, plus avoid logging secrets.
    private static final List<String> REQUEST_HEADERS_TO_LOG = new List<String> {
        HTTP_TRACE_ID_HEADER,
        HTTP_TRANSACTION_ID_HEADER,
        HTTP_CORRELATION_ID_HEADER,
        'Content-Type'
    }; 

    // All of this is state that is retained when using Continuation
    public BWC_Integration_Metadata__mdt integrationMetadata;
    public NamedCredential namedCredential;
    public BWC_Api_Mock__mdt apiMock;
    public String requestEndpoint;
    public String requestMethod;
    public Map<String, String> requestHeaders;
    public String requestBody;
    public String continuationRequestLabel;

    // These are marked transient as they cannot be serialized with continuation state (and don't need to be)
    public transient System.HttpRequest httpRequest;   
    public transient System.HttpResponse httpResponse;
    public transient System.Continuation continuation;

    // Strictly for unit testing because Test.invokeContinuationMethod() doesn't work with static controllers.
    @TestVisible private static Object lastContinuationState;

    /*
        Make callout synchronously -- without continuation.
    */
    public void makeCallout() {

        this.continuation = null;
        BWC_Callout.lastContinuationState = null;

        if (this.httpResponse == null) {
            // No mock response, call real API
            Http objHttp = new Http(); 
            this.httpResponse = objHttp.send(this.httpRequest); //Sending HTTP Request
        }

        this.processHttpResponse();

    }

    /*
        Returns a continuation for an API call OR returns the mock response.
    */
    public void makeCalloutWithContinuation(Object state) {

        if (this.httpResponse != null) {
            // There's a mock response -- return it instead of continuation
            this.continuation = null;
            BWC_Callout.lastContinuationState = null;
            this.processHttpResponse();
            return;
        }

        // There's no mock, so will use a continuation
        this.continuation = new Continuation(this.integrationMetadata.Timeout__c.intValue() / 1000);
        this.continuationRequestLabel = this.continuation.addHttpRequest(this.httpRequest);

        // If the caller passes in a state, then use that for the Continuation state, otherwise it's this object
        Object continuationState = state != null ? state : this;
        this.continuation.state = continuationState;
        BWC_Callout.lastContinuationState = continuationState;

    }

    /*
        Set request and response back from continuation
    */
    public void processContinuationResponse() {

        // Clear continuation now -- we got a response
        this.continuation = null;

        // Get the HTTP response
        this.httpResponse = System.Continuation.getResponse(this.continuationRequestLabel);

        // Rebuild HttpRequest from state
        this.httpRequest = new HttpRequest();
        this.httpRequest.setEndpoint(this.requestEndpoint);
        this.httpRequest.setMethod(this.requestMethod);
        if (this.requestBody != null) {
            this.httpRequest.setBody(this.requestBody);
        }
        for (String headerName : this.requestHeaders.keySet()) {
            this.httpRequest.setHeader(headerName, this.requestHeaders.get(headerName));
        }

        this.processHttpResponse();

    }

    /*
        Derived class calls this to set request state from the caller's arguments.
    */
    protected void setCallout(String apiName, Object requestObject, String path, String queryString, String methodType) {

        // Get the integration custom metadata record
        List<BWC_Integration_Metadata__mdt> integrationMetadatas = [
            SELECT
                Id, DeveloperName, Named_Credential__c, Enable_API_Logging__c, Method_Name__c, Method_type__c, Certificate_Name__c, 
                Sub_URL__c, RTF_Sub_URL__c, Timeout__c, Mocking_Request_URL_Regex__c, Mocking_Request_Body_Regex__c
            FROM
                BWC_Integration_Metadata__mdt
            WHERE
                DeveloperName = :apiName
        ];

        if (integrationMetadatas.isEmpty()) {
            throw new BWC_Exception('BWC_Integration_Metadata__mdt record not found for apiName: ' + apiName);
        }

        this.integrationMetadata = integrationMetadatas[0];

        // Serialize request body if it's not already a string
        String requestBody;
        if (requestObject != null) {
            if (requestObject instanceof String) {
                requestBody = (String)requestObject;
            }
            else {
                requestBody = JSON.serialize(requestObject, true);
            }
        }

        // Build the HTTP Request
        buildHttpRequest(this.integrationMetadata, requestBody, path, queryString, methodType);
    
        // Check for available mock response
        if (BWC_ApiMock.userHasMockPermission() || Test.isRunningTest()) {

            this.apiMock = BWC_ApiMock.findApiMock(this.integrationMetadata, this.httpRequest);

            if (this.apiMock != null) {
                // There's a mock, get response -- may return null if it's Use Processor Only
                this.httpResponse = BWC_ApiMock.getMockResponse(this.apiMock, this.httpRequest);
            }

        }

    }

    /*
        Instantiate the HttpRequest which can be used directly or with Continuation.
    */
    private void buildHttpRequest(BWC_Integration_Metadata__mdt integrationMetadata, String requestBody, String path, String queryString, String methodType) {

        // Get the right Named Credential record
        this.namedCredential = getNamedCredential(integrationMetadata);

        // Get the endoint path (not including named cred) based upon integration metadata and named credential
        String endpointPath = getEndpointPath(this.namedCredential, integrationMetadata, path, queryString);

        // Construct request
        this.httpRequest = new HttpRequest();

        // Set request properties
        this.httpRequest.setEndpoint('callout:' + this.namedCredential.DeveloperName + endpointPath);
        this.httpRequest.setMethod(String.isNotEmpty(methodType) ? methodType : integrationMetadata.Method_Type__c);
        this.httpRequest.setClientCertificateName(integrationMetadata.Certificate_Name__c);
        this.httpRequest.setTimeout(integrationMetadata.Timeout__c.intValue());

        // Set trace and transaction ID, and correlation to unique value
        String uniqueTraceId = EncodingUtil.ConvertTohex(Crypto.GenerateAESKey(128)).left(16);
        String traceId = uniqueTraceId + ':' + uniqueTraceId + ':' + '0:0';
        String trxId = BWC_Utils.newGuid();
        this.httpRequest.setHeader(HTTP_TRACE_ID_HEADER, traceId);
        this.httpRequest.setHeader(HTTP_CORRELATION_ID_HEADER, trxId);
        this.httpRequest.setHeader(HTTP_TRANSACTION_ID_HEADER, trxId);
        this.httpRequest.setHeader(HTTP_ATT_TRANSACTION_ID_HEADER, trxId);
        this.httpRequest.setHeader('Content-Type', 'application/json');

        // Get client ID and secret from named credential user/password
        this.httpRequest.setHeader('client_id', '{!$Credential.UserName}');
        this.httpRequest.setHeader('client_secret', '{!$Credential.Password}');

        // Log specific headers
        this.requestHeaders = new Map<String, String>();
        for (String headerKey : REQUEST_HEADERS_TO_LOG) {
            this.requestHeaders.put(headerKey, this.httpRequest.getHeader(headerKey));
        }            

        if (requestBody != null) {
            this.httpRequest.setBody(requestBody); 
        }

        // Stash request information into state so it survives continuation
        this.requestEndpoint = this.namedCredential.Endpoint + endpointPath;
        this.requestMethod = this.httpRequest.getMethod();
        this.requestBody = this.httpRequest.getBody();

    }

    /*
        Handle remaining processing after HttpResponse is received. This may have been synchronous or from a continuation.
    */
    private void processHttpResponse() {

        try {

            if (this.integrationMetadata.Enable_API_Logging__c == true) {
                // Log request and response
                BWC_APILogging.log(this.integrationMetadata.DeveloperName, this.namedCredential, this.httpRequest, this.httpResponse, null);
            }
            if (this.apiMock != null) {
                // There's an API mock, let it process if there's a processor
                BWC_ApiMock.processResponse(this.apiMock, this.httpRequest, this.httpResponse);
            }

            if (this.httpResponse.getStatusCode() >= 400) {

                // Throw status 400 or greater as error
                // Derived class can override throwOnError to prevent throwing of certain HTTP statuses
                if (this.throwOnError()) {
                    throw new BWC_HttpException(this.httpRequest, this.httpResponse);
                }

            }

        }
        catch (System.Exception e) {

            BWC_HttpException httpException;

            // Just rethrow if already HTTP exception -- it's been logged
            if (e instanceof BWC_HttpException) {
                throw e;
            }

            // Create new HTTP exception
            httpException = new BWC_HttpException(this.httpRequest, e);

            // Log request and exception (no response)
            if (this.integrationMetadata.Enable_API_Logging__c == true) {
                BWC_APILogging.log(this.integrationMetadata.DeveloperName, this.namedCredential, this.httpRequest, null, e);
            }

            throw httpException;

        }
        finally {

            Logger.saveLog();

        }

    }

    /*
        Derived class can override to decide whether to throw on a specific HTTP status during processHttpResponse.
        This can be used to avoid throwing on a 400, for example, and instead still get the response without exception.
    */
    protected virtual Boolean throwOnError() {
        return true;
    }

    /*
        Return the current response -- whether it's a Continuation or final response.
    */
    public Object getResponse() {

        if (this.continuation != null) {
            // It's a continuation, just return that
            return this.continuation;
        }

        // Http call is done, build the response.
        return this.buildResponse();

    }

    /*
        Derived class must override this to build and return the final response.
    */
    protected abstract Object buildResponse();

    /*
        Derived class can call this to attempt deserialize of response body to specified type.
    */
    protected Object deserialize(System.Type responseBodyType) {

        String responseBody = this.httpResponse.getBody();
        try {
            Object response = JSON.deserialize(responseBody, responseBodyType);
            if (response instanceof CalloutResponse) {
                ((CalloutResponse)response).setHttpInfo(this.httpRequest, this.httpResponse);
            }
            return response;
        }
        catch (System.JSONException e) {
            throw new BWC_Exception('Failed to deserialize HTTP response body into expected type: ' + responseBody + ' ' + e.getMessage(), e);
        }

    }
    
    /*
        Common base for top level API response.
    */
    public virtual class CalloutResponse {

        public CalloutError error;      // Error details if isError == true

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
        public CalloutError error;              // Error details if isError == true
    }

    public class CalloutError {
        public String node;
        public Integer code;
        public String message;
        public String description;
        public String transactionId;
        public String traceId;
        public String idpTraceId;
    }

    /*
        Retrieve the Named Credential record to use for next callout.
        Uses Named Credential base name as specified on Integration Metadata record. If blank falls back to Default Named Credential in BWC Settings.
        If multi-servers are in use, selects random server.
    */
    public static NamedCredential getNamedCredential(BWC_Integration_Metadata__mdt integrationMetadata) {

        BWC_Settings__mdt settings = BWC_Settings.getBwcSettings();
        Integer serverCount = (Integer)settings.API_Multi_Server_Count__c;

        String namedCredentialBaseName = integrationMetadata.Named_Credential__c;
        if (String.isEmpty(namedCredentialBaseName)) {
            // Record doesn't specify named credential, use default
            namedCredentialBaseName = settings.Default_Named_Credential__c;
        }

        // Determine if index needs to be added to credential name
        String namedCredentialName = namedCredentialBaseName;
        if (serverCount != null && serverCount > 1) {
            Integer serverIndex = BWC_Utils.getRandomInteger(0, serverCount - 1);
            if (serverIndex != 0) {
                namedCredentialName += String.valueOf(serverIndex);
            }
        }

        // Find record(s)
        // Select base name along with indexed, in case indexed does not exist will fall back
        // ORDER BY DeveloperName DESC means if both are selected, the one we want is always first
        List<NamedCredential> namedCredentials = 
            [SELECT DeveloperName, Endpoint 
            FROM NamedCredential 
            WHERE DeveloperName = :namedCredentialName OR DeveloperName = :namedCredentialBaseName
            ORDER BY DeveloperName DESC];

        if (!namedCredentials.isEmpty()) {
            return namedCredentials[0];
        }
        throw new BWC_Exception('Named Credential not found. Base Name = ' + namedCredentialBaseName + ' Indexed Name = ' + namedCredentialName);

    }

    public static String getEndpointPath(NamedCredential namedCredential, BWC_Integration_Metadata__mdt integrationMetadata, String path, String queryString) {

        // Build endpoint
        String endpointPath = integrationMetadata.Sub_URL__c;
        Boolean isRtf = namedCredential.DeveloperName.contains('_RTF');
        if (isRtf) {

            // Matches URL patterns like:
            //  https://c360-api-perf-18.att.com (example, PERF instance number 18 of MuleSoft)
            //  https://c360-api-18.att.com (example, Production instance number 18)
            // Group 1 is the instance name, e.g. "perf"
            Pattern thePattern = Pattern.compile('https://.*-api(-\\D+)(?:-\\d+)*\\.att\\.com');
            Matcher theMatcher = thePattern.matcher(namedCredential.Endpoint);
            endpointPath = integrationMetadata.RTF_Sub_URL__c;
            if (theMatcher.matches()) {
                // Replace MuleSoft instance name into path
                String instanceName = theMatcher.group(1);
                endpointPath = endpointPath.replace('{instance}', instanceName);
            }
            else {
                // Remove {instance}
                endpointPath = endpointPath.replace('{instance}', '');
            }
    
        }

        if (!String.isEmpty(path)) {
            if (path.startsWith('/') || endpointPath.endsWith('/')) {
                endpointPath += path;
            }
            else {
                endpointPath += '/' + path;
            }
        }

        if (!String.isEmpty(queryString)) {
            endpointPath += '?' + queryString;
        }

        return endpointPath;

    }

}