public with sharing class BWC_TermAndConditionController {

    @AuraEnabled
    public static String getTermsAndConditions(List<String> paymentEventTypes) {

        TermAndConditionResponseWrapper responseWrapper = new TermAndConditionResponseWrapper();
        try {

            List<PaymentTerm__c> records = BWC_TermAndConditionService.getTermsAndConditions(paymentEventTypes);

            // Return success with data
            responseWrapper.success = true;
            responseWrapper.termsAndConditions = records;

        }
        catch (System.Exception e) {

            // Log
            BWC_ExceptionUtils.handleException(e, 'tncKeys: ' + JSON.serialize(paymentEventTypes, true), null);

            // Return failure with message
            responseWrapper.success = false;
            responseWrapper.message = e.getMessage();

        }

        return JSON.serialize(responseWrapper, true);

    }

    public class TermAndConditionResponseWrapper extends BWC_ResponseWrapper {
     
        public List<PaymentTerm__c> termsAndConditions;

    }

}