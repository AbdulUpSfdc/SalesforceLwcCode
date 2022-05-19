public with sharing class MTLS_Constants {
       // the constants for Browser names retrieved from the User Agent string
       public static final String MICROSOFT_EDGE = 'Microsoft Edge';
       public static final String INTERNET_EXPLORER = 'Internet Explorer';
       public static final String ARCHAIC_BROWSER = 'Archaic Browser';
       public static final String CHROMIUM = 'Chromium';
       public static final String CHROME = 'Chrome';
       public static final String SAFARI = 'Safari';
       public static final String FIREFOX = 'Firefox';
       public static final String UNKNOWN = 'Unknown';
   
       // the constants for Operating System names retrieved from the User Agent string
       public static final String IOS = 'iOS';
       public static final String IPADOS = 'iPadOS';
       public static final String ANDROID = 'Android';
       public static final String WINDOWS_PHONE = 'Windows Phone';
       public static final String WINDOWS = 'Windows';
       public static final String CHROME_OS = 'Chrome OS';
       public static final String MAC_OS_X = 'Mac OS X';
       public static final String LINUX = 'Linux';
   
    public static final Pattern Base32Pattern = Pattern.compile(
        '^(?:[A-Z2-7]{8})*(?:[A-Z2-7]{2}={6}|[A-Z2-'+
        '7]{4}={4}|[A-Z2-7]{5}={3}|[A-Z2-7]{7}=)?$');

    public static final Pattern UUIDv4Pattern = Pattern.compile(
        '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{'+
        '3}-[89abAB]{1}[0-9a-fA-F]{3}-[0-9a-fA-F]{12}$');

    public static final Pattern XHOTPPattern = Pattern.compile(
        '^[0-9]{8} (?:[A-Z2-7]{8})*(?:[A-Z2-7]{2}={6}|[A-Z2'+
        '-7]{4}={4}|[A-Z2-7]{5}={3}|[A-Z2-7]{7}=)?( 0){5}$');

    public static final String NO_VALID_STORE_ERROR = 'Valid Employee Store Record Not found';
    public static final String NO_VALID_EMPLOYEE_ERROR = 'Employee Record Not found';
    public static final String PROXY_UUID_MISSMATCH_ERROR = 'ERROR: Proxy UUID Missmatch';
    public static final String NO_VALID_SIP_ERROR = 'ERROR: sIP Invalid';
    public static final String NO_VALID_USER_ERROR = 'ERROR: user is not valid';
    public static final String NO_VALID_TICKET_ERROR = 'ERROR: Invalid Ticket';
    public static final String NO_VALID_UUID_ERROR = 'ERROR: Invalid PROXY UUID';

}