@isTest
public class leadFollowupFieldUpdateBatchTest {
    
      @testSetup static void testSetupMethod(){
        
        profile pofileSO =  [SELECT Id, Name FROM Profile WHERE Name = 'Retail SM']; 
        profile pofileRep =  [SELECT Id, Name FROM Profile WHERE Name = 'Retail RSC Rep']; 
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
        user usrRep = new User(
            LastName = 'Test NameRetail_REP',
            Email = orgId + seconds + '@att.test1.com',
            Username = orgId + seconds + '@att.test1.com',
            CompanyName = 'TEST1',
            Title = 'title1',
            Alias = 'talias1',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            profileId = pofileRep.Id
        );
        insert usrRep;
        
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
        Employee__c objEmp1 = new Employee__c();
        objEmp.Name = 'test';
        objEmp.SFProfileId__c = 'RSC-REP';
        objEmp.user__c = usrRep.Id;
        objEmp.HomeStoreLocation__c = store.Id;
        insert objEmp1;
        
        List<Lead> lstLeads = new List<Lead>();
        Lead objL = new Lead();
        objL.store__c = store.Id;
        objL.firstname = 'Test1';
        objL.lastname = 'DCI Lead1';
        objL.LeadSource = 'Customer Interaction';
        objL.mobilephone = '9898989891';
        objL.reasonForLeaving__c = 'Product Out of Stock';
        objL.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Consumer').getRecordTypeId();
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
        objL.ProductsDiscussed__c = 'Prepaid';
        
        objL.Company = 'ATT';
        lstLeads.add(objL);
        Lead objL1 = new Lead();
        objL1.store__c = store.Id;
        objL1.firstname = 'Test2';
        objL1.lastname = 'DCI Lead2';
        objL1.LeadSource = 'Customer Interaction';
        objL1.mobilephone = '9898989892';
        objL1.reasonForLeaving__c = 'Product Out of Stock';
        objL1.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Consumer').getRecordTypeId();
        objL1.smsConsent__c = 'Yes';
        objL1.preferredMethodofContact__c = 'Call; SMS; Email';
        objL1.smsConsent__c = 'Yes';
        objL1.smsConsent__c = 'Yes';
        objL1.smsConsent__c = 'Yes';
        objL1.CustomerType__c = 'Existing Customer';  
        
        objL1.NextFollowUpDate__c = system.today().addDays(4);
        objL1.OtherNotes__c = 'test';
        objL.ProductsDiscussed__c = 'Postpaid';
        
        objL1.Company = 'ATT';
        lstLeads.add(objL1);
        Lead objL2 = new Lead();
        objL2.store__c = store.Id;
        objL2.firstname = 'Test3';
        objL2.lastname = 'DCI Lead3';
        objL2.LeadSource = 'Campaign';
        objL2.mobilephone = '9898989894';
        objL2.reasonForLeaving__c = 'Product Out of Stock';
        objL2.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Small_Business').getRecordTypeId();
        objL2.smsConsent__c = 'Yes';
        objL2.preferredMethodofContact__c = 'Call; SMS; Email';
        objL2.smsConsent__c = 'Yes';
        objL2.smsConsent__c = 'Yes';
        objL2.smsConsent__c = 'Yes';
        objL2.CustomerType__c = 'Existing Customer';  
        
        objL2.NextFollowUpDate__c = system.today().addDays(5);
        objL2.OtherNotes__c = 'test';
        objL2.ProductsDiscussed__c = 'Post Paid Add A Line';
        
        objL2.Company = 'ATT';
        lstLeads.add(objL2);
        Lead objL3 = new Lead();
        objL3.store__c = store.Id;
        objL3.firstname = 'Test4';
        objL3.lastname = 'DCI Lead4';
        objL3.LeadSource = 'Customer Interaction';
        objL3.mobilephone = '9898989895';
        objL3.reasonForLeaving__c = 'Product Out of Stock';
        objL3.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Consumer').getRecordTypeId();
        objL3.smsConsent__c = 'Yes';
        objL3.preferredMethodofContact__c = 'Call; SMS; Email';
        objL3.smsConsent__c = 'Yes';
        objL3.smsConsent__c = 'Yes';
        objL3.smsConsent__c = 'Yes';
        objL3.CustomerType__c = 'Existing Customer';  
        
        objL3.NextFollowUpDate__c = system.today().addDays(4);
        objL3.OtherNotes__c = 'test';
        objL3.ProductsDiscussed__c = 'Accessories';
        
        objL3.Company = 'ATT';
        lstLeads.add(objL3);
        Lead  objL4 = new Lead();
        objL4.store__c = store.Id;
        objL4.firstname = 'Test5';
        objL4.lastname = 'DCI Lead5';
        objL4.LeadSource = 'Customer Interaction';
        objL4.mobilephone = '9898989896';
        objL4.reasonForLeaving__c = 'Product Out of Stock';
        objL4.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Consumer').getRecordTypeId();
        objL4.smsConsent__c = 'Yes';
        objL4.preferredMethodofContact__c = 'Call; SMS; Email';
        objL4.smsConsent__c = 'Yes';
        objL4.smsConsent__c = 'Yes';
        objL4.smsConsent__c = 'Yes';
        objL4.CustomerType__c = 'Existing Customer';  
        
        objL4.NextFollowUpDate__c = system.today().addDays(4);
        objL4.OtherNotes__c = 'test';
        objL4.ProductsDiscussed__c = 'FirstNet';
        
        objL4.Company = 'ATT';
        lstLeads.add( objL4);
        Lead   objL5 = new Lead();
        objL5.store__c = store.Id;
        objL5.firstname = 'Test6';
        objL5.lastname = 'DCI Lead6';
        objL5.LeadSource = 'Customer Interaction';
        objL5.mobilephone = '9898989897';
        objL5.reasonForLeaving__c = 'Product Out of Stock';
        objL5.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Consumer').getRecordTypeId();
        objL5.smsConsent__c = 'Yes';
        objL5.preferredMethodofContact__c = 'Call; SMS; Email';
        objL5.smsConsent__c = 'Yes';
        objL5.smsConsent__c = 'Yes';
        objL5.smsConsent__c = 'Yes';
        objL5.CustomerType__c = 'Existing Customer';  
        
        objL5.NextFollowUpDate__c = system.today().addDays(4);
        objL5.OtherNotes__c = 'test';
        objL5.ProductsDiscussed__c = 'Protection';
        
        objL5.Company = 'ATT';
        lstLeads.add(  objL5);
        Lead   objL6 = new Lead();
        objL6.store__c = store.Id;
        objL6.firstname = 'Test7';
        objL6.lastname = 'DCI Lead7';
        objL6.LeadSource = 'Customer Interaction';
        objL6.mobilephone = '9898989898';
        objL6.reasonForLeaving__c = 'Product Out of Stock';
        objL6.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Consumer').getRecordTypeId();
        objL6.smsConsent__c = 'Yes';
        objL6.preferredMethodofContact__c = 'Call; SMS; Email';
        objL6.smsConsent__c = 'Yes';
        objL6.smsConsent__c = 'Yes';
        objL6.smsConsent__c = 'Yes';
        objL6.CustomerType__c = 'Existing Customer';  
        
        objL6.NextFollowUpDate__c = system.today().addDays(4);
        objL6.OtherNotes__c = 'test';
        objL6.ProductsDiscussed__c = 'FleetComplete';
        
        objL6.Company = 'ATT';
        lstLeads.add(  objL6);
        Lead   objL7 = new Lead();
        objL7.store__c = store.Id;
        objL7.firstname = 'Test8';
        objL7.lastname = 'DCI Lead8';
        objL7.LeadSource = 'Customer Interaction';
        objL7.mobilephone = '9898989890';
        objL7.reasonForLeaving__c = 'Product Out of Stock';
        objL7.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Consumer').getRecordTypeId();
        objL7.smsConsent__c = 'Yes';
        objL7.preferredMethodofContact__c = 'Call; SMS; Email';
        objL7.smsConsent__c = 'Yes';
        objL7.smsConsent__c = 'Yes';
        objL7.smsConsent__c = 'Yes';
        objL7.CustomerType__c = 'Existing Customer';  
        
        objL7.NextFollowUpDate__c = system.today().addDays(4);
        objL7.OtherNotes__c = 'test';
        objL7.ProductsDiscussed__c = 'AT&T Internet';
        
        objL7.Company = 'ATT';
        lstLeads.add(  objL7);
        Lead   objL8 = new Lead();
        objL8.store__c = store.Id;
        objL8.firstname = 'Test9';
        objL8.lastname = 'DCI Lead9';
        objL8.LeadSource = 'Customer Interaction';
        objL8.mobilephone = '9898989812';
        objL8.reasonForLeaving__c = 'Product Out of Stock';
        objL8.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Consumer').getRecordTypeId();
        objL8.smsConsent__c = 'Yes';
        objL8.preferredMethodofContact__c = 'Call; SMS; Email';
        objL8.smsConsent__c = 'Yes';
        objL8.smsConsent__c = 'Yes';
        objL8.smsConsent__c = 'Yes';
        objL8.CustomerType__c = 'Existing Customer';  
        
        objL8.NextFollowUpDate__c = system.today().addDays(4);
        objL8.OtherNotes__c = 'test';
        objL8.ProductsDiscussed__c = 'AT&T Broadband';
        
        objL8.Company = 'ATT';
        lstLeads.add(  objL8);
        Lead   objL9 = new Lead();
        objL9.store__c = store.Id;
        objL9.firstname = 'Test0';
        objL9.lastname = 'DCI Lead0';
        objL9.LeadSource = 'Customer Interaction';
        objL9.mobilephone = '9898989813';
        objL9.reasonForLeaving__c = 'Product Out of Stock';
        objL9.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Consumer').getRecordTypeId();
        objL9.smsConsent__c = 'Yes';
        objL9.preferredMethodofContact__c = 'Call; SMS; Email';
        objL9.smsConsent__c = 'Yes';
        objL9.smsConsent__c = 'Yes';
        objL9.smsConsent__c = 'Yes';
        objL9.CustomerType__c = 'Existing Customer';  
        
        objL9.NextFollowUpDate__c = system.today().addDays(4);
        objL9.OtherNotes__c = 'test';
        objL9.ProductsDiscussed__c = 'AT&T Fiber';
        
        objL9.Company = 'ATT';
        lstLeads.add(  objL9);
        Lead   objL11 = new Lead();
        objL11.store__c = store.Id;
        objL11.firstname = 'Test12';
        objL11.lastname = 'DCI Lead12';
        objL11.LeadSource = 'Customer Interaction';
        objL11.mobilephone = '9898989815';
        objL11.reasonForLeaving__c = 'Product Out of Stock';
        objL11.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Consumer').getRecordTypeId();
        objL11.smsConsent__c = 'Yes';
        objL11.preferredMethodofContact__c = 'Call; SMS; Email';
        objL11.smsConsent__c = 'Yes';
        objL11.smsConsent__c = 'Yes';
        objL11.smsConsent__c = 'Yes';
        objL11.CustomerType__c = 'Existing Customer';  
        
        objL11.NextFollowUpDate__c = system.today().addDays(4);
        objL11.OtherNotes__c = 'test';
        objL11.ProductsDiscussed__c = 'AT&T Broadband';
        
        objL11.Company = 'ATT';
        lstLeads.add(  objL11);
        Lead   objL10 = new Lead();
        objL10.store__c = store.Id;
        objL10.firstname = 'Test13';
        objL10.lastname = 'DCI Lead13';
        objL10.LeadSource = 'Customer Interaction';
        objL10.mobilephone = '9898989845';
        objL10.reasonForLeaving__c = 'Product Out of Stock';
        objL10.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Consumer').getRecordTypeId();
        objL10.smsConsent__c = 'Yes';
        objL10.preferredMethodofContact__c = 'Call; SMS; Email';
        objL10.smsConsent__c = 'Yes';
        objL10.smsConsent__c = 'Yes';
        objL10.smsConsent__c = 'Yes';
        objL10.CustomerType__c = 'Existing Customer';  
        
        objL10.NextFollowUpDate__c = system.today().addDays(4);
        objL10.OtherNotes__c = 'test';
        objL10.ProductsDiscussed__c = 'AT&T TV';
        
        objL10.Company = 'ATT';
        
        lstLeads.add(  objL10);
        Lead   objL12 = new Lead();
        objL12.store__c = store.Id;
        objL12.firstname = 'Test14';
        objL12.lastname = 'DCI Lead14';
        objL12.LeadSource = 'Customer Interaction';
        objL12.mobilephone = '9898989847';
        objL12.reasonForLeaving__c = 'Product Out of Stock';
        objL12.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Consumer').getRecordTypeId();
        objL12.smsConsent__c = 'Yes';
        objL12.preferredMethodofContact__c = 'Call; SMS; Email';
        objL12.smsConsent__c = 'Yes';
        objL12.smsConsent__c = 'Yes';
        objL12.smsConsent__c = 'Yes';
        objL12.CustomerType__c = 'Existing Customer';  
        
        objL12.NextFollowUpDate__c = system.today().addDays(4);
        objL12.OtherNotes__c = 'test';
        objL12.ProductsDiscussed__c = 'DIRECTV';
        
        objL12.Company = 'ATT';
        lstLeads.add(  objL12);
        Lead   objL13 = new Lead();
        objL13.store__c = store.Id;
        objL13.firstname = 'Test15';
        objL13.lastname = 'DCI Lead15';
        objL13.LeadSource = 'Customer Interaction';
        objL13.mobilephone = '9898989867';
        objL13.reasonForLeaving__c = 'Product Out of Stock';
        objL13.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Consumer').getRecordTypeId();
        objL13.smsConsent__c = 'Yes';
        objL13.preferredMethodofContact__c = 'Call; SMS; Email';
        objL13.smsConsent__c = 'Yes';
        objL13.smsConsent__c = 'Yes';
        objL13.smsConsent__c = 'Yes';
        objL13.CustomerType__c = 'Existing Customer';  
        
        objL13.NextFollowUpDate__c = system.today().addDays(4);
        objL13.OtherNotes__c = 'test';
        objL13.ProductsDiscussed__c = 'HBO Max';
        
        objL13.Company = 'ATT';
        lstLeads.add(  objL13);
        Lead   objL14 = new Lead();
        objL14.store__c = store.Id;
        objL14.firstname = 'Test16';
        objL14.lastname = 'DCI Lead16';
        objL14.LeadSource = 'Customer Interaction';
        objL14.mobilephone = '9898989848';
        objL14.reasonForLeaving__c = 'Product Out of Stock';
        objL14.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Consumer').getRecordTypeId();
        objL14.smsConsent__c = 'Yes';
        objL14.preferredMethodofContact__c = 'Call; SMS; Email';
        objL14.smsConsent__c = 'Yes';
        objL14.smsConsent__c = 'Yes';
        objL14.smsConsent__c = 'Yes';
        objL14.CustomerType__c = 'Existing Customer';  
        
        objL14.NextFollowUpDate__c = system.today().addDays(4);
        objL14.OtherNotes__c = 'test';
        objL14.ProductsDiscussed__c = 'DTVNOW';
        
        objL14.Company = 'ATT';
        lstLeads.add(  objL14);
        insert lstLeads;
        
        
        
    }
    
    
    public static testMethod void myUnitTest(){
        Test.startTest();
        Database.executeBatch(new leadFollowupFieldUpdateBatch());
        Test.stopTest();
    }
}