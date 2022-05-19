@IsTest
public with sharing class BWC_CustomerAccountRel_Selector_Test {


    @TestSetup
    static void makeData(){
        Account acct = BWC_TestDataFactory.createAccount();
        Billing_Account__c bill = BWC_TestDataFactory.createBillingAccount('recordTypeName', acct);
    }

    @IsTest
    static void methodName(){

        Test.startTest();
        Id billAccId = [SELECT Id FROM Billing_Account__c LIMIT 1].Id;
        Set<Id> billAcctIds = new Set<Id>();
        billAcctIds.add(billAccId);

        Map<Id, Customer_Account_Relation__c> response = BWC_CustomerAccountRel_Selector.getCustomerAccountRelation(billAcctIds);

        Test.stopTest();

    }
}