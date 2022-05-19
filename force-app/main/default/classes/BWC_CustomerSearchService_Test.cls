@isTest
public with sharing class BWC_CustomerSearchService_Test {

    @isTest
    private static void test_customerSearch_OneResult() {

        Interaction__c interaction = BWC_TestDataFactory.createNewInteraction();

        // Build request
        BWC_CustomerSearch.CustomerSearchRequest request = new BWC_CustomerSearch.CustomerSearchRequest();
        request.mode = 'banWithAccountType';
        request.ban = '325310161';
        request.accountType = 'wireless';

        // Set mock response
        BWC_ApiMock.setTestApiMock(BWC_CustomerSearchCallout.API_CUSTOMER_SEARCH, 'UT_CustomerSearch_SingleResult_200');

        // Call service
        BWC_CustomerSearch.CustomerSearchResponse response = BWC_CustomerSearchService.accountSearch(interaction.Id, request);

        // Verify
        System.assertEquals(1, response.accountResponseCount);      // 1 response expected
        System.assertEquals(0, response.accountResponses.size());   // Should NOT return responses because interaction is not authorized

    }

}