public inherited sharing class BWC_Employee {
    

    public static final String CHANNEL_RETAIL = 'Retail';

    public static final String SUB_CHANNEL_AUTH_RETAIL = 'Authorized Retail';
    public static final String SUB_CHANNEL_ATT_RETAIL = 'AT&T Retail';
    public static final String SUB_CHANNEL_IHX = 'IHX';
    public static final Set<String> AUTHORIZED_RETAIL_SUB_CHANNELS = new Set<String>{
        SUB_CHANNEL_ATT_RETAIL,
        SUB_CHANNEL_AUTH_RETAIL,
        SUB_CHANNEL_IHX
    };
}