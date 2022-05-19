public with sharing class BWC_AccountDetails {

    // We send a list of this class
    public class AccountDetailsRequest {
        public String accountNumber;
        public String serviceType;

        public AccountDetailsRequest(String accountNumber, String serviceType){
            this.accountNumber = accountNumber;
            this.serviceType = serviceType;
        }

    }

    public class AccountDetailsResponse extends BWC_Callout.CalloutResponse {
        public Individual individuals;
    }

    public class Individual {
        public String id;
        public List<Accounts> accounts;
    }

    public class Accounts {
        public String id;
        public String serviceType;
        public Details details;
    }

    public class Details {
        public String productName360;
        public String serviceNumber;
        public BWC_Callout.CalloutError error;
    }

}