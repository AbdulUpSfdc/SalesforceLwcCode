@IsTest
public with sharing class BWC_BillingEnrollmentController_Test {
    

    @IsTest
    public static void test_getPaperlessStatus(){

        Test.startTest();

        //Setup mock
        BWC_Utils.setStaticResourceMock('BWC_BillingEnrollmentResponseMock', 200);

        //Call API
        String responseJson = BWC_BillingEnrollmentController.getPaperlessStatus('831126922', 'Wireless', 'Paperless');
        System.assertNotEquals(null, responseJson);

        Test.stopTest();
    }

    @IsTest
    public static void test_getPaperlessStatus_Negative(){
        Test.startTest();

        //Setup mock
        BWC_Utils.setStaticResourceMock('BWC_BillingEnrollmentResponseMock', 400);

        //Call API
        String responseJson = BWC_BillingEnrollmentController.getPaperlessStatus('831126922', 'Wireless', 'Paperless');
        System.assertNotEquals(null, responseJson);

        Test.stopTest();
    }
}