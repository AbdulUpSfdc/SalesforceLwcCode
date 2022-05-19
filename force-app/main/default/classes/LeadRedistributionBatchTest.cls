@isTest
public class LeadRedistributionBatchTest {
    @testSetup
    public static void createData(){
        LeadRedistribution__c  ld = new LeadRedistribution__c();
        ld.Status__c = 'Failed';
        ld.Reason__c = 'Employee Home Store Change';
        insert ld;
    }

    public static testMethod void method1(){
        Test.startTest();
        LeadRedistributionBatch batch1 = new LeadRedistributionBatch();
        database.executeBatch(batch1);
        Test.stopTest();
    }
    public static testMethod void method2(){
        LeadRedistribution__c  led = [select id,Reason__c from LeadRedistribution__c];
        led.Reason__c  = 'Floating Employee Removed';
        update led;
        Test.startTest();
        LeadRedistributionBatch batch1 = new LeadRedistributionBatch();
        database.executeBatch(batch1);
        Test.stopTest(); 
    }
    public static testMethod void method3(){
        LeadRedistribution__c  led = [select id,Reason__c from LeadRedistribution__c];
        led.Reason__c  = 'Employee Offboarded';
        update led;
        Test.startTest();
        LeadRedistributionBatch batch1 = new LeadRedistributionBatch();
        database.executeBatch(batch1);
        Test.stopTest();
    }
    public static testMethod void myUnitTest(){
        Store__c store = new Store__c ();
        store.Name = 'test Store';
        store.GeoLocation__latitude__s  = 30.477450;
        store.GeoLocation__longitude__s = -97.773780;
        insert store;
        
        Employee__c objEmp = new Employee__c();
        objEmp.Name = 'test';
        objEmp.SFProfileId__c = 'RSC-MGR';
        objEmp.HomeStoreLocation__c = store.Id;
        insert objEmp;

        /*List<Lead> lstLeads = new List<Lead>();
        Lead objL = new Lead();
        objL.store__c = store.Id;
        objL.firstname = 'Test';
        objL.lastname = 'DCI Lead';
        objL.LeadSource = 'Marketing Campaign';
        objL.mobilephone = '9898989898';
        objL.reasonForLeaving__c = 'Product Out of Stock';
        objL.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Small_Business').getRecordTypeId();
        objL.smsConsent__c = 'Yes';
        objL.preferredMethodofContact__c = 'Call; SMS; Email';
        objL.smsConsent__c = 'Yes';
        objL.smsConsent__c = 'Yes';
        objL.smsConsent__c = 'Yes';
        objL.CustomerType__c = 'Existing Customer';         
        objL.NextFollowUpDate__c = system.today().addDays(3);
        objL.OtherNotes__c = 'test';
        objL.ProductsDiscussed__c = 'Prepaid';*/
        /*
    objL.ProductsDiscussedInternet__c = 'AT&T Fiber';
        objL.ProductsDiscussedWireless__c = '';
        objL.ProductsDiscussedVideo__c = '';
    */
        /*objL.Company = 'ATT';
        lstLeads.add(objL);
        Lead objL1 = new Lead();
        objL1.store__c = store.Id;
        objL1.firstname = 'Test';
        objL1.lastname = 'DCI Lead';
        objL1.LeadSource = 'Marketing Campaign';
        objL1.mobilephone = '9898989899';
        objL1.reasonForLeaving__c = 'Product Out of Stock';
        objL1.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Small_Business').getRecordTypeId();
        objL1.smsConsent__c = 'Yes';
        objL1.preferredMethodofContact__c = 'Call; SMS; Email';
        objL1.smsConsent__c = 'Yes';
        objL1.smsConsent__c = 'Yes';
        objL1.smsConsent__c = 'Yes';
        objL1.CustomerType__c = 'Existing Customer';         
        objL1.NextFollowUpDate__c = system.today().addDays(4);
        objL1.OtherNotes__c = 'test';
        objL.ProductsDiscussed__c = 'Prepaid';*/
        /*
    objL.ProductsDiscussedInternet__c = 'AT&T Fiber';
        objL.ProductsDiscussedWireless__c = '';
        objL.ProductsDiscussedVideo__c = '';
    */
        /*objL1.Company = 'ATT';
        lstLeads.add(objL1);
        insert lstLeads;*/
        
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
		//objL.ProductsDiscussed__c = 'AT&T Internet';
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
          Database.executeBatch(new LeadRedistributionBatch());
        Test.stopTest();
    }
}