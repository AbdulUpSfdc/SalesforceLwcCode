public with sharing class BWC_AddressValidationCallout {

    public static final String API_ADDRESS_VALIDATION ='Address_Validation'; //TODO: create API entry

    public with sharing class AddressValidationCallout extends BWC_Callout {

        BWC_AddressValidation.AddressValidationResponse response;

        public AddressValidationCallout(BWC_AddressValidation.AddressValidationRequest request){
            this.setCallout(API_ADDRESS_VALIDATION, request, null, null, null);
        }

        public override Object buildResponse(){
            this.response = (BWC_AddressValidation.AddressValidationResponse) this.deserialize(BWC_AddressValidation.AddressValidationResponse.class);
            return this.response;
        }

    }
}