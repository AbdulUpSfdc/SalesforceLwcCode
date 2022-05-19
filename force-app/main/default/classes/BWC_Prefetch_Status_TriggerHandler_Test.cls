@isTest
public with sharing class BWC_Prefetch_Status_TriggerHandler_Test {

    @isTest
    private static void test_trigger() {

        insert new BWC_Prefetch_Status__c(
            CTI_Call_Identifier__c = 'Test',
            Started_At__c = Datetime.now(),
            Status__c = BWC_PrefetchCacheManager.STATUS_IN_PROCESS
        );

        // Check cache
        BWC_PrefetchCacheManager.PrefetchStatus value = (BWC_PrefetchCacheManager.PrefetchStatus)Cache.Org.get(BWC_PrefetchCacheManager.makeKey('Test', BWC_PrefetchCacheManager.TYPE_CUSTOMER_SEARCH));
        System.assertNotEquals(null, value);
        System.assertEquals(BWC_PrefetchCacheManager.STATUS_IN_PROCESS, value.status);

    }

}