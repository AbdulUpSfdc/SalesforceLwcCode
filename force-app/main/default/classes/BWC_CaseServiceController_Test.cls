@isTest
public with sharing class BWC_CaseServiceController_Test {
    @isTest
    private static void testPositiveGetCaseById() {
        // Generating and wrapping response
        Case testCase = TestData_Case.generateCase();
        String wrapperJson = BWC_CaseServiceController.getCaseById(testCase.Id);
        Bwc_CaseServiceController.CaseResponseWrapper wrapper = (Bwc_CaseServiceController.CaseResponseWrapper) JSON.deserialize(
            wrapperJson,
            Bwc_CaseServiceController.CaseResponseWrapper.class
        );

        // Checking if success
        System.assertEquals(wrapper.success, true);
        System.assertEquals(wrapper.caseRecord.Id, testCase.Id);
    }

    @isTest
    private static void testNegativeGetCaseById() {
        // Generating and wrapping response
        Case testCase = TestData_Case.generateCase();
        Id fakeId = Id.valueOf('001xa000003DIlo');
        String wrapperJson = BWC_CaseServiceController.getCaseById(fakeId);
        Bwc_CaseServiceController.CaseResponseWrapper wrapper = (Bwc_CaseServiceController.CaseResponseWrapper) JSON.deserialize(
            wrapperJson,
            Bwc_CaseServiceController.CaseResponseWrapper.class
        );

        // Checking if failed
        System.assertEquals(wrapper.success, false);
        System.assert(wrapper.message != null);
    }
}