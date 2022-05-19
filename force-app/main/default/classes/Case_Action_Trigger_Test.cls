@isTest
public with sharing class Case_Action_Trigger_Test {


    @isTest
    public static void testCaseAction(){
        Case_Action__c cA = new Case_Action__c();
        Case c = new Case();
        c.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OOP').getRecordTypeId();
       Test.startTest();
        insert c;
        cA.Case__c = c.id;
        insert cA;
        Test.stopTest();
        System.assertNotEquals(null, cA.Id);
    }
    @isTest
    public static void testCaseActionSelectorGetAssignmentQueueId(){

       System.assertNotEquals(null,  Case_Action_Selector.getAssignmentQueueId('Business_SD_OOP_SE', 'Southeast'));

    }
}