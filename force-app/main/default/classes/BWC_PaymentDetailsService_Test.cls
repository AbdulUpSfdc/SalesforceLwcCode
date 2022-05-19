/*
    Unit test coverage for BWC_PaymentDetailsService.
*/
@isTest
public with sharing class BWC_PaymentDetailsService_Test {

    @isTest
    private static void test_getPaymentDetails() {

        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('L1', 'PASSCODE');

        // Set mock response
        BWC_ApiMock.setTestApiMock(BWC_PaymentDetailsCallout.API_PAYMENT_DETAILS, 'UT_GetPaymentDetails_Master');

        List<BWC_PaymentDetails.PaymentDetailsResponse> response = BWC_PaymentDetailsService.getPaymentDetails(interaction.Id, null, new List<String>{'paymentRecommendations'});

    }

}