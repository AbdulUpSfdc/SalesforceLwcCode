/*
* Author : Rajesh Meda
 * 
 *
  * Modifications Log 
 * Ver   Date         Author                                    Modification
 * 2.0   02-04-2021   Erashad Kurawle ekurawle@salesforce.com   Fixing Sonarqube Vulnerabilities US995
*/
public with sharing class LeadClosureAfter30DayBatch implements Database.Batchable<sObject> {
    public String query;
   
    public Database.QueryLocator start(Database.BatchableContext BC){
        query = 'SELECT Id, ClosedStatus__c, Status, CloseDate__c, LeadExpirationDate__c, CreatedDate FROM Lead '
            	+'WHERE Status != \''+RetailConstants.CLOSED
            	+'\' AND LeadExpirationDate__c < Today';
        system.debug('query--->'+query);

        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<sObject> scope){
        List <Lead> leadsToClose = new List<Lead>(); 
        for(sObject s : scope){
            Lead LeadRec = (Lead)s;
            if(LeadRec.ClosedStatus__c != RetailConstants.CLOSED_SALE && LeadRec.Status != RetailConstants.CLOSED){
                LeadRec.ClosedStatus__c = RetailConstants.CLOSED_NOSALE;
                LeadRec.Status = RetailConstants.CLOSED;
                
                if(LeadRec.LeadExpirationDate__c < System.today()){
                    LeadRec.CloseDate__c = LeadRec.LeadExpirationDate__c;
                }
                leadsToClose.add(LeadRec);
            }
        }
        
        if(leadsToClose.size() > 0){
            update leadsToClose;
        }
    }
    
    public void finish(Database.BatchableContext BC){
    }
}