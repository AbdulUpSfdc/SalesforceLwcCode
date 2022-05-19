@isTest
public with sharing class BWC_ProductUpsertRestService_Test {

    @isTest
    private static void test_upsert() {

        // Get test search response
        BWC_ProductSearch.ProductSearchResponse productSearchResponse = 
            (BWC_ProductSearch.ProductSearchResponse)JSON.deserialize(BWC_Utils.getStaticResourceBody('BWC_ProductSearchMock_wireless'), BWC_ProductSearch.ProductSearchResponse.class);

        // Create account and billing account
        Account testAccount = BWC_TestDataFactory.createAccount();
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount(BWC_Constants.BillingAccount_AccountType_Wireless, testAccount);
        billingAccount.Billing_Account_Number__c = productSearchResponse.accounts[0].ban;
        update billingAccount;

        // Build request
        BWC_ProductUpsertRestService.UpsertRequest request = new BWC_ProductUpsertRestService.UpsertRequest();
        request.accountId = testAccount.Id;
        request.ctiCallIdentifier = 'Test';
        request.productSearchResponse = productSearchResponse;

        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(request));

        BWC_ProductUpsertRestService.doPost();

        System.assertEquals(200, RestContext.response.statusCode);

    } 

    @isTest
    private static void test_upsert_negative() {

        // Get test search response
        BWC_ProductSearch.ProductSearchResponse productSearchResponse = 
            (BWC_ProductSearch.ProductSearchResponse)JSON.deserialize(BWC_Utils.getStaticResourceBody('BWC_ProductSearchMock_wireless'), BWC_ProductSearch.ProductSearchResponse.class);

        // Create account and billing account
        Account testAccount = BWC_TestDataFactory.createAccount();
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount(BWC_Constants.BillingAccount_AccountType_Wireless, testAccount);
        billingAccount.Billing_Account_Number__c = productSearchResponse.accounts[0].ban;
        update billingAccount;

        RestContext.request = new RestRequest();

        // Null request body
        BWC_ProductUpsertRestService.doPost();
        System.assertEquals(400, RestContext.response.statusCode);

        // Empty request body
        RestContext.request.requestBody = Blob.valueOf('');
        BWC_ProductUpsertRestService.doPost();
        System.assertEquals(400, RestContext.response.statusCode);

        // Bad request body
        RestContext.request.requestBody = Blob.valueOf('not json');
        BWC_ProductUpsertRestService.doPost();
        System.assertEquals(400, RestContext.response.statusCode);

        // Missing accountId
        BWC_ProductUpsertRestService.UpsertRequest request = new BWC_ProductUpsertRestService.UpsertRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(request));
        BWC_ProductUpsertRestService.doPost();
        System.assertEquals(400, RestContext.response.statusCode);

        // Missing ctiCallIdentifier
        request.accountId = testAccount.Id;
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(request));
        BWC_ProductUpsertRestService.doPost();
        System.assertEquals(400, RestContext.response.statusCode);

        // Missing search response
        request.ctiCallIdentifier = 'Test';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(request));
        BWC_ProductUpsertRestService.doPost();
        System.assertEquals(400, RestContext.response.statusCode);

        // Error doing upserts
        request.productSearchResponse = productSearchResponse;
        request.productSearchResponse.accounts[0].ban = null;
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(request));
        BWC_ProductUpsertRestService.doPost();
        System.assertEquals(400, RestContext.response.statusCode);

    }

}