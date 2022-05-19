public with sharing class BWC_SOALevelTriggerHelper {

    // Method to handle before insert trigger operation
    public static void onBeforeInsert(){

        setExternalIdValueOnSOA((List<SOA_Level__c>) trigger.new);

    }

    // Method to handle before update trigger operation
    public static void onBeforeUpdate(){

        setExternalIdValueOnSOA((List<SOA_Level__c>) trigger.new);

    }

    // Method to set the external Id field
    private static void setExternalIdValueOnSOA(List<SOA_Level__c> soaLvlList){

        for(SOA_Level__c soaLvl : soaLvlList){

            soaLvl.External_Id__c = soaLvl.Organization__c + '|' + soaLvl.Line_of_Business__c + '|' + soaLvl.Channel__c + '|' +  soaLvl.Sub_Channel__c + '|' + soaLvl.Authorization_Level__c;

        }

    }
}