@IsTest
public with sharing class BWC_ServiceAvailabilityServiceTest {
    @TestSetup
    static void makeData(){
        Account acctObj = BWC_TestDataFactory.createAccount();
        String recType = BWC_Constants.BillingAccount_AccountType_Wireless;
        Billing_Account__c billAcctObj = BWC_TestDataFactory.createBillingAccount(recType,acctObj);
        Interaction__c interact = BWC_TestDataFactory.createInteraction(acctObj);
        interact.Billing_Account__c = billAcctObj.Id;

        update interact;
    }

    @IsTest
    static void getServiceAvailabilityTest(){

        BWC_Utils.setStaticResourceMock('BWC_ServiceAvailabilityResponse', 200);
        Test.startTest();
        Id interactionId = [SELECT ID FROM Interaction__c LIMIT 1].Id;

        //BWC_ServiceAvailability.ServiceAvailabilityRequest request = BWC_ServiceAvailabilityController.getRequest(interactionId);
        //BWC_ServiceAvailability.ServiceAvailabilityResponse response = BWC_ServiceAvailabilityService.getServiceAvailability(request);

        Test.stopTest();

    }
}