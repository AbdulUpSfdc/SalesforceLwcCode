/*
* This Batch class is used for deleting the Lead Consent Records Created in last 30 minutes 
* Author: Venu Peddu
*/

global without sharing class DeleteAcceptedLeadcreatedinlast30mins implements Database.Batchable<sObject>{
    global Integer lastTimeCreated = 0;
    global DeleteAcceptedLeadcreatedinlast30mins(){        
        BatchStatus__c batchDetails = BatchStatus__c.getValues('DeleteAcceptedLeadcreatedinlast30mins');
        if(batchDetails != null && batchDetails.Record_Created_Duration__c != null) {
        lastTimeCreated = Integer.valueOf(batchDetails.Record_Created_Duration__c);
            system.debug('lastTimeCreated'+lastTimeCreated);
        } 
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        Datetime halfHourBack = Datetime.now().addMinutes(-lastTimeCreated);
        return Database.getQueryLocator([
            select Id
            from LeadConsent__c
            where  CreatedDate <=:halfHourBack AND Type__c = 'Prospect'
            ]);
    }

    global void execute(Database.BatchableContext BC, List<LeadConsent__c> scope){
        system.debug('scope' +scope);
        delete scope;
    }

    global void finish(Database.BatchableContext BC){
    }
}