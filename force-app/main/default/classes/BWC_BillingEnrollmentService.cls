public with sharing class BWC_BillingEnrollmentService {
    

    //TODO: Add 3 params from the example request
    public static List<BWC_BillingEnrollment.BillingEnrollmentStatusResponse> getPaperlessStatus(String ban, String accountType, String status){


        if(String.isEmpty(accountType)){
            throw new BWC_Exception('No accountType was specified');
        }
        if(String.isEmpty(status)){
            throw new BWC_Exception('No status was specified');
        }
        if(String.isEmpty(ban)){
            throw new BWC_Exception('No ban was specified');
        }

        BWC_BillingEnrollment.BillingEnrollmentStatusRequest request = new BWC_BillingEnrollment.BillingEnrollmentStatusRequest();
        request.ban = ban;
        request.accountType = accountType;
        request.status = status;

        List<BWC_BillingEnrollment.BillingEnrollmentStatusResponse> response = BWC_BillingEnrollmentCallout.getPaperlessStatus(new List<BWC_BillingEnrollment.BillingEnrollmentStatusRequest>{request});

        return response;
    }
}