/*
    Service API for getting Add Ons for a billing account.
*/
public with sharing class BWC_AddOnsService {

    public class GetAddOnsService extends BWC_InteractionServiceBase{

        public List<BWC_AddOns.AddOnsRequest> request;
        public BWC_AddOns.AddOnsResponse response;

         /*
            Construct the service object from caller arguments.
        */
        public GetAddOnsService(Id recordId,Id InteractionId) {

            super(InteractionId,recordId);
            this.buildRequest();
        }

        public void buildRequest() {

            List<BWC_AddOns.AddOnsRequest> requests = new List<BWC_AddOns.AddOnsRequest>();

                requests.add(new BWC_AddOns.AddOnsRequest(this.billingAccount.Billing_Account_Number__c, 
                this.billingAccount.Billing_Account_Number__c,
                this.billingAccount.Account_Type__c));

            this.callout = new BWC_AddOnsCallout.GetAddOnsCallout(requests);             
        }
        /*
            Builds and returns final response.
        */
         public override Object buildResponse() {

            this.response = (BWC_AddOns.AddOnsResponse)this.callout.getResponse();
            return this.response;
        }
       
     }
}