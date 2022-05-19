/*
    Unit test coverage for BWC_PaymentProfileController.
*/
@isTest
public with sharing class BWC_PaymentProfileController_Test {

    @isTest
    private static void test_postPaymentProfile() {

        Account testAccount = BWC_TestDataFactory.createAccount();
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount(BWC_Constants.BillingAccount_AccountType_Wireless, testAccount);

        Test.startTest();

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_AddPaymentResponseMock', 200);

        // Setup request
        BWC_PaymentProfile.PaymentProfile profile = new BWC_PaymentProfile.PaymentProfile();
        String reqJSON = JSON.serialize(profile);

        // Make call
        String response = BWC_PaymentProfileController.postPaymentProfile(reqJSON, BWC_PaymentProfile.MODE_ADD);

        System.assertNotEquals(null, response);

    }

    @isTest
    private static void test_postPaymentProfile_Negative() {

        Test.startTest();

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_Mock_NotJson', 200);

        String responseJson = BWC_PaymentProfileController.postPaymentProfile('junk', BWC_PaymentProfile.MODE_ADD);
        BWC_PaymentProfileController.PaymentProfileResponseWrapper response =
            (BWC_PaymentProfileController.PaymentProfileResponseWrapper)JSON.deserialize(responseJson, BWC_PaymentProfileController.PaymentProfileResponseWrapper.class);
        System.assertEquals(false, response.success);
        
    }

}