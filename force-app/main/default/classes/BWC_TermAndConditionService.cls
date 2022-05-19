/*
    Service API for getting Term and Condition.
*/
public with sharing class BWC_TermAndConditionService {

    /*
        Retrieve records for specified keys.
    */
    public static List<PaymentTerm__c> getTermsAndConditions(List<String> paymentEventTypes) {

        if (paymentEventTypes == null || paymentEventTypes.isEmpty()) {
            throw new BWC_Exception('Argument required: paymentEventTypes');
        }

        return [
            SELECT
                Id, tncId__c, tncKey__c, paymentEventType__c, tncVerbiage__c
            FROM
                PaymentTerm__c
            WHERE
                paymentEventType__c IN :paymentEventTypes
            WITH SECURITY_ENFORCED
        ];

    }

}