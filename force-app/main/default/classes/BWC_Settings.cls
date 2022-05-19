/*
    For retrieving application settings in LWC client.
*/
public with sharing class BWC_Settings {

    // Cached settings so can be called multiple times in context without requery.
    private static BWC_Settings__mdt CACHED_SETTINGS = null;

    @AuraEnabled
    public static BWC_Settings__mdt getBwcSettings() {

        if (CACHED_SETTINGS== null) {
            CACHED_SETTINGS = [
                SELECT
                    Id, Default_Named_Credential__c, Prefetch_Status_Cache_TTL_Secs__c, API_Multi_Server_Count__c,
                    Prefetch_Status_Polling_Interval__c, Prefetch_Status_Polling_Timeout__c, Product_Prefetch_Polling_Interval__c, Product_Prefetch_Polling_Timeout__c
                FROM
                    BWC_Settings__mdt
                WHERE
                    DeveloperName = 'BWC_Settings'
            ];
        }

        return CACHED_SETTINGS;

    }

}