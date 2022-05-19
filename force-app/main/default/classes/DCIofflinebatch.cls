global without sharing class DCIofflinebatch implements Database.Batchable<sObject>{
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        
        return Database.getQueryLocator([
            select Id, Employee__r.User__c,IsLoginStore__c,Store__c,DCIPresenceStatus__c,
            Employee__c,Employee__r.SFProfileId__c 
            from EmployeeStoreRetail__c where  DCIPresenceStatus__c in ('Online','Busy','Break')
        ]);
    }
    
    global void execute(Database.BatchableContext BC, List<EmployeeStoreRetail__c> scope){
       // List<EmployeeStoreRetail__c> esrList= new List<EmployeeStoreRetail__c>();
        for(EmployeeStoreRetail__c esr: scope){
            esr.DCIPresenceStatus__c ='Offline';
            //esrList.add(esr);
        }
        //DCIRepUtil.updateRepStatusBulkify(esrList);
        update scope;
    }
    
    global void finish(Database.BatchableContext BC){
    }
}