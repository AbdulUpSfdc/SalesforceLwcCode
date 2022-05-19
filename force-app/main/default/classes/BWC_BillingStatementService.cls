/*  
    Service API for getting BillingStatement.
*/
public with sharing class BWC_BillingStatementService {

    /*
        Service API to get BillingStatement for one billing account. Note -- 
        can expose API to get for multiple at one time, when needed.
    */
    public class GetBillingStatementsService extends BWC_InteractionServiceBase{

        public List<BWC_BillingStatement.BillingStatementRequest> request;
        public BWC_BillingStatement.BillingStatementResponse response;

         /*
            Construct the service object from caller arguments.
        */
        public GetBillingStatementsService(Id recordId,Id InteractionId) {

            super(InteractionId,recordId);
            this.buildRequest();

        }

        public void buildRequest() {

            // Build request list
            List<BWC_BillingStatement.BillingStatementRequest> requests = new List<BWC_BillingStatement.BillingStatementRequest>();
            if (this.billingAccount.Account_Type__c == BWC_Constants.BillingAccount_AccountType_Wireless) {
                requests.add(new BWC_BillingStatement.BillingStatementRequest(this.billingAccount.Billing_Account_Number__c, BWC_Constants.BillingAccount_AccountType_Wireless));
            }else {
                requests.add(new BWC_BillingStatement.BillingStatementRequest(this.billingAccount.Billing_Account_Number__c, BWC_BillingStatement.BILLINGACCOUNT_WIRELINE));
            }
            this.request = requests;
            this.callout = new BWC_BillingStatementCallout.getBillingStatementsCallout(requests);
           
        }

        /*
            Builds and returns final response.
        */
         public override Object buildResponse() {

            this.response = (BWC_BillingStatement.BillingStatementResponse)this.callout.getResponse();
            return this.response;

        }
       
     }

}