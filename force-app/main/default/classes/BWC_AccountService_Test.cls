/*
    Unit test coverage for BWC_AccountService.
*/
@isTest
public with sharing class BWC_AccountService_Test {

    @isTest
    private static void test_getBillingAccounts() {

        Account testAccount = BWC_TestDataFactory.createAccount();
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount(BWC_Constants.BillingAccount_AccountType_Wireless, testAccount);
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(testAccount);

        Test.startTest();

        // Required ID
        String billingAccountsJson = BWC_AccountServiceController.getBillingAccounts(null, false, false, null, null, false);
        BWC_AccountServiceController.BillingAccountsResponseWrapper response =
            ( BWC_AccountServiceController.BillingAccountsResponseWrapper)JSON.deserialize(billingAccountsJson, BWC_AccountServiceController.BillingAccountsResponseWrapper.class);
        System.assertEquals(false, response.success);

        billingAccountsJson = BWC_AccountServiceController.getBillingAccounts(testAccount.Id, false, false, null, null, false);
        response = (BWC_AccountServiceController.BillingAccountsResponseWrapper)JSON.deserialize(billingAccountsJson, BWC_AccountServiceController.BillingAccountsResponseWrapper.class);
        System.assertEquals(true, response.success);
        System.assertEquals(1, response.billingAccounts.size());

        billingAccountsJson = BWC_AccountServiceController.getBillingAccounts(interaction.Id, false, false, null, null, false);
        response = (BWC_AccountServiceController.BillingAccountsResponseWrapper)JSON.deserialize(billingAccountsJson, BWC_AccountServiceController.BillingAccountsResponseWrapper.class);
        System.assertEquals(true, response.success);
        System.assertEquals(1, response.billingAccounts.size());

        billingAccountsJson = BWC_AccountServiceController.getBillingAccounts(interaction.Id, true, false, null, null, false);
        response = (BWC_AccountServiceController.BillingAccountsResponseWrapper)JSON.deserialize(billingAccountsJson, BWC_AccountServiceController.BillingAccountsResponseWrapper.class);
        System.assertEquals(true, response.success);
        System.assertEquals(0, response.billingAccounts.size());

        billingAccountsJson = BWC_AccountServiceController.getBillingAccounts(billingAccount.Id, true, false, null, null, false);
        response = (BWC_AccountServiceController.BillingAccountsResponseWrapper)JSON.deserialize(billingAccountsJson, BWC_AccountServiceController.BillingAccountsResponseWrapper.class);
        System.assertEquals(false, response.success);
        
        billingAccount.Is_Unified__c = true;
        billingAccount.Unified_BAN__c = '423432423';
        update billingAccount;
        billingAccountsJson = BWC_AccountServiceController.getBillingAccounts(interaction.Id, false, true, null, null, false);
        response = (BWC_AccountServiceController.BillingAccountsResponseWrapper)JSON.deserialize(billingAccountsJson, BWC_AccountServiceController.BillingAccountsResponseWrapper.class);
        System.assertEquals(true, response.success);
        System.assertEquals(0, response.billingAccounts.size());


        interaction.Is_Authorized__c = true;
        interaction.Authorization_Json__c = '{"associatedAccounts": [{"accountType": "UVERSE", "accountBan": "423432423", "authorizationLevel": "L1"}, {"accountType": "WIRELESS", "accountBan": "232083293", "authorizationLevel": "L0"}]}';
        update interaction;
        billingAccountsJson = BWC_AccountServiceController.getBillingAccounts(interaction.Id, true, false, null, null, false);
        response = (BWC_AccountServiceController.BillingAccountsResponseWrapper)JSON.deserialize(billingAccountsJson, BWC_AccountServiceController.BillingAccountsResponseWrapper.class);
        System.assertEquals(true, response.success);
        System.assertEquals(1, response.billingAccounts.size());

        interaction.Customer__c = null;
        update interaction;
        billingAccountsJson = BWC_AccountServiceController.getBillingAccounts(interaction.Id, true, false, null, null, false);
        response = (BWC_AccountServiceController.BillingAccountsResponseWrapper)JSON.deserialize(billingAccountsJson, BWC_AccountServiceController.BillingAccountsResponseWrapper.class);
        System.assertEquals(false, response.success);
    }

    @isTest
    private static void test_getBillingAccountForBan() {

        Account testAccount = BWC_TestDataFactory.createAccount();
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount(BWC_Constants.BillingAccount_AccountType_Wireless, testAccount);

        Test.startTest();

        String responseWrapperJson = BWC_AccountServiceController.getBillingAccountForBan('423432423');
        BWC_AccountServiceController.BillingAccountsResponseWrapper responseWrapper = (BWC_AccountServiceController.BillingAccountsResponseWrapper)JSON.deserialize(responseWrapperJson, BWC_AccountServiceController.BillingAccountsResponseWrapper.class);

        System.assertEquals(true, responseWrapper.success);

    }

    @isTest
    private static void test_getBillingAccountForBan_Negative() {

        Account testAccount = BWC_TestDataFactory.createAccount();
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount(BWC_Constants.BillingAccount_AccountType_Wireless, testAccount);

        Test.startTest();

        String responseWrapperJson = BWC_AccountServiceController.getBillingAccountForBan('nonexistent');
        BWC_AccountServiceController.BillingAccountsResponseWrapper responseWrapper = (BWC_AccountServiceController.BillingAccountsResponseWrapper)JSON.deserialize(responseWrapperJson, BWC_AccountServiceController.BillingAccountsResponseWrapper.class);

        System.assertEquals(false, responseWrapper.success);

    }

    @isTest
    private static void test_getBillingAccountForId() {

        Account testAccount = BWC_TestDataFactory.createAccount();
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount(BWC_Constants.BillingAccount_AccountType_Wireless, testAccount);

        Test.startTest();

        String responseWrapperJson = BWC_AccountServiceController.getBillingAccountForId(billingAccount.Id);
        BWC_AccountServiceController.BillingAccountsResponseWrapper responseWrapper = (BWC_AccountServiceController.BillingAccountsResponseWrapper)JSON.deserialize(responseWrapperJson, BWC_AccountServiceController.BillingAccountsResponseWrapper.class);

        System.assertEquals(true, responseWrapper.success);

    }

    @isTest
    private static void test_getBillingAccountForId_Negative() {

        Account testAccount = BWC_TestDataFactory.createAccount();
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount(BWC_Constants.BillingAccount_AccountType_Wireless, testAccount);

        Test.startTest();

        String responseWrapperJson = BWC_AccountServiceController.getBillingAccountForId(testAccount.Id);
        BWC_AccountServiceController.BillingAccountsResponseWrapper responseWrapper = (BWC_AccountServiceController.BillingAccountsResponseWrapper)JSON.deserialize(responseWrapperJson, BWC_AccountServiceController.BillingAccountsResponseWrapper.class);

        System.assertEquals(false, responseWrapper.success);

    }

    @isTest
    private static void test_getInteractionBillingAccount() {

        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('L1', 'PASSCODE');

        Account testAccount = BWC_TestDataFactory.createAccount();
        Billing_Account__c billingAccountNonL1 = BWC_TestDataFactory.createBillingAccount('', testAccount);
        Interaction__c interactionNonL1 = BWC_TestDataFactory.createInteraction(testAccount);

        Test.startTest();

        // Positive
        String billingAccountJson = BWC_AccountServiceController.getInteractionBillingAccount(interaction.Id, interaction.Billing_Account__c);
        Billing_Account__c billingAccount = (Billing_Account__c)JSON.deserialize(billingAccountJson, Billing_Account__c.class);
        System.assertEquals(interaction.Billing_Account__c, billingAccount.Id);

        // Billing account not found
        try {
            // Wrong interaction...
            billingAccountJson = BWC_AccountServiceController.getInteractionBillingAccount(interactionNonL1.Id, interaction.Billing_Account__c);         
            System.assert(false, 'Exception not thrown');
        }
        catch (BWC_Exception e) {
            System.assertEquals(BWC_AccountService.EXCEPTION_BILLING_ACCOUNT_NOT_FOUND, e.code);
        }

        // Not L1
        try {
            billingAccountJson = BWC_AccountServiceController.getInteractionBillingAccount(interactionNonL1.Id, billingAccountNonL1.Id);         
            System.assert(false, 'Exception not thrown');
        }
        catch (BWC_Exception e) {
            System.assertEquals(BWC_AccountService.EXCEPTION_NOT_AUTHORIZED, e.code);
        }

    }

    @IsTest
    private static void test_getSortedBillingAccounts(){

        Test.startTest();

        Account testAccount = BWC_TestDataFactory.createAccount();
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount(BWC_Constants.BillingAccount_AccountType_Wireless, testAccount);
        Billing_Account__c billingAccount1 = BWC_TestDataFactory.createBillingAccount(BWC_Constants.BillingAccount_AccountType_Internet, testAccount);
        Billing_Account__c billingAccount2 = BWC_TestDataFactory.createBillingAccount(BWC_Constants.BillingAccount_AccountType_DirecTV, testAccount);
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(testAccount);

        String responseJson = BWC_AccountServiceController.getSortedBillingAccounts(interaction.Id, null, null, null, null, true, 'Broadband_Agent');
        BWC_AccountServiceController.BillingAccountsResponseWrapper response = (BWC_AccountServiceController.BillingAccountsResponseWrapper) JSON.deserialize(responseJson, BWC_AccountServiceController.BillingAccountsResponseWrapper.class);
        List<Billing_Account__c> billingAccounts = response.billingAccounts;

        System.assertEquals('wireless', billingAccounts.get(0).Account_Type__c, 'Billing account is not in the correct order');

        responseJson = BWC_AccountServiceController.getSortedBillingAccounts(null, null, null, null, null, true, 'Broadband_Agent');

        Test.stopTest();

    }

    @IsTest
    private static void test_getCustomerAccount(){

        Test.startTest();

        Account testAccount = BWC_TestDataFactory.createBSSeAccount();
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount(BWC_Constants.BillingAccount_AccountType_Wireless, testAccount);
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(testAccount);

        String responseJson = BWC_AccountServiceController.getCustomerAccount(interaction.Id);
        Account response = (Account) JSON.deserialize(responseJson, Account.class);

        System.assertEquals('eb407049-c555-46fa-9bf2-010bcfa6333a', response.Individual_ID__c);

        Test.stopTest();

    }

    @IsTest
    private static void test_getCustomerAccount_error(){

        Test.startTest();

        Account testAccount = BWC_TestDataFactory.createBSSeAccount();
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount(BWC_Constants.BillingAccount_AccountType_Wireless, testAccount);
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(testAccount);

        interaction.Customer__c = null;
        update interaction;

        try {
            String responseJson = BWC_AccountServiceController.getCustomerAccount(interaction.Id);   
            Account response = (Account) JSON.deserialize(responseJson, Account.class);
            System.assert(false);
        } catch (BWC_Exception e) {
            System.assert(true);
        }

        try {
            String responseJson = BWC_AccountServiceController.getCustomerAccount(null);   
            Account response = (Account) JSON.deserialize(responseJson, Account.class);
            System.assert(false);
        } catch (BWC_Exception e) {
            System.assert(true);
        }

        Test.stopTest();

    }
}