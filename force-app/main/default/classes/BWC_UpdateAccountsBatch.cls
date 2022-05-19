public with sharing class BWC_UpdateAccountsBatch implements Database.Batchable<sObject> {


    String query = '';
    public BWC_UpdateAccountsBatch(String query){
        this.query = query;
    }
    public Database.QueryLocator start(Database.BatchableContext BC){

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<CG_Data_Sync__c> dataSyncLst){

        try {
            testScriptUpdate.processCGData(dataSyncLst);
        } catch (Exception e) {
            System.debug(e.getCause()+'-'+e.getMessage()+' - '+e.getStackTraceString());
        }
    }

    public void finish(Database.BatchableContext BC){
    }
}