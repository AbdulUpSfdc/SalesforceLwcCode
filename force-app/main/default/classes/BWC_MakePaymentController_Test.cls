/*
    Unit test coverage for BWC_MakePaymentController.
*/
@isTest
public with sharing class BWC_MakePaymentController_Test {

    @isTest
    private static void test_makePayment() {
        BWC_MakePayment.MakePaymentRequest mpr = BWC_TestDataFactory.createMakePaymentRequest();

        // Serialize
        String requestBody = JSON.serialize(mpr, true);

        Test.startTest();

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_PaymentMock', 200);

        // Make call
        String response =
            BWC_MakePaymentController.makePayment(requestBody);

        Test.stopTest();

        System.assertNotEquals(null, response);

    }
    
    @isTest
    private static void test_makePaymentRaisr() {
        BWC_MakePayment.MakePaymentRequest mpr = BWC_TestDataFactory.createMakePaymentRequest();
        String spiDataJson = '[{ "spiDataList": [ { "name": "bankAccountNumber", "token": "1234-6543-7894-78945" }, { "name": "routingNumber", "value": "123456" }, { "name": "cardNumber", "token": "1234-6543-7894-78941" } ] }]';

        // Serialize
        String requestBody = JSON.serialize(mpr, true);

        Test.startTest();

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_PaymentMock', 200);

        // Make call
        String response =
            BWC_MakePaymentController.makePaymentRaisr(requestBody, spiDataJson);

        Test.stopTest();

        System.assertNotEquals(null, response);

    }

    @isTest
    private static void test_makePayment_Negative() {
        BWC_MakePayment.MakePaymentRequest mpr = BWC_TestDataFactory.createMakePaymentRequest();

        // Serialize
        String requestBody = JSON.serialize(mpr, true);

        Test.startTest();

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_PaymentMock', 400);

        // Make call
        String response =
            BWC_MakePaymentController.makePayment(null);

        Test.stopTest();

        System.assertNotEquals(null, response);
    }


    @isTest
    private static void test_updatePayment() {
        BWC_MakePayment.UpdatePaymentRequest upr = BWC_TestDataFactory.createUpdatePaymentRequest();

        // Serialize
        String requestBody = JSON.serialize(upr, true);

        Test.startTest();

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_UpdatePaymentMock', 200);

        // Make call
        String response =
            BWC_MakePaymentController.updatePayment(requestBody);

        Test.stopTest();

        System.assertNotEquals(null, response);

    }

    @isTest
    private static void test_updatePaymentRaisr() {
        BWC_MakePayment.UpdatePaymentRequest upr = BWC_TestDataFactory.createUpdatePaymentRequest();
        String spiDataJson = '[{ "spiDataList": [ { "name": "bankAccountNumber", "token": "1234-6543-7894-78945" }, { "name": "routingNumber", "value": "123456" }, { "name": "cardNumber", "token": "1234-6543-7894-78941" } ] }]';

        // Serialize
        String requestBody = JSON.serialize(upr, true);

        Test.startTest();

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_UpdatePaymentMock', 200);

        // Make call
        String response =
            BWC_MakePaymentController.updatePaymentRaisr(requestBody, spiDataJson);

        Test.stopTest();

        System.assertNotEquals(null, response);

    }

    @isTest
    private static void test_updatePayment_Negative() {
        BWC_MakePayment.UpdatePaymentRequest upr = BWC_TestDataFactory.createUpdatePaymentRequest();

        // Serialize
        String requestBody = JSON.serialize(upr, true);

        Test.startTest();

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_UpdatePaymentMock', 400);

        // Make call
        String response =
            BWC_MakePaymentController.updatePayment(null);

        Test.stopTest();

        System.assertNotEquals(null, response);
    }

    @isTest
    private static void test_deletePayment() {
        BWC_MakePayment.DeletePaymentRequest request = new BWC_MakePayment.DeletePaymentRequest();

        // Serialize
        String requestBody = JSON.serialize(request, true);

        Test.startTest();

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_DeletePaymentMock', 200);

        // Make call
        String response =
            BWC_MakePaymentController.deletePayment(requestBody);

        Test.stopTest();

        System.assertNotEquals(null, response);

    }

    @isTest
    private static void test_deletePayment_Negative() {
        BWC_MakePayment.DeletePaymentRequest request = new BWC_MakePayment.DeletePaymentRequest();

        // Serialize
        String requestBody = JSON.serialize(request, true);

        Test.startTest();

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_DeletePaymentMock', 400);

        // Make call
        String response =
            BWC_MakePaymentController.deletePayment(null);

        Test.stopTest();

        System.assertNotEquals(null, response);
    }

    @isTest
    private static void test_epaEnroll() {

        BWC_MakePayment.EpaEnrollRequest request = new BWC_MakePayment.EpaEnrollRequest();
        request.makePaymentItemRequest = new BWC_MakePayment.PaymentItemRequest();
        request.makePaymentItemRequest.paymentMethod = new BWC_MakePayment.PaymentMethod();
        request.makePaymentItemRequest.paymentMethod.card = new BWC_MakePayment.Card();
        String requestBody = JSON.serialize(request, true);

        Test.startTest();

        BWC_ApiMock.setTestApiMock(BWC_Constants.API_EPA_ENROLL, 'UT_EPA_Enroll_Success');

        String response = BWC_MakePaymentController.epaEnroll(requestBody);

        Test.stopTest();

        BWC_MakePaymentController.EpaEnrollResponseWrapper responseWrapper = 
            (BWC_MakePaymentController.EpaEnrollResponseWrapper)JSON.deserialize(response, BWC_MakePaymentController.EpaEnrollResponseWrapper.class);
        System.assertEquals(true, responseWrapper.success);
        
    }

    @isTest
    private static void test_epaEnrollRaisr() {
        
        BWC_MakePayment.EpaEnrollRequest request = new BWC_MakePayment.EpaEnrollRequest();
        request.makePaymentItemRequest = new BWC_MakePayment.PaymentItemRequest();
        request.makePaymentItemRequest.paymentMethod = new BWC_MakePayment.PaymentMethod();
        request.makePaymentItemRequest.paymentMethod.card = new BWC_MakePayment.Card();
        String requestBody = JSON.serialize(request, true);

        String spiDataJson = '{ "spiDataList": [ { "name": "bankAccountNumber", "token": "1234-6543-7894-78945" }, { "name": "routingNumber", "value": "123456" }, { "name": "cardNumber", "token": "1234-6543-7894-78941" } ] }';

        Test.startTest();

        BWC_ApiMock.setTestApiMock(BWC_Constants.API_EPA_ENROLL, 'UT_EPA_Enroll_Success');

        String response = BWC_MakePaymentController.epaEnrollRaisr(requestBody, spiDataJson);

        Test.stopTest();

        BWC_MakePaymentController.EpaEnrollResponseWrapper responseWrapper = 
            (BWC_MakePaymentController.EpaEnrollResponseWrapper)JSON.deserialize(response, BWC_MakePaymentController.EpaEnrollResponseWrapper.class);
        System.assertEquals(true, responseWrapper.success);

    }

    @isTest
    private static void test_epaEnroll_ServerFailure() {

        BWC_MakePayment.EpaEnrollRequest request = new BWC_MakePayment.EpaEnrollRequest();
        String requestBody = JSON.serialize(request, true);

        Test.startTest();

        BWC_ApiMock.setTestApiMock(BWC_Constants.API_EPA_ENROLL, 'UT_EPA_Enroll_500');
        String response = BWC_MakePaymentController.epaEnroll(requestBody);

        BWC_MakePaymentController.EpaEnrollResponseWrapper responseWrapper = 
            (BWC_MakePaymentController.EpaEnrollResponseWrapper)JSON.deserialize(response, BWC_MakePaymentController.EpaEnrollResponseWrapper.class);
        System.assertEquals(false, responseWrapper.success);

    }

}