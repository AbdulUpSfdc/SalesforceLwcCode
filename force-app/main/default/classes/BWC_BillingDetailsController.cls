/*
    Exposes methods to allow LWC to call Billing Statement service.
*/
public with sharing class BWC_BillingDetailsController {
    /*
        Method for calling from LWC. Returns serialized JSON.
    */
    @AuraEnabled
    public static String getBillingDetails(String product, String statementId) {

        BillingDetailsResponseWrapper responseWrapper = new BillingDetailsResponseWrapper();

        try {
            BWC_BillingDetails.BillingDetailsResponse response = 
            BWC_BillingDetailsService.getBillingDetails(product, statementId);
            responseWrapper.success = true;
            responseWrapper.response = response;
        }
        catch (System.Exception e) {

            responseWrapper.success = false;
            responseWrapper.message = e.getMessage();
            BWC_ExceptionUtils.handleException(e, 'statementId: ' + statementId, null);

        }
        // Return the JSON, LWC will parse it.
        return responseWrapper.serialize();
    }

    /*
        Method for getting Billing Details -> Adjustment Eligible Line Items from LWC. Returns serialized JSON.
    */
    @AuraEnabled
    public static String getEligibleForAdjustmentLineItems(String product, String statementId, String ban) {

        AdjustableLineItemsResponseWrapper responseWrapper = new AdjustableLineItemsResponseWrapper();

        try {
            BWC_BillingDetails.BillingDetailsResponse billingDetails;
            BWC_BillingDetails.AdjustableLineItemsResponse response;

            if (!Test.isRunningTest()) {
                billingDetails = BWC_BillingDetailsService.getBillingDetails(product, statementId);
            } else {
                // Setup mock response from static resource - BWC_BillingDetailsForChargeCodes
                StaticResource sr = [SELECT Id, Body FROM StaticResource WHERE Name = 'BWC_BillingDetailsForChargeCodes' LIMIT 1];
                billingDetails = (BWC_BillingDetails.BillingDetailsResponse)JSON.deserialize(
                        sr.Body.toString(), BWC_BillingDetails.BillingDetailsResponse.class);
            }

            // Get line items that are eligible for adjustment
            response = BWC_BillingDetailsService.getAdjustableLineItems(billingDetails.content);

            // Call Billing Code Charges API
            response = BWC_BillingDetailsService.getChargeCodes(ban, response);
            responseWrapper.success = true;
            responseWrapper.response = response;
        }
        catch (System.Exception e) {

            responseWrapper.success = false;
            responseWrapper.message = e.getMessage();
            BWC_ExceptionUtils.handleException(e, 'statementId: ' + statementId, null);

        }
        // Return the JSON, LWC will parse it.
        return responseWrapper.serialize();
    }

    /*
        Method for calling from LWC. Returns serialized JSON.
    */
    @AuraEnabled
    public static String getBillPdf(String product, String statementId) {

        BillPdfResponseWrapper responseWrapper = new BillPdfResponseWrapper();

        try {
            BWC_BillingDetails.BillPdfResponse response = BWC_BillingDetailsService.getBillPdf(product, statementId);
            responseWrapper.success = true;
            responseWrapper.response = response;
        }
        catch (System.Exception e) {

            responseWrapper.success = false;
            responseWrapper.message = e.getMessage();
            BWC_ExceptionUtils.handleException(e, 'statementId: ' + statementId, null);

        }
        // Return the JSON, LWC will parse it.
        return responseWrapper.serialize();
    }

    /*
        Wrapper for returning response along with error information.
    */
    public class BillingDetailsResponseWrapper extends BWC_ResponseWrapper {
        public BWC_BillingDetails.BillingDetailsResponse response;
    }

    public class BillPdfResponseWrapper extends BWC_ResponseWrapper {
        public BWC_BillingDetails.BillPdfResponse response;
    }

    public class AdjustableLineItemsResponseWrapper extends BWC_ResponseWrapper {
        public BWC_BillingDetails.AdjustableLineItemsResponse response;
    }

}