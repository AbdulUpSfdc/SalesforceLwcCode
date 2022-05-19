@IsTest
public with sharing class BWC_CommunicationHistoryCallout_Test {

    @IsTest
    static void requestResend(){

        BWC_ApiMock.setTestApiMock('Communication_Resend', 'UT_Communication_Resend');
        Test.startTest();
        BWC_CommunicationHistory.ResendRequest request = new BWC_CommunicationHistory.ResendRequest();
        BWC_CommunicationHistory.ResendDetails details = new BWC_CommunicationHistory.ResendDetails();
        details.category = 'Services';
        details.uniqueId = 'objId';
        request.resendDetails = details;

        BWC_CommunicationHistory.ResendResponse response = BWC_CommunicationHistoryCallout.requestResend(request);
        Test.stopTest();

    }

    @IsTest
    static void requestResendNullRequest(){

        Test.startTest();
        Boolean exceptionThrown = false;

        try {
            BWC_CommunicationHistory.ResendResponse response = BWC_CommunicationHistoryCallout.requestResend(null);
        } catch (Exception ex) {
            exceptionThrown = true;
        }

        System.assert(exceptionThrown);

        Test.stopTest();

    }

    @IsTest
    static void requestResendNegative(){

        BWC_ApiMock.setTestApiMock('Communication_Resend', 'UT_Communication_Resend_Malformed');
        Test.startTest();
        BWC_CommunicationHistory.ResendRequest request = new BWC_CommunicationHistory.ResendRequest();
        BWC_CommunicationHistory.ResendDetails details = new BWC_CommunicationHistory.ResendDetails();
        details.category = 'Services';
        details.uniqueId = 'objId';
        request.resendDetails = details;

        Boolean exceptionThrown = false;

        try {
            BWC_CommunicationHistory.ResendResponse response = BWC_CommunicationHistoryCallout.requestResend(request);
        } catch (Exception ex) {
            exceptionThrown = true;
        }

        System.assert(exceptionThrown);
        Test.stopTest();

    }
}