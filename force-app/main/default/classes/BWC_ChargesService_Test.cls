/*
    Unit Test coverage for BWC_ChargesService & BWC_ChargesCallout.
*/
@isTest
public with sharing class BWC_ChargesService_Test {

    private static String ATTUID = 'ab102x';

    @TestSetup
    static void makeData(){

        User u = [SELECT Id FROM User where Id=:UserInfo.getUserId() LIMIT 1];

        u.ATTUID__c = ATTUID;

        update u;

        SOA_Level__c soaLevel = BWC_TestDataFactory.createSOA('Centers','Collections','Collections','Level 1','Wireless',100);
        insert soaLevel;

        Employee__c e = BWC_TestDataFactory.createEmployeeWithSOA(soaLevel, ATTUID, UserInfo.getUserId());
        e.SFProfileId__c = 'test profile';
        insert e;
    }

    @isTest
    private static void test_CreateChargeCallout() {

        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('L1', 'PASSCODE');
        
        // Set mock response
        BWC_ApiMock.setTestApiMock(BWC_ChargesCallout.API_CREATE_CHARGE, 'UT_Create_Charge');

        BWC_Charges.CreateChargeRequest request = new BWC_Charges.CreateChargeRequest();
        request.chargeInfo = new List<BWC_Charges.ChargeInfo>();

        BWC_Charges.CreateChargeResponse response = BWC_ChargesService.createCharge(
            interaction.id, 
            request
        );
    }
}