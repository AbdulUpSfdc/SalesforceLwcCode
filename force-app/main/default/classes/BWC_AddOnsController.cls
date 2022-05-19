/*
    Exposes methods to allow LWC to call Add-ons service.
*/
public with sharing class BWC_AddOnsController {
    /*
        Method for calling from LWC. Returns serialized JSON.
    */
    @AuraEnabled(continuation = true)
    public static Object getAddOnsForBillingAccountCont(Id recordId, Id InteractionId) {

        try {

            BWC_AddOnsService.GetAddOnsService service = new BWC_AddOnsService.GetAddOnsService(recordId,InteractionId);
            Object response = service.callWithContinuation();

            if (response instanceof Continuation) {
                // It's a continuation, so need to set the method to call when continuation returns
                ((Continuation)response).continuationMethod = 'getAddOnsResp';
                return response;
            }

            BWC_AddOns.AddOnsResponse addOnsResponse = (BWC_AddOns.AddOnsResponse)response;
            return addOnsResponse.serialize();
        }
        catch (System.Exception e) {

            // Turn into an AuraHandledException containing embedded JSON that client can parse.
            throw BWC_Controller.handleException(e, 'Record Id:' + recordId);
        }
    }

    @AuraEnabled
    public static String getAddOnsResp(List<String> labels, Object state) {
        try {
            BWC_AddOnsService.GetAddOnsService service = ( BWC_AddOnsService.GetAddOnsService)state;
            BWC_AddOns.AddOnsResponse addOnsResponse = (BWC_AddOns.AddOnsResponse)service.processContinuationResponse();
            return addOnsResponse.serialize();
        }
        catch (System.Exception e) {
            // Turn into an AuraHandledException containing embedded JSON that client can parse.
            throw BWC_Controller.handleException(e);
        }
    }
}