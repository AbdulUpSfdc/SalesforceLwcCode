/*
    Exposes methods to allow LWC to call User Associations service.
*/
public with sharing class BWC_PromotionDetailsController {
/*
        Method for calling from LWC. Returns serialized JSON.
    */
    @AuraEnabled(continuation=true)
    public static Object getPromotionDetailsForBillingAccountCont(Id recordId, Id InteractionId) {


        try {

            BWC_PromotionDetailsService.GetPromotionDetailsService promotion = new  BWC_PromotionDetailsService.GetPromotionDetailsService(recordId, InteractionId);
            Object response = promotion.callWithContinuation();
            
            if (response instanceof Continuation) {
                // It's a continuation, so need to set the method to call when continuation returns
                ((Continuation)response).continuationMethod = 'getPromotionDetailsResp';
                return response;
            }
            
            BWC_PromotionDetails.PromotionDetailsResponse promotionDetailsResponse = (BWC_PromotionDetails.PromotionDetailsResponse)response;
            return promotionDetailsResponse.serialize();

        }
        catch (System.Exception e) {

            throw BWC_Controller.handleException(e, 'Record Id:' + recordId);

        }


    }
    
    @AuraEnabled
    public static String getPromotionDetailsResp(List<String> labels, Object state) {

        try {

            BWC_PromotionDetailsService.GetPromotionDetailsService service = (BWC_PromotionDetailsService.GetPromotionDetailsService)state;
            BWC_PromotionDetails.PromotionDetailsResponse promotionDetailsResponse = (BWC_PromotionDetails.PromotionDetailsResponse)service.processContinuationResponse();
            return promotionDetailsResponse.serialize();

        }
        catch (System.Exception e) {
            // Turn into an AuraHandledException containing embedded JSON that client can parse.
            throw BWC_Controller.handleException(e);
        }

    }

}