/*
    Unit test coverage for BWC_AuthenticationController.
    Also provides coverage for corresponding parts of BWC_AuthenticationService and BWC_AuthenticationCallout.
*/
@isTest
public with sharing class BWC_AuthenticationController_Test {
    
    private static Interaction__c getTestInteraction() {
        return BWC_TestDataFactory.createFullInteraction('STEPUPSONLY', 'NONE');
    }

    @isTest
    private static void test_generatePin_Success() {

        Interaction__c interaction = getTestInteraction();

        BWC_AuthenticationCallout.DeliveryMethods deliveryMethods = new BWC_AuthenticationCallout.DeliveryMethods();
        deliveryMethods.sms = new BWC_AuthenticationCallout.SmsDeliveryMethod();
        deliveryMethods.sms.smsPhoneNumber = BWC_Utils.hashContactMethod('2144350011');

        // Call method using continuation
        System.Continuation continuation =
            (System.Continuation)BWC_AuthenticationController.generatePinCont(interaction.Id, interaction.Billing_Account__c, JSON.serialize(deliveryMethods, true));        
        
        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_AuthenticationCallout.API_AUTHENTICATION_GENERATE_PIN, 'UT_Generate_Pin_Success');

        // Get continuation response
        String responseJson = BWC_AuthenticationController.generatePinResp(null, BWC_Callout.lastContinuationState);

        // Verify
        BWC_AuthenticationCallout.GeneratePinResponse response =
            (BWC_AuthenticationCallout.GeneratePinResponse)JSON.deserialize(responseJson, BWC_AuthenticationCallout.GeneratePinResponse.class);

        System.assertEquals('SUCCESS', response.appStatusMsg);

        // Set mock so synchronous response is returned
        BWC_ApiMock.setTestApiMock(BWC_AuthenticationCallout.API_AUTHENTICATION_GENERATE_PIN, 'UT_Generate_Pin_Success');
        responseJson = (String)BWC_AuthenticationController.generatePinCont(interaction.Id, interaction.Billing_Account__c, JSON.serialize(deliveryMethods, true));
        response =
            (BWC_AuthenticationCallout.GeneratePinResponse)JSON.deserialize(responseJson, BWC_AuthenticationCallout.GeneratePinResponse.class);
        System.assertEquals('SUCCESS', response.appStatusMsg);

    }

    @isTest
    private static void test_generatePin_Email_Success() {

        Interaction__c interaction = getTestInteraction();

        BWC_AuthenticationCallout.DeliveryMethods deliveryMethods = new BWC_AuthenticationCallout.DeliveryMethods();
        deliveryMethods.email = new BWC_AuthenticationCallout.EmailDeliveryMethod();
        deliveryMethods.email.emailAddress = BWC_Utils.hashContactMethod('test@email.com');

        // Call method using continuation
        System.Continuation continuation =
            (System.Continuation)BWC_AuthenticationController.generatePinCont(interaction.Id, interaction.Billing_Account__c, JSON.serialize(deliveryMethods, true));        
        
        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_AuthenticationCallout.API_AUTHENTICATION_GENERATE_PIN, 'UT_Generate_Pin_Success');

        // Get continuation response
        String responseJson = BWC_AuthenticationController.generatePinResp(null, BWC_Callout.lastContinuationState);

        // Verify
        BWC_AuthenticationCallout.GeneratePinResponse response =
            (BWC_AuthenticationCallout.GeneratePinResponse)JSON.deserialize(responseJson, BWC_AuthenticationCallout.GeneratePinResponse.class);

        System.assertEquals('SUCCESS', response.appStatusMsg);

        // Set mock so synchronous response is returned
        BWC_ApiMock.setTestApiMock(BWC_AuthenticationCallout.API_AUTHENTICATION_GENERATE_PIN, 'UT_Generate_Pin_Success');
        responseJson = (String)BWC_AuthenticationController.generatePinCont(interaction.Id, interaction.Billing_Account__c, JSON.serialize(deliveryMethods, true));
        response =
            (BWC_AuthenticationCallout.GeneratePinResponse)JSON.deserialize(responseJson, BWC_AuthenticationCallout.GeneratePinResponse.class);
        System.assertEquals('SUCCESS', response.appStatusMsg);

    }

    @isTest
    private static void test_generatePin_InvalidPhone() {

        Interaction__c interaction = getTestInteraction();

        BWC_AuthenticationCallout.DeliveryMethods deliveryMethods = new BWC_AuthenticationCallout.DeliveryMethods();
        deliveryMethods.sms = new BWC_AuthenticationCallout.SmsDeliveryMethod();
        deliveryMethods.sms.smsPhoneNumber = '123456789';

        try {

            System.Continuation continuation =
                (System.Continuation)BWC_AuthenticationController.generatePinCont(interaction.Id, interaction.Billing_Account__c, JSON.serialize(deliveryMethods, true));        

            System.assert(false, 'Expected exception not thrown.');

        }
        catch (BWC_Exception e) {
            System.assertEquals(BWC_Authentication.INVALID_OTP_PHONE, e.code);
        }

    }

    @isTest
    private static void test_generatePin_InvalidEmail() {

        Interaction__c interaction = getTestInteraction();

        BWC_AuthenticationCallout.DeliveryMethods deliveryMethods = new BWC_AuthenticationCallout.DeliveryMethods();
        deliveryMethods.email = new BWC_AuthenticationCallout.EmailDeliveryMethod();
        deliveryMethods.email.emailAddress = 'email@att.com';

        try {

            System.Continuation continuation =
                (System.Continuation)BWC_AuthenticationController.generatePinCont(interaction.Id, interaction.Billing_Account__c, JSON.serialize(deliveryMethods, true));        

            System.assert(false, 'Expected exception not thrown.');

        }
        catch (BWC_Exception e) {
            System.assertEquals(BWC_Authentication.INVALID_OTP_EMAIL, e.code);
        }

    }

    @isTest
    private static void test_generatePin_ServerFailure() {

        Interaction__c interaction = getTestInteraction();

        BWC_AuthenticationCallout.DeliveryMethods deliveryMethods = new BWC_AuthenticationCallout.DeliveryMethods();
        deliveryMethods.sms = new BWC_AuthenticationCallout.SmsDeliveryMethod();
        deliveryMethods.sms.smsPhoneNumber = BWC_Utils.hashContactMethod('2144350011');

        // Call method using continuation
        System.Continuation continuation =
            (System.Continuation)BWC_AuthenticationController.generatePinCont(interaction.Id, interaction.Billing_Account__c, JSON.serialize(deliveryMethods, true));        
        
        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_AuthenticationCallout.API_AUTHENTICATION_GENERATE_PIN, 'UT_Generate_Pin_500');
        BWC_Controller.THROW_TEST_AURA_EXCEPTION = true;

        // Get continuation response
        try {
            String responseJson = BWC_AuthenticationController.generatePinResp(null, BWC_Callout.lastContinuationState);
            System.assert(false, 'Exception not thrown.');
        }
        catch(AuraHandledException e) {
            System.assert(true);
        }

    }

    /*
        Test initial authentication of interaction using OTP.
    */
    @isTest
    private static void test_validatePin_Success() {

        Interaction__c interaction = getTestInteraction();

        // Call method using continuation
        System.Continuation continuation =
            (System.Continuation)BWC_AuthenticationController.validatePinCont(interaction.Id, interaction.Billing_Account__c, '123456', 'sms', BWC_Utils.hashContactMethod('2144350011'));        
        
        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_AuthenticationCallout.API_AUTHENTICATION_VALIDATE_PIN, 'UT_Validate_Pin_Success');

        // Get continuation response
        String responseJson = BWC_AuthenticationController.validatePinResp(null, BWC_Callout.lastContinuationState);

        // Verify
        BWC_AuthenticationCallout.ValidatePinResponse response =
            (BWC_AuthenticationCallout.ValidatePinResponse)JSON.deserialize(responseJson, BWC_AuthenticationCallout.ValidatePinResponse.class);
        System.assertEquals('SUCCESS', response.appStatusMsg);
        interaction = BWC_Interaction.getInteraction(interaction.Id);
        verifyManualAuthentication(interaction, interaction.Billing_Account__c, BWC_Authentication.AUTHENTICATION_METHOD_OTP);

        // Set mock so synchronous response is returned
        BWC_ApiMock.setTestApiMock(BWC_AuthenticationCallout.API_AUTHENTICATION_VALIDATE_PIN, 'UT_Validate_Pin_Success');
        responseJson = (String)BWC_AuthenticationController.validatePinCont(interaction.Id, interaction.Billing_Account__c, '123456', 'sms', BWC_Utils.hashContactMethod('2144350011'));
        response =
            (BWC_AuthenticationCallout.ValidatePinResponse)JSON.deserialize(responseJson, BWC_AuthenticationCallout.ValidatePinResponse.class);
        System.assertEquals('SUCCESS', response.appStatusMsg);

    }

    @isTest
    private static void test_validatePin_Email_Success() {

        Interaction__c interaction = getTestInteraction();

        // Call method using continuation
        System.Continuation continuation =
            (System.Continuation)BWC_AuthenticationController.validatePinCont(interaction.Id, interaction.Billing_Account__c, 'test@email.com', 'email', 'email@att.com');
        
        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_AuthenticationCallout.API_AUTHENTICATION_VALIDATE_PIN, 'UT_Validate_Pin_Success');

        // Get continuation response
        String responseJson = BWC_AuthenticationController.validatePinResp(null, BWC_Callout.lastContinuationState);

        // Verify
        BWC_AuthenticationCallout.ValidatePinResponse response =
            (BWC_AuthenticationCallout.ValidatePinResponse)JSON.deserialize(responseJson, BWC_AuthenticationCallout.ValidatePinResponse.class);
        System.assertEquals('SUCCESS', response.appStatusMsg);
        interaction = BWC_Interaction.getInteraction(interaction.Id);
        verifyManualAuthentication(interaction, interaction.Billing_Account__c, BWC_Authentication.AUTHENTICATION_METHOD_OTP);

        // Set mock so synchronous response is returned
        BWC_ApiMock.setTestApiMock(BWC_AuthenticationCallout.API_AUTHENTICATION_VALIDATE_PIN, 'UT_Validate_Pin_Success');
        responseJson = (String)BWC_AuthenticationController.validatePinCont(interaction.Id, interaction.Billing_Account__c, 'test@email.com', 'email', 'email@att.com');
        response =
            (BWC_AuthenticationCallout.ValidatePinResponse)JSON.deserialize(responseJson, BWC_AuthenticationCallout.ValidatePinResponse.class);
        System.assertEquals('SUCCESS', response.appStatusMsg);

    }

    @isTest
    private static void test_validatePin_WrongOtp() {

        Interaction__c interaction = getTestInteraction();

        // Call method using continuation
        System.Continuation continuation =
            (System.Continuation)BWC_AuthenticationController.validatePinCont(interaction.Id, interaction.Billing_Account__c, '123456', 'sms', BWC_Utils.hashContactMethod('2144350011'));        
        
        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_AuthenticationCallout.API_AUTHENTICATION_VALIDATE_PIN, 'UT_Validate_Pin_Invalid');

        // Get continuation response
        String responseJson = BWC_AuthenticationController.validatePinResp(null, BWC_Callout.lastContinuationState);

        // Verify
        BWC_AuthenticationCallout.ValidatePinResponse response =
            (BWC_AuthenticationCallout.ValidatePinResponse)JSON.deserialize(responseJson, BWC_AuthenticationCallout.ValidatePinResponse.class);
        interaction = BWC_Interaction.getInteraction(interaction.Id);
        System.assertEquals('ERR_INCORRECT_CODE', response.appStatusMsg);
        verifyManualAuthentication(interaction, interaction.Billing_Account__c, BWC_Authentication.AUTHENTICATION_METHOD_NONE);

    }

    @isTest
    private static void test_validatePin_Email_WrongOtp() {

        Interaction__c interaction = getTestInteraction();

        // Call method using continuation
        System.Continuation continuation =
            (System.Continuation)BWC_AuthenticationController.validatePinCont(interaction.Id, interaction.Billing_Account__c, 'test@email.com', 'email', 'email@att.com');
        
        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_AuthenticationCallout.API_AUTHENTICATION_VALIDATE_PIN, 'UT_Validate_Pin_Invalid');

        // Get continuation response
        String responseJson = BWC_AuthenticationController.validatePinResp(null, BWC_Callout.lastContinuationState);

        // Verify
        BWC_AuthenticationCallout.ValidatePinResponse response =
            (BWC_AuthenticationCallout.ValidatePinResponse)JSON.deserialize(responseJson, BWC_AuthenticationCallout.ValidatePinResponse.class);
        interaction = BWC_Interaction.getInteraction(interaction.Id);
        System.assertEquals('ERR_INCORRECT_CODE', response.appStatusMsg);
        verifyManualAuthentication(interaction, interaction.Billing_Account__c, BWC_Authentication.AUTHENTICATION_METHOD_NONE);

    }

    @isTest
    private static void test_validatePin_ServerFailure() {

        Interaction__c interaction = getTestInteraction();

        // Call method using continuation
        System.Continuation continuation =
            (System.Continuation)BWC_AuthenticationController.validatePinCont(interaction.Id, interaction.Billing_Account__c, '123456', 'sms', BWC_Utils.hashContactMethod('2144350011'));        
        
        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_AuthenticationCallout.API_AUTHENTICATION_VALIDATE_PIN, 'UT_Validate_Pin_500');
        BWC_Controller.THROW_TEST_AURA_EXCEPTION = true;

        // Get continuation response
        try {
            String responseJson = BWC_AuthenticationController.validatePinResp(null, BWC_Callout.lastContinuationState);
            System.assert(false, 'Exception not thrown.');
        }
        catch(AuraHandledException e) {
            System.assert(true);
        }

    }

    /*
        Test initial authentication of interaction using Passcode.
    */    
    @isTest
    private static void test_validateCredentials_Success() {

        Interaction__c interaction = getTestInteraction();

        BWC_AuthenticationCallout.AccountCredentials credentials = new BWC_AuthenticationCallout.AccountCredentials();
        credentials.passcode = '1111';

        // Call method using continuation
        System.Continuation continuation =
            (System.Continuation)BWC_AuthenticationController.validateCredentialsCont(interaction.Id, interaction.Billing_Account__c, JSON.serialize(credentials));        
        
        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_AuthenticationCallout.API_AUTHENTICATION_VALIATE_CREDENTIALS, 'UT_Validate_Credentials_Success');

        // Get continuation response
        String responseJson = BWC_AuthenticationController.validateCredentialsResp(null, BWC_Callout.lastContinuationState);

        // Verify
        BWC_AuthenticationCallout.ValidateCredentialsResponse response =
            (BWC_AuthenticationCallout.ValidateCredentialsResponse)JSON.deserialize(responseJson, BWC_AuthenticationCallout.ValidateCredentialsResponse.class);

        System.assertEquals('SUCCESS', response.appStatusMsg);
        interaction = BWC_Interaction.getInteraction(interaction.Id);
        verifyManualAuthentication(interaction, interaction.Billing_Account__c, BWC_Authentication.AUTHENTICATION_METHOD_PASSCODE);

        // Set mock so synchronous response is returned
        BWC_ApiMock.setTestApiMock(BWC_AuthenticationCallout.API_AUTHENTICATION_VALIATE_CREDENTIALS, 'UT_Validate_Credentials_Success');
        responseJson = (String)BWC_AuthenticationController.validateCredentialsCont(interaction.Id, interaction.Billing_Account__c, JSON.serialize(credentials));
        response =
            (BWC_AuthenticationCallout.ValidateCredentialsResponse)JSON.deserialize(responseJson, BWC_AuthenticationCallout.ValidateCredentialsResponse.class);
        System.assertEquals('SUCCESS', response.appStatusMsg);

    }

    @isTest
    private static void test_validateCredentials_Invalid() {

        Interaction__c interaction = getTestInteraction();

        BWC_AuthenticationCallout.AccountCredentials credentials = new BWC_AuthenticationCallout.AccountCredentials();
        credentials.passcode = '1111';

        // Call method using continuation
        System.Continuation continuation =
            (System.Continuation)BWC_AuthenticationController.validateCredentialsCont(interaction.Id, interaction.Billing_Account__c, JSON.serialize(credentials));        
        
        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_AuthenticationCallout.API_AUTHENTICATION_VALIATE_CREDENTIALS, 'UT_Validate_Credentials_Invalid');

        // Get continuation response
        String responseJson = BWC_AuthenticationController.validateCredentialsResp(null, BWC_Callout.lastContinuationState);

        // Verify
        BWC_AuthenticationCallout.ValidateCredentialsResponse response =
            (BWC_AuthenticationCallout.ValidateCredentialsResponse)JSON.deserialize(responseJson, BWC_AuthenticationCallout.ValidateCredentialsResponse.class);
        System.assertEquals('ERR_INVALID_CREDENTIALS', response.appStatusMsg);
        interaction = BWC_Interaction.getInteraction(interaction.Id);
        verifyManualAuthentication(interaction, interaction.Billing_Account__c, BWC_Authentication.AUTHENTICATION_METHOD_NONE);

    }

    @isTest
    private static void test_validateCredentials_ServerFailure() {

        Interaction__c interaction = getTestInteraction();

        BWC_AuthenticationCallout.AccountCredentials credentials = new BWC_AuthenticationCallout.AccountCredentials();
        credentials.passcode = '1111';

        // Call method using continuation
        System.Continuation continuation =
            (System.Continuation)BWC_AuthenticationController.validateCredentialsCont(interaction.Id, interaction.Billing_Account__c, JSON.serialize(credentials));        
        
        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_AuthenticationCallout.API_AUTHENTICATION_VALIATE_CREDENTIALS, 'UT_Validate_Credentials_500');

        BWC_Controller.THROW_TEST_AURA_EXCEPTION = true;

        // Get continuation response
        try {
            String responseJson = BWC_AuthenticationController.validateCredentialsResp(null, BWC_Callout.lastContinuationState);
            System.assert(false, 'Exception not thrown.');
        }
        catch(AuraHandledException e) {
            System.assert(true);
        }

    }

    /*
        Test initial bypass of interaction authentication using OTP.
    */    
    @isTest
    private static void test_Bypass_Success() {

        Interaction__c interaction = getTestInteraction();

        BWC_AuthenticationController.bypassAuthentication(interaction.Id, interaction.Billing_Account__c);
        interaction = BWC_Interaction.getInteraction(interaction.Id);
        System.assertEquals(BWC_Authentication.AUTHENTICATION_METHOD_BYPASS, interaction.Authentication_Method_Used__c);

    }

    /*
        Verifies expected manual authentication JSON is on the interaction after an authentication attempt.
    */
    public static void verifyManualAuthentication(Interaction__c interaction, Id billingAccountId, String authenticationMethod) {

        // If this is first authentication, then manual method should be set
        if (interaction.Is_Authorized__c != true) {
            if (authenticationMethod == 'NONE') {
                System.assert(String.isEmpty(interaction.Manual_Authentication_Method__c) || interaction.Manual_Authentication_Method__c == 'NONE');
            }
            else {
                System.assertEquals(authenticationMethod, interaction.Manual_Authentication_Method__c);
            }
        }

        if (String.isEmpty(interaction.Manual_Authentication_Json__c)) {
            if (authenticationMethod != BWC_Authentication.AUTHENTICATION_METHOD_NONE) {
                System.assert(false, 'No Manual_Authentication_Json__c on interaction.');
            }
        }
        else {
            Map<String, String> authenticationMethods = (Map<String, String>)JSON.deserialize(interaction.Manual_Authentication_Json__c, Map<String, String>.class);
            System.assertEquals(authenticationMethod, authenticationMethods.get(billingAccountId));
        }

    }

}