@isTest
public with sharing class BWC_InteractionTriggerTest {
  
    static testMethod void testInteractionTrigger() {

        Account acct = BWC_TestDataFactory.createAccount();
        acct.CTI_Call_Identifier__c = '1234';
        update acct;
        Billing_Account__c billAcct = BWC_TestDataFactory.createBillingAccount('Wireless', acct);
        billAcct.CTI_Call_Identifier__c = '1234';
        update billAcct;
        Interaction__c interaction =  new Interaction__c();
        interaction.CTI_Call_Identifier__c = '1234';
        interaction.User_Account_Number__c = billAcct.Billing_Account_Number__c;

        Test.startTest(); 
        insert interaction;
        interaction.CompletedDate__c = DateTime.now();
        interaction.Notes__c = 'This BAN 999999999999';
        update interaction;
        Test.stopTest();

        interaction = [SELECT Id, Billing_Account__c FROM Interaction__c WHERE Id = :interaction.Id];

        System.assertEquals(billAcct.Id, interaction.Billing_Account__c);

        
    }
 }