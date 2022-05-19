/*
    Extra test coverage for BWC_AuthenticationService -- main coverage is provided via BWC_AuthenticationController_Test.
*/
@isTest
public with sharing class BWC_AuthenticationService_Test {

    @isTest
    private static void test_generatePin() {

        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('STEPUPSONLY', 'NONE');

        BWC_AuthenticationCallout.DeliveryMethods deliveryMethods = new BWC_AuthenticationCallout.DeliveryMethods();
        deliveryMethods.sms = new BWC_AuthenticationCallout.SmsDeliveryMethod();
        deliveryMethods.sms.smsPhoneNumber = BWC_Utils.hashContactMethod('2144350011');

        // Set mock response
        BWC_ApiMock.setTestApiMock(BWC_AuthenticationCallout.API_AUTHENTICATION_GENERATE_PIN, 'UT_Generate_Pin_Success');

        // Call method synchronous
        BWC_AuthenticationService.GeneratePinService service = new BWC_AuthenticationService.GeneratePinService(interaction.Id, interaction.Billing_Account__c, deliveryMethods);
        BWC_AuthenticationCallout.GeneratePinResponse response = (BWC_AuthenticationCallout.GeneratePinResponse)service.call();

        System.assertEquals('SUCCESS', response.appStatusMsg);

    }

}