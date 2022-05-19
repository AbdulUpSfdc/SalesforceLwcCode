/*
 Test class to test BWC_LIC_OpusMsgController
*/
@isTest
public with sharing class BWC_LIC_OpusMsgController_Test {

    @isTest
    private static void test_postToOPUS() {
        Account acctObj = BWC_TestDataFactory.createAccount();
        String recType = BWC_Constants.BillingAccount_AccountType_Wireless;
        Billing_Account__c biilAcctObj =
                    BWC_TestDataFactory.createBillingAccount(recType,acctObj);
        Interaction__c interact = BWC_TestDataFactory.createInteraction(acctObj);
        User u = BWC_TestDataFactory.createUser();
        System.runAs(u) {
            ApexPages.currentPage().getParameters().put('id', interact.Id);
            BWC_LIC_OpusMsgController ctr = new BWC_LIC_OpusMsgController();
            ctr.postToOPUS();
        }
    }

    @IsTest
    static void test_postToOPUS_recordIdNull(){

        Test.startTest();

        ApexPages.currentPage().getParameters().put('id', null);
        BWC_LIC_OpusMsgController ctr = new BWC_LIC_OpusMsgController();
        ctr.postToOPUS();

        Test.stopTest();

    }

    @IsTest
    static void test_postToOPUS_AttuidNull(){

        Test.startTest();

        Account acctObj = BWC_TestDataFactory.createAccount();
        String recType = BWC_Constants.BillingAccount_AccountType_Wireless;
        Billing_Account__c biilAcctObj = BWC_TestDataFactory.createBillingAccount(recType,acctObj);
        Interaction__c interact = BWC_TestDataFactory.createInteraction(acctObj);
        User u = BWC_TestDataFactory.createUser();
        u.ATTUID__c = '';
        update u;
        System.runAs(u) {
            ApexPages.currentPage().getParameters().put('id', interact.Id);
            BWC_LIC_OpusMsgController ctr = new BWC_LIC_OpusMsgController();
            ctr.postToOPUS();
        }

        Test.stopTest();

    }

    @IsTest
    static void test_postToOPUS_NoBillingAccount(){

        Test.startTest();

        Account acctObj = BWC_TestDataFactory.createAccount();
        String recType = BWC_Constants.BillingAccount_AccountType_Wireless;
        Billing_Account__c biilAcctObj = BWC_TestDataFactory.createBillingAccount(recType,acctObj);
        Interaction__c interact = BWC_TestDataFactory.createInteraction(acctObj);
        User u = BWC_TestDataFactory.createUser();
        interact.User_Account_Number__c = '951';
        update interact;
        System.runAs(u) {
            ApexPages.currentPage().getParameters().put('id', interact.Id);
            BWC_LIC_OpusMsgController ctr = new BWC_LIC_OpusMsgController();
            ctr.postToOPUS();
        }

        Test.stopTest();

    }

    @IsTest
    static void test_postToOPUS_AuthorizedInteraction(){

        Test.startTest();

        Account acctObj = BWC_TestDataFactory.createAccount();
        String recType = BWC_Constants.BillingAccount_AccountType_Wireless;
        Billing_Account__c biilAcctObj = BWC_TestDataFactory.createBillingAccount(recType,acctObj);
        Interaction__c interact = BWC_TestDataFactory.createInteraction(acctObj);
        User u = BWC_TestDataFactory.createUser();
        interact.Is_Authorized__c = true;
        interact.Authorization_Json__c = '{"associatedAccounts":[{"authorizationLevel":"L1","authenticationMethod":"OTP","accountType":"wireless","accountBan":"423432423"}]}';
        update interact;
        System.runAs(u) {
            ApexPages.currentPage().getParameters().put('id', interact.Id);
            BWC_LIC_OpusMsgController ctr = new BWC_LIC_OpusMsgController();
            ctr.postToOPUS();
        }

        Test.stopTest();

    }


}