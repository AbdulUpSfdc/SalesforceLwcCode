public with sharing class BWC_BillingAccountTriggerHandler {

    public static void delegateProcessing(){

        if(Trigger.isBefore && Trigger.isInsert){
            handleBeforeInsert();
        }

        if(Trigger.isBefore && Trigger.isUpdate){
            handleBeforeUpdate();
        }

    }

    public static void handleBeforeInsert(){
        populateExternalId(Trigger.new);
    }

    public static void handleBeforeUpdate(){
        populateExternalId(Trigger.new);
    }

    public static void populateExternalId(List<Billing_Account__c> newList){

        for (Billing_Account__c billingAccount : newList) {

            if(billingAccount.External_Id__c == null){

                String externalId = billingAccount.Account_Type__c + '|' + billingAccount.Billing_Account_Number__c;
                billingAccount.External_Id__c = externalId.toLowerCase();

            }
			billingAccount.Name = billingAccount.Billing_Account_Number__c;
        }

    }
}