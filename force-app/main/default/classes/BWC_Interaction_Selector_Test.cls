@IsTest
public with sharing class BWC_Interaction_Selector_Test {

    @TestSetup
    static void makeData(){
        Account acc = BWC_TestDataFactory.createAccount();
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(acc);
    }

    @IsTest
    static void getInteractionTest(){

        Test.startTest();
        String recordId = [SELECT Id FROM Interaction__c LIMIT 1].Id;
        Interaction__c interaction = BWC_Interaction_Selector.getInteraction(recordId);
        Test.stopTest();

    }


}