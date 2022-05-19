public with sharing class BWC_ChargeCodeServiceController {
    /*
        Return a list of charge codes related to the billing market
    */
    @AuraEnabled
    public static List<Charge_Code_By_Market__c> getChargeCodesByMarket(String billingMarket) {
        try {
            return BWC_ChargeCodeService.getChargeCodesByMarket(billingMarket);
        } catch (Exception e) {
            throw BWC_Controller.handleException(e, 'billingMarket=' + billingMarket);
        }
    }

    @AuraEnabled
    public static List<Reason_Code_for_Charge_Code__c> getReasonForChargeCode(String chargeCode, String chargeType){
        try {
            return BWC_ChargeCodeService.getReasonForChargeCode(chargeCode, chargeType);
        } catch (Exception e) {
            throw BWC_Controller.handleException(e, 'chargeCode: ' + chargeCode + ', ' + 'chargeType: ' + chargeType);
        }
    }

    @AuraEnabled
    public static List<Reason_Code_for_Charge_Code__c> getGoodwillAdjustmentReasons(){
        try {
            return BWC_ChargeCodeService.getGoodwillAdjustmentReasons();
        } catch (Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }

    @AuraEnabled
    public static List<Reason_Code_for_Charge_Code__c> getLineItemAdjustmentReasons(){
        try {
            return BWC_ChargeCodeService.getLineItemAdjustmentReasons();
        } catch (Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }
}