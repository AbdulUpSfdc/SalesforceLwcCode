public inherited sharing class BWC_Asset_Selector {

    /*
        Get all asset records whose ids are in assetIds.
    */
    public static List<Asset> getAssets(Set<Id> assetIds) {

        return [
            SELECT
                Id, Billing_Account__r.Billing_Account_Number__c, Billing_Account__r.Account_Type__c
            FROM
                Asset
            WHERE
                Id IN :assetIds AND
                Is_Deleted__c <> true
            WITH SECURITY_ENFORCED
        ];

    }

    /*
        Gets all assets for billing account, omitting any that are soft deleted.
    */
    public static List<Asset> getAssetsForBillingAccounts(Set<Id> billingAccountIds) {

        return [
            SELECT
                Id, CTI_Call_Identifier__c, Device__c, Phone_Number__c, toLabel(Status), Description, Mobile_Created_Date__c,
                Field_Set_Name_View__c, Receiver_Model__c, Device_Type__c, Billing_Account__r.Billing_Account_Number__c, Make_And_Model__c,
                Billing_Account__r.Account_Type__c, Name, Billing_Account__c, Is_Primary__c, User__c, Plan__r.Plan_Price_Code__c,
                Plan__r.Plan_Effective_Date__c, Plan__r.Product_Description__c, ProductCode, Manufacturer__c, IMEI__c,
                SIM__c, Plan__c, Plan__r.Billing_Account__c, Plan__r.Plan_Name__c, Plan__r.Product__c, Plan__r.Plan_Code__c,
                Submarket__c, Equipment_Status__c, Phone_Number_Display__c, Subscriber_Plan_Name__c
            FROM
                Asset
            WHERE
                Billing_Account__c IN :billingAccountIds AND
                Is_Deleted__c <> true
            WITH SECURITY_ENFORCED
        ];

    }

    /*
        Selects asset records that no longer have corresponding data as returned from API.
    */
    public static List<Asset> getAssetsToSoftDelete(List<Billing_Account__c> billingAccounts, Set<String> assetUniqueNames) {

        return [
            SELECT
                Id, Is_Deleted__c
            FROM
                Asset
            WHERE
                Billing_Account__c IN :billingAccounts AND
                Equipment_Unique_Identifier__c NOT IN :assetUniqueNames AND
                Is_Deleted__c <> true
        ];

    }

}