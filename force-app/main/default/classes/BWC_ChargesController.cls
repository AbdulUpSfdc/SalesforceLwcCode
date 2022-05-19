/*
    Aura Enabled Methods for Charges
*/
public with sharing class BWC_ChargesController {
    
    /*
        Synchronous Method for Create Charge
    */
    @AuraEnabled
    public static Object createCharge(String recordId, String requestJson) {
        try {

            BWC_Log.setRelatedRecordId(recordId);

            BWC_Charges.CreateChargeRequest request =
                (BWC_Charges.CreateChargeRequest) JSON.deserialize(requestJson, BWC_Charges.CreateChargeRequest.class);

            return BWC_ChargesService.createCharge(recordId, request).serialize();
            
        } catch (System.Exception e) {
            throw BWC_Controller.handleException(
                e, 
                'recordId=' + recordId + '|' + 'requestJson=' + requestJson,
                recordId
            );
        }
    }
}