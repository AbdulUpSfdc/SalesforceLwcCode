/* ================================================
* @class name: BWC_BillingAndPaymentsController_Test
* @author: Salesforce Inc.
* @group: Billing Summary
* @purpose: Test coverage for BWC_BillingAndPaymentsController.
* @created date (mm/dd/yyyy) :  10/01/2020
================================================*/ 
@isTest
public with sharing class BWC_BillingAndPaymentsController_Test {
    public BWC_BillingAndPaymentsController_Test() {

    }

    
    @TestSetup
    static void setupData() {
        Account acctObj = BWC_TestDataFactory.createAccount();
        Billing_Account__c billAcctObj = BWC_TestDataFactory.createBillingAccount('Wireless',acctObj);
        billAcctObj.Billing_Account_Number__c = '287263650846';
        update billAcctObj;
    }

    @isTest
    private static void getBillingAndPaymentsDataTest() {

        Account acctObj = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        BWC_BillingAndPaymentsController controller = new BWC_BillingAndPaymentsController();
        
        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_BillingSummaryMock', 200);

        BWC_BillingAndPaymentsController.BillingAndPaymentsResult result = BWC_BillingAndPaymentsController.getBillingAndPaymentsData(acctObj.Id);

        result.billingData[0].autoPay = null;
        result.billingData[0].paperlessBill = null;
        Test.stopTest();
        System.assertEquals(true, result.success);
    }

    

    @isTest
    private static void getBillingAndPaymentsDataTest_Error() {

        Account acctObj = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        
        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_BillingSummaryMock', 400);

        BWC_BillingAndPaymentsController.BillingAndPaymentsResult result = BWC_BillingAndPaymentsController.getBillingAndPaymentsData(acctObj.Id);

        Test.stopTest();
        System.assertEquals(false, result.success);
    }
}