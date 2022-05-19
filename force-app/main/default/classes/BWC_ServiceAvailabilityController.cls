public with sharing class BWC_ServiceAvailabilityController {

    @AuraEnabled(continuation = true)
    public static Object getServiceAvailabilityCont(Id interactionId) {

        BWC_Log.setRelatedRecordId(interactionId);

        try {

            BWC_ServiceAvailabilityService.GetServiceAvailabilityService service = new BWC_ServiceAvailabilityService.GetServiceAvailabilityService(interactionId, null);
            Object response = service.callWithContinuation();

            if (response instanceof Continuation) {
                // It's a continuation, so need to set the method to call when continuation returns
                ((Continuation)response).continuationMethod = 'getServiceAvailabilityResp';
                return response;
            }

            // No continuation needed, so return it directly
            BWC_ServiceAvailability.ServiceAvailabilityResponse serviceAvailability = (BWC_ServiceAvailability.ServiceAvailabilityResponse)response;
            return JSON.serialize(serviceAvailability, true);
        }
        catch (System.Exception e) {
            throw BWC_Controller.handleException(e, 'interactionId=' + interactionId);
        }
    }

    //Method used by agents when they enter a different/refined address or select an specific MDU address
    @AuraEnabled(continuation = true)
    public static Object getServiceAvailabilityByAddressCont(String interactionId, Map<String, Object> updatedAddress){

        try {

            BWC_ServiceAvailabilityService.GetServiceAvailabilityService service = new BWC_ServiceAvailabilityService.GetServiceAvailabilityService(interactionId, updatedAddress);
            Object response = service.callWithContinuation();

            if (response instanceof Continuation) {
                // It's a continuation, so need to set the method to call when continuation returns
                ((Continuation)response).continuationMethod = 'getServiceAvailabilityResp';
                return response;
            }

            // No continuation needed, so return it directly
            BWC_ServiceAvailability.ServiceAvailabilityResponse serviceAvailability = (BWC_ServiceAvailability.ServiceAvailabilityResponse)response;
            return JSON.serialize(serviceAvailability, true);
        }
        catch (System.Exception e) {
            throw BWC_Controller.handleException(e, 'interactionId=' + interactionId);
        }
    }

    @AuraEnabled
    public static String getServiceAvailabilityResp(List<String> labels, Object state) {

        try {

            BWC_ServiceAvailabilityService.GetServiceAvailabilityService service = (BWC_ServiceAvailabilityService.GetServiceAvailabilityService)state;
            BWC_ServiceAvailability.ServiceAvailabilityResponse serviceAvailability = (BWC_ServiceAvailability.ServiceAvailabilityResponse)service.processContinuationResponse();
            return JSON.serialize(serviceAvailability, true);

        }
        catch (System.Exception e) {
            throw BWC_Controller.handleException(e);
        }

    }

    @AuraEnabled
    public static String getServiceAvailabilityMtd(Id interactionId) {
        BWC_ServiceAvailabilityService.GetServiceAvailabilityService service = new BWC_ServiceAvailabilityService.GetServiceAvailabilityService(interactionId, null);
        return service.getServiceAvailabilityMtd();
    }
    
    public class ServiceAvailabilityResponseWrapper extends BWC_ResponseWrapper{
        public BWC_ServiceAvailability.ServiceAvailabilityResponse response;
    }
}