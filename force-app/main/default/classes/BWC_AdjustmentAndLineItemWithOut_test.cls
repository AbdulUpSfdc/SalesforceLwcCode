@isTest
private class BWC_AdjustmentAndLineItemWithOut_test {
    @isTest
    static void testAdjWithLineItems() {
        User managerOne = BWC_TestDataFactory.createEmployeeWithManager();

        System.runAs(managerOne) {
            // Creating test data and calling class
            Case testCase = TestData_Case.generateCaseForAdjustment();

            Test.startTest();
            BWC_AdjustmentAndLineItemWithOutShareing.handleBillingAdjustmentCase(
                CaseConstants.detailRecordWithListOfLineItems,
                testCase
            );
            Test.stopTest();

            // Check if adjustment was created
            Adjustment__c adj = [SELECT Id, Status__c FROM Adjustment__c LIMIT 1];
            System.assert(adj != null, 'Adjustment is null.');

            // Check adjustment line items
            List<Adjustment_Line_Item__c> adjLines = [SELECT Id FROM Adjustment_Line_Item__c LIMIT 1];
            System.assert(adjLines.size() > 0, 'Adjustment line items is null.');
        }
    }

    @isTest
    static void testAdjWithOutLineItems() {
        User managerOne = BWC_TestDataFactory.createEmployeeWithManager();

        System.runAs(managerOne) {
            // Creating test data and calling class
            Case testCase = TestData_Case.generateCaseForAdjustment();

            Test.startTest();
            BWC_AdjustmentAndLineItemWithOutShareing.handleBillingAdjustmentCase(
                CaseConstants.detailRecordWithOutListOfLineItems,
                testCase
            );
            Test.stopTest();

            // Check if adjustment was created
            Adjustment__c adj = [SELECT Id, Status__c FROM Adjustment__c LIMIT 1];
            System.assert(adj != null, 'Adjustment is null.');
        }
    }
}