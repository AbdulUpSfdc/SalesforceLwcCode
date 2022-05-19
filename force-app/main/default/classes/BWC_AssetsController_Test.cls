/*
    Test Methods for Assets Controller
*/
@isTest
public with sharing class BWC_AssetsController_Test {
  
    @isTest
    private static void test_getAssetsForBillingAccounts() {

        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('L1', 'PASSCODE');
        String recordType = BWC_Constants.BillingAccount_AccountType_Wireless;
        Plan__c plan = BWC_TestDataFactory.createPlan(
            recordType,
            new Billing_Account__c(Id=interaction.Billing_Account__c)
        );
        Asset equipment = BWC_TestDataFactory.createEquipment(
            recordType,
            new Account(Id=interaction.Customer__c),
            new Billing_Account__c(Id=interaction.Billing_Account__c),
            plan
        );

        Set<Id> requests = new Set<Id>();
        requests.add(interaction.Billing_Account__c);

        BWC_AssetsController.getAssetsForBillingAccounts(
            JSON.serialize(requests)
        );
    }

    @isTest
    private static void test_getAssetsForBillingAccountsNullRequest() {
        
        try {

            BWC_AssetsController.getAssetsForBillingAccounts(null);

        } catch(Exception e) {

            System.assert(e != null, 'Failed to catch bad input.');
            
        }
    }

}