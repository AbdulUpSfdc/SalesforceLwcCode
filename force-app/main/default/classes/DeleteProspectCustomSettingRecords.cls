/**
 * Author : Rajesh Meda,Akshay Kumar
 * Date : 12/07/2020
 * Last Modified on : 2/17/2021 
 * Last Modified by : Akshay Kumar 
 * This class is mainly inteneded to clear all the user location trace (Prospect) custom setting records (Ex: 2.5 MB) upto yesterday and avoid reaching custom setting space (10 MB) limits.
 * This Job runs every night at 1 AM.
 */
public with sharing class DeleteProspectCustomSettingRecords implements Database.Batchable<SObject>, Schedulable,Database.stateful
{
    // String variable to capture the exception message
    String failureBody='';
    
    // Boolean variable to trigger exception from test class;
    @TestVisible Boolean forceException=false;
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([Select id from UserCurrentLocation__c where CreatedDate < today ]);
    }

    public void execute(Database.BatchableContext bc, List<sObject> scope)
    {
        try
        {
            // delete the record and remove them from recycle bin
            delete scope;
            DataBase.emptyRecycleBin(scope);
            /*The line below have been written to trigger the exception forcefully and
            * will only be executed when test classes are run
            */
            if(Test.isRunningTest() && forceException)
             throw new DMLException('This is just for test class');
        }
        catch(Exception e)
        {
            failureBody=failureBody+e.getMessage()+'<br/>';
        }
    }

    public void finish(Database.BatchableContext bc)
    {
        // send an email to the person running the batch
        BatchStatus__c batchDetails = BatchStatus__c.getValues(RetailConstants.USERLOCATIONDELETION_BATCH_NAME);
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
                mail.setSubject(RetailConstants.USERLOCATIONDELETION_BATCH_NAME+' Batch ' + a.Status);
                mail.setPlainTextBody('The batch Apex job processed ' + a.TotalJobItems +' batches with '+ a.NumberOfErrors + ' failures.');
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }
        }
    }

	public void execute (SchedulableContext ctx)
    {
        Database.executeBatch(new DeleteProspectCustomSettingRecords());
    }
}