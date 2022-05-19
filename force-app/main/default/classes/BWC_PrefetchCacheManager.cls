public inherited sharing class BWC_PrefetchCacheManager {

    public static final String PARTION_NAME = 'BwcPrefetchStatus';

    public static final String TYPE_CUSTOMER_SEARCH = 'CustomerSearch';
    public static final String TYPE_PRODUCT_SEARCH = 'ProductSearch';

    public static final String STATUS_IN_PROCESS = 'In Process';
    public static final String STATUS_SUCCEEDED = 'Succeeded';
    public static final String STATUS_FAILED = 'Failed';

    /*
        Defines the structure of the value stored in platform cache.
    */
    public class PrefetchStatus {

        public String ctiCallIdentifier;
        public String prefetchType;
        public String status;

        public PrefetchStatus(BWC_Prefetch_Status__c record) {
            this.ctiCallIdentifier = record.CTI_Call_Identifier__c;
            this.prefetchType = record.Prefetch_Type__c;
            this.status = record.Status__c;
        }

        public PrefetchStatus(String ctiCallIdentifier, String prefetchType, String status) {
            this.ctiCallIdentifier = ctiCallIdentifier;
            this.prefetchType = prefetchType;
            this.status = status;
        }

    }

    /*
        Build key name.
    */
    @testvisible private static String makeKey(String ctiCallIdentifier, String prefetchType) {
        // Build key name from ctiCallIdentifier + prefetchType
        // Must be strictly alphanumeric -- strip all other characters from ctiCallIdentifier
        return 'local.' + PARTION_NAME + '.' + ctiCallIdentifier.replaceAll('[^a-zA-Z0-9]', '') + prefetchType.replaceAll(' ', '');
    }

    /*
        Put a cached value based corresponding customer object record.
    */
    public static void put(BWC_Prefetch_Status__c record) {

        PrefetchStatus value = new PrefetchStatus(record);
        Cache.Org.put(makeKey(value.ctiCallIdentifier, value.prefetchType), value, (Integer)BWC_Settings.getBwcSettings().Prefetch_Status_Cache_TTL_Secs__c);

    }

    /*
        Put specific status.
    */
    public static void putStatus(String ctiCallIdentifier, String prefetchType, String status) {

        PrefetchStatus value = new PrefetchStatus(ctiCallIdentifier, prefetchType, status);
        Cache.Org.put(makeKey(value.ctiCallIdentifier, value.prefetchType), value, (Integer)BWC_Settings.getBwcSettings().Prefetch_Status_Cache_TTL_Secs__c);

    }

    /*
        Retrieve status for a given ctiCallIdentifier, first checking the cache then the custom object.
    */
    public static String getStatus(String ctiCallIdentifier, String prefetchType) {

        PrefetchStatus value = (PrefetchStatus)Cache.Org.get(makeKey(ctiCallIdentifier, prefetchType));
        if (value == null) {

            System.debug('Cache miss: ' + ctiCallIdentifier);
            List<BWC_Prefetch_Status__c> records = [SELECT Status__c FROM BWC_Prefetch_Status__c WHERE CTI_Call_Identifier__c = :ctiCallIdentifier AND Prefetch_Type__c = :prefetchType];
            if (!records.isEmpty()) {
                System.debug('Record found: ' + ctiCallIdentifier);
                return records[0].Status__c;
            }
            System.debug('No Record found: ' + ctiCallIdentifier);
            return null;

        }
        else {
            System.debug('Cache hit: ' + ctiCallIdentifier);
            return value.status;
        }

    }

}