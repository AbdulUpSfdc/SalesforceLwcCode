@IsTest
private class BWC_CaseMilestoneEventTrigHandler_Test {
    @IsTest(seeAllData=true)
    static void testUpdateTargetDate() {
        // Create test case and event
        Case testCase = TestData_Case.generateCaseForAdjustment();
        Case_Milestone_Event__e milestoneEvent = new Case_Milestone_Event__e(Case_ID__c = testCase.Id);

        // Update Case to fire trigger
        testCase.Type = 'Billing | Adjustment';
        testCase.CaseAction__c = 'Adjustment Wireless | Billing Adjustment - HLA';
        testCase.EntitlementId = BWC_SLA_Entitlement.handleSLA(testCase.Type);
        update testCase;

        // Publish test event
        Test.startTest();
        Database.SaveResult saveResult = EventBus.publish(milestoneEvent);
        Test.stopTest();

        // Verify SaveResult value
        System.assertEquals(true, saveResult.isSuccess(), 'SaveResult not successful.');
    }
}