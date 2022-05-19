/*
    Call Mulesoft to get  Billing Statement .
*/
public with sharing class BWC_BillingStatementCallout {

    public static final String BILLING_STATEMENT = 'Billing_Statement';

    /*
        Callout to get Billing Statement for requested accounts.
    */
    public class getBillingStatementsCallout extends BWC_Callout {
       
        // Request and Response state
        List<BWC_BillingStatement.BillingStatementRequest> request;
        BWC_BillingStatement.BillingStatementResponse response;

        /*
            Construct the callout object from request.
        */
        public getBillingStatementsCallout(List<BWC_BillingStatement.BillingStatementRequest> request) {

            this.setCallout(BILLING_STATEMENT, request, null, null, null);

        }

        /*
            Returns BWC_BillingStatement.BillingStatementResponse.
        */
        public override Object buildResponse() {

            // Response requires extra wrapper because API returns an array but we need root to be an object so it can extend BWC_Callout.Response
            this.response = (BWC_BillingStatement.BillingStatementResponse)this.deserialize(BWC_BillingStatement.BillingStatementResponse.class);
            return this.response;

        }

    } 
}