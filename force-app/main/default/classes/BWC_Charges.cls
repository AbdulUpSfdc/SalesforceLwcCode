/*
    Shared Code for Charges API
*/
public with sharing class BWC_Charges {
 
    /*
        CreateCharge Wrappers
    */
    public class CreateChargeRequest {
        public String accountNumber;
        public String accountType;
        public String marketCode; 
        public String agentId;
        public List<ChargeInfo> chargeInfo;
    }

    public class ChargeInfo {
        public String chargeId;
        public String batchId; 
        public String chargeAmount; 
        public String chargeCode; 
        public String effectiveDate; 
        public String chargeLevel; 
        public String subscriberNumber;
        public String productType; 
        public String transactionId; 
        public String userBillText; 
    }

    public static final String DEFAULT_PRODUCT_TYPE = 'G';

    public class CreateChargeResponse extends BWC_Callout.CalloutResponse {
        public List<ChargeReturnInfo> chargeReturnInfo;
        public List<ChargeError> errors;
    }

    public class ChargeReturnInfo {
        public String chgSeqNo;
        public String batchId;
        public String applicationId; 
        public String transactionId; 
    }

    public class ChargeError {
        public String errorId;
        public String message;
        public List<ChargeErrorDetails> details;
    }

    public class ChargeErrorDetails {
        public String code;
        public String message;
    }

}