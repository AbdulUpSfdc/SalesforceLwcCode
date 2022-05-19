public with sharing class BWC_PostPendingAdjustmentSelector {
    public static String createAdjustmentObject(Set<Id> adjustmentIds) {
        Id adjustmentId = new List<Id>(adjustmentIds)[0];

        // Querying SF for Adjustment
        Adjustment__c adjustment = [
            SELECT
                Id,
                Billing_Account__r.Billing_Account_Number__c,
                Billing_Account__r.Account_Type__c,
                Decision_Update_Transaction_ID__c,
                Status__c,
                CreatedBy.ATTUID__c,
                Case__r.First_Interaction__r.Name,
                (
                    SELECT
                        Id,
                        Adjustment_Type__c,
                        Agent_Adjusted_Amount__c,
                        Adj_Reason_System_Code__c,
                        Bill_Date__c,
                        Bill_Seq_Number__c,
                        CDE_Product_Level_Id__c,
                        Charge_Seq_Number__c
                    FROM Adjustment_Line_Items__r
                )
            FROM Adjustment__c
            WHERE Id = :adjustmentId
            LIMIT 1
        ];

        // Creating Adjustment Line Items
        List<BWC_Adjustments.PostAdjustmentsLineItem> lineItemsList = new List<BWC_Adjustments.PostAdjustmentsLineItem>();
        for (Adjustment_Line_Item__c lineItem : adjustment.Adjustment_Line_Items__r) {
            BWC_Adjustments.PostAdjustmentsLineItem postAdjLineItem = new BWC_Adjustments.PostAdjustmentsLineItem();

            postAdjLineItem.adjustedAmount = String.valueOf(lineItem.Agent_Adjusted_Amount__c);
            postAdjLineItem.adjustmentReasonCode = lineItem.Adj_Reason_System_Code__c;
            // Conditional logic depending on whether adjustment is approved or rejected
            postAdjLineItem.billerAdjustmentStatus = adjustment.Status__c != CaseConstants.REJECTED
                ? 'POSTED'
                : 'REJECTED';
            postAdjLineItem.chargeLevel = 'B';
            postAdjLineItem.isGoodwill = lineItem.Adjustment_Type__c == 'Goodwill' ? true : false;
            postAdjLineItem.overridden = true;
            postAdjLineItem.productLevelId = lineItem.CDE_Product_Level_Id__c;
            postAdjLineItem.billSeqNo = lineItem.Bill_Seq_Number__c != null
                ? String.valueOf(lineItem.Bill_Seq_Number__c)
                : null;
            postAdjLineItem.billChrgSeqNo = lineItem.Charge_Seq_Number__c != null
                ? String.valueOf(lineItem.Charge_Seq_Number__c)
                : null;
            postAdjLineItem.billDate = lineItem.Bill_Date__c != null ? String.valueOf(lineItem.Bill_Date__c) : null;

            lineItemsList.add(postAdjLineItem);
        }

        // Creating Adjustment
        BWC_Adjustments.PostAdjustmentsRequest postAdjustmentRequest = new BWC_Adjustments.PostAdjustmentsRequest();

        postAdjustmentRequest.accountNumber = adjustment.Billing_Account__r.Billing_Account_Number__c;
        postAdjustmentRequest.accountType = adjustment.Billing_Account__r.Account_Type__c;
        postAdjustmentRequest.decisionUpdateTrnsId = adjustment.Decision_Update_Transaction_ID__c;
        // Conditional logic depending on whether adjustment is approved or rejected
        postAdjustmentRequest.transBillerAdjustmentStatus = adjustment.Status__c != CaseConstants.REJECTED
            ? 'POSTED'
            : 'REJECTED';
        postAdjustmentRequest.lineItems = lineItemsList;
        postAdjustmentRequest.interactionId = adjustment.Case__r.First_Interaction__r.Name;
        postAdjustmentRequest.requestingAgentId = adjustment.CreatedBy.ATTUID__c;

        return JSON.serialize(postAdjustmentRequest);
    }
}