@IsTest
private class BWC_PostPendingAdjustmentSelector_Test {
    @IsTest
    static void testCreateJson() {
        // Creating test data
        Adjustment__c adjustment = BWC_TestDataFactory.createAdjustment();
        Set<Id> adjustmentIds = new Set<Id>();
        adjustmentIds.add(adjustment.Id);

        // Testing selector method
        String requestBody = BWC_PostPendingAdjustmentSelector.createAdjustmentObject(
            adjustmentIds
        );

        // Verifying result
        System.assert(requestBody != null);
    }
}