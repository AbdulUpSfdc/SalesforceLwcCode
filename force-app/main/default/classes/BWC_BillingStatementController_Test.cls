/*
Unit test coverage for BWC_BillingStatementController.
*/
@isTest
public with sharing class BWC_BillingStatementController_Test {
    
    @isTest
    private static void test_getBillingStatementDetails() { 
        
        Account testAccount = BWC_TestDataFactory.createAccount();
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount(BWC_Constants.BillingAccount_AccountType_Wireless, testAccount);
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(testAccount);
        
        try{
            // Call method using continuation
            System.Continuation continuation =
                (System.Continuation)BWC_BillingStatementController.getBillingStatementsCont(billingAccount.Id, interaction.Id);
            
            // Set mock response
            BWC_ApiMock.setTestContinuationResponse(continuation, BWC_BillingStatementCallout.billing_Statement,'UT_GetBillingStatement_error');
            
            // Get continuation response
            String responseJson = BWC_BillingStatementController.getBillingStatementResp(null, BWC_Callout.lastContinuationState);
            
            // Verify 
            BWC_BillingStatement.BillingStatementResponse response = (BWC_BillingStatement.BillingStatementResponse)JSON.deserialize(responseJson, BWC_BillingStatement.BillingStatementResponse.class);
            
            // Set mock so synchronous response is returned
            BWC_ApiMock.setTestApiMock(BWC_BillingStatementCallout.billing_Statement, 'UT_GetBillingStatement_error');
            responseJson = (String)BWC_BillingStatementController.getBillingStatementsCont(billingAccount.Id, interaction.Id);
            response = (BWC_BillingStatement.BillingStatementResponse)JSON.deserialize(responseJson, BWC_BillingStatement.BillingStatementResponse.class);
            System.assert(false);
        }
        catch (System.Exception e) {
            System.assert(true);
        }
    }
    
    @isTest
    private static void test_getBillingStatementPositive() { 
        
        Account testAccount = BWC_TestDataFactory.createAccount();
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount(BWC_Constants.BillingAccount_AccountType_Wireless, testAccount);
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(testAccount);
        
            // Call method using continuation
            System.Continuation continuation =
                (System.Continuation)BWC_BillingStatementController.getBillingStatementsCont(billingAccount.Id, interaction.Id);
            
            // Set mock response
            BWC_ApiMock.setTestContinuationResponse(continuation, BWC_BillingStatementCallout.billing_Statement,'UT_GetBillingStatement_Result');
            
            // Get continuation response
            String responseJson = BWC_BillingStatementController.getBillingStatementResp(null, BWC_Callout.lastContinuationState);
            
            // Verify 
            BWC_BillingStatement.BillingStatementResponse response = (BWC_BillingStatement.BillingStatementResponse)JSON.deserialize(responseJson, BWC_BillingStatement.BillingStatementResponse.class);
            
            // Set mock so synchronous response is returned
            BWC_ApiMock.setTestApiMock(BWC_BillingStatementCallout.billing_Statement, 'UT_GetBillingStatement_Result');
            responseJson = (String)BWC_BillingStatementController.getBillingStatementsCont(billingAccount.Id, interaction.Id);
            response = (BWC_BillingStatement.BillingStatementResponse)JSON.deserialize(responseJson, BWC_BillingStatement.BillingStatementResponse.class);
        }
    
    @isTest
    private static void test_getBillingStatementDetails_Negative() { 
        
        try{
            // Call method using continuation
            System.Continuation continuation =
                (System.Continuation)BWC_BillingStatementController.getBillingStatementsCont(null, null);
        }
        catch (System.Exception e) {
            System.assert(true);
        }
    }
    
    @isTest
    private static void test_getBillingStatement_RequestNull() {
        
        //Get response
        try{
            BWC_BillingStatementCallout.getBillingStatementsCallout  response  = new BWC_BillingStatementCallout.getBillingStatementsCallout(null);
            System.assert(true, 'Expected exception not thrown.');
        }
        catch (BWC_Exception e) {
            System.assertEquals('Argument required: request', e.getMessage());
        }
    }
        
    @isTest
    private static void test_getBillingStatement() {
        
        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_BillingStatementMock', 200);
        // Setup request
        List<BWC_BillingStatement.BillingStatementRequest> request = BWC_TestDataFactory.createBillingStatementRequest();
        //Get response
        BWC_BillingStatementCallout.getBillingStatementsCallout response  = new BWC_BillingStatementCallout.getBillingStatementsCallout(null);
        System.assertNotEquals(null, response);
    }
    
    @isTest
    private static void test_Negative_BadBody() {
        
        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_Mock_NotJson', 200);
        // Setup request
        List<BWC_BillingStatement.BillingStatementRequest> request = BWC_TestDataFactory.createBillingStatementRequest();
        //Get response
        try {
            BWC_BillingStatementCallout.getBillingStatementsCallout response  = new BWC_BillingStatementCallout.getBillingStatementsCallout(request);
            System.assert(true, 'Excpected exception not thrown.');
        }
        catch (BWC_Exception e) {
            System.assert(e.getCause() instanceOf System.JSONException);
        }
    }
    
    @isTest
    private static void test_getBillingStatement2(){
        
        Account testAccount = BWC_TestDataFactory.createAccount();
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount(BWC_Constants.BillingAccount_AccountType_Wireless, testAccount);
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(testAccount);
        List<BWC_BillingStatement.BillingStatementRequest> request = BWC_TestDataFactory.createBillingStatementRequest();
        Test.startTest();
        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_BillingStatementMock', 200);
        // Make call
        BWC_BillingStatementService.GetBillingStatementsService getBillingStatement = new BWC_BillingStatementService.GetBillingStatementsService(billingAccount.Id, interaction.Id);
        Test.stopTest();
        System.assertNotEquals(null, getBillingStatement);   
    }  
        
    @isTest
    private static void test_getBillingStatementService() { 
        
        Account testAccount = BWC_TestDataFactory.createAccount();
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount('wireline', testAccount);
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(testAccount);
        
        BWC_BillingStatement.BillingStatementResponse response;
        try{
            // Call method using continuation
            System.Continuation continuation =
                (System.Continuation)BWC_BillingStatementController.getBillingStatementsCont(billingAccount.Id, interaction.Id);
            
            // Set mock response
            BWC_ApiMock.setTestContinuationResponse(continuation, BWC_BillingStatementCallout.billing_Statement,'UT_GetBillingStatement_error');
            
            // Get continuation response
            String responseJson = BWC_BillingStatementController.getBillingStatementResp(null, BWC_Callout.lastContinuationState);
            
            // Set mock so synchronous response is returned
            BWC_ApiMock.setTestApiMock(BWC_BillingStatementCallout.billing_Statement, 'UT_GetBillingStatement_error');
            responseJson = (String)BWC_BillingStatementController.getBillingStatementsCont(billingAccount.Id, interaction.Id);
            response = (BWC_BillingStatement.BillingStatementResponse)JSON.deserialize(responseJson, BWC_BillingStatement.BillingStatementResponse.class);
            System.assert(false);
        }
        catch (System.Exception e) {
            System.assert(true);
        }
    }
}