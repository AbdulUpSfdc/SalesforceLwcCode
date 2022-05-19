@IsTest
public with sharing class BWC_InteractionActivityController_Test {

    @TestSetup
    static void makeData(){
        Account acct = BWC_TestDataFactory.createAccount();
        Billing_Account__c billAcc = BWC_TestDataFactory.createBillingAccount('wireless', acct);
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(acct);
    }

    @IsTest
    static void logActivitiyTest(){

        Test.startTest();

        String action = 'Authentication Bypassed';
        String type = 'Inquiry';

        Interaction__c interaction = [SELECT Id FROM Interaction__c LIMIT 1];

        BWC_InteractionActivityService.InteractionActivity activity = new BWC_InteractionActivityService.InteractionActivity();
        activity.setAction(action)
        .setType(type)
        .setInteractionId(interaction.Id);

        String activityString = JSON.serialize(activity);
        BWC_InteractionActivityController.logActivity(activityString, null);


        List<Interaction_Activity__c> activities = [SELECT Id, Action__c, Type__c FROM Interaction_Activity__c ];
        Interaction_Activity__c intActivity = activities[0];

        System.assert(activities.size()==1);
        System.assertEquals(action, intActivity.Action__c, 'Action does not match');
        System.assertEquals(type, intActivity.Type__c, 'Type does not match');

        Test.stopTest();

    }

    @IsTest
    static void logActivitiyTestNegative(){

        Test.startTest();

        String action = 'Authentication Bypassed';
        String type = 'Bad Type';
        Boolean exceptionThrown = false;

        Interaction__c interaction = [SELECT Id FROM Interaction__c LIMIT 1];

        BWC_InteractionActivityService.InteractionActivity activity = new BWC_InteractionActivityService.InteractionActivity();
        activity.setAction(action)
        .setType(type)
        .setInteractionId(interaction.Id);

        String activityString = JSON.serialize(activity);

        try {

            BWC_InteractionActivityController.logActivity(activityString, null);

        } catch (Exception e) {
            exceptionThrown = true;
        }

        System.assert(exceptionThrown, 'Exception was not thrown');


        Test.stopTest();

    }
}