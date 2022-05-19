/*
    Extra test coverage for BWC_AuthorizationService -- main coverage is provided via BWC_AuthorizationController_Test.
*/
@isTest
public with sharing class BWC_AuthorizationService_Test {

    @isTest
    private static void test_getFullAuthorizationStatus() {

        // Get interaction with step-ups and authenticated with passcode
        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('NONE', 'NONE');

        BWC_AuthorizationCallout.AuthorizationStatusResponse response = BWC_AuthorizationService.getFullAuthorizationStatus(interaction.Id);

    }

}