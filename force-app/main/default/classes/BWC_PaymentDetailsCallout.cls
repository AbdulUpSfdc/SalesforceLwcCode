/*
    Call Mulesoft to get payment details.
*/
public with sharing class BWC_PaymentDetailsCallout {

    public static final String API_PAYMENT_DETAILS = 'Payment_Details';

    public class GetPaymentDetailsCallout extends BWC_Callout {

        // Request and Response state
        List<BWC_PaymentDetails.PaymentDetailsRequest> request;
        BWC_PaymentDetails.PaymentDetailsResponses response;

        /*
            Construct the callout object from request.
        */
        public GetPaymentDetailsCallout(List<BWC_PaymentDetails.PaymentDetailsRequest> request) {

            this.setCallout(API_PAYMENT_DETAILS, request, null, null, null);

        }

        /*
            Returns BWC_PaymentDetails.PaymentDetailsResponses.
        */
        public override Object buildResponse() {

            // Response requires extra wrapper because API returns an array but we need root to be an object so it can extend BWC_Callout.Response
            this.response = new BWC_PaymentDetails.PaymentDetailsResponses();
            this.response.responses = (List<BWC_PaymentDetails.PaymentDetailsResponse>)this.deserialize(List<BWC_PaymentDetails.PaymentDetailsResponse>.class);
            this.response.setHttpInfo(this.httpRequest, this.httpResponse);

            return this.response;

        }

    }

}