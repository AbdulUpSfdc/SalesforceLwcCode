@isTest
public with sharing class BWC_ServiceAction_Controller_Test {





    static testMethod void testGetData() {
        Account acct = BWC_TestDataFactory.createAccount();
        Billing_Account__c billAcctObj = BWC_TestDataFactory.createBillingAccount('Wireless',acct);
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(acct);

        Test.startTest(); 
       string returnV = BWC_ServiceAction_Controller.getData(billAcctObj.id);
        Test.stopTest();

        System.assertNotEquals(null,returnV);
    }
    static testMethod void testGetComboboxOptions() {
        Test.startTest(); 
       string returnV = BWC_ServiceAction_Controller.getComboboxOptions('Product Service');
        Test.stopTest();

        System.assertNotEquals(null,returnV);
    }

}