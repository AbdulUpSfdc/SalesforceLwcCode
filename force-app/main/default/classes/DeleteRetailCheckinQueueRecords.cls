/**
* Author :Akshay Kumar
* Date :3/4/2021
* This class is mainly inteneded to clear all the DCI records for the day, prior to deleting these records the Lead Status and Lead Close Status is updated
* for the corresponding lead and the required field values are copied to the lead if the status is Arrived, Pending or No Show
*/


public without sharing class DeleteRetailCheckinQueueRecords  implements Database.Batchable<SObject>, Schedulable,Database.stateful
{ 
    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([Select id,ArrivingTimeLocalTz__c,CheckInTimeLocalTz__c,CreatedDateLocalTz__c,LastModifiedDateLocalTz__c,lead__c,DCIInitialEWT__c,DCIEWTCalculationType__c,DCIInitialQueuePosition__c,DCITimeUntilFree__c,ArrivingTime__c,DCIMaximum_EWT__c,DCITimeWaiting__c,DCIMinimum_EWT__c, 
                                         createddate,Store__c,Status__c,DCITransactionTime__c,DCITotalRepCount__c,DCIAvailableRepCount__c, InitialMaximumEWT__c from RetailCheckinQueue__c where Status__c in 
                                         :DCIConstants.ALLOWED_STATUS_FOR_STORE_CLEANUP  and (CheckInTime__c<=TODAY or CheckInTime__c=null)]);
    }
    
    public void execute(Database.BatchableContext bc, List<sObject> scope)
    {
        List<Lead> updateLeadList=new List<Lead>();
        Map<Id,store__c> updateStoreMap=new Map<Id,Store__c>();
        for(Sobject obj : scope)
        {
            RetailCheckinQueue__c currentRecord=(RetailCheckinQueue__c) obj;
            
            if(currentRecord.Status__c==DCIConstants.PENDING || currentRecord.Status__c==DCIConstants.INSTORE|| currentRecord.Status__c==DCIConstants.NOSHOW || currentRecord.Status__c==DCIConstants.ACTIVE)
            {
                if(currentRecord.lead__c!=null)
                {
                    Lead relatedLead=new Lead(id=currentRecord.lead__c);
                    relatedLead.DciArrivingTimeLocalTz__c = currentRecord.ArrivingTimeLocalTz__c;
                    relatedLead.DciCheckInTimeLocalTz__c = currentRecord.CheckInTimeLocalTz__c;
                    relatedLead.DciCreatedDateLocalTz__c = currentRecord.CreatedDateLocalTz__c;
                    relatedLead.DciLastModifiedDateLocalTz__c = currentRecord.LastModifiedDateLocalTz__c;
                    relatedLead.DCIInitialEWT__c = currentRecord.DCIInitialEWT__c;
                    relatedLead.DCIEWTCalculationType__c = currentRecord.DCIEWTCalculationType__c;
                    relatedLead.DCIInitialQueuePosition__c = currentRecord.DCIInitialQueuePosition__c;
                    relatedLead.DCITimeUntilFree__c = currentRecord.DCITimeUntilFree__c;
                    relatedLead.DCIArriving_Time__c=currentRecord.ArrivingTime__c;
                    relatedLead.DCIMaximum_EWT__c=currentRecord.DCIMaximum_EWT__c;
                    relatedLead.DCITime_Waiting__c=currentRecord.DCITimeWaiting__c;
                    relatedLead.DCIMinimum_EWT__c=currentRecord.DCIMinimum_EWT__c;
                    relatedLead.status=RetailConstants.CLOSED ;
                    if(currentRecord.Status__c!=DCIConstants.ACTIVE)
                        relatedLead.closedstatus__c=RetailConstants.CLOSED_NOSHOW;
                    else
                        relatedLead.closedstatus__c=RetailConstants.CLOSED_COMPLETED;
                    relatedLead.DCIStatus__c=currentRecord.Status__c;
                    relatedLead.DCITransactionTime__c=currentRecord.DCITransactionTime__c;
                    relatedLead.DCITotalRepCount__c=currentRecord.DCITotalRepCount__c;
                    relatedLead.DCIAvailableRepCount__c=currentRecord.DCIAvailableRepCount__c;
                    relatedLead.DCIInitialMaximumEWT__c = currentRecord.InitialMaximumEWT__c;
                    Store__c relatedStore=new Store__c(id=currentRecord.Store__c);
                    relatedStore.DCILeadsinCheckinQueue__c  =0;
                    relatedStore.DCIEstimatedWaitTime__c=0;
                    updateStoreMap.put(relatedStore.Id,relatedStore);
                    
                    updateLeadList.add(relatedLead);
                }
            } else if (currentRecord.Status__c==DCIConstants.CANCELLED || currentRecord.Status__c==DCIConstants.COMPLETED){
                if(currentRecord.lead__c!=null)
                {
                    Lead relativeLead=new Lead(id=currentRecord.lead__c);
                    relativeLead.DciArrivingTimeLocalTz__c = currentRecord.ArrivingTimeLocalTz__c;
                    relativeLead.DciCheckInTimeLocalTz__c = currentRecord.CheckInTimeLocalTz__c;
                    relativeLead.DciCreatedDateLocalTz__c = currentRecord.CreatedDateLocalTz__c;
                    relativeLead.DciLastModifiedDateLocalTz__c = currentRecord.LastModifiedDateLocalTz__c;
                    relativeLead.DCIInitialEWT__c = currentRecord.DCIInitialEWT__c;
                    relativeLead.DCIEWTCalculationType__c = currentRecord.DCIEWTCalculationType__c;
                    relativeLead.DCIInitialQueuePosition__c = currentRecord.DCIInitialQueuePosition__c;
                    relativeLead.DCITimeUntilFree__c = currentRecord.DCITimeUntilFree__c;
                    relativeLead.DCIArriving_Time__c=currentRecord.ArrivingTime__c;
                    relativeLead.DCIMaximum_EWT__c=currentRecord.DCIMaximum_EWT__c;
                    relativeLead.DCITime_Waiting__c=currentRecord.DCITimeWaiting__c;
                    relativeLead.DCIMinimum_EWT__c=currentRecord.DCIMinimum_EWT__c;
                    relativeLead.DCIStatus__c=currentRecord.Status__c;
                    relativeLead.status=RetailConstants.CLOSED ;
                    if(currentRecord.Status__c==DCIConstants.CANCELLED)
                        relativeLead.closedstatus__c=RetailConstants.CLOSED_CANCELLED;
                    else
                        relativeLead.closedstatus__c=RetailConstants.CLOSED_COMPLETED;
                    relativeLead.DCITransactionTime__c=currentRecord.DCITransactionTime__c;
                    relativeLead.DCITotalRepCount__c=currentRecord.DCITotalRepCount__c;
                    relativeLead.DCIAvailableRepCount__c=currentRecord.DCIAvailableRepCount__c;
                    relativeLead.DCIInitialMaximumEWT__c = currentRecord.InitialMaximumEWT__c;
                    Store__c relativeStore=new Store__c(id=currentRecord.Store__c);
                    relativeStore.DCILeadsinCheckinQueue__c  =0;
                    relativeStore.DCIEstimatedWaitTime__c=0;
                    updateStoreMap.put(relativeStore.Id,relativeStore);
                    
                    updateLeadList.add(relativeLead);
                    
                }
                
            }
            
        }
        if(updateStoreMap.size()>0)
        {
            Database.update(updateStoreMap.values(),false);
        }
        
        // delete the record and remove them from recycle bin
        Database.delete(scope,false);
        //delete scope;
        DataBase.emptyRecycleBin(scope);
        if(updateLeadList.size()>0)
        {
            Database.update(updateLeadList,false);
        }
        
    }
    
    public void finish(Database.BatchableContext bc)
    {
        ID BatchId = Database.executeBatch(new DCIofflinebatch(), 200);
        // send an email to the person running the batch
        BatchStatus__c batchDetails = BatchStatus__c.getValues(RetailConstants.RETAILCHECKINQUEUEDELETION_BATCH_NAME);
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
                mail.setSubject(RetailConstants.RETAILCHECKINQUEUEDELETION_BATCH_NAME +' Batch ' + a.Status);
                mail.setPlainTextBody('The batch Apex job processed ' + a.TotalJobItems +' batches with '+ a.NumberOfErrors + ' failures.');
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }
        }
    }
    public void execute (SchedulableContext ctx)
    {
        Database.executeBatch(new DeleteRetailCheckinQueueRecords());
    }
}