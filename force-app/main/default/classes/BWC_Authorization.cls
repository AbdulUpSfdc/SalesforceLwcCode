public with sharing class BWC_Authorization {

    // Permissions
    public static final String PERM_BYPASS_INTERACTION_AUTHORIZATION = 'Bypass_Interaction_Authorization';

    // Authorization levels
    public static final String AUTHORIZATION_CLIENT_ID = 'SalesForce';
    public static final String AUTHORIZATION_LEVEL_L0 = 'L0';
    public static final String AUTHORIZATION_LEVEL_L1 = 'L1';
    public static final String AUTHORIZATION_LEVEL_BYPASS = 'BYPASS';
    public static final Set<String> AUTHORIZATION_LEVELS_L1_PRIVILEGED = new Set<String>{AUTHORIZATION_LEVEL_L1, AUTHORIZATION_LEVEL_BYPASS};

    // Only types that are supported by the API
    public static Set<String> VALID_ACCOUNT_TYPES = new Set<String> {
        BWC_Constants.ACCOUNT_TYPE_WIRELESS,
        BWC_Constants.ACCOUNT_TYPE_UVERSE,
        BWC_Constants.ACCOUNT_TYPE_ATTTV
    };
    
}