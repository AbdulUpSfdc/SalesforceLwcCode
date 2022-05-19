public with sharing class BWC_Controller {

    public static final String LOG_CATEGORY = 'category=AuraEnabledMethod';

    // Allows unit test to specify throw of normal AuraException
    @testVisible private static Boolean THROW_TEST_AURA_EXCEPTION = false;

    public with sharing class ExceptionResponse {

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
        Also logs the exception.
    */
    public static System.Exception handleException(System.Exception caughtException, BWC_Log.Context context, Id relatedRecordId) {
        return handleException(caughtException, context != null ? context.toString() : null, relatedRecordId);
    }

    /*
        Convert the exception to AuraHandledException whose message is JSON with embedded detail that can be parsed on browser.
        Also logs the exception.
    */
    public static System.Exception handleException(System.Exception caughtException, String context, Id relatedRecordId) {

        if (Test.isRunningTest() && THROW_TEST_AURA_EXCEPTION != true) {
            // If running unit test, AuraHandledException is opaque -- throw normal exception so details can be seen
            return caughtException;
        }

        if (!Test.isRunningTest()) {
            BWC_Log.logException(caughtException, BWC_Log.CATEGORY_AURAENABLED, context, relatedRecordId);
        }

        ExceptionResponse response = new ExceptionResponse();
        response.message = caughtException.getMessage();

        if (caughtException instanceof BWC_HttpException) {

            BWC_HttpException httpException = (BWC_HttpException)caughtException;
            response.code = httpException.statusCode;

        }

        response.stacktrace = caughtException.getStackTraceString();
        return new AuraHandledException(JSON.serialize(response));

    }

    public static System.Exception handleException(System.Exception caughtException, String context) {
        return handleException(caughtException, context, BWC_Log.relatedRecordId);
    }

    public static System.Exception handleException(System.Exception caughtException) {
        return handleException(caughtException, '', BWC_Log.relatedRecordId);
    }

}