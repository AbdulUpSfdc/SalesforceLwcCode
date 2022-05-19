@IsTest
public with sharing class BWC_CommunicationHistoryService_Test {

    @IsTest
    static void requestResend(){

        BWC_ApiMock.setTestApiMock('Communication_Resend', 'UT_Communication_Resend');
        Test.startTest();
        String response = BWC_CommunicationHistoryController.requestResend('objId', 'Services');
        Test.stopTest();

    }

    @IsTest
    static void requestResendNullExternalId(){

        Test.startTest();
        Boolean exceptionThrown = false;

        try {
            String response = BWC_CommunicationHistoryController.requestResend('', 'Services');
        } catch (Exception ex) {
            exceptionThrown = true;
        }

        System.assert(exceptionThrown);

        Test.stopTest();

    }

    @IsTest
    static void requestResendNullCategory(){

        Test.startTest();
        Boolean exceptionThrown = false;

        try {
            String response = BWC_CommunicationHistoryController.requestResend('objId', '');
        } catch (Exception ex) {
            exceptionThrown = true;
        }

        System.assert(exceptionThrown);

        Test.stopTest();

    }

}