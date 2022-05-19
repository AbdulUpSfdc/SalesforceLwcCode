public with sharing class BWC_BillingEnrollment {
    
    public class BillingEnrollmentStatusRequest{
        public String ban;
        public String accountType;
        public String status;
    }

    public class BillingEnrollmentStatusResponse{
        public String ban;
        public String accountType;
        public String status;
        public BillingEnrollmentStatusContent content;
    }

    public class BillingEnrollmentStatusContent{
        public String returnCode;
        public String message; 
    }
}