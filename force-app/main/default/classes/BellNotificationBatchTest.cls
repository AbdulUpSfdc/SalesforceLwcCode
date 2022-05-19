@isTest
public with sharing class BellNotificationBatchTest {
    public static testMethod void myUnitTest(){
        profile pofileSO =  [SELECT Id, Name FROM Profile WHERE Name = 'Retail SM']; 
        String orgId = UserInfo.getOrganizationId();
        String seconds = system.now().format('ssSSS');
      
        user usr = new User(
                LastName = 'Test NameRetail_SM',
                Email = orgId + seconds + '@att.test.com',
                Username = orgId + seconds + '@att.test.com',
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'talias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                profileId = pofileSO.Id
            );
        insert usr;
        
        Store__c store = new Store__c ();
        store.Name = 'test Store';
        store.GeoLocation__latitude__s  = 30.477450;
        store.GeoLocation__longitude__s = -97.773780;
        insert store;
        
        Employee__c objEmp = new Employee__c();
        objEmp.Name = 'test';
        objEmp.SFProfileId__c = 'RSC-MGR';
        objEmp.user__c = usr.Id;
        objEmp.HomeStoreLocation__c = store.Id;
        insert objEmp;

        List<Lead> lstLeads = new List<Lead>();
        Lead objL = new Lead();
        objL.store__c = store.Id;
        objL.firstname = 'Test';
        objL.lastname = 'DCI Lead';
        objL.LeadSource = 'Campaign';
        objL.mobilephone = '9898989898';
        objL.reasonForLeaving__c = 'Product Out of Stock';
        objL.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Small_Business').getRecordTypeId();
        objL.smsConsent__c = 'Yes';
        objL.preferredMethodofContact__c = 'Call; SMS; Email';
        objL.smsConsent__c = 'Yes';
        objL.smsConsent__c = 'Yes';
        objL.smsConsent__c = 'Yes';
        objL.CustomerType__c = 'Existing Customer';  
        //objL.ATT_Products__c = 'Internet';
		// objL.ProductsDiscussed__c = 'AT&T Internet';
        objL.NextFollowUpDate__c = system.today().addDays(3);
        objL.OtherNotes__c = 'test';
        //objL.ProductsDiscussedInternet__c = 'AT&T Fiber';
        //objL.ProductsDiscussedWireless__c = '';
        //objL.ProductsDiscussedVideo__c = '';
        objL.ProductsDiscussed__c = 'Internet';
        objL.ProductsDiscussedInternet__c = 'AT&T Fiber';
        objL.ProductsDiscussedWireless__c = '';
        objL.ProductsDiscussedVideo__c = '';
        objL.Company = 'ATT';
        lstLeads.add(objL);
        Lead objL1 = new Lead();
        objL1.store__c = store.Id;
        objL1.firstname = 'Test';
        objL1.lastname = 'DCI Lead';
        objL1.LeadSource = 'Campaign';
        objL1.mobilephone = '9898989899';
        objL1.reasonForLeaving__c = 'Product Out of Stock';
        objL1.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Small_Business').getRecordTypeId();
        objL1.smsConsent__c = 'Yes';
        objL1.preferredMethodofContact__c = 'Call; SMS; Email';
        objL1.smsConsent__c = 'Yes';
        objL1.smsConsent__c = 'Yes';
        objL1.smsConsent__c = 'Yes';
        objL1.CustomerType__c = 'Existing Customer';  
        //objL1.ATT_Products__c = 'Internet';
		//objL1.ProductsDiscussed__c = 'AT&T Internet';
        objL1.NextFollowUpDate__c = system.today().addDays(4);
        objL1.OtherNotes__c = 'test';
        //objL1.ProductsDiscussedInternet__c = 'AT&T Fiber';
        //objL1.ProductsDiscussedWireless__c = '';
        //objL1.ProductsDiscussedVideo__c = '';
        objL1.ProductsDiscussed__c = 'Internet';
        objL1.ProductsDiscussedInternet__c = 'AT&T Fiber';
        objL1.ProductsDiscussedWireless__c = '';
        objL1.ProductsDiscussedVideo__c = '';
        objL1.Company = 'ATT';
        lstLeads.add(objL1);
        insert lstLeads;
        
        
        Test.startTest();
          Database.executeBatch(new BellNotificationBatch());
        Test.stopTest();
    }
}