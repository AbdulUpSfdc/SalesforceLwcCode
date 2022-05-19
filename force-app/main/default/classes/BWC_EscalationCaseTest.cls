@isTest
public with sharing class BWC_EscalationCaseTest {

    @TestSetup static void createTestData() {
        Account a0 = BWC_TestDataFactory.createAccount();
        Billing_Account__c ba = BWC_TestDataFactory.createBillingAccount(BWC_Constants.BillingAccount_AccountType_Wireless, a0);

        Account a1 = [select Id, PersonContactId from Account where id = :a0.Id];

        Case c = BWC_TestDataFactory.createEscalatedCase(a0, ba, a1.PersonContactId);

        c.Type = 'Billing | Adjustment';
        c.CaseAction__c = '	Adjustment Wireless | Billing Adjustment - COLL';
        insert c;
    }
   
    @isTest
    public static void getEscalationCasesByBillingAccountTest() {
        
        List<Billing_Account__c> billingAccounts = [select id, Billing_Account_Number__c from Billing_Account__c LIMIT 1];

        System.assert(billingAccounts.size() > 0, 'Failed to create & retrieve test billing account.');
        
        List<Case> response = BWC_EscalationCaseServiceController.getEscalationCasesByBillingAccount(billingAccounts[0].Billing_Account_Number__c);

        System.assert(response.size() > 0, 'Response Failed. Failed to get case list.');
    }

    @isTest
    public static void getEscalationCasesByBillingAccountNullTest() {
        try {
            List<Case> response = BWC_EscalationCaseServiceController.getEscalationCasesByBillingAccount(null);
        } catch(BWC_Exception e) {
            System.assert(e != null, 'failed response was not caught.');
            System.assert(e.getMessage() != null, 'failed response message was not created.');
        }

    }
}