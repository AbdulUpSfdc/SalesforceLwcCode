/*
    Unit test coverage for BWC_NotesSearchService.
*/
@isTest
public with sharing class BWC_NotesSearchService_Test {

    @isTest
    static void test_BWC_NotesSearchService(){
        
        Account testAccount = BWC_TestDataFactory.createAccount();
        Billing_Account__c billingAccount = BWC_TestDataFactory.createBillingAccount(BWC_Constants.BillingAccount_AccountType_Wireless, testAccount);
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(testAccount);
        BWC_NotesSearch.NotesSearchRequest nsr = BWC_TestDataFactory.createNotesSearchRequest();
        Test.startTest();
        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_NotesSearchMock', 200);
        // Make call
        BWC_NotesSearchService.GetNotesSearchService getNotesSearch = new BWC_NotesSearchService.GetNotesSearchService(interaction.Id, nsr);
        Test.stopTest();
        System.assertNotEquals(null, getNotesSearch);   
        
    }
}