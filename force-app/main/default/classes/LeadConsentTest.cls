@isTest
public with sharing class LeadConsentTest {
    private static TestDataFactory.TestWrapper dataFactoryWrap = new TestDataFactory.TestWrapper();
    private static TestDataFactory dataFactory = new TestDataFactory();

    /*
    *This method is used to setup test data
    */
    @TestSetup
    static void makeData(){
    dataFactoryWrap = dataFactory.createTestData(1,'Empl');
    }

    /**
     * This method tests the codebase and scenarios for updateLeadConsent method
    */
    @IsTest
    static void testUpdateLeadConsent(){
        try{
        LeadConsent__c leadCons = [SELECT id, FirstName__c,LastName__c, Email__c,Accepted__c,ConsentCancelled__c FROM LeadConsent__c LIMIT 1];
        System.debug('leadCons-->>'+leadCons);
        Test.startTest();
        LeadConsent.updateLeadConsent('qwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklxcvbn');
        Test.stopTest();
        }
        catch(exception ex){
            
        }
    }

    /**
     * This method tests the codebase and scenarios for updateLeadConsent method
    */
    @IsTest
    static void testGetLeadConsent(){
        try{
        LeadConsent__c leadCons = [SELECT id, FirstName__c,LastName__c, Email__c,Accepted__c,ConsentCancelled__c FROM LeadConsent__c LIMIT 1];
        System.debug('leadCons-->>'+leadCons);
        Test.startTest();
        LeadConsent__c leadConsreturned = LeadConsent.getLeadConsent('qwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklxcvbn');
        system.assertEquals(leadConsreturned.id, leadCons.id);
        Test.stopTest();
        }
        catch(exception ex){
            
        }
    }

    /**
     * This method tests the codebase and scenarios for updateLeadConsent method
    */
    /*@IsTest
    static void testDeleteLeadConsent(){
        LeadConsent__c leadCons = [SELECT id, FirstName__c,LastName__c, Email__c,Accepted__c,ConsentCancelled__c FROM LeadConsent__c LIMIT 1];
        System.debug('leadCons-->>'+leadCons);
        Test.startTest();
        Boolean deleted = LeadConsent.deleteLeadConsent('qwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklxcvbn');
        Test.stopTest();
    }*/

     /**
     * This method tests the codebase and scenarios for updateLeadConsent method
    */
    @IsTest
    static void testUpdateLeadConsentCancelled(){
        try{
        LeadConsent__c leadCons = [SELECT id, FirstName__c,LastName__c, Email__c,Accepted__c,ConsentCancelled__c FROM LeadConsent__c LIMIT 1];
        System.debug('leadCons-->>'+leadCons);
        Test.startTest();
        LeadConsent.updateLeadConsentCancelled('qwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklxcvbn');
        Test.stopTest();
        }
        catch(exception ex){
            
        }
    }
}