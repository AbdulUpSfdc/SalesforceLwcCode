@isTest
public with sharing class BWC_InteractionsWithActivitiesCont_Tst {
    private static final String EQUIPMENT_REPLACEMENT_OPTIONS_ACTION = 'Equipment | Replacement options';
    private static final String ACCOUNT_INQUIRY_TYPE = 'Account Inquiry';
    private static final String DETAIL_RECORD = '{"ban":"287273122837"}';
    private static final String THREEMONTHS = '3 months';
    private static final String ONEYEAR = '1 year';
    private static final String ALLTIME = 'all time';
    private static final String MILLISECS = '0000000000';

    
    @testSetup 
    static void setUpData() {
        Account acct = BWC_TestDataFactory.createAccount();
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(acct);
		Billing_Account__c billing = BWC_TestDataFactory.createBillingAccount('',acct);
        BWC_InteractionActivity.createInteractionActivity(interaction.Id, EQUIPMENT_REPLACEMENT_OPTIONS_ACTION, DETAIL_RECORD);
    }

    @isTest 
    static void testgetInteractionRecordList(){
       
        Interaction__c interaction =[SELECT id FROM Interaction__c LIMIT 1];
       
        BWC_InteractionsWithActivitiesController.getInteractionRecordList(interaction.id, THREEMONTHS, MILLISECS);

    }
    @isTest 
    static void testhandleDateFilterLogic(){
       
        BWC_InteractionsWithActivitiesController.handleDateFilterLogic(THREEMONTHS, MILLISECS);
        BWC_InteractionsWithActivitiesController.handleDateFilterLogic(ONEYEAR, MILLISECS);
        BWC_InteractionsWithActivitiesController.handleDateFilterLogic(ALLTIME, MILLISECS);


    }
    @isTest 
    static void testgetRelatedRecords(){
       
        Interaction__c interaction =[SELECT id FROM Interaction__c LIMIT 1];
        BWC_InteractionsWithActivitiesController.getRelatedRecords(interaction.id);
       

    }

}