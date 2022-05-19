/*
    Unit test coverage for BWC_BillingDetailsController.
*/
@isTest
public with sharing class BWC_BillingDetailsController_Test {
    @isTest
    private static void test_getBillingDetails() {

        Test.startTest();

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_BillingDetailsMock', 200);

        // Make call
        String response =
            BWC_BillingDetailsController.getBillingDetails('Wireless','20180228-325310161-TLG-W');

        Test.stopTest();

        System.assertNotEquals(null, response);
    }

    @isTest
    private static void test_getBillPdf() {

        Test.startTest();

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_BillingDetailsPDFMock', 200);

        // Make call
        String response =
            BWC_BillingDetailsController.getBillPdf('Wireless','20180228-325310161-TLG-W');

        Test.stopTest();

        System.assertNotEquals(null, response);
    }

    @isTest
    private static void test_getBillingDetails_Negative() {

        Test.startTest();

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_BillingDetailsMock', 400);

        // Make call
        String response =
            BWC_BillingDetailsController.getBillingDetails(null,null);

        Test.stopTest();

        System.assertNotEquals(null, response);
    }

    @isTest
    private static void test_getBillPdf_Negative() {

        Test.startTest();

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_BillingDetailsPDFMock', 400);

        // Make call
        String response =
            BWC_BillingDetailsController.getBillPdf(null,null);

        Test.stopTest();

        System.assertNotEquals(null, response);
    }
}