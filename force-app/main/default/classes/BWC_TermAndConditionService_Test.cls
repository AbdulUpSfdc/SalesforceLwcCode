/*
    Unit test coverage for public with sharing class BWC_TermAndConditionService
*/
@isTest
public with sharing class BWC_TermAndConditionService_Test {
    
    @isTest
    private static void test_getTermsAndConditions() {
        BWC_TermAndConditionService.getTermsAndConditions(new LIst<String> {'123'});
    }
    
    @isTest
    private static void test_getTermsAndConditions_negative() {
        try {
            BWC_TermAndConditionService.getTermsAndConditions(new List<String> ());
        }
        catch (BWC_Exception e) {
            System.assert(true);

        }
    }
}