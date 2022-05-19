/*
    Unit test coverage for BWC_InteractionCustomerSearchController.
*/
@isTest
public with sharing class BWC_InteractionCustomerSearchCntrl_Test {
    @isTest
    private static void test_linkInteractionAndPersonAccount() {
        Account acct = BWC_TestDataFactory.createAccount();
        String recType = BWC_Constants.BillingAccount_AccountType_Wireless;
        Billing_Account__c biilAcctObj = BWC_TestDataFactory.createBillingAccount(recType, acct);
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(acct);

        Test.startTest();
        BWC_InteractionCustomerSearchController.resetInteraction(interaction.Id);
        BWC_InteractionCustomerSearchController.ResultWrapper result1 = BWC_InteractionCustomerSearchController.linkInteractionAndPersonAccount(interaction.Id, acct.Id);
        BWC_InteractionCustomerSearchController.ResultWrapper result2 = BWC_InteractionCustomerSearchController.linkInteractionAndPersonAccount(interaction.Id, biilAcctObj.Id);
        BWC_InteractionCustomerSearchController.ResultWrapper result3 = BWC_InteractionCustomerSearchController.linkInteractionAndPersonAccount(biilAcctObj.Id, biilAcctObj.Id);
        System.assertEquals(true, result1.success);
        System.assertEquals(false, result2.success);
        System.assertEquals(false, result3.success);
        Test.stopTest();
    }
}