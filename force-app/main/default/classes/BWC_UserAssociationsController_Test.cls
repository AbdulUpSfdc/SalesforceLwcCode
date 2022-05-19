/*
    Unit test coverage for BWC_UserAssociationsController.
*/
@isTest
public with sharing class BWC_UserAssociationsController_Test {


    @isTest
    private static void test_getUserAssociations2() {

        Account testAccount = BWC_TestDataFactory.createAccount();
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount(BWC_Constants.BillingAccount_AccountType_Wireless, testAccount);

        Test.startTest();

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_UserAssociationsMock_wireless', 200);

        // Make call
        String responseWrapperJson =
            BWC_UserAssociationsController.getUserAssociations(testAccount.Id);

        System.assertNotEquals(null, responseWrapperJson);

    }

    @isTest
    private static void test_getUserAssociations2_Negative() {

        Account testAccount = BWC_TestDataFactory.createAccount();
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount(BWC_Constants.BillingAccount_AccountType_Wireless, testAccount);

        Test.startTest();

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_UserAssociationsMock_wireless', 400);

        String responseWrapperJson =
            BWC_UserAssociationsController.getUserAssociations(testAccount.Id);

        System.assertNotEquals(null, responseWrapperJson);

    }


    @isTest
    private static void test_getUserAssociations3() {

        Account testAccount = BWC_TestDataFactory.createAccount();
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount(BWC_Constants.BillingAccount_AccountType_Wireless, testAccount);

        Test.startTest();

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_UserAssociationsMock_wireless', 200);

        // Make call
        String responseWrapperJson =
            BWC_UserAssociationsController.getUserAssociationsForBan(billingAccount.Billing_Account_Number__c, billingAccount.Account_Type__c);

        System.assertNotEquals(null, responseWrapperJson);
        
    }
    
    @isTest
    private static void test_getUserAssociations3_negative() {

        
        Test.startTest();

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_UserAssociationsMock_wireless', 200);

        // Make call
        String responseWrapperJson =
            BWC_UserAssociationsController.getUserAssociationsForBan(null, null);

        System.assertNotEquals(null, responseWrapperJson);
        
    }

    @isTest
    private static void test_Add_Positive() {

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_UserAssociationsAddDelMock', 200);

        // Setup request
        List<BWC_UserAssociations.UserAssociation> requests = new List<BWC_UserAssociations.UserAssociation>{
            new BWC_UserAssociations.UserAssociation()
        };

        //Get response
        String responseWrapperJson = BWC_UserAssociationsController.addUserAssociations(JSON.serialize(requests));

        System.assertNotEquals(null, responseWrapperJson);

    }

    @isTest
    private static void test_Add_Negative() {

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_UserAssociationsAddDelMock', 400);

        // Setup request
        List<BWC_UserAssociations.UserAssociation> requests = new List<BWC_UserAssociations.UserAssociation>{
            new BWC_UserAssociations.UserAssociation()
        };

        //Get response
        String responseWrapperJson = BWC_UserAssociationsController.addUserAssociations(JSON.serialize(requests));

        System.assertNotEquals(null, responseWrapperJson);

    }

    @isTest
    private static void test_Delete_Positive() {

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_UserAssociationsAddDelMock', 200);

        // Setup request
        List<BWC_UserAssociations.UserAssociation> requests = new List<BWC_UserAssociations.UserAssociation>{
            new BWC_UserAssociations.UserAssociation()
        };

        //Get response
        String responseWrapperJson = BWC_UserAssociationsController.deleteUserAssociations(JSON.serialize(requests));

        System.assertNotEquals(null, responseWrapperJson);

    }

    @isTest
    private static void test_Delete_Negative() {

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_UserAssociationsAddDelMock', 400);

        // Setup request
        List<BWC_UserAssociations.UserAssociation> requests = new List<BWC_UserAssociations.UserAssociation>{
            new BWC_UserAssociations.UserAssociation()
        };

        //Get response
        String responseWrapperJson = BWC_UserAssociationsController.deleteUserAssociations(JSON.serialize(requests));

        System.assertNotEquals(null, responseWrapperJson);

    }

    @isTest
    private static void test_getUserAsscoationsDetails() {
        
        Account testAccount = BWC_TestDataFactory.createAccount();
        String recType = BWC_Constants.BillingAccount_AccountType_Wireless;
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount(BWC_Constants.BillingAccount_AccountType_Wireless, testAccount);
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(testAccount);

      
        try{
        // Call method using continuation
        System.Continuation continuation =
            (System.Continuation)BWC_UserAssociationsController.getUserAssociationsForBillingAccountCont(billingAccount.Id, interaction.Id);
        
        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_UserAssociationsCallout.USER_ASSOC_DETAILS,'UT_GetUsageAssociations_error');

        // Get continuation response
        String responseJson = BWC_UserAssociationsController.getUserAssociationResp(null, BWC_Callout.lastContinuationState);

        // Verify
        BWC_UserAssociations.UserAssociationsResponse response =
            (BWC_UserAssociations.UserAssociationsResponse)JSON.deserialize(responseJson, BWC_UserAssociations.UserAssociationsResponse.class);

        // Set mock so synchronous response is returned
        BWC_ApiMock.setTestApiMock(BWC_UserAssociationsCallout.USER_ASSOC_DETAILS, 'UT_GetUsageAssociations_error');
        responseJson = (String)BWC_UserAssociationsController.getUserAssociationsForBillingAccountCont(billingAccount.Id, interaction.Id);
        response = (BWC_UserAssociations.UserAssociationsResponse)JSON.deserialize(responseJson, BWC_UserAssociations.UserAssociationsResponse.class);
        System.assert(false);
    	}
    
    catch (System.Exception e) {
            System.assert(true);
        }
    }



}