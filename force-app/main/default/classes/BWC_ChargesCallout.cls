/*
    Call Mulesoft to Create Charges.
*/
public with sharing class BWC_ChargesCallout {
    
    public static final String API_CREATE_CHARGE = 'Create_Charge';

    public class GetCreateChargeCallout extends BWC_Callout {
        List<BWC_Charges.CreateChargeRequest> request;
        BWC_Charges.CreateChargeResponse response;

        /*
            Construct the callout object from request
        */
        public GetCreateChargeCallout(BWC_Charges.CreateChargeRequest request) {

            this.setCallout(
                API_CREATE_CHARGE, 
                request, 
                request.accountNumber + '/charges', // Path
                'accountType=' + request.accountType, // QueryString
                null
            );

        }

        /*
            Returns  BWC_Charges.CreateChargeResponse
        */
        public override Object buildResponse() {

            this.response = (BWC_Charges.CreateChargeResponse) this.deserialize(
                BWC_Charges.CreateChargeResponse.class
            );

            return this.response;

        }
    }
    
}