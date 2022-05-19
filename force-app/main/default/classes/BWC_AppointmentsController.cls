/*
	Exposes method to allow LWC to call Service Appointments API .
 */
public with sharing class BWC_AppointmentsController {
    

    /*Section for Getting Service and Isntall appointments*/
    @AuraEnabled(continuation = true)
    public static Object getAppointmentsCont(String payload, Id interactionId) { 
        try {
            List<BWC_Appointments.AppointmentRequest> payloadObj = (List<BWC_Appointments.AppointmentRequest>)JSON.deserialize(payload,List<BWC_Appointments.AppointmentRequest>.class);
            BWC_AppointmentsService.AppointmentsService service = new BWC_AppointmentsService.AppointmentsService(interactionId,payloadObj);
            Object response = service.callWithContinuation();

            if (response instanceof Continuation) {
                // It's a continuation, so need to set the method to call when continuation returns
                ((Continuation)response).continuationMethod = 'getAppointmentsResponse';
                return response;
            }

            // No continuation needed, so return it directly
            BWC_Appointments.AppointmentsResponse appointmentResponse = (BWC_Appointments.AppointmentsResponse)response;
            return appointmentResponse.serialize();

        }
        catch (System.Exception e) {
            throw BWC_Controller.handleException(e, 'Record Id:' + interactionId);
        }

    }
    
     @AuraEnabled
    public static String getAppointmentsResponse(List<String> labels, Object state) {

        try {

            BWC_AppointmentsService.AppointmentsService service = (BWC_AppointmentsService.AppointmentsService)state;
            BWC_Appointments.AppointmentsResponse appointmentResponse = (BWC_Appointments.AppointmentsResponse)service.processContinuationResponse();
            return appointmentResponse.serialize();

        }
        catch (System.Exception e) {
            // Turn into an AuraHandledException containing embedded JSON that client can parse.
            throw BWC_Controller.handleException(e);
        }

    }
}