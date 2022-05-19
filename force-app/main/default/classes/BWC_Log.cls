/*
    Common code related to logging.
*/
public with sharing class BWC_Log {

    public static final String CATEGORY_AURAENABLED = 'AuraEnabledMethod';
    public static final String CATEGORY_QUEUEABLE = 'QueueableJob';


    /*
        Set the related record for Nebula logger. This is used in cases where the record ID may not be available at the point where logging occurs.
    */
    public static Id relatedRecordId;
    public static void setRelatedRecordId(Id relatedRecordId) {
        BWC_Log.relatedRecordId = relatedRecordId;
    }

    /*
        Builds a pipe-delimited context string.
    */
    public with sharing class Context {

        private String value = '';

        public Context() {}

        /*
            Construct with one name/value pair.
        */
        public Context(String name, String value) {
            this.add(name, value);
        }

        public Context add(String name, String value) {
            if (!String.isEmpty(this.value)) {
                this.value += '|';
            }
            this.value += name + '=' + value;
            return this;
        }

        public override String toString() {
            return this.value;
        }

    }

    /*
        Log exception to Nebula.
    */
    public static void logException(System.Exception caughtException, String category, BWC_Log.Context context, Id relatedRecordId) {
        logException(caughtException, category, context != null ? context.toString() : null, relatedRecordId);
    }

    /*
        Log exception to Nebula.
    */
    public static void logException(System.Exception caughtException, String category, String context, Id relatedRecordId) {

        String message = 'category=' + category;
        if (!String.isEmpty(context)) {
            message += '|' + context;
        }

        // Log to Nebula
        if (caughtException != null) {
            Logger.error(message, relatedRecordId, caughtException).parseStackTrace(caughtException.getStackTraceString());
        }
        else {
            Logger.error(message, relatedRecordId);
        }
        Logger.saveLog();

    }

}