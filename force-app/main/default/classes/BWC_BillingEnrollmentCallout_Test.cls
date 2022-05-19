@IsTest
public with sharing class BWC_BillingEnrollmentCallout_Test {
    
    @IsTest
    static void test_getPaperlessStatus(){

        Test.startTest();

        List<BWC_BillingEnrollment.BillingEnrollmentStatusRequest> requests = new List<BWC_BillingEnrollment.BillingEnrollmentStatusRequest>();
        BWC_BillingEnrollment.BillingEnrollmentStatusRequest request = new BWC_BillingEnrollment.BillingEnrollmentStatusRequest();

        request.ban = '831126922';
        request.accountType = 'Wireless';
        request.status = 'Paperless';
        requests.add(request);

        BWC_Utils.setStaticResourceMock('BWC_BillingEnrollmentResponseMock', 200);
        BWC_BillingEnrollmentCallout.getPaperlessStatus(requests);

        Test.stopTest();
    }

    @IsTest
    static void test_getPaperlessStatus_emptyParam(){
        Test.startTest();

        Boolean wasExceptionThrown = false;

        List<BWC_BillingEnrollment.BillingEnrollmentStatusRequest> requests = new List<BWC_BillingEnrollment.BillingEnrollmentStatusRequest>();

        BWC_Utils.setStaticResourceMock('BWC_BillingEnrollmentResponseMock', 200);
        try{
            BWC_BillingEnrollmentCallout.getPaperlessStatus(requests);
        }catch(Exception e){
            wasExceptionThrown = true;
        }

        System.assert(wasExceptionThrown);
        

        Test.stopTest();
    }

    @IsTest
    static void test_getPaperlessStatus_negative(){
        Test.startTest();

        Boolean wasExceptionThrown = false;

        List<BWC_BillingEnrollment.BillingEnrollmentStatusRequest> requests = new List<BWC_BillingEnrollment.BillingEnrollmentStatusRequest>();
        BWC_Utils.setStaticResourceMock('BWC_BillingEnrollmentResponseMock', 400);

        try{
            BWC_BillingEnrollmentCallout.getPaperlessStatus(requests);
        }catch(Exception e){
            wasExceptionThrown = true;
        }

        System.assert(wasExceptionThrown);
        

        Test.stopTest();
    }
}