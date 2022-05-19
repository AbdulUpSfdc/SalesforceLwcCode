public with sharing class BWC_ChargeCodeService {
    
    public static List<Charge_Code_By_Market__c> getChargeCodesByMarket(String billingMarket) {

        if (billingMarket == null) {
            throw new BWC_Exception('Argument required: billingMarket');
        }

        List<Charge_Code_By_Market__c> chargeCodes = [
            SELECT Id, Charge_Code__c, Charge_Code_Description__c, Charge_Amount__c, Market_Code__c, Used_Count__c, Charge_Level__c
            FROM Charge_Code_By_Market__c 
            WHERE Market_Code__c = :billingMarket
            ORDER BY Used_Count__c DESC, Charge_Code__c ASC
        ];

        return chargeCodes;
    }

    public static List<Reason_Code_for_Charge_Code__c> getReasonForChargeCode(String chargeCode, String chargeType) {

        if(chargeCode == null) {
            throw new BWC_Exception('Argument required: chargeCode');
        }

        // ChargeType as an optional param
        if(chargeType == null) {
            return [
                SELECT Id, Adj_Reason_Explanation_Code__c, Adj_Reason_System_Code__c, Adj_Reason_Description__c, Charge_Code__c, Charge_Type__c, Used_Count__c
                FROM Reason_Code_for_Charge_Code__c
                WHERE Charge_Code__c = :chargeCode 
                ORDER BY Used_Count__c DESC, Charge_Code__c ASC
            ];
        }

        return [
            SELECT Id, Adj_Reason_Explanation_Code__c, Adj_Reason_System_Code__c, Adj_Reason_Description__c, Charge_Code__c, Charge_Type__c, Used_Count__c
            FROM Reason_Code_for_Charge_Code__c
            WHERE Charge_Code__c = :chargeCode 
            AND Charge_Type__c = :chargeType
            ORDER BY Used_Count__c DESC, Charge_Code__c ASC
        ];
    }

    public static List<Reason_Code_for_Charge_Code__c> getGoodwillAdjustmentReasons() {
        return [
            SELECT Id, Adj_Reason_Explanation_Code__c, Adj_Reason_System_Code__c, Adj_Reason_Description__c, Charge_Code__c, Charge_Type__c, Used_Count__c
            FROM Reason_Code_for_Charge_Code__c
            WHERE Charge_Type__c = 'Goodwill'
            ORDER BY Used_Count__c DESC, Charge_Code__c ASC
        ];
    }

    public static List<Reason_Code_for_Charge_Code__c> getLineItemAdjustmentReasons() {
        return [
            SELECT Id, Adj_Reason_Explanation_Code__c, Adj_Reason_System_Code__c, Adj_Reason_Description__c, Charge_Code__c, Charge_Type__c, Used_Count__c
            FROM Reason_Code_for_Charge_Code__c
            WHERE Charge_Type__c != 'Goodwill'
            ORDER BY Used_Count__c DESC, Charge_Code__c ASC
        ];
    }

    public static void incrementChargeCodeUseCount(Id chargeCodeId) {

        if(chargeCodeId == null) {
            throw new BWC_Exception('Argument required: chargeCodeId');
        }

        Charge_Code_By_Market__c[] chargeCodes = [
            SELECT Id, Used_Count__c 
            FROM Charge_Code_By_Market__c
            WHERE Id = :chargeCodeId
        ];

        if(chargeCodes.size() > 0) {
            Charge_Code_By_Market__c chargeCode = chargeCodes[0];
            
            chargeCode.Used_Count__c = 
                (chargeCode.Used_Count__c == null) 
                ? 1
                : chargeCode.Used_Count__c+1;
        }

        update chargeCodes;
    }

    public static void incrementReasonCodeUseCount(Id reasonCodeId) {

        if(reasonCodeId == null) {
            throw new BWC_Exception('Argument required: reasonCodeId');
        }

        Reason_Code_for_Charge_Code__c[] reasonCodes = [
            SELECT Id, Used_Count__c 
            FROM Reason_Code_for_Charge_Code__c
            WHERE Id = :reasonCodeId
        ];

        if(reasonCodes.size() > 0) {
            Reason_Code_for_Charge_Code__c reasonCode = reasonCodes[0];
            
            reasonCode.Used_Count__c = 
                (reasonCode.Used_Count__c == null) 
                ? 1
                : reasonCode.Used_Count__c+1;
        }

        update reasonCodes;
    }
}