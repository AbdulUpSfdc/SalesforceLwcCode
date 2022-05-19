@isTest
private class BWC_ProductSearchController_Test {

    @isTest
    private static void test_productSearch() {

        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('L1', 'PASSCODE');

        // Call method using continuation
        System.Continuation continuation = (System.Continuation)BWC_ProductSearchController.getProductsGroupedByServiceCont(interaction.Id, null, null);
        
        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_ProductSearchCallout.API_PRODUCT_SEARCH, 'UT_Product_Search_200');

        // Get continuation response
        BWC_ProductSearchResultWrapper response = BWC_ProductSearchController.getProductsGroupedByServiceResp(null, BWC_Callout.lastContinuationState);

        // Verify
        System.assertEquals(true, response.success);
        System.assertEquals(4, response.services.size(), JSON.serialize(response.services, true));      // 4 services expected because there are 4 bans

        // Set mock so synchronous response is returned
        BWC_ApiMock.setTestApiMock(BWC_ProductSearchCallout.API_PRODUCT_SEARCH, 'UT_Product_Search_200');
        response = (BWC_ProductSearchResultWrapper)BWC_ProductSearchController.getProductsGroupedByServiceCont(interaction.Id, null, null);
        System.assertEquals(true, response.success);
        System.assertEquals(4, response.services.size(), JSON.serialize(response.services, true));

    }

    @isTest
    private static void test_productSearch_500() {

        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('L1', 'PASSCODE');

        // Call method using continuation
        System.Continuation continuation = (System.Continuation)BWC_ProductSearchController.getProductsGroupedByServiceCont(interaction.Id, null, null);
        
        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_ProductSearchCallout.API_PRODUCT_SEARCH, 'UT_Product_Search_500');
        BWC_Controller.THROW_TEST_AURA_EXCEPTION = true;

        // Get continuation response
        BWC_ProductSearchResultWrapper response = BWC_ProductSearchController.getProductsGroupedByServiceResp(null, BWC_Callout.lastContinuationState);

        // Verify
        System.assertEquals(false, response.success);

        // Set mock so synchronous response is returned
        BWC_ApiMock.setTestApiMock(BWC_ProductSearchCallout.API_PRODUCT_SEARCH, 'UT_Product_Search_500');
        response = (BWC_ProductSearchResultWrapper)BWC_ProductSearchController.getProductsGroupedByServiceCont(interaction.Id, null, null);
        System.assertEquals(false, response.success);

    }

    @isTest
    private static void test_GetSOCCode() {

        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('L1', 'PASSCODE');

        // Call method using continuation
        System.Continuation continuation = (System.Continuation)BWC_ProductSearchController.getSOCCodeCont(interaction.Id, interaction.Billing_Account__c);
        
        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_ProductSearchCallout.API_PRODUCT_SEARCH, 'UT_Product_Search_200');

        // Get continuation response
        BWC_ProductSearchController.SOCCodeResultWrapper response = BWC_ProductSearchController.getSOCCodeResp(null, BWC_Callout.lastContinuationState);

        // Verify
        System.assertEquals(true, response.success);

        // Set mock so synchronous response is returned
        BWC_ApiMock.setTestApiMock(BWC_ProductSearchCallout.API_PRODUCT_SEARCH, 'UT_Product_Search_200');
        response = (BWC_ProductSearchController.SOCCodeResultWrapper)BWC_ProductSearchController.getSOCCodeCont(interaction.Id, interaction.Billing_Account__c);
        System.assertEquals(true, response.success);

    }

    @isTest
    private static void test_GetSOCCode_500() {

        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('L1', 'PASSCODE');

        // Call method using continuation
        System.Continuation continuation = (System.Continuation)BWC_ProductSearchController.getSOCCodeCont(interaction.Id, interaction.Billing_Account__c);
        
        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_ProductSearchCallout.API_PRODUCT_SEARCH, 'UT_Product_Search_500');

        // Get continuation response
        BWC_ProductSearchController.SOCCodeResultWrapper response = BWC_ProductSearchController.getSOCCodeResp(null, BWC_Callout.lastContinuationState);

        // Verify
        System.assertEquals(false, response.success);

        // Set mock so synchronous response is returned
        BWC_ApiMock.setTestApiMock(BWC_ProductSearchCallout.API_PRODUCT_SEARCH, 'UT_Product_Search_500');
        response = (BWC_ProductSearchController.SOCCodeResultWrapper)BWC_ProductSearchController.getSOCCodeCont(interaction.Id, interaction.Billing_Account__c);
        System.assertEquals(false, response.success);

    }

}