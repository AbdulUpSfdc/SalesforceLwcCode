@isTest
public class MarketingSMSToPastLeadSchedule_Test { 

    @TestSetup
    static void testData() { 
        TestDataFactory td = new TestDataFactory();
        list<Store__c> storeList = td.getStores(1, 'test store');
        storeList[0].State__c = 'TX';
        storeList[0].Turn_Off_Marketing_SMS__c = false;
        insert storeList;
        Lead leadSO = new Lead();
        leadSO.lastName = 'Test_Name'+system.Today();
        leadSO.FirstName = 'Test';
        leadSO.recordTypeId = RetailConstants.CONSUMER_RECORDTYPEID; 
        leadSO.Store__c = storeList[0].Id;
        leadSO.SmsConsent__c = 'Yes';
        leadSO.LeadExpirationDate__c = System.today().addDays(10);
        leadSO.Owner__c = userInfo.getUserId();
        leadSO.LeadSource = 'Customer Interaction';
        leadSO.NextFollowUpDate__c = null;
        leadSO.MobilePhone = '6824140464';
        leadSO.Company = 'Test';
        leadSO.ProductsDiscussed__c = 'Prepaid';
        leadSO.ProductsDiscussedWireless__c  = 'Prepaid';
        leadSO.MobilePhone = '6824140464';
        leadSO.Company = 'Test';
        insert leadSO;
        
        Employee__c empStore = new Employee__c();
        empStore.HomeStoreLocation__c = storeList[0].id;
        empStore.EmployeeId__c = storeList[0].id;
        empStore.User__c = leadSO.Owner__c;
        insert empStore;
        
        RetailCustomSetting__c cust = new RetailCustomSetting__c();
        cust.name='MyStoreUrl';
        cust.KeyValue__c = 'MyStoreUrl';
        cust.Key__c = 'MyStoreUrl';
        insert cust;
    }

    @isTest
    private static void Method1() {
        MarketingSMSToPastLeadSchedule lrs = new MarketingSMSToPastLeadSchedule();
        lrs.execute(null);
    }
}