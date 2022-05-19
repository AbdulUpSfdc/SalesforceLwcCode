@IsTest
public with sharing class BWC_UnifiedSearchController_Test {

    @IsTest
    static void unifiedSearchOneResult(){

        Test.startTest();

        Interaction__c interaction = BWC_TestDataFactory.createNewInteraction();

        BWC_UnifiedSearch.UnifiedSearchRequest request =  new BWC_UnifiedSearch.UnifiedSearchRequest();
        request.phoneNumber = '1231231231';
        String requestJson = JSON.serialize(request, true);

        System.Continuation continuation = (System.Continuation) BWC_UnifiedSearchController.customerSearchCont(interaction.Id, requestJson);

        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_UnifiedSearchCallout.API_UNIFIED_SEARCH, 'UT_UnifiedSearch_SingleResult');

        String responseJson = BWC_UnifiedSearchController.customerSearchResp(null, BWC_Callout.lastContinuationState);

        BWC_UnifiedSearch.UnifiedSearchResponse response = (BWC_UnifiedSearch.UnifiedSearchResponse) JSON.deserialize(responseJson, BWC_UnifiedSearch.UnifiedSearchResponse.class);

        System.assertEquals(1, response.accountResponseCount);
        System.assertEquals(0, response.individuals.size());

        BWC_ApiMock.setTestApiMock(BWC_UnifiedSearchCallout.API_UNIFIED_SEARCH, 'UT_UnifiedSearch_SingleResult');

        responseJson = (String) BWC_UnifiedSearchController.customerSearchCont(interaction.Id, requestJson);
        response = (BWC_UnifiedSearch.UnifiedSearchResponse) JSON.deserialize(responseJson, BWC_UnifiedSearch.UnifiedSearchResponse.class);

        System.assertEquals(1, response.accountResponseCount);
        System.assertEquals(0, response.individuals.size());

        Test.stopTest();

    }

    @IsTest
    static void unifiedSearchNoResults(){

        Test.startTest();
        Interaction__c interaction = BWC_TestDataFactory.createNewInteraction();

        BWC_UnifiedSearch.UnifiedSearchRequest request =  new BWC_UnifiedSearch.UnifiedSearchRequest();
        request.phoneNumber = '1231231231';
        String requestJson = JSON.serialize(request, true);

        System.Continuation continuation = (System.Continuation) BWC_UnifiedSearchController.customerSearchCont(interaction.Id, requestJson);

        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_UnifiedSearchCallout.API_UNIFIED_SEARCH, 'UT_UnifiedSearch_NoResults');

        String responseJson = BWC_UnifiedSearchController.customerSearchResp(null, BWC_Callout.lastContinuationState);

        BWC_UnifiedSearch.UnifiedSearchResponse response = (BWC_UnifiedSearch.UnifiedSearchResponse) JSON.deserialize(responseJson, BWC_UnifiedSearch.UnifiedSearchResponse.class);

        System.assertEquals(0, response.accountResponseCount);
        System.assertEquals(0, response.individuals.size());

        BWC_ApiMock.setTestApiMock(BWC_UnifiedSearchCallout.API_UNIFIED_SEARCH, 'UT_UnifiedSearch_NoResults');

        responseJson = (String) BWC_UnifiedSearchController.customerSearchCont(interaction.Id, requestJson);
        response = (BWC_UnifiedSearch.UnifiedSearchResponse) JSON.deserialize(responseJson, BWC_UnifiedSearch.UnifiedSearchResponse.class);

        System.assertEquals(0, response.accountResponseCount);
        System.assertEquals(0, response.individuals.size());
        Test.stopTest();

    }

    @IsTest
    static void unifiedSearchMultipleResults(){

        Test.startTest();

        Interaction__c interaction = BWC_TestDataFactory.createNewInteraction();

        BWC_UnifiedSearch.UnifiedSearchRequest request =  new BWC_UnifiedSearch.UnifiedSearchRequest();
        request.phoneNumber = '1231231231';
        String requestJson = JSON.serialize(request, true);

        System.Continuation continuation = (System.Continuation) BWC_UnifiedSearchController.customerSearchCont(interaction.Id, requestJson);

        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_UnifiedSearchCallout.API_UNIFIED_SEARCH, 'UT_UnifiedSearch_MultipleResult');

        String responseJson = BWC_UnifiedSearchController.customerSearchResp(null, BWC_Callout.lastContinuationState);

        BWC_UnifiedSearch.UnifiedSearchResponse response = (BWC_UnifiedSearch.UnifiedSearchResponse) JSON.deserialize(responseJson, BWC_UnifiedSearch.UnifiedSearchResponse.class);

        System.assertEquals(2, response.accountResponseCount);
        System.assertEquals(0, response.individuals.size());

        BWC_ApiMock.setTestApiMock(BWC_UnifiedSearchCallout.API_UNIFIED_SEARCH, 'UT_UnifiedSearch_MultipleResult');

        responseJson = (String) BWC_UnifiedSearchController.customerSearchCont(interaction.Id, requestJson);
        response = (BWC_UnifiedSearch.UnifiedSearchResponse) JSON.deserialize(responseJson, BWC_UnifiedSearch.UnifiedSearchResponse.class);

        System.assertEquals(2, response.accountResponseCount);
        System.assertEquals(0, response.individuals.size());
        Test.stopTest();
    }

    @IsTest
    static void unifiedSearchServerError(){

        Test.startTest();

        Interaction__c interaction = BWC_TestDataFactory.createNewInteraction();

        BWC_UnifiedSearch.UnifiedSearchRequest request =  new BWC_UnifiedSearch.UnifiedSearchRequest();
        request.phoneNumber = '1231231231';
        String requestJson = JSON.serialize(request, true);

        System.Continuation continuation = (System.Continuation) BWC_UnifiedSearchController.customerSearchCont(interaction.Id, requestJson);

        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_UnifiedSearchCallout.API_UNIFIED_SEARCH, 'UT_UnifiedSearch_Server_Error');

        try {
            String responseJson = BWC_UnifiedSearchController.customerSearchResp(null, BWC_Callout.lastContinuationState);
            System.assert(false, 'Exception not thrown');
        } catch (Exception e) {
            System.assert(true);
        }

        Test.stopTest();

    }

    @IsTest
    static void linkInteractionWithAccountTest(){

        Test.startTest();

        Account acct = BWC_TestDataFactory.createAccount();
        Interaction__c interaction = BWC_TestDataFactory.createNewInteraction();
        String recType = BWC_Constants.BillingAccount_AccountType_Wireless;
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount(recType,acct);

        interaction.Billing_Account__c = billingAccount.Id;
        update interaction;

        BWC_UnifiedSearchController.linkInteractionWithAccount(interaction.Id, acct.Id, true);

        Test.stopTest();

    }

    @IsTest
    static void linkInteractionWithAccountTestNegative(){

        Test.startTest();

        Account acct = BWC_TestDataFactory.createAccount();
        Interaction__c interaction = BWC_TestDataFactory.createNewInteraction();

        // Deleting account record to provoke an error while trying to update the account and interaction
        List<Customer_Account_Relation__c> relations = [SELECT Id FROM Customer_Account_Relation__c WHERE Customer__c =:acct.Id];
        delete relations;
        delete acct;

        try {
            BWC_UnifiedSearchController.linkInteractionWithAccount(interaction.Id, acct.Id, true);
            System.assert(false, 'Exception not thrown');
        } catch (Exception e) {
            System.assert(true);
        }


        Test.stopTest();
    }
}