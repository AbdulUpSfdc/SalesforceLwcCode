/*
    Unit test coverage for BWC_AuthorizationController.
    Also provides coverage for corresponding parts of BWC_AuthorizationService and BWC_AuthorizationCallout.
*/
@isTest
public with sharing class BWC_AuthorizationController_Test {
 
    private static Interaction__c getTestInteraction() {
        return BWC_TestDataFactory.createFullInteraction('STEPUPSONLY', 'NONE');
    }

    /*
        Test first call to authorization status, gets step-ups but will not be authorized.
    */
    @isTest
    private static void test_checkAuthorization_NotAuthenticated() {

        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('NONE', 'NONE');

        // Call method using continuation
        System.Continuation continuation =
            (System.Continuation)BWC_AuthorizationController.checkAuthorizationStatusCont(interaction.Id, null);
        
        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_AuthorizationCallout.API_AUTHORIZATION_STATUS, 'UT_Authorize_Status_StepUps_Success');

        // Get continuation response
        String responseJson = BWC_AuthorizationController.checkAuthorizationStatusResp(null, BWC_Callout.lastContinuationState);

        // Verify
        BWC_AuthorizationService.CheckAuthorizationStatusResponse response =
            (BWC_AuthorizationService.CheckAuthorizationStatusResponse)JSON.deserialize(responseJson, BWC_AuthorizationService.CheckAuthorizationStatusResponse.class);

        System.assertEquals(false, response.isAuthorized);

    }

    @isTest
    private static void test_checkAuthorization_RequestFailure() {

        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('NONE', 'NONE');
        interaction.CTI_Call_Identifier__c = null;
        update interaction;
        BWC_Controller.THROW_TEST_AURA_EXCEPTION = true;

        // Call method using continuation
        try {
            System.Continuation continuation = (System.Continuation)BWC_AuthorizationController.checkAuthorizationStatusCont(interaction.Id, null);
            System.assert(false, 'Exception not thrown.');
        }
        catch (AuraHandledException e) {
            System.assert(true);
        }

    }    

    @isTest
    private static void test_checkAuthorization_ServerFailure() {

        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('NONE', 'NONE');

        // Call method using continuation -- this part succeeds
        System.Continuation continuation =
            (System.Continuation)BWC_AuthorizationController.checkAuthorizationStatusCont(interaction.Id, null);
        
        // Set mock response to cause failure
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_AuthorizationCallout.API_AUTHORIZATION_STATUS, 'UT_Authorize_500');
        BWC_Controller.THROW_TEST_AURA_EXCEPTION = true;

        // Get continuation response
        try {
            String responseJson = BWC_AuthorizationController.checkAuthorizationStatusResp(null, BWC_Callout.lastContinuationState);
            System.assert(false, 'Exception not thrown.');
        }
        catch (AuraHandledException e) {
            System.assert(true);
        }

    }    

    /*
        Test authorized with passcode.
    */
    @isTest
    private static void test_checkAuthorization_PasscodeSuccess() {

        // Get interaction with step-ups and authenticated with passcode
        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('STEPUPSONLY', 'PASSCODE');

        // Call method using continuation
        System.Continuation continuation =
            (System.Continuation)BWC_AuthorizationController.checkAuthorizationStatusCont(interaction.Id, null);
        
        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_AuthorizationCallout.API_AUTHORIZATION_STATUS, 'UT_Authorize_Status_L1_Success');

        // Get continuation response
        String responseJson = BWC_AuthorizationController.checkAuthorizationStatusResp(null, BWC_Callout.lastContinuationState);

        // Verify
        BWC_AuthorizationService.CheckAuthorizationStatusResponse response =
            (BWC_AuthorizationService.CheckAuthorizationStatusResponse)JSON.deserialize(responseJson, BWC_AuthorizationService.CheckAuthorizationStatusResponse.class);

        // Should be authorized now
        System.assertEquals(true, response.isAuthorized);

        // NOT with OTP
        System.assertEquals(false, BWC_AuthorizationController.isAuthenticatedWithOtp(interaction.Id, interaction.Billing_Account__c));

    }

    /*
        Test authorized with OTP.
    */
    @isTest
    private static void test_checkAuthorization_OtpSuccess() {

        // Get interaction with step-ups and authenticated with passcode
        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('STEPUPSONLY', 'OTP');

        // Call method using continuation
        System.Continuation continuation =
            (System.Continuation)BWC_AuthorizationController.checkAuthorizationStatusCont(interaction.Id, null);
        
        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_AuthorizationCallout.API_AUTHORIZATION_STATUS, 'UT_Authorize_Status_L1_Success');

        // Get continuation response
        String responseJson = BWC_AuthorizationController.checkAuthorizationStatusResp(null, BWC_Callout.lastContinuationState);

        // Verify
        BWC_AuthorizationService.CheckAuthorizationStatusResponse response =
            (BWC_AuthorizationService.CheckAuthorizationStatusResponse)JSON.deserialize(responseJson, BWC_AuthorizationService.CheckAuthorizationStatusResponse.class);

        // Should be authorized now
        System.assertEquals(true, response.isAuthorized);

        // Also with OTP
        System.assertEquals(true, BWC_AuthorizationController.isAuthenticatedWithOtp(interaction.Id, interaction.Billing_Account__c));

    }

    /*
        Test first initial authorization with bypass.
    */
    @isTest
    private static void test_checkAuthorization_FullBypass() {

        // Get interaction with step-ups and authenticated with passcode
        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('STEPUPSONLY', 'BYPASS');

        // Call method using continuation, but should return response without continuation because callout not required
        String responseJson = (String)BWC_AuthorizationController.checkAuthorizationStatusCont(interaction.Id, null);

        // Verify
        BWC_AuthorizationService.CheckAuthorizationStatusResponse response =
            (BWC_AuthorizationService.CheckAuthorizationStatusResponse)JSON.deserialize(responseJson, BWC_AuthorizationService.CheckAuthorizationStatusResponse.class);

        // Should be authorized now
        System.assertEquals(true, response.isAuthorized);

    }

    /*
        Test step-up bypass authorization to OTP
    */
    @isTest
    private static void test_checkAuthorization_OTPBypass() {

        // Get interaction with step-ups and authenticated to L1 with passcode
        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('L1', 'PASSCODE');

        // Step up the wireless billing account to BYPASS
        Map<String, String> manualAuthentications = (Map<String, String>)JSON.deserialize(interaction.Manual_Authentication_Json__c, Map<String, String>.class);
        manualAuthentications.put(interaction.Billing_Account__c, 'BYPASS');
        interaction.Manual_Authentication_Json__c = JSON.serialize(manualAuthentications, true);
        update interaction;

        // Should NOT be OTP yet
        System.assertEquals(false, BWC_AuthorizationController.isAuthenticatedWithOtp(interaction.Id, interaction.Billing_Account__c));

        // Call method using continuation, but should return response without continuation because callout not required
        String responseJson = (String)BWC_AuthorizationController.checkAuthorizationStatusCont(interaction.Id, interaction.Billing_Account__c);

        // Verify
        BWC_AuthorizationService.CheckAuthorizationStatusResponse response =
            (BWC_AuthorizationService.CheckAuthorizationStatusResponse)JSON.deserialize(responseJson, BWC_AuthorizationService.CheckAuthorizationStatusResponse.class);

        // Should be authorized now
        System.assertEquals(true, BWC_AuthorizationController.isAuthenticatedWithOtp(interaction.Id, interaction.Billing_Account__c));

    }

    /*
        Test setNoAuthentication which generates interaction activity when using legacy auth.
    */
    @isTest
    private static void test_setNoAuthentication() {

        // Get interaction with step-ups and authenticated with passcode
        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('STEPUPSONLY', 'NONE');

        BWC_AuthorizationController.setNoAuthentication(interaction.Id);

    }

}