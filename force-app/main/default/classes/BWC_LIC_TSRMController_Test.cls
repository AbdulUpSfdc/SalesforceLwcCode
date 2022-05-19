@isTest
public with sharing class BWC_LIC_TSRMController_Test {
    private static final String EQUIPMENT_REPLACEMENT_OPTIONS_ACTION = 'Equipment | Replacement options';
    private static final String ACCOUNT_INQUIRY_TYPE = 'Account Inquiry';

    @TestSetup
    static void makeData(){
        BWC_TestDataFactory.createUser();
        Account acct = BWC_TestDataFactory.createAccount();
        BWC_TestDataFactory.createBillingAccount('wireless', acct);
    }

    @isTest
    private static void testGetTSRMMetaData() {
        Test.startTest();
        String response = BWC_LIC_TSRMController.getTSRMMetaData();
        String response1 = BWC_UnauthDeviceIssues.getTSRMMetaData();
        Test.stopTest();
        System.assertNotEquals(null, response);
        System.assertNotEquals(null, response1);

    }
    @isTest
    private static void testGetATTUID() {

        User us = [SELECT Id, ATTUID__c FROM User WHERE ATTUID__c ='md809k' LIMIT 1];
        String response;
        Test.startTest();

        System.runAs(us){
            response = BWC_LIC_TSRMController.getATTUID();
        }

        Test.stopTest();
        System.assertEquals(us.ATTUID__c, response);

    }
    @isTest
    private static void testGetTSRMRequest() {

        String ctn,interactionId,ban = '';
        Test.startTest();
        String response = BWC_LIC_TSRMController.getTSRMRequest(ctn,interactionId,ban);
        String response2 = BWC_LIC_TSRMController.getTSRMRequest('Unauth',interactionId,ban);
        String response3 = BWC_UnauthDeviceIssues.getTSRMRequest('Unauth',interactionId,ban);

        Test.stopTest();
        System.assertNotEquals(null, response);
        System.assertNotEquals(null, response2);
        System.assertNotEquals(null, response3);

    }
    @isTest
    private static void testLogAPICall() {
        String request,response,interactionId;
        request='{"wban":null,"siteName":"Madison - Sales & Service","sfc_intrxn_objid":"testData","ctn":"6086984746","attuid":"ay838t","alrtUserWorkgroup":"Sales & Service","alrtCallerVerifiedInd":"Yes"}';
        response='{"status":200,"statusText":"OK"}';
        Test.startTest();
        String res = BWC_LIC_TSRMController.logAPICall(request, response, interactionId);
        String res2 = BWC_UnauthDeviceIssues.logAPICall(request, response, interactionId);
        Test.stopTest();
        System.assertNotEquals(null, res);
        System.assertNotEquals(null, res2);

    }
    @isTest
    private static void testCreateInteractionActivity() {

        Account acct = [SELECT Id FROM Account LIMIT 1];
        Interaction__c interaction = BWC_TestDataFactory.createInteraction(acct);

        try {
            Test.startTest();
            BWC_UnauthDeviceIssues.createInteractionActivity(interaction.Id, EQUIPMENT_REPLACEMENT_OPTIONS_ACTION, '{"ban":"423432423","ctn":"6086984746","manufacturer":"Apple","makeAndModel":"iPhone 8","service":"232270176","serviceName":"Wireless - 232270176","assetId":"02i3F0000067QPHQA2"}');
            Test.stopTest();    
            Interaction_Activity__c ia = [SELECT Id,Type__c FROM Interaction_Activity__c WHERE Interaction__c = :interaction.Id LIMIT 1];
        System.assertEquals(ACCOUNT_INQUIRY_TYPE, ia.Type__c, 'Unexpected Type__c in Interaction Activity');
        } catch (Exception e) {
            
        }
        

        
    }
}