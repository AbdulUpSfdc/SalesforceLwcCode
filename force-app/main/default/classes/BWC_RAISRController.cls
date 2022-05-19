public with sharing class BWC_RAISRController {
    private static final Map<Integer,String> CONTEXT_BY_STATUS_CODE = 
        new Map<Integer,String> {
                	2000 =>'The timeout was reached, and the server didn’t get a chance to respond.',
                    2001 =>'There was a connection failure.',
                    2002 =>'Exceptions occurred.',
                    2003 =>'The response hasn’t arrived.',
                    2004 =>'The response size is too large (greater than 1 MB).'
                };
    
    // @AuraEnabled(cacheable = true  continuation = true)
    // public static Object saveEventData(String recordId, BWC_RAISREventLogging raisrEvent) {		
        // try {
        //     BWC_RAISRRedactionEventService.EventLoggingService service = 
        //         new BWC_RAISRRedactionEventService.EventLoggingService(recordId, raisrEvent);
        //     Object response = service.callWithContinuation();
        //     if (response instanceof Continuation) {
        //         ((Continuation)response).continuationMethod = 'eventLoggingResponse';
        //         return response;
        //     }
            
        //     // if continuation not needed return it directly
        //     BWC_RAISREventLogging.EventLoggingResponse eventLoggingResponse = (BWC_RAISREventLogging.EventLoggingResponse)response;
        //     return eventLoggingResponse.serialize();
        // }
        // catch (System.Exception e) {
        //     throw BWC_Controller.handleException(e, 'RAISR redaction event Logging failed - Interaction Id:' + recordId + ';');
        // }
    //     return null;
    // }
    
    /*
    	Handle continuation response for event logging
    */
    @AuraEnabled (cacheable=true)
    public static String eventLoggingResponse(List<String> labels, Object state) {
        // String serializedResponse;
        // BWC_RAISRRedactionEventService.EventLoggingService service = (BWC_RAISRRedactionEventService.EventLoggingService)state;
        // HttpResponse response = Continuation.getResponse(labels[0]);
        // String requestAndResponse = (service != null ? '|Request JSON='+ JSON.serialize(service.request, true) : '') 
        //     + (response != null ? '|Response =' + response.getBody() : '');
        
        // try { 
        //     //Check continuation response for failure
        //     if(CONTEXT_BY_STATUS_CODE.containsKey(response.getStatusCode())) {
        //         throw new RAISRControllerException(CONTEXT_BY_STATUS_CODE.get(response.getStatusCode()) 
        //                                            + requestAndResponse);
        //     }
        //     // Set related record for logging
        //     BWC_Log.setRelatedRecordId(service.recordId);
            
        //     // Allow service to process the response
        //     BWC_RAISREventLogging.EventLoggingResponse eventLoggingResponse = (BWC_RAISREventLogging.EventLoggingResponse)service.processContinuationResponse();
            
        //     serializedResponse = eventLoggingResponse.serialize();

        // }
        // catch (System.JSONException e) {
        //     throw BWC_Controller.handleException(e, 'JSON Exception' + requestAndResponse );
        // }
        // catch (System.SerializationException e) {
        //     throw BWC_Controller.handleException(e, 'Serialization Exception' + requestAndResponse);
        // }
        // catch (System.CalloutException e) {
        //     throw BWC_Controller.handleException(e, 'Callout Exception' + requestAndResponse);
        // }
        // catch (System.Exception e) {
        //     throw BWC_Controller.handleException(e, 'System Exception' + requestAndResponse);
        // }
        // return serializedResponse;
        return null;
    }
    
   
    @AuraEnabled (cacheable = true)
    public static BWC_RAISRRegistrationData getRegistrationData (String interactionId) {
        BWC_RAISRRegistrationData obj_registrationData = BWC_RAISRRedactionService.getRegistrationData(interactionId);
        return obj_registrationData;
    }
    
    public class RAISRControllerException extends Exception {
  	}

    @AuraEnabled(cacheable = true)
    public static Boolean isProdOrg(){
        Organization org = [select IsSandbox from Organization where Id =:UserInfo.getOrganizationId()];
        return !org.IsSandbox;
    }
  
}