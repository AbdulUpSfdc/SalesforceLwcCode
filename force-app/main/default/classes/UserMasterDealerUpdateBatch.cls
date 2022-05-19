/*
* Author : Anand Tiwari
* Purpose: This batch class will be executed from Scheduler class every day
* and Will update the Master Dealer & ID field on Employee and User record.
* 
*
* Modifications Log 
* Ver   Date         Author
* 1.0   06-30-2021   Anand 
*/

public without sharing class UserMasterDealerUpdateBatch implements Database.Batchable<sObject> {
    public String query;
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        List<String> RETAIL_PROFILES = RetailConstants.RETAIL_PROFILES;

        query = 'SELECT Id, User__c, User__r.MasterDealer__c, HomeStoreLocation__c, HomeStoreLocation__r.MasterDealer__c, HomeStoreLocation__r.MasterDealerID__c FROM Employee__c '
                + 'WHERE HomeStoreLocation__r.MasterDealerID__c != null '
                + 'AND HomeStoreLocation__r.MasterDealer__c != null '
               // + 'AND User__r.MasterDealer__c = null '
                + 'AND User__r.IsActive = true '
                + 'AND SFProfileId__c IN :RETAIL_PROFILES '
                + 'AND HomeStoreLocation__r.ChannelType__c = \''+RetailConstants.AGENT_CHANNEL_TYPE+'\'';
        
        system.debug('Store Batch Query ---> ' + query);
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<sObject> scope){
        List <Employee__c> empUpdateList = new List<Employee__c>(); 
        List <User> userUpdateList = new List<User>(); 

        for(sObject sc : scope){
            Employee__c empRecord = (Employee__c)sc;
            
            empRecord.MasterDealer__c = empRecord.HomeStoreLocation__r.MasterDealer__c;
            empRecord.MasterDealerID__c = empRecord.HomeStoreLocation__r.MasterDealerID__c;

            if(empRecord.User__c != null && (empRecord.User__r.MasterDealer__c != empRecord.HomeStoreLocation__r.MasterDealer__c || empRecord.User__r.MasterDealer__c == null)){
                    User userRecord = new User();
                    userRecord.Id = empRecord.User__c;
                    userRecord.MasterDealer__c = empRecord.HomeStoreLocation__r.MasterDealer__c;

                    userUpdateList.add(userRecord);
            }
            empUpdateList.add(empRecord);
        }
        
        if(userUpdateList.size() > 0 && !Test.isRunningTest()){
            update userUpdateList;
        }
        if(empUpdateList.size() > 0 && userUpdateList.size() > 0){
            update empUpdateList;
         }
         
    }
    
    public void finish(Database.BatchableContext BC){
    }
    
}