/*
    Unit test coverage for BWC_MakePaymentService.
*/
@isTest
public with sharing class BWC_MakePaymentService_Test {

    @isTest
    private static void test_makePayment(){

        // Setup request
        BWC_MakePayment.MakePaymentRequest mpr = BWC_TestDataFactory.createMakePaymentRequest();

        Test.startTest();

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_PaymentMock', 200);

        // Make call
        BWC_MakePayment.MakePaymentResponse response =
            BWC_MakePaymentService.makePayment(mpr);

        Test.stopTest();

        System.assertNotEquals(null, response);
    }

    @isTest
    private static void test_makePayment_NoFixedValues(){

        // Setup request
        BWC_MakePayment.MakePaymentRequest mpr = BWC_TestDataFactory.createMakePaymentRequest();
        mpr.locationId = '';
        mpr.sourceBusinessUnit = '';
        mpr.customerAgreement = '';
        mpr.appName = '';
        mpr.sourceSystem = '';
        mpr.sourceLocation = '';
        mpr.sourceUser = '';


        Test.startTest();

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_PaymentMock', 200);

        // Make call
        BWC_MakePayment.MakePaymentResponse response =
            BWC_MakePaymentService.makePayment(mpr);

        Test.stopTest();

        System.assertNotEquals(null, response);
    }

    @isTest
    private static void test_updatePayment(){

        // Setup request
        BWC_MakePayment.UpdatePaymentRequest upr = BWC_TestDataFactory.createUpdatePaymentRequest();

        Test.startTest();

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_UpdatePaymentMock', 200);

        // Make call
        BWC_MakePayment.UpdatePaymentResponse response =
            BWC_MakePaymentService.updatePayment(upr);

        Test.stopTest();

        System.assertNotEquals(null, response);
    }

    @isTest
    private static void test_updatePayment_NoFixedValues(){

        // Setup request
        BWC_MakePayment.UpdatePaymentRequest upr = BWC_TestDataFactory.createUpdatePaymentRequest();
        upr.locationId = '';
        upr.sourceBusinessUnit = '';
        upr.customerAgreement = '';
        upr.appName = '';
        upr.sourceSystem = '';
        upr.sourceLocation = '';
        upr.sourceUser = '';


        Test.startTest();

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_UpdatePaymentMock', 200);

        // Make call
        BWC_MakePayment.UpdatePaymentResponse response =
            BWC_MakePaymentService.updatePayment(upr);

        Test.stopTest();

        System.assertNotEquals(null, response);
    }

    @isTest
    private static void test_deletePayment(){

        // Setup request
        BWC_MakePayment.DeletePaymentRequest request = new BWC_MakePayment.DeletePaymentRequest();

        Test.startTest();

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_DeletePaymentMock', 200);

        // Make call
        BWC_MakePayment.DeletePaymentResponse response =
            BWC_MakePaymentService.deletePayment(request);

        Test.stopTest();

        System.assertNotEquals(null, response);
    }

}