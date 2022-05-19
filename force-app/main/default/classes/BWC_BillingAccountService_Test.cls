@IsTest
public with sharing class BWC_BillingAccountService_Test {

    @TestSetup
    static void makeData(){
        Account acct = BWC_TestDataFactory.createAccount();
        Billing_Account__c billAcc = BWC_TestDataFactory.createBillingAccount('wireless', acct);
        Billing_Account__c billAcc2 = BWC_TestDataFactory.createBillingAccount('uverse', acct);
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(acct);
    }

    @IsTest
    static void getBillingAccountSummaryTest(){

        Test.startTest();


        Interaction__c interaction = [SELECT ID FROM Interaction__c LIMIT 1];
        List<Billing_Account__c> billAccs = [SELECT ID, Billing_Account_Number__c FROM Billing_Account__c LIMIT 2];

        BWC_AuthorizationCallout.AuthorizationStatusContent authorizationContent = new BWC_AuthorizationCallout.AuthorizationStatusContent();
        authorizationContent.associatedAccounts = new List<BWC_AuthorizationCallout.AssociatedAccount>();

        Boolean authLevelFlag = true;
        for(Billing_Account__c billAcc : billAccs){

            BWC_AuthorizationCallout.AssociatedAccount associatedAccount = new BWC_AuthorizationCallout.AssociatedAccount();
            associatedAccount.accountBan = billAcc.Billing_Account_Number__c;
            associatedAccount.authorizationLevel = authLevelFlag ? 'L1' : 'L0';
            associatedAccount.accountType = 'Wireless';

            authLevelFlag = !authLevelFlag;
            authorizationContent.associatedAccounts.add(associatedAccount);
        }


        interaction.Authorization_Json__c = JSON.serialize(authorizationContent, true);

        update interaction;

        List<Billing_Account__c> response = BWC_BillingAccountService.getBillingAccountSummary(interaction.Id);

        Test.stopTest();

    }
}