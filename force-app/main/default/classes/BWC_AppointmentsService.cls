/*
 * Build request required for Service/Install Appointments API
 */
public with sharing class BWC_AppointmentsService {
                
    public class AppointmentsService extends BWC_InteractionServiceBase{
		
        public List<BWC_Appointments.AppointmentRequest> request;
        public BWC_Appointments.AppointmentsResponse response;
         /*
            Construct the service object from caller arguments.
        */
        public AppointmentsService(Id InteractionId,List<BWC_Appointments.AppointmentRequest> payload) {
            super(InteractionId,null);
            this.request = payload;
            this.buildRequest();
        }

        public void buildRequest() {
            this.callout = new BWC_AppointmentsCallout.AppointmentsCallout(this.request); 
        }

        /*
            Builds and returns final response.
        */
         public override Object buildResponse() {
            this.response = (BWC_Appointments.AppointmentsResponse)this.callout.getResponse();
            return this.response;
        }  
     }
    
}