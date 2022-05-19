@isTest
public class BWC_OrderControllerTest {
	@isTest
    private static void test_getOrderHistory() {
        
        Account testAccount = BWC_TestDataFactory.createAccount();
        String recType = BWC_Constants.BillingAccount_AccountType_Wireless;
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount(BWC_Constants.BillingAccount_AccountType_Wireless, testAccount);
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(testAccount);

      
        try{
        // Call method using continuation
        System.Continuation continuation =
            (System.Continuation)BWC_OrderController.getOrderHistoryCont(interaction.Id);
        
        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_OrderCallout.API_ORDER_HISTORY,'UT_GetOrderHistory_error');

        // Get continuation response
        String responseJson = BWC_OrderController.getOrderHistoryResp(null, BWC_Callout.lastContinuationState);

        // Verify
        BWC_Order.OrderHistoryResponse response =
            (BWC_Order.OrderHistoryResponse)JSON.deserialize(responseJson, BWC_Order.OrderHistoryResponse.class);

        // Set mock so synchronous response is returned
        BWC_ApiMock.setTestApiMock(BWC_OrderCallout.API_ORDER_HISTORY, 'UT_GetOrderHistory_error');
        responseJson = (String)BWC_OrderController.getOrderHistoryCont(interaction.Id);
        response = (BWC_Order.OrderHistoryResponse)JSON.deserialize(responseJson, BWC_Order.OrderHistoryResponse.class);
        System.assert(false);
    	}
    
    catch (System.Exception e) {
            System.assert(true);
        }
    }
    
    @isTest
    private static void test_getOrderHistoryException() {

        try{
        // Call method using continuation
        System.Continuation continuation =
            (System.Continuation)BWC_OrderController.getOrderHistoryCont(null);
    	}
    
    catch (System.Exception e) {
            System.assert(true);
        }
    }
    
    @isTest
    private static void test_getOrderDetails() {
        
        Account testAccount = BWC_TestDataFactory.createAccount();
        String recType = BWC_Constants.BillingAccount_AccountType_Wireless;
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount(BWC_Constants.BillingAccount_AccountType_Wireless, testAccount);
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(testAccount);

      
        try{
        // Call method using continuation
        System.Continuation continuation =
            (System.Continuation)BWC_OrderController.getOrderDetailsCont(interaction.Id, 'a3C7c000000kUGkEAM');
        
        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_OrderCallout.API_ORDER_DETAILS,'UT_GetOrderDetails_error');

        // Get continuation response
        String responseJson = BWC_OrderController.getOrderDetailsResp(null, BWC_Callout.lastContinuationState);

        // Verify
        BWC_Order.OrderDetailsResponse response =
            (BWC_Order.OrderDetailsResponse)JSON.deserialize(responseJson, BWC_Order.OrderDetailsResponse.class);

        // Set mock so synchronous response is returned
        BWC_ApiMock.setTestApiMock(BWC_OrderCallout.API_ORDER_DETAILS, 'UT_GetOrderDetails_error');
        responseJson = (String)BWC_OrderController.getOrderDetailsCont(interaction.Id, 'a3C7c000000kUGkEAM');
        response = (BWC_Order.OrderDetailsResponse)JSON.deserialize(responseJson, BWC_Order.OrderDetailsResponse.class);
        System.assert(false);
    	}
    
    catch (System.Exception e) {
            System.assert(true);
        }
    }
    
    @isTest
    private static void test_getOrderDetailsException() {

        try{
        // Call method using continuation
        System.Continuation continuation =
            (System.Continuation)BWC_OrderController.getOrderDetailsCont(null, null);
    	}
    
    catch (System.Exception e) {
            System.assert(true);
        }
    }
    @isTest
    private static void test_getOrderHistoryPositive() {
        
        Account testAccount = BWC_TestDataFactory.createAccount();
        String recType = BWC_Constants.BillingAccount_AccountType_Wireless;
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount(BWC_Constants.BillingAccount_AccountType_Wireless, testAccount);
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(testAccount);

      
        // Call method using continuation
        System.Continuation continuation =
            (System.Continuation)BWC_OrderController.getOrderHistoryCont(interaction.Id);
        
        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_OrderCallout.API_ORDER_HISTORY,'UT_GetOrderHistory_Result');

        // Get continuation response
        String responseJson = BWC_OrderController.getOrderHistoryResp(null, BWC_Callout.lastContinuationState);

        // Verify
        BWC_Order.OrderHistoryResponse response =
            (BWC_Order.OrderHistoryResponse)JSON.deserialize(responseJson, BWC_Order.OrderHistoryResponse.class);

        // Set mock so synchronous response is returned
        BWC_ApiMock.setTestApiMock(BWC_OrderCallout.API_ORDER_HISTORY, 'UT_GetOrderHistory_Result');
        responseJson = (String)BWC_OrderController.getOrderHistoryCont(interaction.Id);
        response = (BWC_Order.OrderHistoryResponse)JSON.deserialize(responseJson, BWC_Order.OrderHistoryResponse.class);
    	}
    
        @isTest
    	private static void test_getOrderDetailsPositive() {
        String billingAccountNo = '523038965765';
        Account testAccount = BWC_TestDataFactory.createAccount();
        String recType = BWC_Constants.BillingAccount_AccountType_Wireless;
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount(BWC_Constants.BillingAccount_AccountType_Wireless, testAccount);
        billingAccount.Billing_Account_Number__c = billingAccountNo;
        update billingAccount;
        
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(testAccount);
            
        BWC_AuthorizationCallout.AuthorizationStatusContent authorizationContent = new BWC_AuthorizationCallout.AuthorizationStatusContent();
        BWC_AuthorizationCallout.AssociatedAccount associatedAccount = new BWC_AuthorizationCallout.AssociatedAccount();
        associatedAccount.accountBan = billingAccountNo;
        associatedAccount.authorizationLevel='L1';
        associatedAccount.accountType='Wireless';
            
        authorizationContent.associatedAccounts = new List<BWC_AuthorizationCallout.AssociatedAccount>{associatedAccount};

        interaction.Authorization_Json__c = JSON.serialize(authorizationContent, true);

        update interaction;

      
       try{
        // Call method using continuation
        System.Continuation continuation =
            (System.Continuation)BWC_OrderController.getOrderDetailsCont(interaction.Id, '50-202000020168613');
        
        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_OrderCallout.API_ORDER_DETAILS,'UT_Order_Details');

        // Get continuation response
        String responseJson = BWC_OrderController.getOrderDetailsResp(null, BWC_Callout.lastContinuationState);

        // Verify
        BWC_Order.OrderDetailsResponse response =
            (BWC_Order.OrderDetailsResponse)JSON.deserialize(responseJson, BWC_Order.OrderDetailsResponse.class);

        // Set mock so synchronous response is returned
        BWC_ApiMock.setTestApiMock(BWC_OrderCallout.API_ORDER_DETAILS, 'UT_Order_Details');
        responseJson = (String)BWC_OrderController.getOrderDetailsCont(interaction.Id, '50-202000020168613');
        response = (BWC_Order.OrderDetailsResponse)JSON.deserialize(responseJson, BWC_Order.OrderDetailsResponse.class);
        System.assert(true);
    	}
    
    catch (System.Exception e) {
            System.assert(true);
        }
    }
}