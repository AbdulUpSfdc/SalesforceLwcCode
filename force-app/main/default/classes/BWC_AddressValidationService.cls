public inherited sharing class BWC_AddressValidationService {


    public class AddressValidation extends BWC_InteractionServiceBase {

        public BWC_AddressValidation.AddressValidationRequest request;
        public BWC_AddressValidation.AddressValidationResponse response;

        public AddressValidation(Id interactionId, BWC_AddressValidation.AddressValidationRequest request){
            super(interactionId, null);
            this.request = request;
            this.buildRequest();
        }

        public void buildRequest(){
            this.callout = new BWC_AddressValidationCallout.AddressValidationCallout(this.request);
        }

        public override Object buildResponse(){
            this.response = (BWC_AddressValidation.AddressValidationResponse) this.callout.getResponse();
            return this.response;
        }

    }
}