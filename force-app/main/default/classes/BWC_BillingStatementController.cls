/*
    Exposes methods to allow LWC to call Billing Statement service.
*/
public with sharing class BWC_BillingStatementController {
    /*
        Method for calling from LWC. Returns serialized JSON.
    */
    @AuraEnabled(continuation = true)
    public static Object getBillingStatementsCont(Id recordId, Id InteractionId){

        try {

            BWC_BillingStatementService.GetBillingStatementsService service = new BWC_BillingStatementService.GetBillingStatementsService(recordId, InteractionId);
            Object response = service.callWithContinuation();

            if (response instanceof Continuation) {
                // It's a continuation, so need to set the method to call when continuation returns
                ((Continuation)response).continuationMethod = 'getBillingStatementResp';
                return response;
            }

             // No continuation needed, so return it directly
             BWC_BillingStatement.BillingStatementResponse billingStatementResponse = (BWC_BillingStatement.BillingStatementResponse)response;
             return billingStatementResponse.serialize();

        }
        catch (System.Exception e) {

            throw BWC_Controller.handleException(e, 'Record Id:' + recordId);

        }
            
    }

    @AuraEnabled
    public static String getBillingStatementResp(List<String> labels, Object state) {
        try {
            BWC_BillingStatementService.GetBillingStatementsService service = ( BWC_BillingStatementService.GetBillingStatementsService)state;
            BWC_BillingStatement.BillingStatementResponse billingStatementResponse = (BWC_BillingStatement.BillingStatementResponse)service.processContinuationResponse();
            return billingStatementResponse.serialize();
        }
        catch (System.Exception e) {
            // Turn into an AuraHandledException containing embedded JSON that client can parse.
            throw BWC_Controller.handleException(e);
        }
    }
}