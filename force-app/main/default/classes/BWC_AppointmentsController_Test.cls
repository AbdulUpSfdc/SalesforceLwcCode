@isTest
public class BWC_AppointmentsController_Test {
    
    static testMethod void testGetServiceAppointments1(){
        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('L1', 'PASSCODE');
        
        List<BWC_Appointments.AppointmentRequest> request = new List<BWC_Appointments.AppointmentRequest>();
        BWC_Appointments.AppointmentRequest req = new BWC_Appointments.AppointmentRequest();
        req.ban = '100416182';
        req.appointmentType = 'service';
        req.accountType = 'uverse';
        request.add(req);
        try{
            
            // Call method using continuation
            System.Continuation continuation =
                (System.Continuation)BWC_AppointmentsController.getAppointmentsCont(JSON.serialize(request),interaction.Id);
            
            // Set mock response
            BWC_ApiMock.setTestContinuationResponse(continuation, BWC_Appointments.APPOINTMENTS_API, 'UT_Service_Install_Appointments');
            
            // Get continuation response
            String responseJson = BWC_AppointmentsController.getAppointmentsResponse(new list<String>(continuation.getRequests().keySet()), BWC_Callout.lastContinuationState);
            
            
            // Verify
            BWC_AppointmentsService.AppointmentsService response =
                (BWC_AppointmentsService.AppointmentsService)JSON.deserialize(responseJson, BWC_AppointmentsService.AppointmentsService.class);
            
            // Set mock so synchronous response is returned
            BWC_ApiMock.setTestApiMock(BWC_Appointments.APPOINTMENTS_API, 'UT_Service_Install_Appointments');
            responseJson = (String)BWC_AppointmentsController.getAppointmentsCont(JSON.serialize(request),interaction.Id);
            response =
                (BWC_AppointmentsService.AppointmentsService)JSON.deserialize(responseJson, BWC_AppointmentsService.AppointmentsService.class);
        }catch(Exception e){
            
        }
        
    }
    static testMethod void testGetServiceAppointments2(){
        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('L1', 'PASSCODE');
        
        List<BWC_Appointments.AppointmentRequest> request = new List<BWC_Appointments.AppointmentRequest>();
        BWC_Appointments.AppointmentRequest req = new BWC_Appointments.AppointmentRequest();
        req.ban = '100416182';
        req.appointmentType = 'service';
        req.accountType = 'uverse';
        request.add(req);
        test.startTest();
        try{
            BWC_ApiMock.setTestApiMock(BWC_Appointments.APPOINTMENTS_API, 'UT_Service_Install_Appointments');
            
            BWC_AppointmentsController.getAppointmentsCont(JSON.serialize(request),interaction.Id);
        }catch(Exception e){
            
        }
        
    }
    static testMethod void testGetServiceAppointments3(){
        
        test.startTest();
        BWC_Appointments service = new BWC_Appointments();
        try{
            BWC_AppointmentsController.getAppointmentsResponse(new List<String>{},null);
        }catch(Exception e){
            
        }
        test.stopTest();
    }
    static testMethod void testGetInstallAppointments1(){
        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('L1', 'PASSCODE');
        
        List<BWC_Appointments.AppointmentRequest> request = new List<BWC_Appointments.AppointmentRequest>();
        BWC_Appointments.AppointmentRequest req = new BWC_Appointments.AppointmentRequest();
        req.ban = '100416182';
        req.appointmentType = 'install';
        req.accountType = 'uverse';
        request.add(req);
        
            
        // Call method using continuation
        System.Continuation continuation =
        (System.Continuation)BWC_AppointmentsController.getAppointmentsCont(JSON.serialize(request),interaction.Id);
            
        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_Appointments.APPOINTMENTS_API, 'UT_Service_Install_Appointments');
            
        // Get continuation response
        String responseJson = BWC_AppointmentsController.getAppointmentsResponse(new list<String>(continuation.getRequests().keySet()), BWC_Callout.lastContinuationState);
            
            
        // Verify
        BWC_AppointmentsService.AppointmentsService response =
            (BWC_AppointmentsService.AppointmentsService)JSON.deserialize(responseJson, BWC_AppointmentsService.AppointmentsService.class);
            
        // Set mock so synchronous response is returned
        BWC_ApiMock.setTestApiMock(BWC_Appointments.APPOINTMENTS_API, 'UT_Service_Install_Appointments');
        responseJson = (String)BWC_AppointmentsController.getAppointmentsCont(JSON.serialize(request),interaction.Id);
        response =
            (BWC_AppointmentsService.AppointmentsService)JSON.deserialize(responseJson, BWC_AppointmentsService.AppointmentsService.class);
             
    }
}