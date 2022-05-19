public inherited sharing class BWC_ApiMock {

    // Permission set required for mocking outside of unit tests
    public static final String MOCK_PERMISSION = 'BWC_Api_Mock';

    // HTTP headers added to flag that response is mock
    public static final String BWC_MOCK_ID_HEADER = 'Bwc-Mock-Id';
    public static final String BWC_MOCK_NAME_HEADER = 'Bwc-Mock-Name';

    // Allows mock to be set by a unit test without requiring matching
    public static Map<String, BWC_Api_Mock__mdt> testMocksByApiName = new Map<String, BWC_Api_Mock__mdt>();
    
    // Allows a mock to be set for the purpose of getting test coverage of the matching process
    @TestVisible private static BWC_Api_Mock__mdt testMock;

    public static Boolean userHasMockPermission() {
        return FeatureManagement.checkPermission(MOCK_PERMISSION);
    }

    /*
        During an apex unit test, explicitly set a mock to be used by the running unit test.
    */
    public static void setTestApiMock(String apiName, String apiMockDeveloperName) {

        if (Test.isRunningTest()) {

            BWC_Api_Mock__mdt apiMock = getApiMock(apiMockDeveloperName);
            if (apiMock.Api__r.DeveloperName != apiName) {
                throw new BWC_Exception('Specific mock: ' + apiMockDeveloperName + ' is not associated with API: ' + apiName);
            }
            testMocksByApiName.put(apiName, apiMock);

        }

    }

    /*
        During an apex unit test, calls Test.setContinuationResponse for the specified continuation and setting the specified HttpResponse for apiMockDeveloperName.
    */
    public static void setTestContinuationResponse(Continuation continuation, String apiName, String apiMockDeveloperName) {

        if (continuation == null) {
            throw new BWC_Exception('Continuation is required.');
        }

        // Assumes there is only one callout on the continuation
        String requestLabel = (new List<String>(continuation.getRequests().keySet()))[0];

        // Get the mock record
        BWC_Api_Mock__mdt apiMock = getApiMock(apiMockDeveloperName);
        if (apiMock.Api__r.DeveloperName != apiName) {
            throw new BWC_Exception('Specific mock: ' + apiMockDeveloperName + ' is not associated with API: ' + apiName);
        }

        // Set the response. Will fail if not Test.isRunningTest().
        Test.setContinuationResponse(requestLabel, getMockResponse(apiMock, continuation.getRequests().get(requestLabel)));

    }

    /*
        Takes a current API request and attempts to find a matching mock response record.
    */
    public static BWC_Api_Mock__mdt findApiMock(BWC_Integration_Metadata__mdt integrationSettings, HttpRequest request) {

        System.debug('BWC_ApiMock.findApiMock: ' + integrationSettings.DeveloperName);

        if (Test.isRunningTest() && testMocksByApiName.containsKey(integrationSettings.DeveloperName)) {
            // This is running unit test, and a mock is set for the API, just return it.
            return testMocksByApiName.get(integrationSettings.DeveloperName);
        }

        try {

            String urlMatchValue;
            String bodyMatchValue;

            if (String.isNotEmpty(integrationSettings.Mocking_Request_URL_Regex__c)) {

                System.Pattern matchPattern = Pattern.compile(integrationSettings.Mocking_Request_URL_Regex__c);
                System.Matcher theMatcher = matchPattern.matcher(request.getEndpoint());
                if (theMatcher.find()) {
                    urlMatchValue = theMatcher.group(1);
                }

            }

            if (String.isNotEmpty(integrationSettings.Mocking_Request_Body_Regex__c)) {

                System.Pattern matchPattern = Pattern.compile(integrationSettings.Mocking_Request_Body_Regex__c);
                System.Matcher theMatcher = matchPattern.matcher(request.getBody());
                if (theMatcher.find()) {
                    bodyMatchValue = theMatcher.group(1);
                }

            }

            // Query for mock response
            // If there are multiple, it picks the first one by DeveloperName
            // If there is an entry with no matching criteria, it will come last
            List<BWC_Api_Mock__mdt> apiMocks = [
                SELECT
                    Id, DeveloperName, Response_Body__c, Response_Content_Type__c, Response_Status_Code__c, Apex_Processor__c, Use_Processor_Only__c, Restrict_To_User__c,
                    Additional_Request_Body_Match_Regex__c, Additional_Request_URL_Match_Regex__c
                FROM
                    BWC_Api_Mock__mdt
                WHERE
                    Api__c = :integrationSettings.Id AND
                    Enabled__c = true AND
                    Request_Method__c = :request.getMethod() AND
                    (BWC_API_Mock_Group__c = null OR BWC_API_Mock_Group__r.Enabled__c = true) AND
                    For_Apex_Unit_Test__c <> true AND
                    (Request_URL_Match_Value__c = :urlMatchValue OR Request_URL_Match_Value__c = NULL) AND
                    (Request_Body_Match_Value__c = :bodyMatchValue OR Request_Body_Match_Value__c = NULL)
                ORDER BY
                    DeveloperName, Restrict_To_User__c, Request_URL_Match_Value__c NULLS LAST, Request_Body_Match_Value__c NULLS LAST,
                    Additional_Request_URL_Match_Regex__c, Additional_Request_Body_Match_Regex__c
            ];

            System.debug('BWC_ApiMock: Candidate Records: ' + apiMocks.size());

            if (Test.isRunningTest() && testMock != null) {
                // There's a test mock, replace with that to allow coverage
                apiMocks = new List<BWC_Api_Mock__mdt>{testMock};
            }

            String requestUrl = request.getEndpoint();
            String requestBody = request.getBody();

            // Find match
            BWC_Api_Mock__mdt matchingMock = null;
            for (BWC_Api_Mock__mdt apiMock : apiMocks) {

                System.debug('BWC_ApiMock: Checking mock candidate ' + apiMock.DeveloperName);

                if (!Pattern.matches(apiMock.Restrict_To_User__c, UserInfo.getUserName())) {
                    // No user match
                    System.debug('BWC_ApiMock: No Restrict to User: ' + apiMock.Restrict_To_User__c);
                    continue;
                }

                if (String.isNotEmpty(apiMock.Additional_Request_URL_Match_Regex__c) &&
                    !Pattern.compile(apiMock.Additional_Request_URL_Match_Regex__c).matcher(requestUrl).find()) {
                    // No regex match
                    System.debug('BWC_ApiMock: No Additional Request URL Match Regex: ' + apiMock.Additional_Request_URL_Match_Regex__c);
                    continue;
                }

                if (String.isNotEmpty(apiMock.Additional_Request_Body_Match_Regex__c) &&
                    !Pattern.compile(apiMock.Additional_Request_Body_Match_Regex__c).matcher(requestBody).find()) {
                    // No regex match
                    System.debug('BWC_ApiMock: No Additional Request Body Match Regex: ' + apiMock.Additional_Request_Body_Match_Regex__c);
                    continue;
                }

                // If we made it here, it matches -- use it
                matchingMock = apiMock;
                break;

            }

            if (matchingMock != null) {

                // We have a hit, return it
                System.debug('BWC_ApiMock: MOCKING MATCH: ' + matchingMock.DeveloperName);
                return matchingMock;

            }
            else {

                System.debug('BWC_ApiMock: NO MATCHES');
                return null;

            }

        }
        catch (System.Exception e) {

            throw new BWC_Exception('Failure while attempting to find any mock response: ' + e.getMessage(), e);

        }

    }

    /*
        Constructs a mock response from a specific mock record.
    */
    public static HttpResponse getMockResponse(BWC_Api_Mock__mdt apiMock, HttpRequest request) {

        if (apiMock.Use_Processor_Only__c == true) {
            System.debug('API mock is Use Processor Only, API will be called: ' + apiMock.DeveloperName);
            return null;
        }

        try {

            // Build response
            HttpResponse response = new HttpResponse();
            response.setStatusCode((Integer)apiMock.Response_Status_Code__c);
            response.setHeader('Content-Type', apiMock.Response_Content_Type__c);
            response.setHeader(BWC_MOCK_ID_HEADER, apiMock.Id == null ? '' : apiMock.Id);
            response.setHeader(BWC_MOCK_NAME_HEADER, apiMock.DeveloperName);
            response.setBody(apiMock.Response_Body__c);

            return response;

        }
        catch (System.Exception e) {

            throw new BWC_Exception('Failure while building mock response: ' + e.getMessage(), e);

        }

    }

    public static void processResponse(BWC_Api_Mock__mdt apiMock, HttpRequest request, HttpResponse response) {

        // Check for processor
        if (String.isNotEmpty(apiMock.Apex_Processor__c)) {

            try {

                Type customProcessorType = Type.forName(apiMock.Apex_Processor__c);
                if (customProcessorType == null) {
                    throw new BWC_Exception('Failed to instantiate mocking processor type ' +  apiMock.Apex_Processor__c);
                }
                Processor customProcessor = (Processor)customProcessorType.newInstance();

                System.debug('Running API Mock Processor: ' + apiMock.Apex_Processor__c);
                customProcessor.processRequest(apiMock, request, response);

            }
            catch (System.Exception e) {

                throw new BWC_Exception('Failed attempt to use mocking processor: ' + e.getMessage(), e);

            }

        }

    }

    /*
        Retrieve specified API Mock.
    */
    public static BWC_Api_Mock__mdt getApiMock(String apiMockDeveloperName) {

        if (String.isEmpty(apiMockDeveloperName)) {
            throw new BWC_Exception('apiMockDeveloperName is required.');
        }

        List<BWC_Api_Mock__mdt> apiMocks = [
            SELECT
                Id, DeveloperName, Api__r.DeveloperName,
                Response_Body__c, Response_Content_Type__c, Response_Status_Code__c, Apex_Processor__c, Use_Processor_Only__c, Restrict_To_User__c,
                Additional_Request_Body_Match_Regex__c, Additional_Request_URL_Match_Regex__c
            FROM
                BWC_Api_Mock__mdt
            WHERE
                DeveloperName = :apiMockDeveloperName
        ];

        if (apiMocks.isEmpty()) {
            throw new BWC_Exception('BWC_Api_Mock__mdt API Mock not found for Developer Name: ' + apiMockDeveloperName);
        }

        return apiMocks[0];

    }

    public Interface Processor {

        void processRequest(BWC_Api_Mock__mdt apiMock, HttpRequest request, HttpResponse response);

    }

}