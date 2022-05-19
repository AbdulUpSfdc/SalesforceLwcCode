@IsTest
private class BWC_Case_Feedback_Trigger_Helper_Test {
    @IsTest
    static void testCaseIssueDescMask() {
        // Creating test data
        Case testCase = TestData_Case.generateCaseForAdjustment();

        Case_Feedback__c feedback = new Case_Feedback__c(
            Case__c = testCase.Id,
            Case_Issue_Description__c = '123-45-6789',
            Case_Issue_Reason__c = 'Should not require case'
        );
        insert feedback;

        // Verifying results
        List<Case_Feedback__c> feedbackList = [SELECT Id, Case_Issue_Description__c FROM Case_Feedback__c LIMIT 1];
        System.assert(
            feedbackList[0].Case_Issue_Description__c != feedback.Case_Issue_Description__c,
            'Masking did not fire.'
        );
    }
}