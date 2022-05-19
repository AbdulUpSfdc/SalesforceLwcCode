/*
    Test coverage for BWC_CustomerProfileXXX classes
*/
@isTest
public with sharing class BWC_CustomerProfile_Test {

    @isTest
    private static void test_resetPassword() {

        BWC_Utils.setStaticResourceMock('BWC_CustomerProfileMock_resetPassword', 200);

        Test.startTest();

        BWC_CustomerProfile.PasswordResetRequest request = new BWC_CustomerProfile.PasswordResetRequest();
        String responseWrapperJson = BWC_CustomerProfileController.resetPassword(JSON.serialize(request));

        Test.stopTest();

        BWC_CustomerProfileController.ResetPasswordResponseWrapper responseWrapper = 
            (BWC_CustomerProfileController.ResetPasswordResponseWrapper)JSON.deserialize(responseWrapperJson, BWC_CustomerProfileController.ResetPasswordResponseWrapper.class);

        System.assertEquals(true, responseWrapper.success, responseWrapperJson);
        System.assertNotEquals(null, responseWrapper.response);

    }

    @isTest
    private static void test_resetPassword_negative() {

        BWC_Utils.setStaticResourceMock('BWC_Mock_NotJson', 200);

        BWC_CustomerProfile.PasswordResetRequest request = new BWC_CustomerProfile.PasswordResetRequest();

        Test.startTest();

        // Non-json response
        String responseWrapperJson = BWC_CustomerProfileController.resetPassword(JSON.serialize(request));
        BWC_CustomerProfileController.ResetPasswordResponseWrapper responseWrapper = 
            (BWC_CustomerProfileController.ResetPasswordResponseWrapper)JSON.deserialize(responseWrapperJson, BWC_CustomerProfileController.ResetPasswordResponseWrapper.class);
        System.assertEquals(false, responseWrapper.success);
        System.assertEquals(null, responseWrapper.response);
        
        // Missing request
        try {
            responseWrapperJson = BWC_CustomerProfileController.resetPassword(null);
            System.assert(false, 'Expected exception not thrown.');
        }
        catch (BWC_Exception e) {
            System.assert(true);
        }

    }

}