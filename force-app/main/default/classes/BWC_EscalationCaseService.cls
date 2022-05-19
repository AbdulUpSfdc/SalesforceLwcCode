public with sharing class BWC_EscalationCaseService {
    
    public static List<Case> getEscalationCasesByBillingAccount(String billingAccountNumber) {
        if(billingAccountNumber == null){
            throw new BWC_Exception('billing account number must be set.');
        }
        
        Integer numberOfDaysPast = BWC_Constants.ESCALATION_CASE_RECENT_NUMBER_OF_DAYS;

        Date since = Date.today().addDays(numberOfDaysPast * -1);
        
        return [
            SELECT
                Id, CaseNumber, Type, CaseAction__c, IsClosed, CreatedDate, ClosedDate, Target_Close_Date__c
            FROM Case 
            WHERE 
                Billing_Account__r.Billing_Account_Number__c = :billingAccountNumber AND
                RecordType.Name = 'Escalation' AND
                CaseAction__c != null AND
                (IsClosed = false OR ClosedDate > :since)
            WITH SECURITY_ENFORCED
            ORDER BY ClosedDate DESC, CreatedDate DESC
        ];
    }
}