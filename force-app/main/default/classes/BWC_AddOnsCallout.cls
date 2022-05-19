/*
    Call Mulesoft to get Add-ons to a billing account.
*/
public with sharing class BWC_AddOnsCallout {
    
    public static final String ADD_ON_DETAILS = 'Add_Ons';

    public class GetAddOnsCallout extends BWC_Callout {
       
        // Request and Response state
        List<BWC_AddOns.AddOnsRequest> request;
        BWC_AddOns.AddOnsResponse response;

        /*
            Construct the callout object from request.
        */
        public GetAddOnsCallout(List<BWC_AddOns.AddOnsRequest> request) {

            this.setCallout(ADD_ON_DETAILS, request, null, null, null);
        }

        /*
            Returns BWC_AddOns.AddOnsResponse.
        */
        public override Object buildResponse() {

            this.response = (BWC_AddOns.AddOnsResponse)this.deserialize(BWC_AddOns.AddOnsResponse.class);
            return this.response;
        }
    } 
}