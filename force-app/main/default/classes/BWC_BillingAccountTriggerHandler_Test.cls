@IsTest
public with sharing class BWC_BillingAccountTriggerHandler_Test {
    @IsTest
    static void populateExternalIdTest(){

        Test.startTest();
        Account acct = BWC_TestDataFactory.createAccount();
        Billing_Account__c billAcc = BWC_TestDataFactory.createBillingAccount('wireless', acct);

        Billing_Account__c updatedBillingAccount = [SELECT ID, External_Id__c FROM Billing_Account__c WHERE Id=:billAcc.Id LIMIT 1];

        System.assert(updatedBillingAccount.External_Id__c!=null);

        updatedBillingAccount.External_Id__c = '';
        update updatedBillingAccount;

        updatedBillingAccount = [SELECT ID, External_Id__c FROM Billing_Account__c WHERE Id=:billAcc.Id LIMIT 1];

        System.assert(updatedBillingAccount.External_Id__c!=null);

        Test.stopTest();

    }

}