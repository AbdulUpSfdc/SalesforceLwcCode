/*
    Unit test coverage for public with sharing class BWC_TermAndConditionController
*/
@isTest
public with sharing class BWC_TermAndConditionController_Test {
    
    @isTest
    private static void test_getTermsAndConditions() {
        String response = BWC_TermAndConditionController.getTermsAndConditions(new LIst<String> {'123'});
        System.assertNotEquals(null, response);
    }

    
    @isTest
    private static void test_getTermsAndConditions_negative() {
        String response = BWC_TermAndConditionController.getTermsAndConditions(new List<String> ());
        System.assertNotEquals(null, response);
    }
}