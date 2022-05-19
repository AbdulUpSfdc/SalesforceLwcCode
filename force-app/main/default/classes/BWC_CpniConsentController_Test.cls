@isTest
public with sharing class BWC_CpniConsentController_Test {

    @TestSetup
    static void createData(){
        Profile p = [SELECT Id FROM Profile WHERE name='Standard User']; 

        User usr = new User(alias = 'test123', email='test123@noemail.com', emailencodingkey='UTF-8', firstName='test', lastname='Testing', 
                            languagelocalekey='en_US', localesidkey='en_US', profileid = p.Id, timezonesidkey='America/New_York', username='test123abc@noemail.com'); 
        insert usr;
    }
    
    @isTest
    private static void test_updateCpniConsent() {

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_CpniConsentResponseMock', 200);
        
        BWC_CpniConsent.UpdateCpniConsentRequest request = new BWC_CpniConsent.UpdateCpniConsentRequest();
        request.consentPreferences = new List<BWC_CpniConsent.ConsentPreference>();
        BWC_CpniConsent.ConsentPreference cp = new BWC_CpniConsent.ConsentPreference();
        cp.consentType = 'CPNI';
        cp.preference = 'Y';
        cp.market = 'SAN';
        request.consentPreferences.add(cp);

        Test.startTest();
        String response = BWC_CpniConsentController.updateCpniConsent(JSON.serialize(request), '1234567890', 'wireless');
        System.assertEquals('{"success":true,"rawResponse":"","rawRequest":"","response":{"status":"SUCCESS"}}', response);
        Test.stopTest();
    }

    @isTest
    private static void test_updateCpniConsent_error() {

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_CpniConsentErrorResponseMock', 400);

        // Incorrect request to generate exception
        BWC_CpniConsent.UpdateCpniConsentResponse requestError = new BWC_CpniConsent.UpdateCpniConsentResponse();
        requestError.status = 'false';

        Test.startTest();
        String responseError = BWC_CpniConsentController.updateCpniConsent(JSON.serialize(requestError), '/1234567890', 'wireless');
        System.assertNotEquals('{"success":true,"rawResponse":"","rawRequest":"","response":{"status":"SUCCESS"}}', responseError);
        Test.stopTest();
    }
    
}