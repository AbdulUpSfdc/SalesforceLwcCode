public with sharing class BWC_Adjustment_Selector {
    public static List<Adjustment__c> getAdjustments(Set<Id> adjIdList) {
        return [
            SELECT
                Id, Status__c
            FROM
                Adjustment__c
            WHERE
                Id IN :adjIdList
        ];
    }
}