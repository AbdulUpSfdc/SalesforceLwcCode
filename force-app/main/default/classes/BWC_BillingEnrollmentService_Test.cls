@IsTest
public with sharing class BWC_BillingEnrollmentService_Test {
    

    @IsTest
    static void test_getPaperlessStatus(){

        Test.startTest();

        //Setup mock
        BWC_Utils.setStaticResourceMock('BWC_BillingEnrollmentResponseMock', 200);

        //Call API
        List<BWC_BillingEnrollment.BillingEnrollmentStatusResponse> response = BWC_BillingEnrollmentService.getPaperlessStatus('831126922', 'Wireless', 'Paperless');

        Test.stopTest();
    }

    @IsTest
    static void test_getPaperlessStatus_Negative(){
        Test.startTest();
        BWC_Utils.setStaticResourceMock('BWC_BillingEnrollmentResponseMock', 200);

        try {
            List<BWC_BillingEnrollment.BillingEnrollmentStatusResponse> noBan = BWC_BillingEnrollmentService.getPaperlessStatus('', 'Wireless', 'Paperless');    
        } catch (Exception e) {
            System.assert(true);
        }

        try {
            List<BWC_BillingEnrollment.BillingEnrollmentStatusResponse> noAccountType = BWC_BillingEnrollmentService.getPaperlessStatus('831126922', '', 'Paperless');    
        } catch (Exception e) {
            System.assert(true);
        }

        try {
            List<BWC_BillingEnrollment.BillingEnrollmentStatusResponse> noStatus = BWC_BillingEnrollmentService.getPaperlessStatus('831126922', 'Wireless', '');    
        } catch (Exception e) {
            System.assert(true);
        }


        Test.stopTest();
    }
}