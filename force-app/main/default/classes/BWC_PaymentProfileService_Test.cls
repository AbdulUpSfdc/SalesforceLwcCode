/*
    Unit test coverage for BWC_PaymentProfileService.
*/
@isTest
public with sharing class BWC_PaymentProfileService_Test {

    @isTest
    private static void test_postPaymentProfile() {

        Account testAccount = BWC_TestDataFactory.createAccount();
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount(BWC_Constants.BillingAccount_AccountType_Wireless, testAccount);

        Test.startTest();

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_AddPaymentResponseMock', 200);

        // Setup profile
        BWC_PaymentProfile.PaymentProfile profile = new BWC_PaymentProfile.PaymentProfile();

        // Make call
        BWC_PaymentProfile.PaymentProfileResponse response = BWC_PaymentProfileService.postPaymentProfile(profile, BWC_PaymentProfile.MODE_ADD);

        System.assertNotEquals(null, response);

    }

}