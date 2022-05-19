@isTest
public with sharing class BWC_BillingAccountAction_Test {
    
    @isTest
    private static void testGetBillingAndPaymentsDataTest() {
        string returnValue;
        Test.startTest();
        returnValue = BWC_BillingAccountAction.getAllowedActions();
        Test.stopTest();
    }
}