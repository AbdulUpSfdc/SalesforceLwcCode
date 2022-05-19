@isTest
public with sharing class BWC_PrefetchCacheManager_Test {

    @isTest
    private static void test() {

        String IDENTIFIER = 'Test123';
        String key = BWC_PrefetchCacheManager.makeKey('Test123', BWC_PrefetchCacheManager.TYPE_CUSTOMER_SEARCH);

        // Test cache miss
        System.assertEquals(null, BWC_PrefetchCacheManager.getStatus('foo', BWC_PrefetchCacheManager.TYPE_CUSTOMER_SEARCH));

        BWC_Prefetch_Status__c record = new BWC_Prefetch_Status__c(
            CTI_Call_Identifier__c = IDENTIFIER,
            Prefetch_Type__c = BWC_PrefetchCacheManager.TYPE_CUSTOMER_SEARCH,
            Started_At__c = Datetime.now(),
            Status__c = BWC_PrefetchCacheManager.STATUS_IN_PROCESS
        );

        // Test that put goes to cache
        BWC_PrefetchCacheManager.put(record);
        System.assertNotEquals(null, Cache.Org.get(key));
        System.assertNotEquals(null, BWC_PrefetchCacheManager.getStatus(IDENTIFIER, BWC_PrefetchCacheManager.TYPE_CUSTOMER_SEARCH));

        // Test fallback to record instead of cache
        insert record;
        Cache.Org.remove(key);
        System.assertEquals(null, Cache.Org.get(key));
        System.assertNotEquals(null, BWC_PrefetchCacheManager.getStatus(IDENTIFIER, BWC_PrefetchCacheManager.TYPE_CUSTOMER_SEARCH));

    }

}