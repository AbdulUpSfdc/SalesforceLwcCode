public inherited sharing class BWC_ServiceAvailabilityCallout {

    public static final String API_SERVICE_AVAILABILITY_GET ='Service_Availability_Get';

    public class GetServiceAvailabilityCallout extends BWC_Callout {

        // Request and Response state
        BWC_ServiceAvailability.ServiceAvailabilityRequest request;
        BWC_ServiceAvailability.ServiceAvailabilityResponses response;

        /*
            Construct the callout object from request.
        */
        public GetServiceAvailabilityCallout(BWC_ServiceAvailability.ServiceAvailabilityRequest request) {

            // Sending a POST Request
            this.setCallout(BWC_Constants.API_SERVICE_AVAILABILITY, request, null, null, null);

        }

        /*
            Returns BWC_ServiceAvailability.ServiceAvailabilityResponse.
        */
        public override Object buildResponse() {

            // Response requires extra wrapper because API returns an array but we need root to be an object so it can extend BWC_Callout.Response
            this.response = new BWC_ServiceAvailability.ServiceAvailabilityResponses();
            this.response.response = (BWC_ServiceAvailability.ServiceAvailabilityResponse)this.deserialize(BWC_ServiceAvailability.ServiceAvailabilityResponse.class);
            this.response.setHttpInfo(this.httpRequest, this.httpResponse);

            return this.response;

        }

    }

    public class GetServiceAvailabilityByAddressIdCallout extends BWC_Callout{

        BWC_ServiceAvailability.ServiceAvailabilityResponses response;

        public GetServiceAvailabilityByAddressIdCallout(String addressId) {

            // Sending a GET Request
            String queryString = 'address_id='+addressId+'&clientName=mulesoft';
            this.setCallout(API_SERVICE_AVAILABILITY_GET, null, null, queryString, null);

        }

        public override Object buildResponse() {

            // Response requires extra wrapper because API returns an array but we need root to be an object so it can extend BWC_Callout.Response
            this.response = new BWC_ServiceAvailability.ServiceAvailabilityResponses();
            this.response.response = (BWC_ServiceAvailability.ServiceAvailabilityResponse)this.deserialize(BWC_ServiceAvailability.ServiceAvailabilityResponse.class);
            this.response.setHttpInfo(this.httpRequest, this.httpResponse);

            return this.response;

        }
    }
}