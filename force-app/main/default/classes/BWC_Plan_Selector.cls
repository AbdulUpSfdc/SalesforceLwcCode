public inherited sharing class BWC_Plan_Selector {

    /*
        Gets all plans for billing account, omitting any that are soft deleted.
    */
    public static List<Plan__c> getPlansForBillingAccounts(Set<Id> billingAccountIds) {

        return [
            SELECT
                Id, Plan_Name__c, Field_Set_Name_View__c , CTI_Call_Identifier__c,
                Billing_Account__c, Billing_Account__r.Has_Only_Direct_TV__c, Product__c,
                Transport_Type__c, Plan_Effective_Date__c, Plan_Code__c
            FROM
                Plan__c
            WHERE
                Billing_Account__c IN :billingAccountIds AND
                Is_Deleted__c <> true
        ];

    }

    /*
        Selects plans records that no longer have corresponding data as returned from API.
    */
    public static List<Plan__c> getPlansToSoftDelete(List<Billing_Account__c> billingAccounts, Set<String> planUniqueNames) {

        return [
            SELECT
                Id, Is_Deleted__c
            FROM
                Plan__c
            WHERE
                Billing_Account__c IN :billingAccounts AND
                Plan_Unique_Name__c NOT IN :planUniqueNames AND
                Is_Deleted__c <> true
        ];

    }
    
    
    //Get Map of Plans based on billing accounts  
    public static Map<Id,Plan__c> getPlans(Set<Id> billAcctIds){
        Map<Id,Plan__c> planMap = new Map<Id,Plan__c>([Select 
                                                            Id,Plan_Name__c,Transport_Type__c,Product__c
                                                            , Billing_Account__c 
                                                        FROM Plan__c 
                                                        WHERE Billing_Account__c IN :billAcctIds]); 
                                                                                                 
        return planMap;
    }

}