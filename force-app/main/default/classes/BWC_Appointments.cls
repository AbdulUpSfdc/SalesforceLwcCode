/*
	Exposes Constant required for Appointments API call 
 */
public inherited sharing class BWC_Appointments {
    
    public static final String APPOINTMENTS_API = 'Service_Install_Appointments';
    
    public BWC_Appointments(){
        
    }
    public class AppointmentsResponse extends BWC_Callout.CalloutResponse  {
        public List<AppointmentResponse> responses;
    }
    public class AppointmentRequest{
        public String ban; //BAN Banking account number
        public String appointmentType; //install or service
        public String accountType; //dtv or uverse
    }

    public class AppointmentResponse{
        public Integer ban;
        public String appointmentType;
        public List<Appointment> appointments; 
    }

    public class Appointment {
        public String appointmentNumber;
        public String appointmentStatus;
        public String scheduledDate;
        public String techArrivalWindow;
        public String techStatus;
        public String closedDate;
    }
}