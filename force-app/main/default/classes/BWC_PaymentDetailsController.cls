public with sharing class BWC_PaymentDetailsController {

    @AuraEnabled(continuation = true)
    public static Object getPaymentDetailsCont(String recordId, List<String> bans, List<String> topics) {
        
        try {

            BWC_PaymentDetailsService.GetPaymentDetailsService service = new BWC_PaymentDetailsService.GetPaymentDetailsService(recordId, bans, null, null, topics);
            Object response = service.callWithContinuation();

            if (response instanceof Continuation) {
                // It's a continuation, so need to set the method to call when continuation returns
                ((Continuation)response).continuationMethod = 'getPaymentDetailsResp';
                return response;
            }

            // No continuation needed, so return it directly
            BWC_PaymentDetails.PaymentDetailsResponses paymentDetailsResponse = (BWC_PaymentDetails.PaymentDetailsResponses)response;
            return paymentDetailsResponse.serialize();

        }
        catch (System.Exception e) {
            // Turn into an AuraHandledException containing embedded JSON that client can parse.
            throw BWC_Controller.handleException(e, 'Record Id:' + recordId + '; BANs:' + JSON.serialize(bans) + '; topics:' + JSON.serialize(topics));
        }

    }

    @AuraEnabled
    public static String getPaymentDetailsResp(List<String> labels, Object state) {

        try {

            BWC_PaymentDetailsService.GetPaymentDetailsService service = (BWC_PaymentDetailsService.GetPaymentDetailsService)state;
            BWC_PaymentDetails.PaymentDetailsResponses paymentDetailsResponse = (BWC_PaymentDetails.PaymentDetailsResponses)service.processContinuationResponse();
            return paymentDetailsResponse.serialize();

        }
        catch (System.Exception e) {
            // Turn into an AuraHandledException containing embedded JSON that client can parse.
            throw BWC_Controller.handleException(e);
        }

    }

}