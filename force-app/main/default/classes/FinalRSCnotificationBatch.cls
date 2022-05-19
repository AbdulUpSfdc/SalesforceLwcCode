/*
* This batch class implements FinalRSCnotification
* fetch all the open leads and send final notification to reps and/or managers
* 5 days prior to lead expiration date.
* 
* itrack : SPTSFDCSLS-729
* Author: Srinivas Vallepu
*
* Modifications Log 
* Ver   Date         Author                                    Modification
* 
*/

public with sharing class FinalRSCnotificationBatch implements Database.Batchable<sObject>{
    String query; Date Dat5 = Date.today().adddays(5);
    public Database.QueryLocator start(Database.BatchableContext BC) {
        query = 'SELECT id, Owner__c, Owner__r.IsActive, Name, Status, Store__c, LeadSource, CustomerType__c, LeadExpirationDate__c'  +
                ' FROM Lead '; 
        query += ' WHERE LeadExpirationDate__c =: Dat5 AND Status != \''+RetailConstants.CLOSED+'\'';
        
        system.debug('query--->>'+query);
        return Database.getQueryLocator(query);
    }
    
    /*
     * This method sends the list in scope to NotificationsHandler for system to send Final RSC bell notification to Reps/Store Managers
    */
    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Lead> leadsToProcess = (List<Lead>) scope; 
        NotificationsHandler.sendLeadExpirationFinalRSCNotification(leadsToProcess);
    }
    
    public void finish(Database.BatchableContext BC){
        BatchStatus__c batchDetails = BatchStatus__c.getValues(RetailConstants.FINAL_RSC_NOTIF);
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
                mail.setSubject(RetailConstants.FINAL_RSC_NOTIF+' Batch ' + a.Status);
                mail.setPlainTextBody('The batch Apex job processed ' + a.TotalJobItems +' batches with '+ a.NumberOfErrors + ' failures.');
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }
        }
    }
}