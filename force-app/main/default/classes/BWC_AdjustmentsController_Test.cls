/*
    Unit test coverage for BWC_AdjustmentsController.
*/
@isTest
public with sharing class BWC_AdjustmentsController_Test {
    
    private static String ATTUID = 'ab102x';

    @TestSetup
    static void makeData(){

        User u = [SELECT Id FROM User where Id=:UserInfo.getUserId() LIMIT 1];

        u.ATTUID__c = ATTUID;

        update u;

        SOA_Level__c soaLevel = BWC_TestDataFactory.createSOA('Centers','Collections','Collections','Level 1','Wireless',100);
        insert soaLevel;

        Employee__c e = BWC_TestDataFactory.createEmployeeWithSOA(soaLevel, ATTUID, UserInfo.getUserId());
        e.SFProfileId__c = 'test profile';
        insert e;
    }
    
    @isTest
    private static void test_getPostedAdjustments() {

        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('L1', 'PASSCODE');

        List<BWC_Adjustments.PostedAdjustmentsRequest> requests = new List<BWC_Adjustments.PostedAdjustmentsRequest>();
        requests.add(new BWC_Adjustments.PostedAdjustmentsRequest());

        // Call method using continuation
        System.Continuation continuation = 
            (System.Continuation) BWC_AdjustmentsController.getPostedAdjustmentsCont(
                interaction.id, 
                JSON.serialize(requests)
        );

        // Set Mock Response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_AdjustmentsCallout.API_POSTED_ADJUSTMENTS, 'UT_Posted_Adjustments');

        // Get continuation response
        String responseJson = BWC_AdjustmentsController.getPostedAdjustmentsResp(null, BWC_Callout.lastContinuationState);

        // Verify
        BWC_Adjustments.PostedAdjustmentsResponse response = 
            (BWC_Adjustments.PostedAdjustmentsResponse) JSON.deserialize(responseJson, BWC_Adjustments.PostedAdjustmentsResponse.class);

        // Set mock so synchronous response is returned
        BWC_ApiMock.setTestApiMock(BWC_AdjustmentsCallout.API_POSTED_ADJUSTMENTS, 'UT_Posted_Adjustments');

        responseJson = (String) BWC_AdjustmentsController.getPostedAdjustmentsCont(
            interaction.id, 
            JSON.serialize(requests)
        );

        response = 
            (BWC_Adjustments.PostedAdjustmentsResponse) JSON.deserialize(responseJson, BWC_Adjustments.PostedAdjustmentsResponse.class);
    }

    @isTest
    private static void test_getPendingAdjustments() {

        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('L1', 'PASSCODE');
        
        List<BWC_Adjustments.PendingAdjustmentsRequest> requests = new List<BWC_Adjustments.PendingAdjustmentsRequest>();
        requests.add(new BWC_Adjustments.PendingAdjustmentsRequest());

        // Call method using continuation
        System.Continuation continuation = 
            (System.Continuation) BWC_AdjustmentsController.getPendingAdjustmentsCont(
                interaction.id, 
                JSON.serialize(requests)
        );

        // Set Mock Response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_AdjustmentsCallout.API_PENDING_ADJUSTMENTS, 'UT_Pending_Adjustments');

        // Get continuation response
        String responseJson = BWC_AdjustmentsController.getPendingAdjustmentsResp(null, BWC_Callout.lastContinuationState);

        // Verify
        BWC_Adjustments.PendingAdjustmentsResponse response = 
            (BWC_Adjustments.PendingAdjustmentsResponse) JSON.deserialize(responseJson, BWC_Adjustments.PendingAdjustmentsResponse.class);

        // Set mock so synchronous response is returned
        BWC_ApiMock.setTestApiMock(BWC_AdjustmentsCallout.API_PENDING_ADJUSTMENTS, 'UT_Pending_Adjustments');

        responseJson = (String) BWC_AdjustmentsController.getPendingAdjustmentsCont(
            interaction.id, 
            JSON.serialize(requests)
        );

        response = 
            (BWC_Adjustments.PendingAdjustmentsResponse) JSON.deserialize(responseJson, BWC_Adjustments.PendingAdjustmentsResponse.class);
    }

    @isTest
    private static void test_getCdeRecommendations() {

        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('L1', 'PASSCODE');

        BWC_Adjustments.CdeRecommendationsRequest requests = new BWC_Adjustments.CdeRecommendationsRequest();
        requests.product = new List<BWC_Adjustments.CdeProductRequest>();

        // Call method using continuation
        System.Continuation continuation = 
            (System.Continuation) BWC_AdjustmentsController.getCdeRecommendationsCont(
                interaction.id, 
                JSON.serialize(requests)
        );

        // Set Mock Response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_AdjustmentsCallout.API_CDE_RECOMMENDATIONS, 'UT_Cde_Recommendations');

        // Get continuation response
        String responseJson = BWC_AdjustmentsController.getCdeRecommendationsResp(null, BWC_Callout.lastContinuationState);

        // Verify
        BWC_Adjustments.CdeRecommendationsResponse response = 
            (BWC_Adjustments.CdeRecommendationsResponse) JSON.deserialize(responseJson, BWC_Adjustments.CdeRecommendationsResponse.class);

        // Set mock so synchronous response is returned
        BWC_ApiMock.setTestApiMock(BWC_AdjustmentsCallout.API_CDE_RECOMMENDATIONS, 'UT_Cde_Recommendations');

        responseJson = (String) BWC_AdjustmentsController.getCdeRecommendationsCont(
            interaction.id,
            JSON.serialize(requests)
        );

        response = 
            (BWC_Adjustments.CdeRecommendationsResponse) JSON.deserialize(responseJson, BWC_Adjustments.CdeRecommendationsResponse.class);
    }

    @isTest
    private static void test_postAdjustments() {

        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('L1', 'PASSCODE');

        Adjustment__c a = BWC_TestDataFactory.createAdjustment();

        BWC_Adjustments.PostAdjustmentsRequest request = new BWC_Adjustments.PostAdjustmentsRequest();
        request.accountNumber = '177057327797';

        // Set mock so synchronous response is returned
        BWC_ApiMock.setTestApiMock(BWC_AdjustmentsCallout.API_POST_ADJUSTMENTS, 'UT_Post_Adjustments');

        String responseJson = (String) BWC_AdjustmentsController.postAdjustments(
            interaction.id, 
            JSON.serialize(request)
        );

        BWC_Adjustments.PostAdjustmentsResponse response = 
            (BWC_Adjustments.PostAdjustmentsResponse) JSON.deserialize(responseJson, BWC_Adjustments.PostAdjustmentsResponse.class);
    }

    @isTest
    private static void test_reverseAdjustment() { 

        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('L1', 'PASSCODE');

        BWC_Adjustments.ReverseAdjustmentRequest request = new BWC_Adjustments.ReverseAdjustmentRequest();

        // Set mock so synchronous response is returned
        BWC_ApiMock.setTestApiMock(BWC_AdjustmentsCallout.API_REVERSE_ADJUSTMENT, 'UT_Reverse_Adjustment');

        String responseJson = (String) BWC_AdjustmentsController.reverseAdjustment(
            interaction.id, 
            JSON.serialize(request)
        );

        BWC_Adjustments.ReverseAdjustmentResponse response = 
            (BWC_Adjustments.ReverseAdjustmentResponse) JSON.deserialize(responseJson, BWC_Adjustments.ReverseAdjustmentResponse.class);
    }
}