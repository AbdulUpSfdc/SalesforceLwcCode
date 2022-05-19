/*
    Unit test coverage for BWC_BillPdfViewerController.
*/
@isTest
public with sharing class BWC_BillPdfViewerController_Test {

    @testSetup static void setup() {
        PageReference pageRef = Page.BWCBillPdfViewer;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('product','Wireless');
        pageRef.getParameters().put('statementId','20180228-325310161-TLG-W');
    }

    @isTest
    private static void test_getBillPdf() {
        setup();
        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_BillingDetailsPDFMock', 200);

        BWC_BillPdfViewerController testPage = new BWC_BillPdfViewerController();
        PageReference p = testPage.getBillPdf();

        system.assertEquals(null, p);

    }

    @isTest
    private static void test_getBillPdf_ContentNull() {
        setup();
        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_BillingDetailsPDErrorMock', 200);

        BWC_BillPdfViewerController testPage = new BWC_BillPdfViewerController();
        testPage.getBillPdf();

        system.assert (ApexPages.getMessages().get(0).getDetail().contains('Error retrieving PDF:'));
    }

    @isTest
    private static void test_getBillPdf_PDFFalse() {
        setup();
        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_BillingDetailsPDFFalseMock', 200);

        BWC_BillPdfViewerController testPage = new BWC_BillPdfViewerController();
        testPage.getBillPdf();

        System.assert (ApexPages.getMessages().get(0).getDetail() == 'PDF not returned. Error Code: 101');
    }

    @isTest
    private static void test_getBillPdf_ProductNull() {

        PageReference pageRef = Page.BWCBillPdfViewer;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('statementId','20180228-325310161-TLG-W');

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_BillingDetailsPDFMock', 200);

        try{

            BWC_BillPdfViewerController testPage = new BWC_BillPdfViewerController();
            testPage.getBillPdf();

        }
        catch (BWC_Exception e) {

            system.assertEquals('Argument required: product', e.getMessage());

        }
    }
}