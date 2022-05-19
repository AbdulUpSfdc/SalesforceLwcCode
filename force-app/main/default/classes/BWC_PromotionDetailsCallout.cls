/*
    Call Mulesoft to get  Promotion Detaiils .
*/
public with sharing class BWC_PromotionDetailsCallout {
    public static final String USER_PROMOTION_DETAILS = 'Promotion_Details';
    /*
        Callout to get Promotion Detaiils for requested accounts.
    */
    public class GetPromotionDetailsCallout extends BWC_Callout {
        
        // Request and Response state
        
        List<BWC_PromotionDetails.PromotionDetailsRequest> request;
        BWC_PromotionDetails.PromotionDetailsResponse response;


    /*
        Construct the callout object from request.
    */
        public GetPromotionDetailsCallout(List<BWC_PromotionDetails.PromotionDetailsRequest> request) {

            this.setCallout(USER_PROMOTION_DETAILS, request, null, null, null);

        }

        /*
            Returns  BWC_PromotionDetails.PromotionDetailsResponse.
        */
        public override Object buildResponse() {
            
        // Response requires extra wrapper because API returns an array but we need root to be an object so it can extend BWC_Callout.Response
         this.response = new BWC_PromotionDetails.PromotionDetailsResponse();
         this.response.responses = (List<BWC_PromotionDetails.PromotionDetailsResponseList>)this.deserialize(List<BWC_PromotionDetails.PromotionDetailsResponseList>.class);
         this.response.setHttpInfo(this.httpRequest, this.httpResponse);
         return this.response;

        }

    } 
}