@IsTest
public with sharing class BWC_ServiceAvailabilityControllerTest {

    @TestSetup
    static void makeData(){
        Account acctObj = BWC_TestDataFactory.createAccount();
        String recType = BWC_Constants.BillingAccount_AccountType_Wireless;
        Billing_Account__c billAcctObj = BWC_TestDataFactory.createBillingAccount(recType,acctObj);
        Interaction__c interact = BWC_TestDataFactory.createInteraction(acctObj);
        interact.Billing_Account__c = billAcctObj.Id;

        update interact;
    }

    @IsTest
    static void getServiceAvailabilityTest(){

        Id interactionId = [SELECT ID FROM Interaction__c LIMIT 1].Id;

        // Call method using continuation
        System.Continuation continuation = (System.Continuation)BWC_ServiceAvailabilityController.getServiceAvailabilityCont(interactionId);

        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_Constants.API_SERVICE_AVAILABILITY, 'UT_GetServiceAvailability');

        // Get continuation response
        String responseJson = BWC_ServiceAvailabilityController.getServiceAvailabilityResp(null, BWC_Callout.lastContinuationState);

        // Verify
        BWC_ServiceAvailability.ServiceAvailabilityResponse response = (BWC_ServiceAvailability.ServiceAvailabilityResponse)JSON.deserialize(responseJson, BWC_ServiceAvailability.ServiceAvailabilityResponse.class);

        // Set mock so synchronous response is returned
        BWC_ApiMock.setTestApiMock(BWC_Constants.API_SERVICE_AVAILABILITY, 'UT_GetServiceAvailability');
        responseJson = (String)BWC_ServiceAvailabilityController.getServiceAvailabilityCont(interactionId);
        response = (BWC_ServiceAvailability.ServiceAvailabilityResponse)JSON.deserialize(responseJson, BWC_ServiceAvailability.ServiceAvailabilityResponse.class);

    }

    @IsTest
    static void getServiceAvailabilityTestNegative(){

        Id interactionId = [SELECT ID FROM Interaction__c LIMIT 1].Id;

        try {
            // Call method using continuation
            System.Continuation continuation = (System.Continuation)BWC_ServiceAvailabilityController.getServiceAvailabilityCont(null);

            // Set mock response
            BWC_ApiMock.setTestContinuationResponse(continuation, BWC_Constants.API_SERVICE_AVAILABILITY, 'UT_GetServiceAvailability');

            // Get continuation response
            String responseJson = BWC_ServiceAvailabilityController.getServiceAvailabilityResp(null, BWC_Callout.lastContinuationState);

            // Verify
            BWC_ServiceAvailability.ServiceAvailabilityResponse response = (BWC_ServiceAvailability.ServiceAvailabilityResponse)JSON.deserialize(responseJson, BWC_ServiceAvailability.ServiceAvailabilityResponse.class);

            System.assert(false,'Exception was not thrown');
        } catch (Exception e) {
            System.assert(true,'Exception was thrown');
        }

        try { 
            // Call method using continuation
            System.Continuation continuation = (System.Continuation)BWC_ServiceAvailabilityController.getServiceAvailabilityCont(interactionId);

            // Set mock response
            BWC_ApiMock.setTestContinuationResponse(continuation, BWC_Constants.API_SERVICE_AVAILABILITY, 'UT_GetServiceAvailability_Error');

            // Get continuation response
            String responseJson = BWC_ServiceAvailabilityController.getServiceAvailabilityResp(null, BWC_Callout.lastContinuationState);

            // Verify
            BWC_ServiceAvailability.ServiceAvailabilityResponse response = (BWC_ServiceAvailability.ServiceAvailabilityResponse)JSON.deserialize(responseJson, BWC_ServiceAvailability.ServiceAvailabilityResponse.class);

            System.assert(false,'Exception was not thrown');
        } catch (Exception e) {
            System.assert(true,'Exception was thrown');
        }

    }

    @IsTest
    static void getServiceAvailabilityBillingAddressTest(){

        Map<String, Object> updatedAddress = new Map<String, Object>();
        updatedAddress.put('aptUnitNumber','apt 101');
        updatedAddress.put('addressId','12456789');
        updatedAddress.put('addressLine1','Test address');
        updatedAddress.put('city','Dallas');
        updatedAddress.put('state','TX');
        updatedAddress.put('zip','75231');

        Id interactionId = [SELECT ID FROM Interaction__c LIMIT 1].Id;

        // Call method using continuation
        System.Continuation continuation = (System.Continuation)BWC_ServiceAvailabilityController.getServiceAvailabilityByAddressCont(interactionId, updatedAddress);

        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_Constants.API_SERVICE_AVAILABILITY, 'UT_GetServiceAvailability');

        // Get continuation response
        String responseJson = BWC_ServiceAvailabilityController.getServiceAvailabilityResp(null, BWC_Callout.lastContinuationState);

        // Verify
        BWC_ServiceAvailability.ServiceAvailabilityResponse response = (BWC_ServiceAvailability.ServiceAvailabilityResponse)JSON.deserialize(responseJson, BWC_ServiceAvailability.ServiceAvailabilityResponse.class);

    }

    @IsTest
    static void getServiceAvailabilityBillingAddressTestNegative(){

        Map<String, Object> updatedAddress = new Map<String, Object>();
        updatedAddress.put('aptUnitNumber','apt 101');
        updatedAddress.put('addressId','12456789');
        updatedAddress.put('addressLine1','Test address');
        updatedAddress.put('city','Dallas');
        updatedAddress.put('state','TX');
        updatedAddress.put('zip','75231');


        try {
            // Call method using continuation
            System.Continuation continuation = (System.Continuation)BWC_ServiceAvailabilityController.getServiceAvailabilityByAddressCont(null, updatedAddress);

            // Set mock response
            BWC_ApiMock.setTestContinuationResponse(continuation, BWC_Constants.API_SERVICE_AVAILABILITY, 'UT_GetServiceAvailability');

            // Get continuation response
            String responseJson = BWC_ServiceAvailabilityController.getServiceAvailabilityResp(null, BWC_Callout.lastContinuationState);

            // Verify
            BWC_ServiceAvailability.ServiceAvailabilityResponse response = (BWC_ServiceAvailability.ServiceAvailabilityResponse)JSON.deserialize(responseJson, BWC_ServiceAvailability.ServiceAvailabilityResponse.class);

            System.assert(false, 'exception was not thrown');

        } catch (Exception e) {
            System.assert(true, 'exception was not thrown');
        }


    }

    @IsTest
    static void getServiceAvailabilityEmptyBillingAddressTest(){

        BWC_Utils.setStaticResourceMock('BWC_ServiceAvailabilityResponse', 200);
        Test.startTest();
        Billing_Account__c billAcctObj = [SELECT Id, Service_Address_Line_1__c FROM Billing_Account__c];
        billAcctObj.Service_Address_Line_1__c = '';
        update billAcctObj;

        Id interactionId = [SELECT ID FROM Interaction__c LIMIT 1].Id;

        // Call method using continuation
        System.Continuation continuation = (System.Continuation)BWC_ServiceAvailabilityController.getServiceAvailabilityCont(interactionId);

        // Set mock response
        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_Constants.API_SERVICE_AVAILABILITY, 'UT_GetServiceAvailability');

        // Get continuation response
        String responseJson = BWC_ServiceAvailabilityController.getServiceAvailabilityResp(null, BWC_Callout.lastContinuationState);

        // Verify
        BWC_ServiceAvailability.ServiceAvailabilityResponse response = (BWC_ServiceAvailability.ServiceAvailabilityResponse)JSON.deserialize(responseJson, BWC_ServiceAvailability.ServiceAvailabilityResponse.class);

        // Set mock so synchronous response is returned
        BWC_ApiMock.setTestApiMock(BWC_Constants.API_SERVICE_AVAILABILITY, 'UT_GetServiceAvailability');
        responseJson = (String)BWC_ServiceAvailabilityController.getServiceAvailabilityCont(interactionId);
        response = (BWC_ServiceAvailability.ServiceAvailabilityResponse)JSON.deserialize(responseJson, BWC_ServiceAvailability.ServiceAvailabilityResponse.class);

    }

    @IsTest
    static void getServiceAvailabilityMtdTest(){

        Id interactionId = [SELECT ID FROM Interaction__c LIMIT 1].Id;

        Test.startTest();
        String response = BWC_ServiceAvailabilityController.getServiceAvailabilityMtd(interactionId);
        Test.stopTest();

    }
}