@IsTest
public with sharing class BWC_AutoPayProfilesController_Test {
    
    @IsTest
    static void test_postAutoPayProfile(){

        BWC_Utils.setStaticResourceMock('BWC_AutoPayProfilesPOST', 200);
        
        Test.startTest();
        //Delete
        String responseJsonDelete = BWC_AutoPayProfilesController.postAutoPayProfile('{"accountNumber":"314970860","accountType":"wireless"}', BWC_AutoPayProfiles.DELETE_MODE);
        System.assertNotEquals(null, responseJsonDelete);

        //Pause
        String responseJsonPause = BWC_AutoPayProfilesController.postAutoPayProfile('{"accountNumber":"314970860","accountType":"wireless"}', BWC_AutoPayProfiles.PAUSE_MODE);
        System.assertNotEquals(null, responseJsonPause);

        String responseJsonAdd = BWC_AutoPayProfilesController.postAutoPayProfile('{"appName": "SFORCECC","sourceUser": "DH1052","sourceSystem": "SFORCECC","sourceLocation": "CS","accountNumber": "314970860","accountType": "wireless","systemId": "CNG","divisionId": "DLS","paymentPlanType": "RECURRINGADV","customerAgreement": "TNC_001","tncId": 1,"storeTermsConditionConsent": true,"paymentMethod": {"type": "CARD","card": {"cardNumber": "4127612341041111","expireMonth": "12","expireYear": "2025","securityCode": "123","cardHolderName": "ROBERT GUEST JR","billingAddress": {"zipCode": "12345"},"merchantId": "IDPCSR-CON"}}}', BWC_AutoPayProfiles.ADD_MODE);
        System.assertNotEquals(null, responseJsonAdd);
        
        String responseJsonUpdate = BWC_AutoPayProfilesController.postAutoPayProfile('{"appName": "SFORCECC","sourceUser": "DH1052","sourceSystem": "SFORCECC","sourceLocation": "CS","accountNumber": "314970860","accountType": "wireless","systemId": "CNG","divisionId": "DLS","paymentPlanType": "RECURRINGADV","customerAgreement": "TNC_001","tncId": 1,"storeTermsConditionConsent": true,"paymentMethod": {"type": "CARD","card": {"cardNumber": "4127612341041111","expireMonth": "12","expireYear": "2025","securityCode": "123","cardHolderName": "ROBERT GUEST JR","billingAddress": {"zipCode": "12345"},"merchantId": "IDPCSR-CON"}}}', BWC_AutoPayProfiles.UPDATE_MODE);
        System.assertNotEquals(null, responseJsonUpdate);

        String responseJsonUnknown = BWC_AutoPayProfilesController.postAutoPayProfile('{"accountNumber":"314970860","accountType":"wireless"}', 'unknown');
        System.assertNotEquals(null, responseJsonUnknown);

        String spiDataJson = '{ "spiDataList": [ { "name": "bankAccountNumber", "token": "1234-6543-7894-78945" }, { "name": "routingNumber", "value": "123456" }, { "name": "cardNumber", "token": "1234-6543-7894-78941" } ] }';
        String responseJsonAddRaisr = BWC_AutoPayProfilesController.postAutoPayProfileRaisr('{"appName": "SFORCECC","sourceUser": "DH1052","sourceSystem": "SFORCECC","sourceLocation": "CS","accountNumber": "314970860","accountType": "wireless","systemId": "CNG","divisionId": "DLS","paymentPlanType": "RECURRINGADV","customerAgreement": "TNC_001","tncId": 1,"storeTermsConditionConsent": true,"paymentMethod": {"type": "CARD","card": {"cardNumber": "4127612341041111","expireMonth": "12","expireYear": "2025","securityCode": "123","cardHolderName": "ROBERT GUEST JR","billingAddress": {"zipCode": "12345"},"merchantId": "IDPCSR-CON"}}}', BWC_AutoPayProfiles.ADD_MODE, spiDataJson);
        System.assertNotEquals(null, responseJsonAddRaisr);

        Test.stopTest();
    }
}