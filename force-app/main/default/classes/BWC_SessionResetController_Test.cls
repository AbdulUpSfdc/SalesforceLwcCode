/*
    Unit test coverage for BWC_InteractionCustomerSearchController.
*/
@isTest
public with sharing class BWC_SessionResetController_Test {
    @isTest
    private static void test_getTabsToClose() {
        Account acct = BWC_TestDataFactory.createAccount();
        String recType = BWC_Constants.BillingAccount_AccountType_Wireless;
        Billing_Account__c biilAcctObj = BWC_TestDataFactory.createBillingAccount(recType, acct);
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(acct);

        BWC_SessionResetController.TabInfo tabInfo = new BWC_SessionResetController.TabInfo();
        tabInfo.tabId = 't123';
        tabInfo.pageReference = new BWC_SessionResetController.PageReference();
        tabInfo.pageReference.type = 'standard__recordPage';
        tabInfo.pageReference.attributes = new BWC_SessionResetController.PageReferenceAttributes();
        tabInfo.pageReference.attributes.actionName = 'View';
        tabInfo.pageReference.attributes.objectApiName = 'Interaction__c';
        tabInfo.pageReference.attributes.recordId = interaction.Id;

        Test.startTest();
        String result = BWC_SessionResetController.getTabsToClose(JSON.serialize(
            new List<BWC_SessionResetController.TabInfo> {tabInfo}));
        Test.stopTest();
    }
}