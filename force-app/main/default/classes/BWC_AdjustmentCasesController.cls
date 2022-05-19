public with sharing class BWC_AdjustmentCasesController {
    // Exposed method for approving adjustment
    @AuraEnabled
    public static String approveAdjustmentRequest(Id workItemId, String comments) {
        try {
            return JSON.serialize(BWC_AdjustmentCasesService.approveAdjustmentRequest(workItemId, comments));
        } catch (System.Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }

    // Exposed method for checking if user can approve adjustment
    @AuraEnabled
    public static String checkAdjustmentApprovalPerm(Id workItemId) {
        try {
            return JSON.serialize(BWC_AdjustmentCasesService.checkAdjustmentApprovalPerm(workItemId));
        } catch (System.Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }

    // Exposed method for checking if user can approve adjustment
    @AuraEnabled
    public static String checkRecordEditability(Id workItemId) {
        try {
            return JSON.serialize(BWC_AdjustmentCasesService.checkRecordEditability(workItemId));
        } catch (System.Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }

    // Exposed method for fully rejecting adjustment
    @AuraEnabled
    public static String fullRejectAdjustment(Id workItemId, String comments) {
        try {
            return JSON.serialize(BWC_AdjustmentCasesService.fullRejectAdjustment(workItemId, comments));
        } catch (System.Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }

    // Exposed method for getting adjustment line item
    @AuraEnabled
    public static Adjustment_Line_Item__c getAdjustmentLineItem(String recordId) {
        try {
            return BWC_AdjustmentCasesService.getAdjustmentLineItem(recordId);
        } catch (System.Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }

    // Exposed method for getting editable adjustment
    @AuraEnabled
    public static List<Adjustment__c> getEditableAdjustment(String recordId) {
        try {
            return BWC_AdjustmentCasesService.getEditableAdjustment(recordId);
        } catch (System.Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }

    // Exposed method for getting adjustment history
    @AuraEnabled
    public static String getHistory(String recordId) {
        try {
            return JSON.serialize(BWC_AdjustmentCasesService.getHistory(recordId));
        } catch (System.Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }

    // Exposed method for getting adjustment reason descriptions
    @AuraEnabled
    public static String getReasonDescriptions(String adjType, String chargeCode, String chargeType) {
        try {
            return JSON.serialize(BWC_AdjustmentCasesService.getReasonDescriptions(adjType, chargeCode, chargeType));
        } catch (System.Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }

    // Exposed method for returning back adjustment
    @AuraEnabled
    public static String returnBackAdjustment(Id workItemId, String comments) {
        try {
            return JSON.serialize(BWC_AdjustmentCasesService.returnBackAdjustment(workItemId, comments));
        } catch (System.Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }

    // Exposed method for taking ownership of adjustment case
    @AuraEnabled
    public static Boolean takeOwnershipAdjustmentCase(String caseId) {
        try {
            return BWC_AdjustmentCasesService.takeOwnershipAdjustmentCase(caseId);
        } catch (System.Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }

    // Exposed method for updating adjustment line items
    @AuraEnabled
    public static void updateAdjustmentLineItem(String requestJson) {
        try {
            Adjustment_Line_Item__c request = (Adjustment_Line_Item__c) JSON.deserialize(
                requestJson,
                Adjustment_Line_Item__c.class
            );
            BWC_AdjustmentCasesService.updateAdjustmentLineItem(request);
        } catch (System.Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }
}