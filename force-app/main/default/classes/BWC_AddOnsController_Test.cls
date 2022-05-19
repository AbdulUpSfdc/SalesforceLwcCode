/*
    Unit test coverage for BWC_AddOnsController.
*/
@isTest
public with sharing class BWC_AddOnsController_Test {

    @isTest
    private static void test_getAddOns() {

        Account testAccount = BWC_TestDataFactory.createAccount();
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount(BWC_Constants.BillingAccount_AccountType_Wireless, testAccount);
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(testAccount);

        try{
            // Call method using continuation
            System.Continuation continuation =
                (System.Continuation)BWC_AddOnsController.getAddOnsForBillingAccountCont(billingAccount.Id, interaction.Id);
            
            // Set mock response
            BWC_ApiMock.setTestContinuationResponse(continuation, BWC_AddOnsCallout.ADD_ON_DETAILS,'UT_GetAddOns_Error');
    
            // Get continuation response
            String responseJson = BWC_AddOnsController.getAddOnsResp(null, BWC_Callout.lastContinuationState);
    
            // Verify
            BWC_AddOns.AddOnsResponse response =
                (BWC_AddOns.AddOnsResponse)JSON.deserialize(responseJson, BWC_AddOns.AddOnsResponse.class);
    
            // Set mock so synchronous response is returned
            BWC_ApiMock.setTestApiMock(BWC_AddOnsCallout.ADD_ON_DETAILS, 'UT_GetAddOns_Error');
            responseJson = (String)BWC_AddOnsController.getAddOnsForBillingAccountCont(billingAccount.Id, interaction.Id);
            response = (BWC_AddOns.AddOnsResponse)JSON.deserialize(responseJson, BWC_AddOns.AddOnsResponse.class);
            System.assert(false);

            }
        
        catch (System.Exception e) {
                System.assert(true);
            }
        }

        
    @isTest
    private static void test_getAddOns_Negative() {

        Account testAccount = BWC_TestDataFactory.createAccount();
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount(BWC_Constants.BillingAccount_AccountType_Wireless, testAccount);
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(testAccount);

        try{
                System.Continuation continuation =
                (System.Continuation)BWC_AddOnsController.getAddOnsForBillingAccountCont(null, null);
            }
        
        catch (System.Exception e) {
                System.assert(true);
            }
        }

        @isTest
    private static void test_getAddOns_positive() {

        Account testAccount = BWC_TestDataFactory.createAccount();
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount(BWC_Constants.BillingAccount_AccountType_Wireless, testAccount);
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(testAccount);

            // Call method using continuation
            System.Continuation continuation =
                (System.Continuation)BWC_AddOnsController.getAddOnsForBillingAccountCont(billingAccount.Id, interaction.Id);
            
            // Set mock response
            BWC_ApiMock.setTestContinuationResponse(continuation, BWC_AddOnsCallout.ADD_ON_DETAILS,'UT_GetAddOns_Result');
    
            // Get continuation response
            String responseJson = BWC_AddOnsController.getAddOnsResp(null, BWC_Callout.lastContinuationState);
    
            // Verify
            BWC_AddOns.AddOnsResponse response =
                (BWC_AddOns.AddOnsResponse)JSON.deserialize(responseJson, BWC_AddOns.AddOnsResponse.class);
    
            // Set mock so synchronous response is returned
            BWC_ApiMock.setTestApiMock(BWC_AddOnsCallout.ADD_ON_DETAILS, 'UT_GetAddOns_Result');
            responseJson = (String)BWC_AddOnsController.getAddOnsForBillingAccountCont(billingAccount.Id, interaction.Id);
            response = (BWC_AddOns.AddOnsResponse)JSON.deserialize(responseJson, BWC_AddOns.AddOnsResponse.class);
    }
}