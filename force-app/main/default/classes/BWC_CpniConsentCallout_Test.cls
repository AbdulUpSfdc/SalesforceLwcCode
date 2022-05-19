@isTest
public with sharing class BWC_CpniConsentCallout_Test {
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
        BWC_CpniConsent.UpdateCpniConsentResponse response = BWC_CpniConsentCallout.updateCpniConsent(request, '1234567890', 'wireless');
        System.assertEquals('SUCCESS', response.status);
        Test.stopTest();
    }
    

    @isTest
    private static void test_updateCpniConsent_nullRequest() {
        
        Test.startTest();
        try {
            BWC_CpniConsent.UpdateCpniConsentResponse response = BWC_CpniConsentCallout.updateCpniConsent(null, '1234567890', 'wireless');
            System.assert(false);
        }
        catch (Exception ex) {
            System.assert(true);
        }
        Test.stopTest();
    }

    @isTest
    private static void test_updateCpniConsent_Error() {
        
        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_CpniConsentErrorResponseMock', 400);
        BWC_CpniConsent.UpdateCpniConsentRequest request = new BWC_CpniConsent.UpdateCpniConsentRequest();

        Test.startTest();
        try {
            BWC_CpniConsent.UpdateCpniConsentResponse response = BWC_CpniConsentCallout.updateCpniConsent(request, 'cpniConsentError', 'wireless');
            System.assert(false);
        }
        catch (Exception ex) {
            System.assert(true);
        }
        Test.stopTest();

    }
}