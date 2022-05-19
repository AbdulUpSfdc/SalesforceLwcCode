@isTest
public with sharing class BWC_Case_Delete_Test {
    
    static testMethod void testDeleteCase() {
        account acct = BWC_TestDataFactory.createAccount();

        case testCase = new case();
        insert testCase;
        test.startTest();
        BWC_Case_Delete.deleteCase(testCase.Id);
        BWC_Case_Delete.deleteCase(null);
        test.stopTest();
    }




}