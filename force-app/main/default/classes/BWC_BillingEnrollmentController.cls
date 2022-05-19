public with sharing class BWC_BillingEnrollmentController {

    @AuraEnabled
    public static String getPaperlessStatus(String ban, String accountType, String status){

        BillingEnrollmentResponseWrapper responseWrapper = new BillingEnrollmentResponseWrapper();

        try{
            BWC_BillingEnrollment.BillingEnrollmentStatusResponse response = BWC_BillingEnrollmentService.getPaperlessStatus(ban, accountType, status)[0];
            responseWrapper.success = true;
            responseWrapper.response = response;
        }catch(Exception e){
            responseWrapper.success = false;
            responseWrapper.message = e.getMessage();
            BWC_ExceptionUtils.handleException(e, 'ban: '+ban, null);
        }

        //LWC will parse JSON
        return responseWrapper.serialize();
        
    }

    public class BillingEnrollmentResponseWrapper extends BWC_ResponseWrapper{
        public BWC_BillingEnrollment.BillingEnrollmentStatusResponse response;
    }
}