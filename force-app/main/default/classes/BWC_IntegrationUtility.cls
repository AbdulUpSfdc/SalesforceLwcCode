/* ================================================
* @author : Anshul Gupta
* @date : 9/06/2020  
* @group : API utility
* @description : API callout utility class holds the logic to make callout to any rest API
================================================*/
public with sharing class BWC_IntegrationUtility {
   
    public static HttpRequest lastRequest;
    public static HttpResponse lastResponse;
    public static BWC_Api_Mock__mdt lastApiMock;

    /*************************************************************************************
    * @description holds all the related details of a particular API callout  
    */
    private static BWC_Integration_Metadata__mdt objIntegrationSetting;

    /* ================================================
    *@description : takes the APIcallout name details and queries for the related data and prepares request 
    and makes a callout and returns the HTTPResponse
    *@param1 : strNamedCredential - API name 
    *@param2 : strRequestBody - the requestbody to be sent to the API   
    *@return : response object returned by API
    ================================================*/

    public static HTTPResponse makeHTTPCallout(String apiName, String strRequestBody) {
        return makeHTTPCallout(apiName, strRequestBody, null, null, null);
    }

    public static HTTPResponse makeHTTPCallout(String apiName, String strRequestBody, String path) {
        return makeHTTPCallout(apiName, strRequestBody, path, null, null);
    }

    public static HTTPResponse makeHTTPCallout(String apiName, String strRequestBody, String path, String queryString){
        return makeHTTPCallout(apiName, strRequestBody, path, queryString, null);
    }

    public static HTTPResponse makeHTTPCallout(String apiName, String strRequestBody, String path, String queryString, String methodType){

        getIntegrationHeader(apiName);

        // Get the right Named Credential record
        NamedCredential namedCredential = BWC_Callout.getNamedCredential(objIntegrationSetting);

        // Get the endoint path (not including named cred) based upon integration metadata and named credential
        String endpointPath = BWC_Callout.getEndpointPath(namedCredential, objIntegrationSetting, path, queryString);

        HttpRequest objRequest = new HttpRequest();
        Http objHttp = new Http(); 

        objRequest.setEndpoint('callout:' + namedCredential.DeveloperName + endpointPath);
        objRequest.setMethod(String.isNotEmpty(methodType) ? methodType : objIntegrationSetting.Method_type__c);
        objRequest.setClientCertificateName(objIntegrationSetting.Certificate_Name__c);
        //driving time out from custom metadata to handle them dynamically based on perfromance.
        objRequest.setTimeout(objIntegrationSetting.Timeout__c.intValue());

        // Set trace and transaction ID, and correlation to unique value
        String uniqueTraceId = EncodingUtil.ConvertTohex(Crypto.GenerateAESKey(128)).left(16);
        String traceId = uniqueTraceId + ':' + uniqueTraceId + ':' + '0:0';
        objRequest.setHeader(BWC_Constants.HTTP_TRACE_ID_HEADER, traceId);

        System.debug(BWC_Constants.HTTP_TRACE_ID_HEADER + ': ' + traceId);

        String trxId = BWC_Utils.newGuid();
        objRequest.setHeader(BWC_Constants.HTTP_CORRELATION_ID_HEADER, trxId);
        objRequest.setHeader(BWC_Constants.HTTP_TRANSACTION_ID_HEADER, trxId);
        objRequest.setHeader(BWC_Constants.HTTP_ATT_TRANSACTION_ID_HEADER, trxId);
        objRequest.setHeader('Content-Type', 'application/json');

        // Get client ID and secret from named credential user/password
        objRequest.setHeader('client_id', '{!$Credential.UserName}');
        objRequest.setHeader('client_secret', '{!$Credential.Password}');
        
        if (strRequestBody != null) {
            objRequest.setBody(strRequestBody); 
            System.debug('Request body: ' + strRequestBody);
        }

        try {

            // Save request
            BWC_IntegrationUtility.lastRequest = objRequest;
            BWC_IntegrationUtility.lastResponse = null;

            HTTPResponse objResponse;
            BWC_Api_Mock__mdt apiMock;
            if (FeatureManagement.checkPermission('BWC_Api_Mock') || Test.isRunningTest()) {

                // Check for matching API mock
                apiMock = BWC_ApiMock.findApiMock(objIntegrationSetting, objRequest);
                if (apiMock != null) {
                    // There's a mock, get response -- may return null if it's Use Processor Only
                    lastApiMock = apiMock;
                    objResponse = BWC_ApiMock.getMockResponse(apiMock, objRequest);
                }

            }

            if (objResponse == null) {
                // No mock response, call real API
                objResponse = objHttp.send(objRequest); //Sending HTTP Request
            }

            if (objIntegrationSetting.Enable_API_Logging__c == true) {
                // Log request and response
                BWC_APILogging.log(apiName, namedCredential, objRequest, objResponse, null);
            }

            // Save response
            BWC_IntegrationUtility.lastResponse = objResponse;

            if (apiMock != null) {
                // There's an API mock, let it process if there's a processor
                BWC_ApiMock.processResponse(apiMock, objRequest, objResponse);
            }

            if (objResponse.getStatusCode() >= 400) {

                // Throw status 400 or greater as error
                // Caller can catch if needed
                throw new BWC_HttpException(objRequest, objResponse);

            }

            return objResponse;

        }
        catch (System.Exception e) {

            BWC_HttpException httpException;

            // Just rethrow if already HTTP exception -- it's been logged
            if (e instanceof BWC_HttpException) {
                throw e;
            }

            // Create new HTTP exception
            httpException = new BWC_HttpException(objRequest, e);

            // Log request and exception (no response)
            if (objIntegrationSetting.Enable_API_Logging__c == true) {
                BWC_APILogging.log(apiName, namedCredential, objRequest, null, e);
            }

            throw httpException;

        }
        finally {

            Logger.saveLog();

        }

    }
    
    /* ================================================
    *@description : Queries the record that holds details for an API callout request
    *@param : strOperation - takes name of the method to uniquely identify the record     
    *@return : void(sets the class variable)
    ================================================*/
    private static void getIntegrationHeader(String apiName){ 
        
        objIntegrationSetting = [Select Id,
                                DeveloperName,
                                 Named_Credential__c,
                                 Enable_API_Logging__c,
                                 Method_Name__c,
                                 Method_type__c,
                                 Certificate_Name__c, 
                                 Sub_URL__c,
                                 RTF_Sub_URL__c,
                                 Timeout__c,
                                 Mocking_Request_URL_Regex__c,
                                 Mocking_Request_Body_Regex__c
                                 FROM BWC_Integration_Metadata__mdt
                                 WHERE DeveloperName=:apiName Limit 1];
        
    }    
   
}