/*
* This class is used to process the bulk load of Unica Leads and assign the Leads based on Store associated with the Leads
* @Author: Reshma Jewrani
*/
public with sharing class ProcessUnicaLeadsBatch implements Database.Batchable<sObject>{
    public String query;
    
    /*
     * This method fetches the relevant Lead data to be processed 
    */
    public Database.QueryLocator start(Database.BatchableContext BC) {
        String whereClause = '';
        List<BatchConditions__c> conditions = [SELECT BatchClassName__c, FieldApiName__c, Operator__c, Value__c
                                        FROM BatchConditions__c 
                                        WHERE BatchClassName__c = :RetailConstants.UNICA_BATCH_NAME];
        if(conditions.size() > 0)
            whereClause = ' WHERE ';
        for(BatchConditions__c cond: conditions) {
            whereClause+= ' '+cond.FieldApiName__c + ' ' + cond.Operator__c + ' ' + cond.Value__c + ' AND ';
        }
        whereClause = whereClause.removeEnd('AND ');
        //Fetch Leads to be processed
        query = 'SELECT id, OwnerId, Owner__c, Name, Status, ReassignmentReason__c, Store__c, LeadSource'  +
                ' FROM Lead '; 
        query += whereClause;
        
        system.debug('query--->>'+query);
        return Database.getQueryLocator(query);
    }
    
    /*
     * This method performs the Lead Redistribution
    */
    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Lead> leadsToProcess = (List<Lead>) scope; 
        List<Lead> updateLeadList = RedistributeLeadHandler.redistributeLeads(leadsToProcess,  RetailConstants.UNICA_BATCH_LEAD);
        TriggerHelper.isUnicaBulkLoad = true; //For not sending notifications for bulk data 
        TriggerHelper.isLeadDateSkipped = true; //For not setting Contact Dates
        update updateLeadList;
    }
    
    /*
     * This method sends a batch status email if the same is configured in the custom setting
    */
    public void finish(Database.BatchableContext BC){
	    Database.executeBatch(new BellNotificationBatch());  //ma242d SPTSLSATT-15
        BatchStatus__c batchDetails = BatchStatus__c.getValues(RetailConstants.UNICA_BATCH_NAME);
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