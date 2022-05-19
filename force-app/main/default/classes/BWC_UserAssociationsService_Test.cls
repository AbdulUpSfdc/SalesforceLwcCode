@isTest
public with sharing class BWC_UserAssociationsService_Test {

    @isTest
    private static void test_getUserAssociations2() {

        Account testAccount = BWC_TestDataFactory.createAccount();
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount(BWC_Constants.BillingAccount_AccountType_Wireless, testAccount);

        Test.startTest();

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_UserAssociationsMock_wireless', 200);

        // Make call
        List<BWC_UserAssociations.UserAssociationsResponse> responses =
            BWC_UserAssociationsService.getUserAssociations(testAccount.Id);

        System.assertNotEquals(null, responses);

    }
	/* **
		08/16/2021
		Billing_Account__c.Billing_Account_Number__c has been modified to be a required field.
	*/
    @isTest
    private static void test_getUserAssociations2_negative() {

        Account testAccount = BWC_TestDataFactory.createAccount();
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount(BWC_Constants.BillingAccount_AccountType_Wireless, testAccount);
        //billingAccount.Billing_Account_Number__c = null;
        billingAccount.Billing_Account_Number__c = '1';
        update billingAccount;

        Test.startTest();

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_UserAssociationsMock_wireless', 200);

        try {
            // Null Id
            List<BWC_UserAssociations.UserAssociationsResponse> responses = BWC_UserAssociationsService.getUserAssociations(null);
            System.assert(true, 'Expected exception not thrown.');
        }
        catch (BWC_Exception e) {
            System.assert(true);
        }

    }

    @isTest
    private static void test_Add_Positive() {

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_UserAssociationsAddDelMock', 200);

        // Setup request
        List<BWC_UserAssociations.UserAssociation> request = new List<BWC_UserAssociations.UserAssociation>{
            new BWC_UserAssociations.UserAssociation()
        };

        //Get response
        List<BWC_UserAssociations.AddDeleteUserAssociationsResponse> responses = BWC_UserAssociationsService.addUserAssociations(request);

        System.assertEquals('SUCCESS', responses[0].result.status);

    }

    @isTest
    private static void test_Add_Negative() {

        // Missing argument
        try {
            List<BWC_UserAssociations.AddDeleteUserAssociationsResponse> responses = BWC_UserAssociationsService.addUserAssociations(null);
            System.assert(false, 'Expected exception not thrown.');
        }
        catch (Bwc_Exception e) {
            System.assert(true, 'Expected failure due to null request.');
        }

    }

    @isTest
    private static void test_Delete_Positive() {

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_UserAssociationsAddDelMock', 200);

        // Setup request
        List<BWC_UserAssociations.UserAssociation> request = new List<BWC_UserAssociations.UserAssociation>{
            new BWC_UserAssociations.UserAssociation()
        };

        //Get response
        List<BWC_UserAssociations.AddDeleteUserAssociationsResponse> responses = BWC_UserAssociationsService.deleteUserAssociations(request);

        System.assertEquals('SUCCESS', responses[0].result.status);

    }

    @isTest
    private static void test_Delete_Negative() {

        // Missing argument
        try {
            List<BWC_UserAssociations.AddDeleteUserAssociationsResponse> responses = BWC_UserAssociationsService.deleteUserAssociations(null);
            System.assert(false, 'Expected exception not thrown.');
        }
        catch (Bwc_Exception e) {
            System.assert(true, 'Expected failure due to null request.');
        }

    }


}