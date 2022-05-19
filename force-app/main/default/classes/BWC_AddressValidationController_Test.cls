@IsTest
public with sharing class BWC_AddressValidationController_Test {

    @IsTest
    static void addressValidation_test(){

        Test.startTest();

        Interaction__c interaction = BWC_TestDataFactory.createNewInteraction();

        BWC_AddressValidation.AddressValidationRequest request = new BWC_AddressValidation.AddressValidationRequest();
        BWC_AddressValidation.AddressCharacteristic characteristic = new BWC_AddressValidation.AddressCharacteristic();
        request.city = 'FARMERS BRANCH';
        request.postcode = '95234';
        request.stateOrProvince = 'TX';
        request.addressCharacteristic = new List<BWC_AddressValidation.AddressCharacteristic>{characteristic};

        String requestJson = JSON.serialize(request, true);

        System.Continuation continuation = (System.Continuation) BWC_AddressValidationController.addressValidationCont(interaction.id, requestJson);

        BWC_ApiMock.setTestContinuationResponse(continuation, BWC_AddressValidationCallout.API_ADDRESS_VALIDATION, 'UT_AddressValidation');

        String responseJson = BWC_AddressValidationController.addressValidationResp(null, BWC_Callout.lastContinuationState);

        BWC_AddressValidation.AddressValidationResponse response = (BWC_AddressValidation.AddressValidationResponse) JSON.deserialize(responseJson, BWC_AddressValidation.AddressValidationResponse.class);

        BWC_ApiMock.setTestApiMock(BWC_AddressValidationCallout.API_ADDRESS_VALIDATION, 'UT_AddressValidation');

        responseJson = (String) BWC_AddressValidationController.addressValidationCont(interaction.Id, requestJson);
        response = (BWC_AddressValidation.AddressValidationResponse) JSON.deserialize(responseJson, BWC_AddressValidation.AddressValidationResponse.class);

        try {

            BWC_ApiMock.setTestApiMock(BWC_AddressValidationCallout.API_ADDRESS_VALIDATION, 'UT_AddressValidation_ServerError');

            responseJson = (String) BWC_AddressValidationController.addressValidationCont(interaction.Id, requestJson);
            response = (BWC_AddressValidation.AddressValidationResponse) JSON.deserialize(responseJson, BWC_AddressValidation.AddressValidationResponse.class);
            System.assert(false, 'Exception was not thrown');
        } catch (Exception e) {
            System.assert(true);
        }

        Test.stopTest();

    }
}