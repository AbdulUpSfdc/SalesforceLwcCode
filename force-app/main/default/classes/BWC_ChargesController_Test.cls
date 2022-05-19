/*
    Unit test coverage for BWC_ChargesController.
*/
@isTest
public with sharing class BWC_ChargesController_Test {
    
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
    private static void test_createCharge() {

        Interaction__c interaction = BWC_TestDataFactory.createFullInteraction('L1', 'PASSCODE');

        Adjustment__c a = BWC_TestDataFactory.createAdjustment();

        BWC_Charges.createChargeRequest request = new BWC_Charges.createChargeRequest();
        request.accountNumber = '177057327797';
        request.chargeInfo = new List<BWC_Charges.ChargeInfo>();

        // Set mock so synchronous response is returned
        BWC_ApiMock.setTestApiMock(BWC_ChargesCallout.API_CREATE_CHARGE, 'UT_Create_Charge');

        String responseJson = (String) BWC_ChargesController.createCharge(
            interaction.id, 
            JSON.serialize(request)
        );

        BWC_Charges.createChargeResponse response = 
            (BWC_Charges.createChargeResponse) JSON.deserialize(responseJson, BWC_Charges.createChargeResponse.class);
    }
}