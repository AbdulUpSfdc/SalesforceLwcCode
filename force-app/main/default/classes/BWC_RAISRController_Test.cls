/*
Unit test coverage for BWC_RAISRController.
*/
@isTest
public with sharing class BWC_RAISRController_Test {
    
    @isTest
    private static void test_saveEventData() {
        
        // Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('L1', 'PASSCODE');
        
        // List<BWC_RAISREventLogging.EventLoggingRequest> eventList = new List<BWC_RAISREventLogging.EventLoggingRequest>();
        
        // BWC_RAISREventLogging.EventLoggingRequest evt = new BWC_RAISREventLogging.EventLoggingRequest();
        // evt.userId = '123';
        // evt.date_time = String.valueOf(DateTime.now());
        // evt.eventData = '{}';
        // evt.eventType ='OUT';
        // evt.callReferenceNumber = '1234';
        // evt.appName = 'SFORCECC';
        // evt.appData = 'Test Data';
        // eventList.add(evt);
        // BWC_RAISREventLogging evts = new BWC_RAISREventLogging();
        // evts.events = eventList;
        
        
        // // Call method using continuation
        // System.Continuation continuation =
        //     (System.Continuation)BWC_RAISRController.saveEventData(interaction.Id, evts);
        // // Set mock response
        // BWC_ApiMock.setTestContinuationResponse(continuation, BWC_RAISREventLoggingCallout.EVENT_LOGGING, 'RedAction_Event_Logging_Test');
        
        // // Get continuation response
        // String responseJson = BWC_RAISRController.EventLoggingResponse(new list<String>(continuation.getRequests().keySet()), BWC_Callout.lastContinuationState);
        
        
        // // Verify
        // BWC_RAISREventLogging.EventLoggingResponse response =
        //     (BWC_RAISREventLogging.EventLoggingResponse)JSON.deserialize(responseJson, BWC_RAISREventLogging.EventLoggingResponse.class);
        
        // // Set mock so synchronous response is returned
        // BWC_ApiMock.setTestApiMock(BWC_RAISREventLoggingCallout.EVENT_LOGGING, 'RedAction_Event_Logging_Test');
        // responseJson = (String)BWC_RAISRController.saveEventData(interaction.Id, evts);
        // response =
        //     (BWC_RAISREventLogging.EventLoggingResponse)JSON.deserialize(responseJson, BWC_RAISREventLogging.EventLoggingResponse.class);
        // BWC_RAISRRegistrationData obj_registrationData = BWC_RAISRController.getRegistrationData(interaction.Id);
    }
    
    @isTest
    private static void test_saveEventData1() {
        
        // Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('L1', 'PASSCODE');
        
        // List<BWC_RAISREventLogging.EventLoggingRequest> eventList = new List<BWC_RAISREventLogging.EventLoggingRequest>();
        
        // BWC_RAISREventLogging.EventLoggingRequest evt = new BWC_RAISREventLogging.EventLoggingRequest();
        // evt.userId = '123';
        // evt.date_time = String.valueOf(DateTime.now());
        // evt.eventData = '{}';
        // evt.eventType ='OUT';
        // evt.callReferenceNumber = '1234';
        // evt.appName = 'SFORCECC';
        // evt.appData = 'Test Data';
        // eventList.add(evt);
        // BWC_RAISREventLogging evts = new BWC_RAISREventLogging();
        // evts.events = eventList;
        
        // BWC_ApiMock.setTestApiMock(BWC_RAISREventLoggingCallout.EVENT_LOGGING, 'RedAction_Event_Logging_Exception_Test');
        
        // test.startTest();
        // try{
        //     BWC_RAISREventLogging.EventLoggingResponse response= BWC_RAISRRedactionEventService.saveEvent(interaction.Id,evts);
        // }catch(Exception e){
        //     System.debug('Error Msg'+e.getMessage());
        //     System.debug('Error Msg'+e.getStackTraceString());
        // }
        
    }
    @isTest
    private static void test_saveEventData2() {
        
        // Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('L1', 'PASSCODE');
        
        // List<BWC_RAISREventLogging.EventLoggingRequest> eventList = new List<BWC_RAISREventLogging.EventLoggingRequest>();
        
        // BWC_RAISREventLogging.EventLoggingRequest evt = new BWC_RAISREventLogging.EventLoggingRequest();
        // evt.userId = '123';
        // evt.date_time = String.valueOf(DateTime.now());
        // evt.eventData = '{}';
        // evt.eventType ='OUT';
        // evt.callReferenceNumber = '1234';
        // evt.appName = 'SFORCECC';
        // evt.appData = 'Test Data';
        // eventList.add(evt);
        // BWC_RAISREventLogging evts = new BWC_RAISREventLogging();
        // evts.events = eventList;
        
        
        // test.startTest();
        // try{
        //     // Call method using continuation
        //     System.Continuation continuation =
        //         (System.Continuation)BWC_RAISRController.saveEventData(interaction.Id, evts);
        //     // Set mock response
        //     BWC_ApiMock.setTestContinuationResponse(continuation, BWC_RAISREventLoggingCallout.EVENT_LOGGING, 'RedAction_Event_Logging_Exception_Test');
       
        //     // Get continuation response
        //     String responseJson = BWC_RAISRController.EventLoggingResponse(new list<String>(continuation.getRequests().keySet()), BWC_Callout.lastContinuationState);
        // }catch(Exception e){
        //     System.debug('Error Type='+e.getTypeName());
        //     System.debug('Error Msg='+e.getMessage());
        //     System.debug('Error Stack='+e.getStackTraceString());
        // }
    }
}