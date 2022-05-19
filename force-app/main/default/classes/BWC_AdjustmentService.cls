public with sharing class BWC_AdjustmentService {
    // Get record where user has edit access
    public static List<Adjustment__c> getEditableAdjustment(String recordId) {
        List<Adjustment__c> adjustmentsList = new List<Adjustment__c>();
        Boolean userCanEdit = BWC_Utils.checkRecordEditability(recordId);

        // Checking permissions
        if (!userCanEdit) {
            throw new BWC_Exception('User does not have permission to edit this record.');
        }

        // Getting adjustments
        adjustmentsList = [
            SELECT
                Id,
                Case__r.Id,
                Case__r.Last_Interaction__c,
                Case__r.Last_Interaction__r.Billing_Account_Type__c,
                Case__r.Last_Interaction__r.Billing_Account_Number__c,
                Statement_ID__c,
                Status__c
            FROM Adjustment__c
            WHERE Id = :recordId
        ];

        // If adjustment isn't rejected, throw an error
        if (adjustmentsList[0].Status__c != 'Rejected') {
            throw new BWC_Exception('Adjustment is still open. Please reject the Adjustment first.');
        }

        // Returning results
        return adjustmentsList;
    }

    // Checks if user has the ability to take ownership of an adjustment case and if so, updates case owner
    public static Boolean takeOwnershipAdjustmentCase(String caseId) {
        String message;
        Id userId = UserInfo.getUserId();

        // Getting adjustments based on criteria
		// FLS Not needed, results not returned to user
        List<Adjustment__c> adjustmentsList = [
            SELECT Id, Case__r.OwnerId, Case__c, Delegate_1__c, Delegate_2__c, Status__c
            FROM Adjustment__c
            WHERE
                Case__c = :caseId
                AND (Delegate_1__c = :userId
                OR Delegate_2__c = :userId
                OR Manager__c = :userId)
                AND Status__c = 'Level 1 (Manager)'
        ];

        // If query returns results, execute ownership update and return Boolean
        if (adjustmentsList.size() > 0) {
            Case obj = [SELECT id, OwnerId FROM Case WHERE Id = :caseId LIMIT 1];
            obj.OwnerId = userId;
            update obj;
            return true;
        } else {
            return false;
        }
    }
}