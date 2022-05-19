public without sharing class BWC_AdjustmentAndLineItemWithOutShareing {

    private static Map<String, Object> uiDataMap;
    private static Map<String, Object> cdeMap;
    private static Map<String, Object> adjustmentMap;
    private static Map<String, Object> lineItemMap;
    private static Map<String, Object> lineItemObj;
    private static List<Object> lineItemDataList;

        public static List<Id> handleBillingAdjustmentCase(String detailRecord, Case eCase)
        {
            List<Id> returnIdList;
            setDataFromUI(detailRecord);

            Adjustment__c adjustment = new Adjustment__c();
            adjustment = populateAdjustment(adjustment, eCase);
            insert adjustment;

            List<Adjustment_Line_Item__c> lineItemList = new List<Adjustment_Line_Item__c>();
            lineItemList =  populateLineItems(adjustment, lineItemList, eCase);
            insert lineItemList;

            adjustment.Status__c = CaseConstants.ADJUSTMENT_SUBMIT_FOR_APPROVAL;
            upsert adjustment;

            return returnIdList;
        }

        private static Adjustment__c populateAdjustment(Adjustment__c adjustment, Case eCase)
        {
            adjustment.Billing_Account__c = BWC_BillingAccount_Selector.getBillingAccountFromAcctIdentifier((String) uiDataMap.get('ban'))?.Id;
            adjustment.Case__c = eCase.Id;
            adjustment.Adjustment_CDE_Submission_Date__c = System.now();
            adjustment.Status__c = 'New';
            adjustment.Statement_ID__c = (String.isNotBlank((String)uiDataMap.get('statementId')))?(String)uiDataMap.get('statementId'):'';
            
            // If adjustmentMap is not null, then it is a Goodwill adjustment. Otherwise, it is a Line Item adjustment.
            if (adjustmentMap != null) {
                adjustment.Overall_CDE_Status__c = (String.isNotBlank((String)cdeMap.get('overallCDEStatus')))?(String)cdeMap.get('overallCDEStatus'):'';
                adjustment.Adjustment_Type__c = 'Goodwill';
            } else {
                // adjustment.Overall_CDE_Status__c = (String.isNotBlank((String)cdeMap.get('overallCDEStatus')))?(String)cdeMap.get('overallCDEStatus'):'';
                adjustment.Adjustment_Type__c = 'Line Item';
            }
            adjustment.Decision_Update_Transaction_ID__c = (String.isNotBlank((String)uiDataMap.get('transactionId')))?(String)uiDataMap.get('transactionId'):'';

            return adjustment;
        }

        private static List<Adjustment_Line_Item__c> populateLineItems(Adjustment__c adjustment, List<Adjustment_Line_Item__c> lineItemList, Case eCase)
        {
            if (lineItemDataList == null) {
                return lineItemList;
            }

            for(Object obj : lineItemDataList) {
                Adjustment_Line_Item__c lineItem = new Adjustment_Line_Item__c();

                lineItemObj = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(obj));
                lineItem.Adjustment__c = adjustment.Id;
                lineItem.Charge_Seq_Number__c =  (String.isNotBlank((String)lineItemObj.get('chargeSequenceNumber')))?Long.valueOf((String)lineItemObj.get('chargeSequenceNumber')):-0;
                lineItem.Bill_Seq_Number__c = (String.isNotBlank((String)lineItemObj.get('billSequenceNumber')))?Decimal.valueOf((String)lineItemObj.get('billSequenceNumber')):00.00;
                lineItem.Charge_Code__c = (String.isNotBlank((String)lineItemObj.get('chargeCode')))?(String)lineItemObj.get('chargeCode'):'';
                lineItem.Charge_Description__c = (String.isNotBlank((String)lineItemObj.get('chargeDescription')))?(String)lineItemObj.get('chargeDescription'):'';
                lineItem.Charge_Amount__c = (String.isNotBlank((String)lineItemObj.get('chargeAmount')))?Decimal.valueOf((String)lineItemObj.get('chargeAmount')):00.00;
                lineItem.Requested_Amount__c = (String.isNotBlank((String)lineItemObj.get('requestAmount')))?Decimal.valueOf((String)lineItemObj.get('requestAmount')):00.00;
                lineItem.CDE_Product_Level_Id__c = (String.isNotBlank((String)lineItemObj.get('productLevelId')))?(String)lineItemObj.get('productLevelId'):'';
                lineItem.Charge_Type__c = (String.isNotBlank((String)lineItemObj.get('chargeType')))?(String)lineItemObj.get('chargeType'):'';
                lineItem.Override_Escalate_By__c = UserInfo.getUserId();

                // If adjustmentMap is not null, then it is a Goodwill adjustment. Otherwise, it is a Line Item adjustment.
                if (adjustmentMap != null) {
                    lineItem.Adjustment_Type__c = 'Goodwill';
                    lineItem.Bill_Date__c = (String.isNotBlank((String)lineItemObj.get('billDate')))?Date.valueOf((String)lineItemObj.get('billDate')):null;
                    lineItem.Adj_Reason_Explanation_Code__c = (String.isNotBlank((String)adjustmentMap.get('adjReasonExplanationCode')))?(String)adjustmentMap.get('adjReasonExplanationCode'):'';
                    lineItem.Adj_Reason_Description__c = (String.isNotBlank((String)adjustmentMap.get('adjReasonDescription')))?(String)adjustmentMap.get('adjReasonDescription'):'';
                    lineItem.Adj_Reason_System_Code__c = (String.isNotBlank((String)adjustmentMap.get('adjReasonSystemCode')))?(String)adjustmentMap.get('adjReasonSystemCode'):'';
                    lineItem.Adjustment_Comments__c = (String.isNotBlank((String)adjustmentMap.get('adjComments')))?(String)adjustmentMap.get('adjComments'):'';
                    lineItem.CDE_Approved_Amount__c = (String.isNotBlank((String)cdeMap.get('cdeApprovedAmount')))?Decimal.valueOf((String)cdeMap.get('cdeApprovedAmount')):00.00;
                    lineItem.CDE_Reason_for_Agents__c = (String.isNotBlank((String)cdeMap.get('cdeReasonForAgent')))?(String)cdeMap.get('cdeReasonForAgent'):'';
                    lineItem.CDE_Reason_for_Customers__c = (String.isNotBlank((String)cdeMap.get('cdeReasonForCustomer')))?(String)cdeMap.get('cdeReasonForCustomer'):'';
                    lineItem.CDE_Recommendation_Status__c = (String.isNotBlank((String)cdeMap.get('cdeRecommendationStatus')))?(String)cdeMap.get('cdeRecommendationStatus'):'';
                    lineItem.Is_Customer_Accepted__c = (String.isNotBlank((String)cdeMap.get('isCustomerAccepted')))?Boolean.valueOf((String)cdeMap.get('isCustomerAccepted')):false;
                    lineItem.Override_Escalate__c = (String.isNotBlank((String)cdeMap.get('overrideEscalate')))?(String)cdeMap.get('overrideEscalate'):'';
                    lineItem.Agent_Adjusted_Amount__c = (String.isNotBlank((String)lineItemObj.get('agentAdjustedAmount')))?Decimal.valueOf((String)lineItemObj.get('agentAdjustedAmount')):00.00;
                } else {
                    lineItem.Adjustment_Type__c = 'Line Item';
                    lineItem.Bill_Date__c = (String.isNotBlank((String)lineItemObj.get('billEndDate')))?Date.valueOf((String)lineItemObj.get('billEndDate')):null;
                    lineItem.Adj_Reason_Explanation_Code__c = (String.isNotBlank((String)lineItemObj.get('adjustmentReasonExplanationCode')))?(String)lineItemObj.get('adjustmentReasonExplanationCode'):'';
                    lineItem.Adj_Reason_Description__c = (String.isNotBlank((String)lineItemObj.get('adjustmentReasonDescription')))?(String)lineItemObj.get('adjustmentReasonDescription'):'';
                    lineItem.Adj_Reason_System_Code__c = (String.isNotBlank((String)lineItemObj.get('adjustmentReasonSystemCode')))?(String)lineItemObj.get('adjustmentReasonSystemCode'):'';
                    lineItem.Adjustment_Comments__c = (String.isNotBlank((String)lineItemObj.get('comments')))?(String)lineItemObj.get('comments'):'';
                    lineItem.CDE_Approved_Amount__c = (String.isNotBlank((String)lineItemObj.get('approvedAmount')))?Decimal.valueOf((String)lineItemObj.get('approvedAmount')):00.00;
                    lineItem.CDE_Reason_for_Agents__c = (String.isNotBlank((String)lineItemObj.get('cdeReasonForAgent')))?(String)lineItemObj.get('cdeReasonForAgent'):'';
                    lineItem.CDE_Reason_for_Customers__c = (String.isNotBlank((String)lineItemObj.get('cdeReasonForCustomer')))?(String)lineItemObj.get('cdeReasonForCustomer'):'';
                    lineItem.CDE_Recommendation_Status__c = (String.isNotBlank((String)lineItemObj.get('decisionStatus')))?(String)lineItemObj.get('decisionStatus'):'';
                    lineItem.Is_Customer_Accepted__c = (String.isNotBlank((String)lineItemObj.get('isCustomerAccepted')))?Boolean.valueOf((String)lineItemObj.get('isCustomerAccepted')):false;
                    lineItem.Override_Escalate__c = (String.isNotBlank((String)lineItemObj.get('overrideEscalate')))?(String)lineItemObj.get('overrideEscalate'):'';
                    lineItem.Agent_Adjusted_Amount__c = (String.isNotBlank((String)lineItemObj.get('adjustmentAmount')))?Decimal.valueOf((String)lineItemObj.get('adjustmentAmount')):00.00;
                    lineItem.Subscriber_Number__c = (String.isNotBlank((String)lineItemObj.get('subscriberNumber')))?(String)lineItemObj.get('subscriberNumber'):'';
                }

                lineItemList.add(lineItem);
            }

            return lineItemList;
        }

        private static void setDataFromUI(String detailRecord)
        {
            uiDataMap = (Map<String, Object>) JSON.deserializeUntyped(detailRecord);
            cdeMap = getDataMap(uiDataMap, 'cdeData');
            adjustmentMap = getDataMap(uiDataMap, 'adjustmentData');
            lineItemMap = getDataMap(uiDataMap, 'billData');
            lineItemDataList = (List<Object>) JSON.deserializeUntyped(JSON.serialize(uiDataMap.get('lineItemDataList')));
        }

        private static Map<String, Object>  getDataMap(Map<String, Object> uiDataMap, String objName)
        {
            return (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize((Map<String, Object>) uiDataMap.get(objName)));
        }
    }