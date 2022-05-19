public with sharing class BWC_ChargesService {

    /*
        Call CDE Recommendations Service Synchronously
    */
    public static BWC_Charges.CreateChargeResponse createCharge(
        String recordId, BWC_Charges.CreateChargeRequest request
    ) {
        
        BWC_ChargesService.GetCreateChargeService service = 
            new BWC_ChargesService.GetCreateChargeService(recordId, request);
        
        BWC_Charges.CreateChargeResponse response = 
            (BWC_Charges.CreateChargeResponse) service.call();
        
        return response;
    }

    /*
        Full Create Charge Service Class with Async & Sync Callout Methods
    */
    public class GetCreateChargeService extends BWC_InteractionServiceBase {

        // Request & Response State
        public String attUID;
        public BWC_Charges.CreateChargeRequest request;
        public BWC_Charges.CreateChargeResponse response;

        public GetCreateChargeService(
            String interactionId, BWC_Charges.CreateChargeRequest request
        ) {

            super(interactionId, null);

            this.attUID = BWC_Utils.getCurrentUserAttId();

            // Save State of Request
            this.request = request;

            buildRequest();

            // Create Callout for Create Charge
            this.callout = new BWC_ChargesCallout.GetCreateChargeCallout(this.request);

        }

        public void buildRequest() {

            this.request.agentId = this.attUID;

            for(BWC_Charges.ChargeInfo c : request.chargeInfo) {
                if(c.productType == null) {
                    c.productType = BWC_Charges.DEFAULT_PRODUCT_TYPE;
                }
                if(String.isNotBlank(c.userBillText)) {
                    c.userBillText = EncodingUtil.urlEncode(c.userBillText, 'UTF-8');
                }
            }
        }

        /*
            Prepare the response for Controller
        */
        public override Object buildResponse() {

            this.response = (BWC_Charges.CreateChargeResponse) this.callout.getResponse();

            // After successful response increment use count.
            for(BWC_Charges.ChargeInfo ci : this.request.chargeInfo) {
                BWC_ChargeCodeService.incrementChargeCodeUseCount(ci.chargeId);
            }

            return this.response;
        }
    }
}