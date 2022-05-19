@isTest
public with sharing class BWC_ApiMock_Test {

    @isTest
    private static void test() {

        // Build mock instance
        BWC_Integration_Metadata__mdt paymentDetailsMetadata = [SELECT Id FROM BWC_Integration_Metadata__mdt WHERE DeveloperName = :BWC_PaymentDetailsCallout.API_PAYMENT_DETAILS];
        BWC_Api_Mock__mdt mock = new BWC_Api_Mock__mdt(
            Label = 'Test',
            DeveloperName = 'Test',
            Api__c = paymentDetailsMetadata.Id,
            Enabled__c = true,
            Restrict_To_User__c = UserInfo.getUserName(),
            Request_Body_Match_Value__c = '1111111111',
            Apex_Processor__c = 'BWC_ApiMock_Test.TestMockProcessor',
            Response_Status_Code__c = 200,
            Response_Content_Type__c = 'application/json',
            Response_Body__c = '[]'
        );

        // Cannnot insert metadata during test, so instead set explicitly
        BWC_ApiMock.testMock = mock;

        // Call callout to exercise BWC_ApiMock code
        BWC_PaymentDetails.PaymentDetailsRequest request = new BWC_PaymentDetails.PaymentDetailsRequest();
        request.accountId = '1111111111';
        request.accountType = 'wireless';
        BWC_PaymentDetailsCallout.GetPaymentDetailsCallout callout = new BWC_PaymentDetailsCallout.GetPaymentDetailsCallout(new List<BWC_PaymentDetails.PaymentDetailsRequest>{request});
        callout.makeCallout();

    }

    public class TestMockProcessor implements BWC_ApiMock.Processor {

        public void processRequest(BWC_Api_Mock__mdt apiMock, HttpRequest request, HttpResponse response) {
        }        

    }

}