/*
    Types for Authentication APIs -- generatePin, validatePin, validateCredentials.
*/
public with sharing class BWC_Authentication {

    // Permissions
    public static final String PERM_BYPASS_CUSTOMER_AUTHENTICATION = 'Bypass_Customer_Authentication';

    // Authenticate methods
    public static final String AUTHENTICATION_METHOD_NONE = 'NONE';
    public static final String AUTHENTICATION_METHOD_PASSCODE = 'PASSCODE';
    public static final String AUTHENTICATION_METHOD_OTP = 'OTP';
    public static final String AUTHENTICATION_METHOD_BYPASS = 'BYPASS';
    public static final Set<String> AUTHENTICATION_METHODS_OTP_PRIVILEGED = new Set<String>{AUTHENTICATION_METHOD_OTP, AUTHENTICATION_METHOD_BYPASS};

    // Exception codes
    public static final String INVALID_OTP_PHONE = 'INVALID_OTP_PHONE';
    public static final String INVALID_OTP_EMAIL = 'INVALID_OTP_EMAIL';

    // Identification Type
    public static final String SMS_IDENTIFICATION_TYPE ='sms';
    public static final String EMAIL_IDENTIFICATION_TYPE ='email';

}