/*
    Unit Test coverage for BWC_AdjustmentsService & BWC_AdjustmentsCallout.
*/
@isTest
public with sharing class BWC_AdjustmentsService_Test {

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
    private static void test_PostedAdjustmentsCallout() {

        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('L1', 'PASSCODE');
        
        // Set mock response
        BWC_ApiMock.setTestApiMock(BWC_AdjustmentsCallout.API_POSTED_ADJUSTMENTS, 'UT_Posted_Adjustments');

        List<BWC_Adjustments.PostedAdjustmentsRequest> requests = new List<BWC_Adjustments.PostedAdjustmentsRequest>();
        requests.add(new BWC_Adjustments.PostedAdjustmentsRequest());
        
        List<BWC_Adjustments.PostedAdjustment> response = BWC_AdjustmentsService.GetPostedAdjustments(interaction.id, requests);
        
    }

    @isTest
    private static void test_PendingAdjustmentsCallout() {

        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('L1', 'PASSCODE');
        
        // Set mock response
        BWC_ApiMock.setTestApiMock(BWC_AdjustmentsCallout.API_PENDING_ADJUSTMENTS, 'UT_Pending_Adjustments');

        List<BWC_Adjustments.PendingAdjustmentsRequest> requests = new List<BWC_Adjustments.PendingAdjustmentsRequest>();
        requests.add(new BWC_Adjustments.PendingAdjustmentsRequest());

        List<BWC_Adjustments.PendingAdjustmentsResponseNode> response = BWC_AdjustmentsService.GetPendingAdjustments(interaction.id, requests);
        
    }

    @isTest
    private static void test_CdeRecommendationsCallout() {

        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('L1', 'PASSCODE');
        
        // Set mock response
        BWC_ApiMock.setTestApiMock(BWC_AdjustmentsCallout.API_CDE_RECOMMENDATIONS, 'UT_Cde_Recommendations');

        BWC_Adjustments.CdeRecommendationsRequest request = new BWC_Adjustments.CdeRecommendationsRequest();
        request.product = new List<BWC_Adjustments.CdeProductRequest>();

        BWC_Adjustments.CdeRecommendationsResponse response = BWC_AdjustmentsService.GetCdeRecommendations(
            interaction.id, 
            request
        );
    }

    @isTest
    private static void test_PostAdjustmentsCallout() {

        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('L1', 'PASSCODE');
        
        Adjustment__c a = BWC_TestDataFactory.createAdjustment();

        // Set mock response
        BWC_ApiMock.setTestApiMock(BWC_AdjustmentsCallout.API_POST_ADJUSTMENTS, 'UT_Post_Adjustments');

        BWC_Adjustments.PostAdjustmentsRequest request = new BWC_Adjustments.PostAdjustmentsRequest();
        request.accountNumber = '177057327797';

        BWC_Adjustments.PostAdjustmentsResponse response = BWC_AdjustmentsService.postAdjustments(interaction.id, request);
        
    }

    @isTest
    private static void test_ReverseAdjustmentCallout() {

        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('L1', 'PASSCODE');
        
        // Set mock response
        BWC_ApiMock.setTestApiMock(BWC_AdjustmentsCallout.API_REVERSE_ADJUSTMENT, 'UT_Reverse_Adjustment');

        BWC_Adjustments.ReverseAdjustmentResponse response = BWC_AdjustmentsService.reverseAdjustment(interaction.id, new BWC_Adjustments.ReverseAdjustmentRequest());
        
    }

}