@IsTest
public with sharing class BWC_InteractionCompleteEvent_Test {

    @TestSetup
    static void makeData(){
        Account acc = BWC_TestDataFactory.createAccount();
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(acc);
    }


    @IsTest
    static void publishTransferEvent(){

        Test.startTest();
        String recordId = [SELECT Id FROM Interaction__c LIMIT 1].Id;
        BWC_InteractionCompleteEvent.publishEvent(recordId, true);
        Test.stopTest();

    }
}