/*
    Unit test coverage for BWC_PaymentDetailsController.
*/
@isTest
public with sharing class BWC_PaymentDetailsController_Test {

    @isTest
    private static void test_getPaymentDetails() {

        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('L1', 'PASSCODE');

        // Call method using continuation
        System.Continuation continuation =
            (System.Continuation)BWC_PaymentDetailsController.getPaymentDetailsCont(interaction.Id, null, new List<String>{'paymentRecommendations'});
        
        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_PaymentDetailsCallout.API_PAYMENT_DETAILS, 'UT_GetPaymentDetails_Master');

        // Get continuation response
        String responseJson = BWC_PaymentDetailsController.getPaymentDetailsResp(null, BWC_Callout.lastContinuationState);

        // Verify
        BWC_PaymentDetails.PaymentDetailsResponses response =
            (BWC_PaymentDetails.PaymentDetailsResponses)JSON.deserialize(responseJson, BWC_PaymentDetails.PaymentDetailsResponses.class);

        // Set mock so synchronous response is returned
        BWC_ApiMock.setTestApiMock(BWC_PaymentDetailsCallout.API_PAYMENT_DETAILS, 'UT_GetPaymentDetails_Master');
        responseJson = (String)BWC_PaymentDetailsController.getPaymentDetailsCont(interaction.Id, null, new List<String>{'paymentRecommendations'});
        response =
            (BWC_PaymentDetails.PaymentDetailsResponses)JSON.deserialize(responseJson, BWC_PaymentDetails.PaymentDetailsResponses.class);

    }

}