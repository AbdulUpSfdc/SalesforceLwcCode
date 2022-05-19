public inherited sharing class BWC_Case_Selector {

    /**
     * @param caseIds List of Case IDs
     * @return A list of cases
    */
    public static List<Case> getCasesById(List<Id> caseIds){

        return [
            SELECT
                Id, Account.Name, Billing_Account__c, Last_Interaction__c, Type, CaseNumber, OwnerId
            FROM Case
            WHERE Id IN :caseIds
        ];
    }
}