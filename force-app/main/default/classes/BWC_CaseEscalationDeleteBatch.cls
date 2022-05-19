/*
    Periodically deletes all records of specified object types which haven't been modified in specified time period.
*/
public with sharing class BWC_CaseEscalationDeleteBatch implements Schedulable, Database.Batchable<SObject> {

    // Constants
    @testvisible private static final String SCHEDULED_JOB_NAME = 'BWC Case Escalation Delete Batch';
    private static final String DAILY_CRON_STRING = '0 0 0 1/1 * ? *';    // Run every day at 12 midnight

    // Object that will be deleted
    private static final List<String> SOBJECT_API_NAMES = new List<String> {
        'Case'
    };
    

    // Allows testing of different metadata
    @testvisible private static BWC_Batch_Parameters__mdt testBatchParameters;

    /*
        Get batch parameters.
    */
    private static BWC_Batch_Parameters__mdt getBatchParameters() {

        // Look for metadata record by class name
        List<BWC_Batch_Parameters__mdt> batchParameters = [
            SELECT
                Id, Enabled__c, Hours_In_Past__c, Scope_Size__c
            FROM
                BWC_Batch_Parameters__mdt
            WHERE
                DeveloperName = 'BWC_CaseEscalationDeleteBatch'
        ];

        if (Test.isRunningTest() && testBatchParameters != null) {
            batchParameters = new List<BWC_Batch_Parameters__mdt>{testBatchParameters};
        }

        if (batchParameters.isEmpty()) {

            throw new BWC_Exception('No BWC_Batch_Parameters__mdt record found for BWC_CaseEscalationDeleteBatch; cannot run batch.');

        }
        else {

            return batchParameters[0];

        }

    }

    /*
        Schedule the batch for the default schedule. Checks if it's already scheduled.
    */
    public static void scheduleBatch() {

        unscheduleBatch();

        System.schedule(SCHEDULED_JOB_NAME, DAILY_CRON_STRING, new BWC_CaseEscalationDeleteBatch());

    }

    /*
        Unschedule any existing scheduled batches.
    */
    public static void unscheduleBatch() {

        // Find scheduled job
        List<CronTrigger> cronTriggers = [
            SELECT Id
            FROM CronTrigger 
            WHERE CronJobDetail.Name = :SCHEDULED_JOB_NAME
        ];

        // Abort all found, ignore any errors caused by it not being abortable for whatever reason
        for (CronTrigger theCronTrigger : cronTriggers) {

            try {
                System.abortJob(theCronTrigger.Id);
            }
            catch (System.Exception e) {

                String message = String.format('Failed to abort CronTrigger job {0}: {1}', new List<Object>{theCronTrigger.Id, e.getMessage()});
                BWC_ExceptionUtils.handleException(new BWC_Exception(message, e), true);

            }

        }

    }

    /*
        Schedulable execute.
    */
    public void execute(SchedulableContext SC) {

        try {

            BWC_Batch_Parameters__mdt batchParameters = getBatchParameters();

            if (batchParameters.Enabled__c != true) {
                System.debug('Batch is not Enabled in BWC_Batch_Parameters__mdt.');
                return;
            }

            // Execute the batch job using the specified scope size and for the first object in the list
            Database.executeBatch(new BWC_CaseEscalationDeleteBatch(SOBJECT_API_NAMES[0]),(Integer)batchParameters.Scope_Size__c);

        }
        catch (System.Exception e) {

            BWC_ExceptionUtils.handleException(e, true);

        }

    }

    //Settings
    public String sObjectApiName;    // SObject type to delete

    public BWC_CaseEscalationDeleteBatch() {}

    public BWC_CaseEscalationDeleteBatch(String sObjectApiName) {
        this.sObjectApiName = sObjectApiName;
    }

    /*
        Batchable start.
    */
    public Database.QueryLocator start(Database.BatchableContext bc) {

        try {

             BWC_Batch_Parameters__mdt batchParameters = getBatchParameters();
             String soql = String.format('SELECT Id FROM {0} WHERE ', new List<Object>{this.sObjectApiName});

            // Contain case by record type
            Id escalationRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Escalation').getRecordTypeId();
            if (this.sObjectApiName == 'Case') {
                soql += 'RecordTypeId = :escalationRecordTypeId ';
                soql += 'AND CaseAction__c = NULL';
            }
            return Database.getQueryLocator(soql);

        }
        catch (System.Exception e) {

            BWC_ExceptionUtils.handleException(e, true);
            System.abortJob(bc.getJobId());
            return null;

        }

    }

    /*
        Batchable execute.
    */
    public void execute(Database.BatchableContext bc, List<SObject> records) {

        try {

            //Just delete the records
            delete records;

        }
        catch (System.Exception e) {

            BWC_ExceptionUtils.handleException(e, true);
            System.abortJob(bc.getJobId());
            

        }

    }

    /*
        Batchable finish.
    */
    public void finish(Database.BatchableContext bc) {}

}