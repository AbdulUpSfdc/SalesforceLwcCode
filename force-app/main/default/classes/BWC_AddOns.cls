/*
    Shared code for AddOns api.
*/
public with sharing class BWC_AddOns {
    /*
        Request and response wrappers.
    */
    public class AddOnsRequest {

        public String customerId;
        public String accountId;
        public String accountType;
        
        public AddOnsRequest(String customerId, String accountId, String accountType) {
            this.customerId = customerId;
            this.accountId = accountId;
            this.accountType = accountType;
        }

    }

    public class AddOnsResponse extends BWC_Callout.CalloutResponse{

        public List<Accounts> accounts;
                
    }

    public class Addons {
        public String title;
        public String monthlyCost;
        public String description;
        public String userId;
    }

    public class Accounts {
        public String accountType;
        public String ban;
        public List<Addons> addons;
        public Error error;
    }

    public class Error {
        public String node;
        public Integer code;
        public String message;
        public String description;
        public String transactionId;
        public String idpTraceId;
    }
}