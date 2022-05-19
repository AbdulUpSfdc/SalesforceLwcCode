/*
    Unit test coverage for BWC_MakePaymentCallout.
*/
@isTest
public with sharing class BWC_MakePaymentCallout_Test {
    @isTest
    private static void test_makePayment() {

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_PaymentMock', 200);

        // Setup request
        BWC_MakePayment.MakePaymentRequest request = BWC_TestDataFactory.createMakePaymentRequest();

        //Get response
        BWC_MakePayment.MakePaymentResponse response = BWC_MakePaymentCallout.makePayment(request);

        System.assertNotEquals(null, response);

    }

    @isTest
    private static void test_makePayment_RequestNull() {

        //Get response
        try{
            BWC_MakePayment.MakePaymentResponse response = BWC_MakePaymentCallout.makePayment(null);
            System.assert(false, 'Expected exception not thrown.');
        }

        catch (BWC_Exception e) {
            System.assertEquals('Argument required: request', e.getMessage());
        }

    }

    @isTest
    private static void test_Negative_BadBody() {

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_Mock_NotJson', 200);

        // Setup request
        BWC_MakePayment.MakePaymentRequest request = BWC_TestDataFactory.createMakePaymentRequest();

        //Get response
        try {
            //Get response
            BWC_MakePayment.MakePaymentResponse response = BWC_MakePaymentCallout.makePayment(request);
            System.assert(false, 'Excpected exception not thrown.');
        }
        catch (BWC_Exception e) {

            // Cause should be JSON exception
            System.assert(e.getCause() instanceOf System.JSONException);

        }
    }

    @isTest
    private static void test_updatePayment() {

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_UpdatePaymentMock', 200);

        // Setup request
        BWC_MakePayment.UpdatePaymentRequest request = BWC_TestDataFactory.createUpdatePaymentRequest();

        //Get response
        BWC_MakePayment.UpdatePaymentResponse response = BWC_MakePaymentCallout.updatePayment(request);

        System.assertNotEquals(null, response);

    }

    @isTest
    private static void test_updatePayment_RequestNull() {

        //Get response
        try{
            BWC_MakePayment.UpdatePaymentResponse response = BWC_MakePaymentCallout.updatePayment(null);
            System.assert(false, 'Expected exception not thrown.');
        }

        catch (BWC_Exception e) {
            System.assertEquals('Argument required: request', e.getMessage());
        }

    }

    @isTest
    private static void test_NegativeUpdatePmt_BadBody() {

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_Mock_NotJson', 200);

        // Setup request
        BWC_MakePayment.UpdatePaymentRequest request = BWC_TestDataFactory.createUpdatePaymentRequest();

        //Get response
        try {
            //Get response
            BWC_MakePayment.UpdatePaymentResponse response = BWC_MakePaymentCallout.updatePayment(request);
            System.assert(false, 'Excpected exception not thrown.');
        }
        catch (BWC_Exception e) {

            // Cause should be JSON exception
            System.assert(e.getCause() instanceOf System.JSONException);

        }
    }

    @isTest
    private static void test_deletePayment() {

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_DeletePaymentMock', 200);

        // Setup request
        BWC_MakePayment.DeletePaymentRequest request = new BWC_MakePayment.DeletePaymentRequest();

        //Get response
        BWC_MakePayment.DeletePaymentResponse response = BWC_MakePaymentCallout.deletePayment(request);

        System.assertNotEquals(null, response);

    }

    @isTest
    private static void test_deletePayment_RequestNull() {

        //Get response
        try{
            BWC_MakePayment.DeletePaymentResponse response = BWC_MakePaymentCallout.deletePayment(null);
            System.assert(false, 'Expected exception not thrown.');
        }

        catch (BWC_Exception e) {
            System.assertEquals('Argument required: request', e.getMessage());
        }

    }

    @isTest
    private static void test_NegativeDeletePmt_BadBody() {

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_Mock_NotJson', 200);

        // Setup request
        BWC_MakePayment.DeletePaymentRequest request = new BWC_MakePayment.DeletePaymentRequest();

        //Get response
        try {
            //Get response
            BWC_MakePayment.DeletePaymentResponse response = BWC_MakePaymentCallout.deletePayment(request);
            System.assert(false, 'Excpected exception not thrown.');
        }
        catch (BWC_Exception e) {

            // Cause should be JSON exception
            System.assert(e.getCause() instanceOf System.JSONException);

        }
    }

}