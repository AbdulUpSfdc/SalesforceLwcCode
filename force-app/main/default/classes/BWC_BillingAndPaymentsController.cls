/* ================================================
* @author : Shoukat Khan
* @date :   09/30/2020   
* @group : Billing Summary
* @description : Controller class for LWC bwcBillingAndPayments
================================================*/
public with sharing class BWC_BillingAndPaymentsController {

    // Method that call the Billing Summary  API
    // Returns an object with fields success, message and billingData
    // if success is true, billingData has billing summary 
    // 11-11-2020 the incoming parmater recordId can be Interaction Id or Person AccountId,
    // hence changed the parameter name from personAccountId to recordId
    @AuraEnabled
    public static BillingAndPaymentsResult getBillingAndPaymentsData(String recordId) {
        BillingAndPaymentsResult result = new BillingAndPaymentsResult();
        result.success = false;
        result.billingData = new LIst<BillingData>();

        // Call the Service class to make a mulesoft call
        BWC_BillingSummaryResultWrapper billingResult = BWC_BillingSummaryService.getBillingData(recordId);
        result.success = billingResult.success;
        result.message = billingResult.message;

        // if successful, parse the result and extract the required data to show on UI
        if (billingResult.success) {

            List<BWC_BillingSummaryRespWrapper.ResponseContent> contentList = new List<BWC_BillingSummaryRespWrapper.ResponseContent>();
            if (billingResult.result.Wireless != null) {
                contentList.addAll(billingResult.result.Wireless);
            }
            if (billingResult.result.Wireline != null) {
                contentList.addAll(billingResult.result.Wireline);
            }

            // Collect the BANs so that we can get their Account types from Billing_Account__c
            Set<String> setBANs = new Set<String>();
            for (BWC_BillingSummaryRespWrapper.ResponseContent contentItem : contentList) {
                if (contentItem.content != null && contentItem.content.billInfo != null && contentItem.content.billInfo.ban != null) {
                    // Get ban from result
                    setBANs.add(contentItem.content.billInfo.ban);
                }
                else {
                    // Get ban that was put there by service
                    setBANs.add(contentItem.ban);
                }
            }

            // Get the Billing_Account__c records and create a map
            Map<String, Billing_Account__c> mapBANToBillingAccount = new Map<String, Billing_Account__c>();
            List<Billing_Account__c> listBillingAccounts = [SELECT Id, Billing_Account_Number__c, Account_Type__c, Service_Type_Name__c FROM Billing_Account__c WHERE Billing_Account_Number__c IN :setBANs];
            for (Billing_Account__c billAcct : listBillingAccounts) {
                mapBANToBillingAccount.put(billAcct.Billing_Account_Number__c, billAcct);
            }

            // Loop all the Billing Data from mulesoft and get the required fields
            for (BWC_BillingSummaryRespWrapper.ResponseContent contentItem : contentList) {

                BillingData bd = new BillingData();
                if (contentItem.error != null) {

                    bd.ban = contentItem.ban;
                    bd.errorMessage = JSON.serialize(contentItem.error);
                    result.billingData.add(bd);

                }
                else if (contentItem.content != null) {
                    if (contentItem.content.billInfo != null) {
                        if (contentItem.content.billInfo.ban != null) {
                            bd.ban = contentItem.content.billInfo.ban;

                            // From the Billing_Account__c record, get the Account Type
                            Billing_Account__c billAcct = mapBANToBillingAccount.get(bd.ban);
                            if (billAcct != null) {
                                bd.service = billAcct.Account_Type__c;
                                bd.serviceLabel = billAcct.Service_Type_Name__c;
                                bd.billingAccountId = billAcct.Id;
                            }
                        }

                        Date startDate = BWC_Utils.parseDate(contentItem.content.billInfo.cycleStDate);
                        Date endDate = BWC_Utils.parseDate(contentItem.content.billInfo.cycleEndDate);
                        if (startDate != null && endDate != null) {
                            bd.billCycle = startDate.month() + '/' + startDate.day() + ' - ' + endDate.month() + '/' + endDate.day();
                        }

                        bd.paperlessBill = contentItem.content.paperBillInd;
                        bd.autoPay = contentItem.content.AutoPay;
                    }
                    if (contentItem.content.billSummary != null) {
                        if (contentItem.content.billSummary.totChrgs != null) {
                            bd.amtDue = contentItem.content.billSummary.totChrgs.amt;
                            if (contentItem.content.billSummary.totChrgs.amtInd == 'CR') {
                                bd.amtDue = '-' + bd.amtDue;
                            }
                        }
                        if (contentItem.content.billSummary.rmningBal  != null) {
                            bd.pastDue = contentItem.content.billSummary.rmningBal.amt;
                            if (contentItem.content.billSummary.rmningBal.amtInd == 'CR') {
                                bd.pastDue = '-' + bd.pastDue;
                            }
                        }
                        if (contentItem.content.billSummary.totalPayments != null) {
                            bd.lastPayment = contentItem.content.billSummary.totalPayments.amt;
                            if (contentItem.content.billSummary.totalPayments.amtInd == 'CR') {
                                bd.lastPayment = '-' + bd.lastPayment;
                            }
                        }
                        if (contentItem.content.billSummary.amountDueMsg != null) {
                            bd.amountDueMsg = contentItem.content.billSummary.amountDueMsg;
                        }
                    }

                    result.billingData.add(bd);

                }
                else if (String.isNotEmpty(contentItem.message)) {

                    bd.ban = contentItem.ban;
                    bd.errorMessage = contentItem.message;
                    result.billingData.add(bd);

                }

            }
        }
        return result;
    }

    // Class that holds data for each row on the Billing table
    public class BillingData {

        @AuraEnabled
        public String ban {get; set;}
        @AuraEnabled
        public String service {get; set;}
        @AuraEnabled
        public String serviceLabel {get; set;}
        @AuraEnabled
        public String amtDue {get; set;}
        @AuraEnabled
        public String pastDue {get; set;}
        @AuraEnabled
        public String lastPayment {get; set;}
        @AuraEnabled
        public String autoPay {get; set;}
        @AuraEnabled
        public String paperlessBill {get; set;}
        @AuraEnabled
        public String billCycle {get; set;}
        @AuraEnabled
        public List<String> amountDueMsg {get; set;}
        @AuraEnabled
        public String errorMessage;
        @AuraEnabled
        public String billingAccountId;
    }

    // The return data object for the method getBillingAndPaymentsData
    // When Payments API is available, add paymentsData too.
    public class BillingAndPaymentsResult {

        @AuraEnabled
        public Boolean success {get; set;}
        @AuraEnabled
        public String message {get; set;}

        @AuraEnabled
        public List<BillingData> billingData {get; set;}        
    }
}