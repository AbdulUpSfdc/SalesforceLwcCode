/**
* This clas comtains the apex test for all the Prospect functionality
*/
@isTest
private class ProspectLeadsListViewControllerTest {
    @testSetup static void setupTestData() {
        Store__c store = new Store__c(Name = 'Test Store'+system.currentTimeMillis(), Geolocation__Latitude__s = 10, Geolocation__Longitude__s = 10);
        insert store;
        // rmeda test class fix
        //create retailcustom settings for welcome onboarding leads
        RetailCustomSetting__c smsSettings = new RetailCustomSetting__c();
        smsSettings.Name = 'WelcomeSMSForOnlineLeads';
        smsSettings.KeyValue__c = 'true';
        insert smsSettings;
    	// rmeda test class fix ends
    	
        Lead testLead = new Lead();
        testLead.FirstName = 'Test';
        testLead.LastName = '4678';
        testLead.LeadListName__c = 'WIRELINE NO MOBILITY';
        testLead.CustomerType__c = 'New Customer;Existing Customer';
        testLead.NumberOfEmployees = 50;
        testLead.Email = 'test4678@gmail.com';       
        testLead.Status = RetailConstants.CAPTURED;
        testLead.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Prospect').getRecordTypeId();
        insert testLead;

    }
    @isTest static void getLeadsByFilterTest() {       
        setupTestData();
        Store__c store = [SELECT id, Name FROM Store__c LIMIT 1];
        String strListFilterOptions = '[{"name":"LeadListName__c","value":"WIRELINE NO MOBILITY"},{"name":"CustomerType__c","value":"New Customer;Existing Customer;Customer Moving"},'+
                                        '{"name":"NumberOfEmployees","value":"100"},{"name":"Name","value":"Test"},{"name":"MobilePhone","value":"8127635878"},'+
                                        '{"name":"Email","value":"test@gmail.com"},{"name":"Proximity__c","value":"25"},{"name":"Store__c","value":"'+store.id+'"}]';
        Test.startTest();
        ProspectLeadsListViewController.getLeadListPickListValues();
        List<String> lstStrFieldNames = new LIst<String>();
        lstStrFieldNames.add('Test');
        ProspectLeadsListViewController.getInitValues(lstStrFieldNames);
        ProspectLeadsListViewController.getLeadsByFilterNew(strListFilterOptions);
        ProspectLeadsListViewController.lazyLoadLeads(10, 20, strListFilterOptions);
        system.assertEquals(ProspectLeadsListViewController.isProfileForStoreSelect(), true);
        system.assertEquals(ProspectLeadsListViewController.getStore(store.id).Name, store.Name);
        system.assertEquals(ProspectLeadsListViewController.getMaxProximity(), 50);
        Test.stopTest();
    }
}