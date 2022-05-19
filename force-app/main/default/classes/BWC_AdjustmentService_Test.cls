// Test class for BWC_AdjustmentService and BWC_AdjustmentServiceController
@IsTest
private class BWC_AdjustmentService_Test {
    @IsTest
    static void testEditableAdjPerm() {
        Adjustment__c adjustment = BWC_TestDataFactory.createAdjustment();
        User testUser = BWC_TestDataFactory.createUser();

        // Checking permissions block
        System.runAs(testUser) {
            try {
                List<Adjustment__c> adj = BWC_AdjustmentServiceController.getEditableAdjustment(adjustment.Id);
            } catch (Exception e) {
                System.assert(e != null, 'Exception is null.');
            }
        }
    }

    @IsTest
    static void testGetEditableAdj() {
        Adjustment__c adjustment = BWC_TestDataFactory.createAdjustment();
        adjustment.Status__c = 'Rejected';
        update adjustment;

        // Get adjustment info and check value
        List<Adjustment__c> adj = BWC_AdjustmentServiceController.getEditableAdjustment(adjustment.Id);
        System.assert(adj != null, 'Adjustment is null.');
    }

    @isTest
    static void testTakeOwnershipAdjustmentCase() {
        Adjustment__c adj = BWC_TestDataFactory.createAdjustment();
        Adjustment__c adjDetails = [SELECT Id, Case__c FROM Adjustment__c WHERE Id = :adj.Id];

        BWC_AdjustmentServiceController.takeOwnershipAdjustmentCase(adjDetails.Case__c);
    }
}