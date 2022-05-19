/**
 * @description       : Batch class to Handle Lead Redistributions
 * @author            : Erashad Kurawle ekurawle@salesforce.com
 * @group             : 
 * @last modified on  : 01-05-2021
 * @last modified by  : Erashad Kurawle ekurawle@salesforce.com
 * Modifications Log 
 * Ver   Date         Author                                    Modification
 * 1.0   12-23-2020   Erashad Kurawle ekurawle@salesforce.com   Initial Version
**/
global without sharing class LeadRedistributionBatch implements Database.Batchable<SObject>, Database.Stateful,Database.RaisesPlatformEvents{
    
    public List<String> errorRecordIds = new List<String>{};
    public List<String> successRecordIds = new List<String>{};
    
    /**
     * @description:   Start method for the batch
     */
    public List<LeadRedistribution__c> start(Database.BatchableContext ctx) {
        return [select Id, Action__c, Reason__c, User__c, OldValue__c, NewValue__c, Status__c, IsPrimary__c, AdditionalAttributes__c, ErrorMessage__c, Retry__c, 
                Employee__c, Employee__r.FirstName__c, Employee__r.LastName__c, Employee__r.SFProfileId__c, Employee__r.User__c, Employee__r.IsActive__c,
                EmployeeStoreRetail__c, EmployeeStoreRetail__r.Store__c, EmployeeStoreRetail__r.Employee__c
                from LeadRedistribution__c 
                where Status__c!='Success'];
    }

    /**
     * @description:   Execute method for the batch
     */
    public void execute(Database.BatchableContext ctx, List<SObject> scope) {
        List<LeadRedistribution__c> leadRedistributions =(List<LeadRedistribution__c>) scope ;
        
        //Initialize a batch Handler
        LeadRedistributionBatchHandler batchHandler = new LeadRedistributionBatchHandler(leadRedistributions);
        //Fill up relevant maps
        batchHandler.fillUpAllMaps();
        //Run strategies for the 4 different scenarios
        batchHandler.runAllStrategies();

    }

    /**
     * @description:   Finish method for the batch
     */
    public void finish(Database.BatchableContext ctx) { }

}