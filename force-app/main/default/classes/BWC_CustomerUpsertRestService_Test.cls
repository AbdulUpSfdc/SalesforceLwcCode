@isTest
public with sharing class BWC_CustomerUpsertRestService_Test {

    @isTest
    private static void test_upsert() {

        // Get test search response
        List<BWC_CustomerSearch.AccountResponse> customerSearchResponses = 
            (List<BWC_CustomerSearch.AccountResponse>)JSON.deserialize(BWC_Utils.getStaticResourceBody('BWC_CustomerSearchMock_ban'), List<BWC_CustomerSearch.AccountResponse>.class);

        // Build request
        BWC_CustomerUpsertRestService.UpsertRequest request = new BWC_CustomerUpsertRestService.UpsertRequest();
        request.ctiCallIdentifier = 'Test';
        request.customerSearchResponse = customerSearchResponses[0];

        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(request));

        BWC_CustomerUpsertRestService.doPost();

        System.assertEquals(200, RestContext.response.statusCode);

    } 

    @isTest
    private static void test_upsert_negative() {

        RestContext.request = new RestRequest();

        // Null request body
        BWC_CustomerUpsertRestService.doPost();
        System.assertEquals(400, RestContext.response.statusCode);

        // Empty request body
        RestContext.request.requestBody = Blob.valueOf('');
        BWC_CustomerUpsertRestService.doPost();
        System.assertEquals(400, RestContext.response.statusCode);

        // Bad request body
        RestContext.request.requestBody = Blob.valueOf('not json');
        BWC_CustomerUpsertRestService.doPost();
        System.assertEquals(400, RestContext.response.statusCode);

        // Missing ctiCallIdentifier
        BWC_CustomerUpsertRestService.UpsertRequest request = new BWC_CustomerUpsertRestService.UpsertRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(request));
        BWC_CustomerUpsertRestService.doPost();
        System.assertEquals(400, RestContext.response.statusCode);

        // Missing search response
        request.ctiCallIdentifier = 'Test';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(request));
        BWC_CustomerUpsertRestService.doPost();
        System.assertEquals(400, RestContext.response.statusCode);

        // Error doing upserts
        List<BWC_CustomerSearch.AccountResponse> customerSearchResponses = 
            (List<BWC_CustomerSearch.AccountResponse>)JSON.deserialize(BWC_Utils.getStaticResourceBody('BWC_CustomerSearchMock_ban'), List<BWC_CustomerSearch.AccountResponse>.class);

        // Build request
        request = new BWC_CustomerUpsertRestService.UpsertRequest();
        request.ctiCallIdentifier = 'Test';
        request.customerSearchResponse = customerSearchResponses[0];
        request.customerSearchResponse.accountHeader = null;
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(request));
        BWC_CustomerUpsertRestService.doPost();
        System.assertEquals(400, RestContext.response.statusCode);

    }

}