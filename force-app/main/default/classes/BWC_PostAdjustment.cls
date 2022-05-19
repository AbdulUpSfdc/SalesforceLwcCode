public with sharing class BWC_PostAdjustment implements Queueable, Database.AllowsCallouts {
    String payload;
    Id adjustmentId;

    public BWC_PostAdjustment(String postAdjustmentPayload, Set<Id> adjustmentIds) {
        this.payload = postAdjustmentPayload;
        this.adjustmentId = new List<Id>(adjustmentIds)[0];
    }

    public void execute(QueueableContext context) {
        if (String.isNotEmpty(this.payload)) {
            Boolean success = false;
            String userId = UserInfo.getUserId();
            String messageText = '';

            // Deserializing request body
            BWC_Adjustments.PostAdjustmentsRequest request = (BWC_Adjustments.PostAdjustmentsRequest) JSON.deserialize(
                payload,
                BWC_Adjustments.PostAdjustmentsRequest.class
            );

            // Getting adjustment
            Adjustment__c adj = [
                SELECT
                    Id,
                    Billing_Account__r.Billing_Account_Number__c,
                    Case__r.Id,
                    Case__r.CaseNumber,
                    Case__r.First_Interaction__c,
                    Status__c
                FROM Adjustment__c
                WHERE Id = :adjustmentId
            ];

            // Attempt callout
            try {
                BWC_AdjustmentsService.postAdjustments(adj.Case__r.First_Interaction__c, request);
                success = true;
            } catch (Exception e) {
                BWC_ExceptionUtils.handleException(e, true);
                success = false;
            }

            // Conditional logic
            if (success == true) {
                if (adj.Status__c == CaseConstants.ADJUSTMENT_STATUS_APPROVED) {
                    // Execute logic if successful
                    adj.Status__c = CaseConstants.ADJUSTMENT_STATUS_POSTED;
                    update adj;

                    // Notify approver on case
                    messageText =
                        'Adjustment successfully posted to customer\'s bill for account number ' +
                        adj.Billing_Account__r.Billing_Account_Number__c +
                        ' and case number ' +
                        adj.Case__r.CaseNumber +
                        '.';
                }
            } else {
                if (adj.Status__c == CaseConstants.ADJUSTMENT_STATUS_APPROVED) {
                    // Execute logic if failed
                    adj.Status__c = CaseConstants.ADJUSTMENT_STATUS_POST_FAILED;
                    update adj;

                    // Notify approver on case
                    messageText =
                        'Adjustment failed to post for account number ' +
                        adj.Billing_Account__r.Billing_Account_Number__c +
                        ' and case number ' +
                        adj.Case__r.CaseNumber +
                        '.';
                }
            }

            // Post Chatter message
            if (String.isNotEmpty(messageText)) {
                BWC_FeedItemTriggerHelperClass.postFeedItemWithMentions(messageText, userId, adj.Case__r.Id);
            }
        }
    }
}