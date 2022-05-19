@isTest
public with sharing class BWC_ChargeCodesTest {
    
    @isTest
    public static void chargeCodesTest() {

        Integer numberOf = 5;
        String billingMarket = 'NBI';

        insert BWC_TestDataFactory.getChargeCodesByMarket(numberOf, billingMarket);

        List<Charge_Code_By_Market__c> response = BWC_ChargeCodeServiceController.getChargeCodesByMarket(billingMarket);
        
        System.assert(response.size() == numberOf, 'No Charge Codes were retrieved.');
        System.assert(response[0].Market_Code__c == billingMarket, 'Charge Codes billing market does not match.');
    }

    @isTest
    public static void chargeCodesNullRequestTest() {

        try {
            BWC_ChargeCodeServiceController.getChargeCodesByMarket(null);
        }  catch(BWC_Exception e) {
            System.assert(e != null, 'Null Parameter was not caught.');
        }

        try {
            BWC_ChargeCodeService.getChargeCodesByMarket(null);
        } catch(BWC_Exception e) {
            System.assert(e != null, 'Null Parameter was not caught.');
        }
    }

    @isTest
    public static void reasonCodeTest() {
        
        Integer numberOf = 10;
        String chargeCode = '1STNET';
        String chargeType = 'Data MRC';

        insert BWC_TestDataFactory.getReasonsForChargeCode(numberOf, chargeCode, chargeType);

        List<Reason_Code_for_Charge_Code__c> response = BWC_ChargeCodeServiceController.getReasonForChargeCode(chargeCode, chargeType);

        System.assert(response.size() == numberOf, 'No Reason Codes were retrieved.');
        System.assert(response[0].Charge_Code__c == chargeCode, 'Reason Codes charge code does not match.');
        System.assert(response[0].Charge_Type__c == chargeType, 'Reason Codes charge type does not match.');
    }

    @isTest
    public static void getGoodwillAdjustmentReasonsTest() {
        
        Integer numberOf = 10;
        String chargeCode = '1STNET';
        String chargeType = 'Goodwill';

        insert BWC_TestDataFactory.getReasonsForChargeCode(numberOf, chargeCode, chargeType);

        List<Reason_Code_for_Charge_Code__c> response = BWC_ChargeCodeServiceController.getGoodwillAdjustmentReasons();

        System.assert(response.size() == numberOf, 'No Reason Codes were retrieved.');
        System.assert(response[0].Charge_Type__c == chargeType, 'Reason Code is not goodwill.');
    }

    @isTest
    public static void getLineItemAdjustmentReasonsTest() {
        
        Integer numberOf = 10;
        String chargeCode = '1STNET';
        String chargeType = 'Non-Goodwill';

        insert BWC_TestDataFactory.getReasonsForChargeCode(numberOf, chargeCode, chargeType);

        List<Reason_Code_for_Charge_Code__c> response = BWC_ChargeCodeServiceController.getLineItemAdjustmentReasons();

        System.assert(response.size() == numberOf, 'No Reason Codes were retrieved.');
        System.assert(response[0].Charge_Type__c == chargeType, 'Reason Code should not be Goodwill.');
    }

    @isTest
    public static void reasonCodeNullTest() {
        try {
            BWC_ChargeCodeServiceController.getReasonForChargeCode(null, 'chargeCode');
        } catch(BWC_Exception e) {
            System.assert(e != null, 'Null Parameter chargeType was not caught.');
        }

        try {
            BWC_ChargeCodeServiceController.getReasonForChargeCode('chargeType', null);
        } catch(BWC_Exception e) {
            System.assert(e != null, 'Null Parameter chargeCode was not caught.');
        }

        try {
            BWC_ChargeCodeService.getReasonForChargeCode(null, 'chargeCode');
        } catch(BWC_Exception e) {
            System.assert(e != null, 'Null Parameter chargeType was not caught.');
        }

        try {
            BWC_ChargeCodeService.getReasonForChargeCode('chargeType', null);
        } catch(BWC_Exception e) {
            System.assert(e != null, 'Null Parameter chargeCode was not caught.');
        }
    }

    @isTest
    public static void incrementChargeCodeUseCount_Test() {

        Charge_Code_By_Market__c[] chargeCodes = BWC_TestDataFactory.getChargeCodesByMarket(5, 'DLS');

        Charge_Code_By_Market__c chargeCode = chargeCodes[0];

        insert chargeCode;

        BWC_ChargeCodeService.incrementChargeCodeUseCount(chargeCode.Id);

        Charge_Code_By_Market__c[] incrementedChargeCodes = [
            SELECT Id, Used_Count__c 
            FROM Charge_Code_By_Market__c
            WHERE Id = :chargeCode.Id
        ];

        System.assert(chargeCode.Used_Count__c == null, 'Charge Code has a count already set during insert.');

        System.assert( 
            incrementedChargeCodes[0].Used_Count__c == 1,
            'Charge_Code_By_Market__c.Used_Count__c was not incremented.'
        );

        BWC_ChargeCodeService.incrementChargeCodeUseCount(chargeCode.Id);

        Charge_Code_By_Market__c[] incrementedChargeCodes2 = [
            SELECT Id, Used_Count__c 
            FROM Charge_Code_By_Market__c
            WHERE Id = :chargeCode.Id
        ];

        System.assert( 
            incrementedChargeCodes2[0].Used_Count__c == (incrementedChargeCodes[0].Used_Count__c + 1),
            'Charge_Code_By_Market__c.Used_Count__c was not incremented.'
        );
    }

    @isTest
    public static void incrementChargeCodeUseCount_NullTest() {
        try {
            BWC_ChargeCodeService.incrementChargeCodeUseCount(null);
        } catch(BWC_Exception e) {
            System.assert(e != null, 'Null Parameter chargeCodeId was not caught.');
        }
    }

    @isTest
    public static void incrementReasonCodeUseCount_Test() {

        Reason_Code_for_Charge_Code__c[] reasonCodes = BWC_TestDataFactory.getReasonsForChargeCode(1, 'AD345', 'Goodwill');

        Reason_Code_for_Charge_Code__c reasonCode = reasonCodes[0];

        insert reasonCode;

        system.debug(reasonCode);

        BWC_ChargeCodeService.incrementReasonCodeUseCount(reasonCode.Id);

        Reason_Code_for_Charge_Code__c[] incrementedReasonCodes = [
            SELECT Id, Used_Count__c 
            FROM Reason_Code_for_Charge_Code__c
            WHERE Id = :reasonCode.Id
        ];

        System.assert(reasonCode.Used_Count__c == null, 'Reason Code has a count already set during insert.');

        System.assert( 
            incrementedreasonCodes[0].Used_Count__c == 1,
            'Reason_Code_for_Charge_Code__c.Used_Count__c was not incremented.'
        );

        BWC_ChargeCodeService.incrementReasonCodeUseCount(reasonCode.Id);

        Reason_Code_for_Charge_Code__c[] incrementedReasonCodes2 = [
            SELECT Id, Used_Count__c 
            FROM Reason_Code_for_Charge_Code__c
            WHERE Id = :reasonCode.Id
        ];

        System.assert( 
            incrementedreasonCodes2[0].Used_Count__c == (incrementedreasonCodes[0].Used_Count__c + 1),
            'Reason_Code_for_Charge_Code__c.Used_Count__c was not incremented.'
        );
    }

    @isTest
    public static void incrementReasonCodeUseCount_NullTest() {
        try {
            BWC_ChargeCodeService.incrementReasonCodeUseCount(null);
        } catch(BWC_Exception e) {
            System.assert(e != null, 'Null Parameter reasonCodeId was not caught.');
        }
    }

}