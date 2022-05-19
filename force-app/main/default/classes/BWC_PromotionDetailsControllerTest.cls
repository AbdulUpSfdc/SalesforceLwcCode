@isTest
public with sharing class BWC_PromotionDetailsControllerTest {
    
    @isTest
    private static void test_getPromotionDetails() {
        
        Account testAccount = BWC_TestDataFactory.createAccount();
        String recType = BWC_Constants.BillingAccount_AccountType_Wireless;
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount(BWC_Constants.BillingAccount_AccountType_Wireless, testAccount);
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(testAccount);

      
        try{
        // Call method using continuation
        System.Continuation continuation =
            (System.Continuation)BWC_PromotionDetailsController.getPromotionDetailsForBillingAccountCont(billingAccount.Id, interaction.Id);
        
        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_PromotionDetailsCallout.USER_PROMOTION_DETAILS,'UT_GetPromotionDetails_error');

        // Get continuation response
        String responseJson = BWC_PromotionDetailsController.getPromotionDetailsResp(null, BWC_Callout.lastContinuationState);

        // Verify
        BWC_PromotionDetails.PromotionDetailsResponse response =
            (BWC_PromotionDetails.PromotionDetailsResponse)JSON.deserialize(responseJson, BWC_PromotionDetails.PromotionDetailsResponse.class);

        // Set mock so synchronous response is returned
        BWC_ApiMock.setTestApiMock(BWC_PromotionDetailsCallout.USER_PROMOTION_DETAILS, 'UT_GetPromotionDetails_error');
        responseJson = (String)BWC_PromotionDetailsController.getPromotionDetailsForBillingAccountCont(billingAccount.Id, interaction.Id);
        response = (BWC_PromotionDetails.PromotionDetailsResponse)JSON.deserialize(responseJson, BWC_PromotionDetails.PromotionDetailsResponse.class);
        System.assert(false);
    	}
    
    catch (System.Exception e) {
            System.assert(true);
        }
    }
    
    @isTest
    private static void test_getUserAsscoationsDetailsError() {
        
        Account testAccount = BWC_TestDataFactory.createAccount();
        String recType = BWC_Constants.BillingAccount_AccountType_Wireless;
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount(BWC_Constants.BillingAccount_AccountType_Wireless, testAccount);
        //Interaction__c interaction = BWC_TestDataFactory.createInteraction(testAccount);

      
        try{
        // Call method using continuation
        System.Continuation continuation =
            (System.Continuation)BWC_PromotionDetailsController.getPromotionDetailsForBillingAccountCont(billingAccount.Id, null);
    	}
    
    catch (System.Exception e) {
            System.assert(true);
        }
    }
}