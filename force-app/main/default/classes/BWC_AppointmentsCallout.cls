/*
* Callout to Service/Install Appointments API 
*/

public with sharing class BWC_AppointmentsCallout {
    
    
    public class AppointmentsCallout extends BWC_Callout {
        
        BWC_Appointments.AppointmentsResponse response;
        /*
Construct the callout object from request.
*/
        public AppointmentsCallout(List<BWC_Appointments.AppointmentRequest> request) {
            this.setCallout(BWC_Appointments.APPOINTMENTS_API, request, null, null, null);
        }
        
        
        public override Object buildResponse() {
            this.response = new BWC_Appointments.AppointmentsResponse();
            this.response.responses = (List<BWC_Appointments.AppointmentResponse>)this.deserialize(List<BWC_Appointments.AppointmentResponse>.class);
            this.response.setHttpInfo(this.httpRequest, this.httpResponse);
            return this.response;
        }
        
    } 
}