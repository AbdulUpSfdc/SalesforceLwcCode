/*
    Test class to test BWC_LIC_OpusBgUtilController
*/
@isTest
public without sharing class BWC_LIC_OpusBgUtilController_Test {

    public static String userName;

    @isTest
    private static void test_getInitDetails() {
        Map<String,String> opusMap =
                BWC_LIC_OpusBgUtilController.getInitDetails();
        System.assertEquals('OPUS-interaction',opusMap.get('WindowName'));
    }

    @isTest
    private static void test_canLaunchOpus() {
        User u = BWC_TestDataFactory.createC360AgentUser();
        Account acctObj = BWC_TestDataFactory.createAccount();
        String recType = BWC_Constants.BillingAccount_AccountType_Wireless;
        Billing_Account__c biilAcctObj =
                    BWC_TestDataFactory.createBillingAccount(recType,acctObj);
        Interaction__c interact = BWC_TestDataFactory.createInteraction(acctObj);
        System.runAs(u) {
            Map<String,String> b = BWC_LIC_OpusBgUtilController.canLaunchOpus(interact.Id);
            //System.assertEquals(true,b);
        }
    }

    @isTest
    private static void test_canLaunchOpus_Negative() {
        User u = BWC_TestDataFactory.createC360AgentUser();
        Account acctObj = BWC_TestDataFactory.createAccount();
        String recType = BWC_Constants.BillingAccount_AccountType_Wireless;
        Billing_Account__c biilAcctObj =
                    BWC_TestDataFactory.createBillingAccount(recType,acctObj);
        Interaction__c interact = BWC_TestDataFactory.createInteraction(acctObj);
        u.ATTUID__c = '';
        update u;
        System.runAs(u) {
            Map<String,String> b = BWC_LIC_OpusBgUtilController.canLaunchOpus(interact.Id);
            //System.assertEquals(true,b);
        }
    }

    /*@isTest
    private static void test_getInitMessage() {
        User u = BWC_TestDataFactory.createC360AgentUser();
        Account acctObj = BWC_TestDataFactory.createAccount();
        String recType = BWC_Constants.BillingAccount_AccountType_Wireless;
        Billing_Account__c biilAcctObj =
                    BWC_TestDataFactory.createBillingAccount(recType,acctObj);
        Interaction__c interact = BWC_TestDataFactory.createInteractionWithAuthorization(acctObj, biilAcctObj);
        interact.Is_Authorized__c = true;
        update interact;
        
        System.runAs(u) {
            String stat = 'opus_sf_init';
            String msg = BWC_LIC_OpusBgUtilController.getInitMessage(stat,interact.Id, true);
            System.assertNotEquals(null,msg);
            BWC_LIC_OpusMsgRequest.OpusPost  postmsg =
            (BWC_LIC_OpusMsgRequest.OpusPost)JSON.deserialize(msg, BWC_LIC_OpusMsgRequest.OpusPost.class);
            System.assertEquals(stat,postmsg.msg.task);
        }
    }
    
    @isTest
    private static void test_getInitMessage_Neg() {
        try
        {
            User u = BWC_TestDataFactory.createC360AgentUser();
            Account acctObj = BWC_TestDataFactory.createAccount();
            String recType = BWC_Constants.BillingAccount_AccountType_Wireless;
            Billing_Account__c biilAcctObj =
                BWC_TestDataFactory.createBillingAccount(recType,acctObj);
            
            System.runAs(u) {
                String stat = 'opus_sf_init';
                String msg = BWC_LIC_OpusBgUtilController.getInitMessage(stat, null, true);
                System.assertNotEquals(null,msg);
                BWC_LIC_OpusMsgRequest.OpusPost  postmsg =
                    (BWC_LIC_OpusMsgRequest.OpusPost)JSON.deserialize(msg, BWC_LIC_OpusMsgRequest.OpusPost.class);
                System.assertEquals(stat,postmsg.msg.task);
            }
        } catch(exception e){
        } 
    }

    @isTest
    private static void test_getTrackingIdent() {
        User u = BWC_TestDataFactory.createC360AgentUser();
        Account acctObj = BWC_TestDataFactory.createAccount();
        String recType = BWC_Constants.BillingAccount_AccountType_Wireless;
        Billing_Account__c biilAcctObj =
                    BWC_TestDataFactory.createBillingAccount(recType,acctObj);
        Interaction__c interact = BWC_TestDataFactory.createInteraction(acctObj);
        System.runAs(u) {
            String stat = 'opus_sf_init';
            String msg = BWC_LIC_OpusBgUtilController.getInitMessage(stat,interact.Id, true);
            ApexPages.currentPage().getParameters().put('id', interact.Id);
            BWC_LIC_OpusMsgController msgCtr = new BWC_LIC_OpusMsgController();
            msgCtr.postToOPUS();
            String trackingIdent =  BWC_LIC_OpusBgUtilController.getTrackingIdent(interact.Id);
            System.assertNotEquals(null,trackingIdent);
        }
    }

    @isTest
    private static void test_getTrackingIdent_Neg(){
        User u = BWC_TestDataFactory.createC360AgentUser();
        Account acctObj = BWC_TestDataFactory.createAccount();
        String recType = BWC_Constants.BillingAccount_AccountType_Wireless;
        Billing_Account__c biilAcctObj =
                    BWC_TestDataFactory.createBillingAccount(recType,acctObj);
        Interaction__c interact = BWC_TestDataFactory.createInteraction(acctObj);
        System.runAs(u) {
            String stat = 'opus_sf_init';
            String msg = BWC_LIC_OpusBgUtilController.getInitMessage(stat,interact.Id, true);
            ApexPages.currentPage().getParameters().put('id', interact.Id);
            BWC_LIC_OpusMsgController msgCtr = new BWC_LIC_OpusMsgController();
            msgCtr.postToOPUS();
            String trackingIdent =  BWC_LIC_OpusBgUtilController.getTrackingIdent(null);
            System.assertEquals(null,trackingIdent);
        }
    }*/

    @IsTest
    static void test_logOpusResponse(){

        Test.startTest();
        Account acctObj = BWC_TestDataFactory.createAccount();
        String recType = BWC_Constants.BillingAccount_AccountType_Wireless;
        Billing_Account__c biilAcctObj =
                    BWC_TestDataFactory.createBillingAccount(recType,acctObj);
        Interaction__c interact = BWC_TestDataFactory.createInteraction(acctObj);

        Map<String, String> opusResponse = new Map<String, String>{
            'task'=>'opus_sf_ready',
            'trackingIdent'=>'SALESFORCE-EM539E-483480-06102021-0017-24-503'
        };

        String opusResponseStr = JSON.serialize(opusResponse);
        BWC_LIC_OpusBgUtilController.logOpusResponse(opusResponseStr, interact.Id, false);

        Test.stopTest();

    }

    @IsTest
    static void test_logOpusResponseError(){

        Test.startTest();
        Account acctObj = BWC_TestDataFactory.createAccount();
        String recType = BWC_Constants.BillingAccount_AccountType_Wireless;
        Billing_Account__c biilAcctObj =
                    BWC_TestDataFactory.createBillingAccount(recType,acctObj);
        Interaction__c interact = BWC_TestDataFactory.createInteraction(acctObj);

        Map<String, String> opusResponse = new Map<String, String>{
            'task'=>'opus_sf_ready', 
            'trackingIdent'=>'SALESFORCE-EM539E-483480-06102021-0017-24-503'
        };

        String opusResponseStr = JSON.serialize(opusResponse);
        BWC_LIC_OpusBgUtilController.logOpusResponse(opusResponseStr, interact.Id, true);

        Test.stopTest();

    }
}