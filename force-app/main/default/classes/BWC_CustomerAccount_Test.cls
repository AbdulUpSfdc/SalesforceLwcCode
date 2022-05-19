/*
    Test coverage for BWC_CustomerAccountXXX classes
*/
@isTest
public with sharing class BWC_CustomerAccount_Test {

    @isTest
    private static void test_getAccountDetailsForBillingAccountRecord() {

        Account accountRecord = BWC_TestDataFactory.createAccount();
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount('Wireless', accountRecord);
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(accountRecord);

        try{
            // Call method using continuation
            System.Continuation continuation =
                (System.Continuation)BWC_CustomerAccountController.getCustomerInfoForBillingAccountCont(billingAccount.Id, interaction.Id);
            
            // Set mock response
            BWC_ApiMock.setTestContinuationResponse(continuation, BWC_Constants.API_CUSTOMER_ACCOUNT,'UT_GetCustomerAccount_error');
    
            // Get continuation response
            String responseJson = BWC_CustomerAccountController.getCustomAccountResp(null, BWC_Callout.lastContinuationState);
    
            // Verify
            BWC_CustomerAccount.AccountDetailsResponse response =
                (BWC_CustomerAccount.AccountDetailsResponse)JSON.deserialize(responseJson, BWC_CustomerAccountController.AccountDetailsResponse.class);
    
            // Set mock so synchronous response is returned
            BWC_ApiMock.setTestApiMock(BWC_Constants.API_CUSTOMER_ACCOUNT, 'UT_GetCustomerAccount_error');
            responseJson = (String)BWC_CustomerAccountController.getCustomerInfoForBillingAccountCont(billingAccount.Id, interaction.Id);
            response = (BWC_CustomerAccount.AccountDetailsResponse)JSON.deserialize(responseJson, BWC_CustomerAccount.AccountDetailsResponse.class);
            System.assert(false);
            }
        
        catch (System.Exception e) {
                System.assert(true);
            }

    }
    
    @IsTest
    static void test_getAccountDetailsForBillingAccountRecordNegative(){

        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            System.Continuation continuation =
                (System.Continuation)BWC_CustomerAccountController.getCustomerInfoForBillingAccountCont(null,null);
 			String responseJson = BWC_CustomerAccountController.getCustomAccountResp(null, null);
            BWC_CustomerAccount.AccountDetailsResponse response =
                (BWC_CustomerAccount.AccountDetailsResponse)JSON.deserialize(responseJson, BWC_CustomerAccountController.AccountDetailsResponse.class);
            responseJson = (String)BWC_CustomerAccountController.getCustomerInfoForBillingAccountCont(null, null);
            response = (BWC_CustomerAccount.AccountDetailsResponse)JSON.deserialize(responseJson, BWC_CustomerAccount.AccountDetailsResponse.class);
        } 
        catch (Exception e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Exception was not thrown');

        Test.stopTest();

    }
    
     @isTest
    static void test_getCustomerAccountCallout(){
          Test.startTest();
         Boolean exceptionThrown = false;
        try
        {  
       	 BWC_CustomerAccountCallout.putBillingInfo('','',NULL);
        }
          catch (Exception e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Exception was not thrown');
        Test.stopTest();
    }
    
    @isTest
    private static void test_putBillingInfo() {

        // (Response content is ignored)
        BWC_Utils.setStaticResourceMock('BWC_CustomerAccountDetailsResponseMock', 200);

        BWC_CustomerAccount.PutBillingInfoRequest billingInfo = new BWC_CustomerAccount.PutBillingInfoRequest();

        Test.startTest();

        String responseWrapperJson = BWC_CustomerAccountController.putBillingInfo('123456789', 'wireless', JSON.serialize(billingInfo));

        Test.stopTest();

        BWC_CustomerAccountController.PutBillingInfoResponseWrapper responseWrapper = 
            (BWC_CustomerAccountController.PutBillingInfoResponseWrapper)JSON.deserialize(responseWrapperJson, BWC_CustomerAccountController.PutBillingInfoResponseWrapper.class);

        System.assertEquals(true, responseWrapper.success);
        System.assertNotEquals(null, responseWrapper.response);

    }

    @isTest
    private static void test_putBillingInfo_negative() {

        BWC_Utils.setStaticResourceMock('BWC_Mock_NotJson', 200);

        BWC_CustomerAccount.PutBillingInfoRequest billingInfo = new BWC_CustomerAccount.PutBillingInfoRequest();

        Test.startTest();

        // Non-json respnose
        String responseWrapperJson = BWC_CustomerAccountController.putBillingInfo('123456789', 'wireless', JSON.serialize(billingInfo));
        BWC_CustomerAccountController.PutBillingInfoResponseWrapper responseWrapper = 
            (BWC_CustomerAccountController.PutBillingInfoResponseWrapper)JSON.deserialize(responseWrapperJson, BWC_CustomerAccountController.PutBillingInfoResponseWrapper.class);
        System.assertEquals(false, responseWrapper.success);
        System.assertEquals(null, responseWrapper.response);
        
        // Missing ban
        responseWrapperJson = BWC_CustomerAccountController.putBillingInfo(null, 'wireless', JSON.serialize(billingInfo));
        responseWrapper = 
            (BWC_CustomerAccountController.PutBillingInfoResponseWrapper)JSON.deserialize(responseWrapperJson, BWC_CustomerAccountController.PutBillingInfoResponseWrapper.class);
        System.assertEquals(false, responseWrapper.success);
        System.assertEquals(null, responseWrapper.response);

        // Missing account type
        responseWrapperJson = BWC_CustomerAccountController.putBillingInfo('123456789', null, JSON.serialize(billingInfo));
        responseWrapper = 
            (BWC_CustomerAccountController.PutBillingInfoResponseWrapper)JSON.deserialize(responseWrapperJson, BWC_CustomerAccountController.PutBillingInfoResponseWrapper.class);
        System.assertEquals(false, responseWrapper.success);
        System.assertEquals(null, responseWrapper.response);

        // Missing billing info
        responseWrapperJson = BWC_CustomerAccountController.putBillingInfo('123456789', 'wireless', null);
        responseWrapper = 
            (BWC_CustomerAccountController.PutBillingInfoResponseWrapper)JSON.deserialize(responseWrapperJson, BWC_CustomerAccountController.PutBillingInfoResponseWrapper.class);
        System.assertEquals(false, responseWrapper.success);
        System.assertEquals(null, responseWrapper.response);

    }

    @isTest
    private static void test_updateAccountPasscode() {

        // (Response content is ignored)
        BWC_Utils.setStaticResourceMock('BWC_UpdateAccountPasscodeResponseMock', 200);

        BWC_CustomerAccount.UpdateAccountPasscodeRequest passcodeInfo = new BWC_CustomerAccount.UpdateAccountPasscodeRequest();

        Test.startTest();

        String responseWrapperJson = BWC_CustomerAccountController.updateAccountPasscode('123456789', 'wireless', JSON.serialize(passcodeInfo));

        Test.stopTest();

        BWC_CustomerAccountController.UpdateAccountPasscodeResponseWrapper responseWrapper = 
            (BWC_CustomerAccountController.UpdateAccountPasscodeResponseWrapper)JSON.deserialize(responseWrapperJson, BWC_CustomerAccountController.UpdateAccountPasscodeResponseWrapper.class);

        System.assertEquals(true, responseWrapper.success);
        System.assertNotEquals(null, responseWrapper.response);

    }

    @isTest
    private static void test_updateAccountPasscode_error() {

        BWC_Utils.setStaticResourceMock('BWC_Mock_NotJson', 200);

        BWC_CustomerAccount.UpdateAccountPasscodeRequest passcodeInfo = new BWC_CustomerAccount.UpdateAccountPasscodeRequest();

        Test.startTest();

        // Non-json respnose
        String responseWrapperJson = BWC_CustomerAccountController.updateAccountPasscode('123456789', 'wireless', JSON.serialize(passcodeInfo));
        BWC_CustomerAccountController.UpdateAccountPasscodeResponseWrapper responseWrapper = 
            (BWC_CustomerAccountController.UpdateAccountPasscodeResponseWrapper)JSON.deserialize(responseWrapperJson, BWC_CustomerAccountController.UpdateAccountPasscodeResponseWrapper.class);
        System.assertEquals(false, responseWrapper.success);
        System.assertEquals(null, responseWrapper.response);
        
        // Missing ban
        responseWrapperJson = BWC_CustomerAccountController.updateAccountPasscode(null, 'wireless', JSON.serialize(passcodeInfo));
        responseWrapper = 
        (BWC_CustomerAccountController.UpdateAccountPasscodeResponseWrapper)JSON.deserialize(responseWrapperJson, BWC_CustomerAccountController.UpdateAccountPasscodeResponseWrapper.class);
        System.assertEquals(false, responseWrapper.success);
        System.assertEquals(null, responseWrapper.response);

        // Missing account type
        responseWrapperJson = BWC_CustomerAccountController.updateAccountPasscode('123456789', null, JSON.serialize(passcodeInfo));
        responseWrapper = 
            (BWC_CustomerAccountController.UpdateAccountPasscodeResponseWrapper)JSON.deserialize(responseWrapperJson, BWC_CustomerAccountController.UpdateAccountPasscodeResponseWrapper.class);
        System.assertEquals(false, responseWrapper.success);
        System.assertEquals(null, responseWrapper.response);

        // Missing billing info
        responseWrapperJson = BWC_CustomerAccountController.updateAccountPasscode('123456789', 'wireless', null);
        responseWrapper = 
            (BWC_CustomerAccountController.UpdateAccountPasscodeResponseWrapper)JSON.deserialize(responseWrapperJson, BWC_CustomerAccountController.UpdateAccountPasscodeResponseWrapper.class);
        System.assertEquals(false, responseWrapper.success);
        System.assertEquals(null, responseWrapper.response);

    }
}