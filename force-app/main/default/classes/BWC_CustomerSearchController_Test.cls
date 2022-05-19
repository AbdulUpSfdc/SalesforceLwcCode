@isTest
public with sharing class BWC_CustomerSearchController_Test {

    @isTest
    private static void test_customerSearch_OneResult() {

        Interaction__c interaction = BWC_TestDataFactory.createNewInteraction();

        // Build request
        BWC_CustomerSearch.CustomerSearchRequest request = new BWC_CustomerSearch.CustomerSearchRequest();
        request.mode = 'banWithAccountType';
        request.ban = '325310161';
        request.accountType = 'wireless';

        // Call method using continuation
        System.Continuation continuation = (System.Continuation)BWC_CustomerSearchController.accountSearchCont(interaction.Id, JSON.serialize(request, true));

        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_CustomerSearchCallout.API_CUSTOMER_SEARCH, 'UT_CustomerSearch_SingleResult_200');

        // Get continuation response
        String responseJson = BWC_CustomerSearchController.accountSearchResp(null, BWC_Callout.lastContinuationState);

        // Verify
        BWC_CustomerSearch.CustomerSearchResponse response =
            (BWC_CustomerSearch.CustomerSearchResponse)JSON.deserialize(responseJson, BWC_CustomerSearch.CustomerSearchResponse.class);
        System.assertEquals(1, response.accountResponseCount);      // 1 response expected
        System.assertEquals(0, response.accountResponses.size());   // Should NOT return responses because interaction is not authorized

        // Set mock so synchronous response is returned
        BWC_ApiMock.setTestApiMock(BWC_CustomerSearchCallout.API_CUSTOMER_SEARCH, 'UT_CustomerSearch_SingleResult_200');
        responseJson = (String)BWC_CustomerSearchController.accountSearchCont(interaction.Id, JSON.serialize(request, true));
        response =
            (BWC_CustomerSearch.CustomerSearchResponse)JSON.deserialize(responseJson, BWC_CustomerSearch.CustomerSearchResponse.class);
        System.assertEquals(1, response.accountResponseCount);      // 1 response expected
        System.assertEquals(0, response.accountResponses.size());   // Should NOT return responses because interaction is not authorized
    }

    @isTest
    private static void test_customerSearch_EmptyResult() {

        Interaction__c interaction = BWC_TestDataFactory.createNewInteraction();

        // Build request
        BWC_CustomerSearch.CustomerSearchRequest request = new BWC_CustomerSearch.CustomerSearchRequest();
        request.mode = 'banWithAccountType';
        request.ban = '325310161';
        request.accountType = 'wireless';

        // Call method using continuation
        System.Continuation continuation = (System.Continuation)BWC_CustomerSearchController.accountSearchCont(interaction.Id, JSON.serialize(request, true));

        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_CustomerSearchCallout.API_CUSTOMER_SEARCH, 'UT_CustomerSearch_EmptyResult_200');

        // Get continuation response
        String responseJson = BWC_CustomerSearchController.accountSearchResp(null, BWC_Callout.lastContinuationState);

        // Verify
        BWC_CustomerSearch.CustomerSearchResponse response =
            (BWC_CustomerSearch.CustomerSearchResponse)JSON.deserialize(responseJson, BWC_CustomerSearch.CustomerSearchResponse.class);
        System.assertEquals(0, response.accountResponseCount);      // No response expected
        System.assertEquals(0, response.accountResponses.size());   // Should NOT return responses because interaction is not authorized

        // Set mock so synchronous response is returned
        BWC_ApiMock.setTestApiMock(BWC_CustomerSearchCallout.API_CUSTOMER_SEARCH, 'UT_CustomerSearch_EmptyResult_200');
        responseJson = (String)BWC_CustomerSearchController.accountSearchCont(interaction.Id, JSON.serialize(request, true));
        response =
            (BWC_CustomerSearch.CustomerSearchResponse)JSON.deserialize(responseJson, BWC_CustomerSearch.CustomerSearchResponse.class);
        System.assertEquals(0, response.accountResponseCount);      // No response expected
        System.assertEquals(0, response.accountResponses.size());   // Should NOT return responses because interaction is not authorized

    }

    @isTest
    private static void test_customerSearch_MultiAddress() {

        Interaction__c interaction = BWC_TestDataFactory.createNewInteraction();

        // Build request
        BWC_CustomerSearch.CustomerSearchRequest request = new BWC_CustomerSearch.CustomerSearchRequest();
        request.mode = 'banWithAccountType';
        request.ban = '325310161';
        request.accountType = 'wireless';

        // Call method using continuation
        System.Continuation continuation = (System.Continuation)BWC_CustomerSearchController.accountSearchCont(interaction.Id, JSON.serialize(request, true));

        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_CustomerSearchCallout.API_CUSTOMER_SEARCH, 'UT_CustomerSearchMultiAddress_300');

        // Get continuation response
        String responseJson = BWC_CustomerSearchController.accountSearchResp(null, BWC_Callout.lastContinuationState);

        // Verify
        BWC_CustomerSearch.CustomerSearchResponse response =
            (BWC_CustomerSearch.CustomerSearchResponse)JSON.deserialize(responseJson, BWC_CustomerSearch.CustomerSearchResponse.class);
        System.assert(response.addressesResponse.addresses.size() > 1);

        // Set mock so synchronous response is returned
        BWC_ApiMock.setTestApiMock(BWC_CustomerSearchCallout.API_CUSTOMER_SEARCH, 'UT_CustomerSearchMultiAddress_300');
        responseJson = (String)BWC_CustomerSearchController.accountSearchCont(interaction.Id, JSON.serialize(request, true));
        response =
            (BWC_CustomerSearch.CustomerSearchResponse)JSON.deserialize(responseJson, BWC_CustomerSearch.CustomerSearchResponse.class);
        System.assert(response.addressesResponse.addresses.size() > 1);

    }

    @isTest
    private static void test_customerSearch_ServerError() {

        Interaction__c interaction = BWC_TestDataFactory.createNewInteraction();

        // Build request
        BWC_CustomerSearch.CustomerSearchRequest request = new BWC_CustomerSearch.CustomerSearchRequest();
        request.mode = 'banWithAccountType';
        request.ban = '325310161';
        request.accountType = 'wireless';

        // Call method using continuation
        System.Continuation continuation = (System.Continuation)BWC_CustomerSearchController.accountSearchCont(interaction.Id, JSON.serialize(request, true));

        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_CustomerSearchCallout.API_CUSTOMER_SEARCH, 'UT_CustomerSearch_500');
        BWC_Controller.THROW_TEST_AURA_EXCEPTION = true;

        try {
            // Get continuation response
            String responseJson = BWC_CustomerSearchController.accountSearchResp(null, BWC_Callout.lastContinuationState);
            System.assert(false, 'Exception not thrown.');
        }
        catch (AuraHandledException e) {
            System.assert(true);
        }

    }

    static testMethod void testResetInteraction(){
        Account acct = BWC_TestDataFactory.createAccount();
        String recType = BWC_Constants.BillingAccount_AccountType_Wireless;
        Billing_Account__c biilAcctObj = BWC_TestDataFactory.createBillingAccount(recType, acct);
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(acct);
        Plan__c planObj = BWC_TestDataFactory.createPlan(recType,biilAcctObj);
        Asset equipmentObj = BWC_TestDataFactory.createEquipment(recType, acct, biilAcctObj, null);

        Test.startTest();
        BWC_CustomerSearchController.resetInteraction(interaction.Id);
        Test.stopTest();

    }

    @IsTest
    static void test_CBRSearch_SingleResult(){

        Test.startTest();

        Interaction__c interaction = BWC_TestDataFactory.createNewInteraction();
        String phoneNumber = '325310161';

        // Call method using continuation
        System.Continuation continuation = (System.Continuation)BWC_CustomerSearchController.cbrSearchCont(interaction.Id, phoneNumber);

        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_CustomerSearchCallout.API_CBR_SEARCH, 'UT_CBR_Search_SingleResult');

        // Get continuation response
        String responseJson = BWC_CustomerSearchController.cbrSearchResp(null, BWC_Callout.lastContinuationState);

        // Verify
        BWC_CustomerSearch.CBRResponse response =
            (BWC_CustomerSearch.CBRResponse)JSON.deserialize(responseJson, BWC_CustomerSearch.CBRResponse.class);
        System.assertEquals(1, response.accounts.size());
        System.assertEquals(0, response.customers.size());
        System.assertEquals(true, response.performSearch);

        // Set mock so synchronous response is returned
        BWC_ApiMock.setTestApiMock(BWC_CustomerSearchCallout.API_CBR_SEARCH, 'UT_CBR_Search_SingleResult');
        responseJson = (String)BWC_CustomerSearchController.cbrSearchCont(interaction.Id, phoneNumber);
        response =
            (BWC_CustomerSearch.CBRResponse)JSON.deserialize(responseJson, BWC_CustomerSearch.CBRResponse.class);
        System.assertEquals(1, response.accounts.size());
        System.assertEquals(0, response.customers.size());
        System.assertEquals(true, response.performSearch);

        Test.stopTest();

    }

    @IsTest
    static void test_CBRSearch_MultipleResults(){

        Test.startTest();

        Interaction__c interaction = BWC_TestDataFactory.createNewInteraction();
        String phoneNumber = '325310161';

        // Call method using continuation
        System.Continuation continuation = (System.Continuation)BWC_CustomerSearchController.cbrSearchCont(interaction.Id, phoneNumber);

        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_CustomerSearchCallout.API_CBR_SEARCH, 'UT_CBR_Search_Multiple');

        // Get continuation response
        String responseJson = BWC_CustomerSearchController.cbrSearchResp(null, BWC_Callout.lastContinuationState);

        // Verify
        BWC_CustomerSearch.CBRResponse response =
            (BWC_CustomerSearch.CBRResponse)JSON.deserialize(responseJson, BWC_CustomerSearch.CBRResponse.class);
        System.assertEquals(2, response.accounts.size());
        System.assertEquals(0, response.customers.size());

        // Set mock so synchronous response is returned
        BWC_ApiMock.setTestApiMock(BWC_CustomerSearchCallout.API_CBR_SEARCH, 'UT_CBR_Search_Multiple');
        responseJson = (String)BWC_CustomerSearchController.cbrSearchCont(interaction.Id, phoneNumber);
        response =
            (BWC_CustomerSearch.CBRResponse)JSON.deserialize(responseJson, BWC_CustomerSearch.CBRResponse.class);
        System.assertEquals(2, response.accounts.size());
        System.assertEquals(0, response.customers.size());

        Test.stopTest();

    }

    @IsTest
    static void test_CBRSearch_EmptyResult(){

        Test.startTest();

        Interaction__c interaction = BWC_TestDataFactory.createNewInteraction();
        String phoneNumber = '325310161';

        // Call method using continuation
        System.Continuation continuation = (System.Continuation)BWC_CustomerSearchController.cbrSearchCont(interaction.Id, phoneNumber);

        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_CustomerSearchCallout.API_CBR_SEARCH, 'UT_CBR_Search_EmptyResult');

        // Get continuation response
        String responseJson = BWC_CustomerSearchController.cbrSearchResp(null, BWC_Callout.lastContinuationState);

        // Verify
        BWC_CustomerSearch.CBRResponse response =
            (BWC_CustomerSearch.CBRResponse)JSON.deserialize(responseJson, BWC_CustomerSearch.CBRResponse.class);
        System.assertEquals(0, response.customers.size());

        // Set mock so synchronous response is returned
        BWC_ApiMock.setTestApiMock(BWC_CustomerSearchCallout.API_CBR_SEARCH, 'UT_CBR_Search_EmptyResult');
        responseJson = (String)BWC_CustomerSearchController.cbrSearchCont(interaction.Id, phoneNumber);
        response =
            (BWC_CustomerSearch.CBRResponse)JSON.deserialize(responseJson, BWC_CustomerSearch.CBRResponse.class);
        System.assertEquals(0, response.customers.size());

        Test.stopTest();

    }

    @IsTest
    static void test_CBRSearch_ServerError(){

        Test.startTest();

        Interaction__c interaction = BWC_TestDataFactory.createNewInteraction();
        String phoneNumber = '325310161';

        // Call method using continuation
        System.Continuation continuation = (System.Continuation)BWC_CustomerSearchController.cbrSearchCont(interaction.Id, phoneNumber);

        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_CustomerSearchCallout.API_CBR_SEARCH, 'UT_CBR_Search_ServerError');
        BWC_Controller.THROW_TEST_AURA_EXCEPTION = true;

        try {
            // Get continuation response
            String responseJson = BWC_CustomerSearchController.cbrSearchResp(null, BWC_Callout.lastContinuationState);
            System.assert(false, 'Exception not thrown.');
        }
        catch (AuraHandledException e) {
            System.assert(true);
        }

        Test.stopTest();

    }
}