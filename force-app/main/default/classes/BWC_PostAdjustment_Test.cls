@IsTest(SeeAllData=true)
private class BWC_PostAdjustment_Test {
    @IsTest
    static void testSuccessfulPostAdjustment() {
        // Creating test data
        Adjustment__c adjustment = BWC_TestDataFactory.createAdjustment();
        adjustment.Status__c = 'Approved';
        update adjustment;
        Set<Id> adjustmentIds = new Set<Id>();
        adjustmentIds.add(adjustment.Id);

        // Getting request body
        String requestBody = BWC_PostPendingAdjustmentSelector.createAdjustmentObject(adjustmentIds);

        // Executing test
        BWC_ApiMock.setTestApiMock(BWC_AdjustmentsCallout.API_POST_ADJUSTMENTS, 'UT_Post_Adjustments');
        Test.startTest();
        System.enqueueJob(new BWC_PostAdjustment(requestBody, adjustmentIds));
        Test.stopTest();

        // Verifying adjustment results
        Adjustment__c adj = [SELECT Id, Status__c, Case__c FROM Adjustment__c WHERE Id = :adjustment.Id];
        System.assert(adj.Status__c == 'Posted', 'Adjustment test status not changed.');

        // Verifying Chatter results
        List<FeedItem> feedList = [SELECT Id, ParentID FROM FeedItem WHERE ParentId = :adj.Case__c];

        System.assert(feedList.size() > 0, 'Chatter post failed.');
    }

    @IsTest
    static void testFailedPostAdjustment() {
        // Creating test data
        Adjustment__c adjustment = BWC_TestDataFactory.createAdjustment();
        adjustment.Status__c = 'Approved';
        update adjustment;

        Set<Id> adjustmentIds = new Set<Id>();
        adjustmentIds.add(adjustment.Id);

        // Getting request body
        String requestBody = BWC_PostPendingAdjustmentSelector.createAdjustmentObject(adjustmentIds);

        // Executing test
        BWC_Utils.setStaticResourceMock('BWC_PostAdjustmentMockError', 400);
        Test.startTest();
        System.enqueueJob(new BWC_PostAdjustment(requestBody, adjustmentIds));
        Test.stopTest();

        // Verifying adjustment results
        Adjustment__c adj = [SELECT Id, Status__c, Case__c FROM Adjustment__c WHERE Id = :adjustment.Id];
        System.assert(adj.Status__c == 'Post Failed', 'Adjustment test status not changed.');

        // Verifying Chatter results
        List<FeedItem> feedList = [SELECT Id, ParentID FROM FeedItem WHERE ParentId = :adj.Case__c];

        System.assert(feedList.size() > 0, 'Chatter post failed.');
    }
}