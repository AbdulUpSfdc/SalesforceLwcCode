@istest
public class LeadConsentServiceTest {
	@testsetup
    static void makedata(){
        RetailCustomSetting__c retailcust = new RetailCustomSetting__c();
        retailcust.Key__c = 'ConsentTTL';
        retailcust.name = 'ConsentTTL';
        retailcust.KeyValue__c = '22';
        insert retailcust;
        leadConsent__c objleadConsent = new leadConsent__c();
        objleadConsent.Firstname__c = 'XyzConsent';
        objleadConsent.RequestId__c = 'Test';
        Insert objleadConsent;
    }
	@istest    
    static void leadConsent(){
        Test.startTest();
        LeadConsent__c objleadcon = LeadConsentService.getConsentDetails('Test');
        LeadConsentService.updateConsentDetails('Test');
        LeadConsentService.updateConsentCancelledDetails('Test');
        try{
        	LeadConsentService.verifyHashID('Test');    
        }
        catch(exception ex){
        }
        Test.stopTest();
        system.assert(objleadcon!= null);
    }
    
}