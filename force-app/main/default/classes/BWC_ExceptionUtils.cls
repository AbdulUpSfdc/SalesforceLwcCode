/* ================================================
* @author : Anshul Gupta
* @date : 9/06/2020     
* @group : utility
* @description : Exception class that wriites an exception to exception object.
================================================*/
public with sharing class BWC_ExceptionUtils {

    public class ExceptionResponse {

        public String node;
        public Integer code;
        public String message;
        public String description;
        public String transactionId;
        public String idpTraceId;
        public string stacktrace;

    }

    /*
        Convert the exception to AuraHandledException whose message is JSON with embedded detail that can be parsed on browser.
    */
    public static AuraHandledException convertToAuraHandledException(System.Exception caughtException) {

        ExceptionResponse response = new ExceptionResponse();
        response.message = caughtException.getMessage();

        if (caughtException instanceof BWC_HttpException) {

            BWC_HttpException httpException = (BWC_HttpException)caughtException;
            response.code = httpException.statusCode;

        }

        response.stacktrace = caughtException.getStackTraceString();
        throw new AuraHandledException(JSON.serialize(response));

    }

    /*
        Log exception along with request and response context information.
    */
    public static void handleException(Exception exceptionCaught, String requestContext, String responseContext) {
        handleException(exceptionCaught, true, requestContext, responseContext);
    }    

    public static void handleException(Exception exceptionCaught, Boolean logToObject) {
        handleException(exceptionCaught, logToObject, null, null);
    }

    public static void handleException(Exception exceptionCaught, Boolean logToObject, String requestContext, String responseContext) {

        // Get full trace all causes
        String causeString = '';
        Exception currentCause = exceptionCaught.getCause();
        while (currentCause != null) {

            if (causeString != '') {
                causeString += '\r\n';
            }

            causeString += '[' + currentCause.getTypeName() + ']\r\n';
            causeString += currentCause.getMessage() + '\r\n';
            causeString += currentCause.getStackTraceString() + '\r\n';

            // Get next cause
            currentCause = currentCause.getCause();

        }

        Exception__c exceptionStaged = new Exception__c();
        
        exceptionStaged.Cause__c = causeString;
        exceptionStaged.Line_Number__c = exceptionCaught.getLineNumber();
        exceptionStaged.Message__c = exceptionCaught.getMessage();
        exceptionStaged.Stack_Trace_String__c = exceptionCaught.getStackTraceString();
        exceptionStaged.Type_Name__c = exceptionCaught.getTypeName();
        exceptionStaged.Request_Context__c = requestContext == null ? '' : requestContext;
        exceptionStaged.Response_Context__c = responseContext == null ? '' : responseContext;

        if (exceptionCaught instanceof BWC_HttpException) {

            // // Get request and response bodies from api call
            // BWC_HttpException httpException = (BWC_HttpException)exceptionCaught;

            // if (httpException.request != null && httpException.request.getBody() != null) {

            //     if (!String.isEmpty(exceptionStaged.Request_Context__c)) {
            //         exceptionStaged.Request_Context__c += '\r\n\r\n';
            //     }
            //     exceptionStaged.Request_Context__c += 'HTTP Endpoint: ' + httpException.request.getMethod() + ' ' + httpException.request.getEndpoint() + '\r\n';
            //     exceptionStaged.Request_Context__c += 'HTTP Request Body: ' + httpException.request.getBody();
            //     exceptionStaged.Request_Context__c = exceptionStaged.Request_Context__c.left(32768);

            // }

            // if (httpException.response != null && httpException.response.getBody() != null) {

            //     if (!String.isEmpty(exceptionStaged.Response_Context__c)) {
            //         exceptionStaged.Response_Context__c += '\r\n\r\n';
            //     }
            //     exceptionStaged.Response_Context__c += 'HTTP Status: ' + httpException.response.getStatusCode() + ' ' + httpException.response.getStatus() + '\r\n';
            //     exceptionStaged.Response_Context__c += 'HTTP Response Body: ' + httpException.response.getBody();
            //     exceptionStaged.Response_Context__c = exceptionStaged.Response_Context__c.left(32768);

            // }

        }

        if (exceptionCaught instanceof BWC_Exception) {

            // Get any context from exception
            BWC_Exception bwcException = (BWC_Exception)exceptionCaught;

            if (!String.isEmpty(bwcException.requestContext)) {

                if (!String.isEmpty(exceptionStaged.Request_Context__c)) {
                    exceptionStaged.Request_Context__c += '\r\n\r\n';
                }
                exceptionStaged.Request_Context__c += bwcException.requestContext;

            }

            if (!String.isEmpty(bwcException.responseContext)) {

                if (!String.isEmpty(exceptionStaged.Response_Context__c)) {
                    exceptionStaged.Response_Context__c += '\r\n\r\n';
                }
                exceptionStaged.Response_Context__c += bwcException.responseContext;

            }

        }

        if(logToObject) {

            exceptionStaged.Request_Context__c = exceptionStaged.Request_Context__c.left(32768);
            exceptionStaged.Response_Context__c = exceptionStaged.Response_Context__c.left(131072);

            BWC_ExceptionUtils.logToObject(exceptionStaged);

        }

    }

    private static void logToObject(Exception__c exceptionPassed) {

		List<Exception__c> exceptionsToInsert = new List<Exception__c >();

        exceptionsToInsert.add(exceptionPassed);
        insert exceptionsToInsert;
    }
}