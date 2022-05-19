public with sharing class CustomerFollowUpMissedBatch implements Database.Batchable<sObject>{
    String query;
    public Database.QueryLocator start(Database.BatchableContext BC) {
        query = 'SELECT id, Owner__c, Owner__r.IsActive, Name, Status, Store__c, LeadSource'  +
                ' FROM Lead '; 
        query += ' WHERE NextFollowUpDate__c = YESTERDAY AND (TotalContactsMade__c = 0 OR TotalContactsMade__c = NULL) AND Status != \''+RetailConstants.CLOSED+'\'';
        
        system.debug('query--->>'+query);
        return Database.getQueryLocator(query);
    }
    
    /*
     * This method performs the Lead Redistribution
    */
    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Lead> leadsToProcess = (List<Lead>) scope; 
        NotificationsHandler.sendCustomerRequestedFollowUpDateHasPassedNotification(leadsToProcess);
    }
    
    public void finish(Database.BatchableContext BC){
        BatchStatus__c batchDetails = BatchStatus__c.getValues(RetailConstants.MISSED_FOLLOWUP_BATCH);
        if(batchDetails != null && batchDetails.Email__c != null) {
            // Get the ID of the AsyncApexJob representing this batch job from Database.BatchableContext.
            // Query the AsyncApexJob object to retrieve the current job's information.
            AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
                                FROM AsyncApexJob WHERE Id = :BC.getJobId()];
            if(a != null) {
                // Send an email to the Apex job's submitter notifying of job completion.
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                list<String> toAddresses = batchDetails.Email__c.split(';');
                mail.setToAddresses(toAddresses);
                mail.setSubject(RetailConstants.UNICA_BATCH_NAME+' Batch ' + a.Status);
                mail.setPlainTextBody('The batch Apex job processed ' + a.TotalJobItems +' batches with '+ a.NumberOfErrors + ' failures.');
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }
        }
    }
}