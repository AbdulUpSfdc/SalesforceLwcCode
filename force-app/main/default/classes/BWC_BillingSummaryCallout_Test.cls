/* ================================================
* @class name: BWC_BillingSummaryCallout_Test
* @author: Salesforce Inc.
* @group: Billing Summary
* @purpose: Test coverage for BWC_BillingSummaryCallout.
* @created date (mm/dd/yyyy) :  10/01/2020
================================================*/ 
@isTest
public with sharing class BWC_BillingSummaryCallout_Test {
    public BWC_BillingSummaryCallout_Test() {

    }

    @TestSetup
    static void setupData() {
        Account acctObj = BWC_TestDataFactory.createAccount();
        Billing_Account__c billAcctObj = BWC_TestDataFactory.createBillingAccount('Wireless',acctObj);
        billAcctObj.Billing_Account_Number__c = '287263650846';
        update billAcctObj;
    }

    @isTest
    private static void getBillingDataTest() {        

        Test.startTest();
        BWC_BillingSummaryCallout callout = new BWC_BillingSummaryCallout();
        BWC_BillingSummaryCallout.BillingSummaryRequest request = new BWC_BillingSummaryCallout.BillingSummaryRequest();
        request = new BWC_BillingSummaryCallout.BillingSummaryRequest('wireless', '287263650846');

        
        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_BillingSummaryMock', 200);

        HttpResponse response = BWC_BillingSummaryCallout.getBillingData(new List<BWC_BillingSummaryCallout.BillingSummaryRequest> {request});

        Test.stopTest();
        System.assertEquals(200, response.getStatusCode());
    }
    
    @isTest
    private static void getBillingDataTest_Error() {

        Test.startTest();
        BWC_BillingSummaryCallout callout = new BWC_BillingSummaryCallout();
        BWC_BillingSummaryCallout.BillingSummaryRequest request = new BWC_BillingSummaryCallout.BillingSummaryRequest();
        request = new BWC_BillingSummaryCallout.BillingSummaryRequest('wireless', '287263650846');

        
        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_BillingSummaryMock', 400);
        try {
            HttpResponse response = BWC_BillingSummaryCallout.getBillingData(new List<BWC_BillingSummaryCallout.BillingSummaryRequest> {request});
            // Should not reach here.
            System.assertEquals(0, 1);
        }
        catch (Exception ex) {
            System.assertEquals(1, 1);
        }
        Test.stopTest();
        
    }
    
    @isTest
    private static void getBillingDataTest_NoData() {
        
        Test.startTest();
        BWC_BillingSummaryCallout callout = new BWC_BillingSummaryCallout();
        BWC_BillingSummaryCallout.BillingSummaryRequest request = new BWC_BillingSummaryCallout.BillingSummaryRequest();
        request = new BWC_BillingSummaryCallout.BillingSummaryRequest('wireless', '287263650846');

        
        
        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_BillingSummaryMock', 404);

        HttpResponse response = BWC_BillingSummaryCallout.getBillingData(new List<BWC_BillingSummaryCallout.BillingSummaryRequest> {request});

        Test.stopTest();
        System.assertEquals(404, response.getStatusCode());
        
    }
}