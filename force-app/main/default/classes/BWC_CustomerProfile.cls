/*
    Types for API_CUSTOMER_PROFILE.
*/
public with sharing class BWC_CustomerProfile {

    public class PasswordResetRequest {
        public String sourceIPAddress;
        public String handle;
        public String domain;
        public DeliveryMethod deliveryMethod;
        public String legacyDTVid;
    }

    public class DeliveryMethod {
        public String deliveryMethodType;   // E or S
        public MethodSMS methodSMS;
        public MethodAO methodAO;
        public MethodEmail methodEmail;
    }

    public class MethodSMS {
        public String valueSMS;
    }

    public class MethodAO {
        public String valueAO;
    }

    public class MethodEmail {
        public String valueEmail;
    }

    public class PasswordResetResponse {
        public String appStatusMsg;
        public String appInfo;
        public String transactionName;
        public String appStatusCode;
    }

}