/*
    Trigger handler for BWC_Prefetch_Status__c.
*/
public inherited sharing class BWC_Prefetch_Status_TriggerHandler {

    public static void delegateProcessing() {

        for (BWC_Prefetch_Status__c record : (List<BWC_Prefetch_Status__c>)Trigger.new) {

            if (Trigger.isBefore) {

                if (String.isEmpty(record.Prefetch_Type__c)) {
                    // Default the Prefetch Type, as it was introduced later
                    record.Prefetch_Type__c = BWC_PrefetchCacheManager.TYPE_CUSTOMER_SEARCH;
                }

                if (String.isEmpty(record.External_Id__c)) {
                    // Set external ID
                    record.External_Id__c = record.CTI_Call_Identifier__c + '|' + record.Prefetch_Type__c;
                }

            }

            if (Trigger.isAfter) {
                // Update the corresponding platform cache
                BWC_PrefetchCacheManager.put(record);
            }

        }

    }

}