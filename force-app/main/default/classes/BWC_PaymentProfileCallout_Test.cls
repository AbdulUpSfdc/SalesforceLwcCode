/*
    Unit test coverage for BWC_PaymentProfileCallout.
*/
@isTest
public with sharing class BWC_PaymentProfileCallout_Test {

    @isTest
    private static void testPaymentProfile_add() {

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_AddPaymentResponseMock', 201);
        
        // Setup request
        BWC_PaymentProfile.PaymentProfile profile = new BWC_PaymentProfile.PaymentProfile();

        //Add
        BWC_PaymentProfile.PaymentProfileResponse response = BWC_PaymentProfileCallout.postPaymentProfile(profile, BWC_PaymentProfile.MODE_ADD);
        System.assertNotEquals(null, response);

    }

    @isTest
    private static void testPaymentProfile_update() {

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_AddPaymentResponseMock', 201);
        
        // Setup request
        BWC_PaymentProfile.PaymentProfile profile = new BWC_PaymentProfile.PaymentProfile();

        //Update
        BWC_PaymentProfile.PaymentProfileResponse response = BWC_PaymentProfileCallout.postPaymentProfile(profile, BWC_PaymentProfile.MODE_UPDATE);
        System.assertNotEquals(null, response);

    }

    @isTest
    private static void testPaymentProfile_delete() {

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_AddPaymentResponseMock', 201);
        
        // Setup request
        BWC_PaymentProfile.PaymentProfile profile = new BWC_PaymentProfile.PaymentProfile();

        //Delete
        BWC_PaymentProfile.PaymentProfileResponse response = BWC_PaymentProfileCallout.postPaymentProfile(profile, BWC_PaymentProfile.MODE_DELETE);
        System.assertNotEquals(null, response);        

    }

    @isTest
    private static void testPaymentProfile_Negative() {

        // Setup request
        BWC_PaymentProfile.PaymentProfile profile = new BWC_PaymentProfile.PaymentProfile();        

        // Missing arguments
        try {
            BWC_PaymentProfile.PaymentProfileResponse response = BWC_PaymentProfileCallout.postPaymentProfile(null, BWC_PaymentProfile.MODE_ADD);
            System.assert(false, 'Expected exception not thrown.');
        }
        catch (BWC_Exception e){
            System.assert(true);
        }
        try {
            BWC_PaymentProfile.PaymentProfileResponse response = BWC_PaymentProfileCallout.postPaymentProfile(profile, null);
            System.assert(false, 'Expected exception not thrown.');
        }
        catch (BWC_Exception e){
            System.assert(true);
        }

        // Unknown mode
        try {
            BWC_PaymentProfile.PaymentProfileResponse response = BWC_PaymentProfileCallout.postPaymentProfile(profile, 'bogus');
            System.assert(false, 'Expected exception not thrown.');
        }
        catch (BWC_Exception e){
            System.assert(true);
        }

        // Bad JSON
        BWC_Utils.setStaticResourceMock('BWC_Mock_NotJson', 201);
        try {
            BWC_PaymentProfile.PaymentProfileResponse response = BWC_PaymentProfileCallout.postPaymentProfile(profile, BWC_PaymentProfile.MODE_ADD);
            System.assert(false, 'Expected exception not thrown.');
        }
        catch (BWC_Exception e) {

            // Cause should be JSON exception
            System.assert(e.getCause() instanceOf System.JSONException);

        }

    }

}