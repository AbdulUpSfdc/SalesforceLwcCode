public with sharing class BWC_CustomerAccountService {

    public class GetCustomerAccountService extends BWC_InteractionServiceBase{

        public BWC_CustomerAccount.AccountDetailsResponse response;
         /*
            Construct the service object from caller arguments.
        */
        public GetCustomerAccountService(Id recordId,Id InteractionId) {
            super(InteractionId,recordId);
            this.buildRequest();
        }

        public void buildRequest() {
            this.callout = new BWC_CustomerAccountCallout.GetCustomerAccountCallout(this.billingAccount.Billing_Account_Number__c,this.billingAccount.Account_Type__c); 
        }

        /*
            Builds and returns final response.
        */
         public override Object buildResponse() {
            this.response = (BWC_CustomerAccount.AccountDetailsResponse)this.callout.getResponse();
            return this.response;
        }  
     }

    public static BWC_CustomerAccount.PutBillingInfoResponse putBillingInfo(String ban, String accountType, BWC_CustomerAccount.PutBillingInfoRequest billingInfo) {

        // Callout
        BWC_CustomerAccount.PutBillingInfoResponse response = BWC_CustomerAccountCallout.putBillingInfo(ban, accountType, billingInfo);
        return response;

    }

    public static BWC_CustomerAccount.UpdateAccountPasscodeResponse updateAccountPasscode(String ban, String accountType, BWC_CustomerAccount.UpdateAccountPasscodeRequest passcodeInfo) {

        // Callout
        BWC_CustomerAccount.UpdateAccountPasscodeResponse response = BWC_CustomerAccountCallout.updateAccountPasscode(ban, accountType, passcodeInfo);
        return response;

    }

}