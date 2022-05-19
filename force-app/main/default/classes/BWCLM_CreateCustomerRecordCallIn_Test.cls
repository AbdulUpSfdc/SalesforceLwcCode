/*
    Test class to test BWCLM_CreateCustomerRecordCallIn class
*/
@isTest
public with sharing class BWCLM_CreateCustomerRecordCallIn_Test {

    @isTest
    private static void dopostEmptyJson() {
   Test.startTest();
        String JsonMsg = '';
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/CreateCustomerRecord';  //Request URL
        req.httpMethod = 'POST';//HTTP Request Type
        req.requestBody = Blob.valueof(JsonMsg);
        RestContext.request = req;
        RestContext.response= res;
        BWCLM_CreateCustomerRecordCallIn.doPost();
        System.assertNotEquals(Null,res.responseBody);
    Test.stopTest();

    }

    @isTest
    private static void dopostWrongJson() {
        Test.startTest();
            String JsonMsg = '[{"a":"aa"},{"a":"aa"}]';
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/CreateCustomerRecord';  //Request URL
            req.httpMethod = 'POST';//HTTP Request Type
            req.requestBody = Blob.valueof(JsonMsg);
            RestContext.request = req;
            RestContext.response= res;
            BWCLM_CreateCustomerRecordCallIn.doPost();
            System.assertNotEquals(Null,res.responseBody);
        Test.stopTest();
    }

     @isTest
    private static void dopostEmptyBan() {
        Test.startTest();
            BWCLM_CreateCustomerRecord ccr = new BWCLM_CreateCustomerRecord();
            ccr.firstName = 'Matt';
            ccr.lastName = 'Goerge';
            String JsonMsg = JSON.serialize(ccr);
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/CreateCustomerRecord';  //Request URL
            req.httpMethod = 'POST';//HTTP Request Type
            req.requestBody = Blob.valueof(JsonMsg);
            RestContext.request = req;
            RestContext.response= res;
            BWCLM_CreateCustomerRecordCallIn.doPost();
            System.assertNotEquals(Null,res.responseBody);
        Test.stopTest();
    }

    @isTest
    private static void dopostRecNotExists() {
        Test.startTest();
            BWCLM_CreateCustomerRecord ccr = new BWCLM_CreateCustomerRecord();
            ccr.firstName = 'Matt';
            ccr.lastName = 'Goerge';
            ccr.accountNumber_ban = 'ABC23456';
            ccr.accessId = 'test@test.att.com';
            List<BWCLM_CreateCustomerRecord.Addresses> addrLst = new List<BWCLM_CreateCustomerRecord.Addresses>();
            List<BWCLM_CreateCustomerRecord.PhonesNumbers> phoneLst = new List<BWCLM_CreateCustomerRecord.PhonesNumbers>();
            BWCLM_CreateCustomerRecord.Addresses addr = new BWCLM_CreateCustomerRecord.Addresses();
            BWCLM_CreateCustomerRecord.PhonesNumbers phone = new BWCLM_CreateCustomerRecord.PhonesNumbers();
            addr.addressType = 'shipping';
            addrLst.add(addr);
            addr.addressType = 'billing';
            addrLst.add(addr);
            addr.addressType = 'mailing';
            addrLst.add(addr);
            addr.addressType = 'other';
            addrLst.add(addr);
            ccr.addresses = addrLst;
            phone.phoneNumber = '3053942286';
            phone.phoneType = 'home';
            phoneLst.add(phone);
            phone.phoneType = 'cell';
            phoneLst.add(phone);
            phone.phoneType = 'mobile';
            phoneLst.add(phone);
            phone.phoneType = 'contact';
            phoneLst.add(phone);
            phone.phoneType = 'work';
            phoneLst.add(phone);
            phone.phoneType = 'fax';
            phoneLst.add(phone);
            ccr.phonesNumbers = phoneLst;
            String JsonMsg = JSON.serialize(ccr);
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/CreateCustomerRecord';  //Request URL
            req.httpMethod = 'POST';//HTTP Request Type
            req.requestBody = Blob.valueof(JsonMsg);
            RestContext.request = req;
            RestContext.response= res;
            BWCLM_CreateCustomerRecordCallIn.doPost();
            System.assertEquals(200,res.statuscode);
        Test.stopTest();
    }

    @isTest
    private static void dopostRecExists() {
        Account acct = BWC_TestDataFactory.createAccount();
        Billing_Account__c billAcct = BWC_TestDataFactory.createBillingAccount('Wireless',acct);
        Test.startTest();
            BWCLM_CreateCustomerRecord ccr = new BWCLM_CreateCustomerRecord();
            ccr.firstName = 'Natasha';
            ccr.lastName = 'Romanov';
            ccr.accountNumber_ban = '423432423';
            List<BWCLM_CreateCustomerRecord.Addresses> addrLst = new List<BWCLM_CreateCustomerRecord.Addresses>();
            List<BWCLM_CreateCustomerRecord.PhonesNumbers> phoneLst = new List<BWCLM_CreateCustomerRecord.PhonesNumbers>();
            BWCLM_CreateCustomerRecord.Addresses addr_shipping = new BWCLM_CreateCustomerRecord.Addresses();
            BWCLM_CreateCustomerRecord.Addresses addr_billing = new BWCLM_CreateCustomerRecord.Addresses();
            BWCLM_CreateCustomerRecord.Addresses addr_mailing = new BWCLM_CreateCustomerRecord.Addresses();
            BWCLM_CreateCustomerRecord.Addresses addr_other = new BWCLM_CreateCustomerRecord.Addresses();
            BWCLM_CreateCustomerRecord.PhonesNumbers phone_home = new BWCLM_CreateCustomerRecord.PhonesNumbers();
            BWCLM_CreateCustomerRecord.PhonesNumbers phone_cell = new BWCLM_CreateCustomerRecord.PhonesNumbers();
            BWCLM_CreateCustomerRecord.PhonesNumbers phone_mobile = new BWCLM_CreateCustomerRecord.PhonesNumbers();
            BWCLM_CreateCustomerRecord.PhonesNumbers phone_contact = new BWCLM_CreateCustomerRecord.PhonesNumbers();
            BWCLM_CreateCustomerRecord.PhonesNumbers phone_work = new BWCLM_CreateCustomerRecord.PhonesNumbers();
            BWCLM_CreateCustomerRecord.PhonesNumbers phone_fax = new BWCLM_CreateCustomerRecord.PhonesNumbers();
            addr_shipping.addressType = 'shipping';
            addrLst.add(addr_shipping);
            addr_billing.addressType = 'billing';
            addrLst.add(addr_billing);
            addr_mailing.addressType = 'mailing';
            addrLst.add(addr_mailing);
            addr_other.addressType = 'other';
            addrLst.add(addr_other);
            ccr.addresses = addrLst;
            phone_home.phoneNumber = '3053942286';
            phone_home.phoneType = 'home';
            phoneLst.add(phone_home);
            phone_cell.phoneNumber = '3053942286';
            phone_cell.phoneType = 'cell';
            phoneLst.add(phone_cell);
            phone_mobile.phoneNumber = '3053942286';
            phone_mobile.phoneType = 'mobile';
            phoneLst.add(phone_mobile);
            phone_contact.phoneNumber = '3053942286';
            phone_contact.phoneType = 'contact';
            phoneLst.add(phone_contact);
            phone_work.phoneNumber = '3053942286';
            phone_work.phoneType = 'work';
            phoneLst.add(phone_work);
            phone_fax.phoneNumber = '3053942286';
            phone_fax.phoneType = 'fax';
            phoneLst.add(phone_fax);
            ccr.phonesNumbers = phoneLst;
            String JsonMsg = JSON.serialize(ccr);
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/CreateCustomerRecord';  //Request URL
            req.httpMethod = 'POST';//HTTP Request Type
            req.requestBody = Blob.valueof(JsonMsg);
            RestContext.request = req;
            RestContext.response= res;
            BWCLM_CreateCustomerRecordCallIn.doPost();
            System.assertEquals(200,res.statuscode);
        Test.stopTest();
    }

    @isTest
    private static void dopostRecExistsNameNotMatch() {
        Account acct = BWC_TestDataFactory.createAccount();
        Billing_Account__c billAcct = BWC_TestDataFactory.createBillingAccount('Wireless',acct);
        Test.startTest();
            BWCLM_CreateCustomerRecord ccr = new BWCLM_CreateCustomerRecord();
            ccr.firstName = 'Natasha1';
            ccr.lastName = 'Romanov1';
            ccr.accountFirstName = 'Natasha1';
            ccr.accountLastName = 'Romanov1';
            ccr.accountNumber_ban = '423432423';
            List<BWCLM_CreateCustomerRecord.Addresses> addrLst = new List<BWCLM_CreateCustomerRecord.Addresses>();
            List<BWCLM_CreateCustomerRecord.PhonesNumbers> phoneLst = new List<BWCLM_CreateCustomerRecord.PhonesNumbers>();
            BWCLM_CreateCustomerRecord.Addresses addr_shipping = new BWCLM_CreateCustomerRecord.Addresses();
            BWCLM_CreateCustomerRecord.Addresses addr_billing = new BWCLM_CreateCustomerRecord.Addresses();
            BWCLM_CreateCustomerRecord.Addresses addr_mailing = new BWCLM_CreateCustomerRecord.Addresses();
            BWCLM_CreateCustomerRecord.Addresses addr_other = new BWCLM_CreateCustomerRecord.Addresses();
            BWCLM_CreateCustomerRecord.PhonesNumbers phone_home = new BWCLM_CreateCustomerRecord.PhonesNumbers();
            BWCLM_CreateCustomerRecord.PhonesNumbers phone_cell = new BWCLM_CreateCustomerRecord.PhonesNumbers();
            BWCLM_CreateCustomerRecord.PhonesNumbers phone_mobile = new BWCLM_CreateCustomerRecord.PhonesNumbers();
            BWCLM_CreateCustomerRecord.PhonesNumbers phone_contact = new BWCLM_CreateCustomerRecord.PhonesNumbers();
            BWCLM_CreateCustomerRecord.PhonesNumbers phone_work = new BWCLM_CreateCustomerRecord.PhonesNumbers();
            BWCLM_CreateCustomerRecord.PhonesNumbers phone_fax = new BWCLM_CreateCustomerRecord.PhonesNumbers();
            addr_shipping.addressType = 'shipping';
            addrLst.add(addr_shipping);
            addr_billing.addressType = 'billing';
            addrLst.add(addr_billing);
            addr_mailing.addressType = 'mailing';
            addrLst.add(addr_mailing);
            addr_other.addressType = 'other';
            addrLst.add(addr_other);
            ccr.addresses = addrLst;
            phone_home.phoneNumber = '3053942286';
            phone_home.phoneType = 'home';
            phoneLst.add(phone_home);
            phone_cell.phoneNumber = '3053942286';
            phone_cell.phoneType = 'cell';
            phoneLst.add(phone_cell);
            phone_mobile.phoneNumber = '3053942286';
            phone_mobile.phoneType = 'mobile';
            phoneLst.add(phone_mobile);
            phone_contact.phoneNumber = '3053942286';
            phone_contact.phoneType = 'contact';
            phoneLst.add(phone_contact);
            phone_work.phoneNumber = '3053942286';
            phone_work.phoneType = 'work';
            phoneLst.add(phone_work);
            phone_fax.phoneNumber = '3053942286';
            phone_fax.phoneType = 'fax';
            phoneLst.add(phone_fax);
            ccr.phonesNumbers = phoneLst;
            String JsonMsg = JSON.serialize(ccr);
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/CreateCustomerRecord';  //Request URL
            req.httpMethod = 'POST';//HTTP Request Type
            req.requestBody = Blob.valueof(JsonMsg);
            RestContext.request = req;
            RestContext.response= res;
            BWCLM_CreateCustomerRecordCallIn.doPost();
            System.assertEquals(200,res.statuscode);
        Test.stopTest();
    }
}