public with sharing class BWC_AdjustmentServiceController {
    // Exposed method for getting editable adjustment
    @AuraEnabled
    public static List<Adjustment__c> getEditableAdjustment(String recordId) {
        try {
            return BWC_AdjustmentService.getEditableAdjustment(recordId);
        } catch (System.Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }

    // Exposed method for taking ownership of adjustment case
    @AuraEnabled(cacheable=false)
    public static Boolean takeOwnershipAdjustmentCase(String caseId) {
        try {
            return BWC_AdjustmentService.takeOwnershipAdjustmentCase(caseId);
        } catch (System.Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }
}