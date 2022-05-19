public with sharing class BWC_CaseServiceController {

    @AuraEnabled
    public static String getCaseById(Id caseId){

        CaseResponseWrapper responseWrapper = new CaseResponseWrapper();
        try {

            List<Case> cases = [
                SELECT
                    Id, Billing_Account__r.Email__c, Billing_Account__r.Contact_Number__c, Billing_Account__r.Alternate_Phone_Number__c
                FROM
                    Case
                WHERE
                    Id = :caseId
            ];

            if (cases.isEmpty()) {
                throw new BWC_Exception('Case not found for ID: ' + caseId);
            }

            // Return success with data
            responseWrapper.success = true;
            responseWrapper.caseRecord = cases[0];

        }
        catch (System.Exception e) {

            // Log
            BWC_ExceptionUtils.handleException(e, 'caseId: ' + caseId, null);

            // Return failure with message
            responseWrapper.success = false;
            responseWrapper.message = e.getMessage();

        }

        return responseWrapper.serialize();
    }

    public class CaseResponseWrapper extends BWC_ResponseWrapper {
     
        public Case caseRecord;

    }    

}