// Generic class to maintain all thr constants used throughout the project.
public with sharing class BWC_Constants {

    public static final String BillingAccount_AccountType_Wireless = 'Wireless';
    public static final String BillingAccount_AccountType_Internet = 'internet';
    public static final String BillingAccount_AccountType_DirecTV = 'DirecTV';
    public static final String PERSON_ACCOUNT = 'Person Account';
    public static final String CUSTOMER_SEARCH = 'CUSTOMER_SEARCH';

    public static final String ACCOUNT_RELATIONSHIP= 'Primary Account Owner';
    public static final String ACCOUNT_RECORD_TYPE_PERSON_ACCOUNT = 'PersonAccount';

    // Billing_Account__c.Customer_Type__c
    public static String CUSTOMER_TYPE_BUSINESS = 'Business';
    public static String CUSTOMER_TYPE_GOVERNMENT = 'Government';

    // Billing_Account__c.Account_Type__c API values
    public static final String ACCOUNT_TYPE_WIRELESS = 'wireless';
    public static final String ACCOUNT_TYPE_UVERSE = 'uverse';
    public static final String ACCOUNT_TYPE_ATTTV = 'dtvnow';
    public static final String ACCOUNT_TYPE_DIRECTV = 'DirecTV';
    public static final String ACCOUNT_TYPE_INTERNET = 'internet';
    public static final String ACCOUNT_TYPE_DTVS = 'dtvs';
    public static final String ACCOUNT_TYPE_POTS = 'POTS';

    //3rd Party LOB
    public static final String THIRD_PARTY_INTERNET = '3rd Party Internet';

    //Plan Product Types
    public static final String PLAN_PRODUCT_TYPE_VBP = 'VBP';
    public static final String PLAN_PRODUCT_TYPE_IPTV = 'IPTV';

    // Types for which billing and payment apis can be called
    public static final Set<String> VALID_BILLING_ACCOUNT_TYPES = new Set<String>{
        ACCOUNT_TYPE_WIRELESS,
        ACCOUNT_TYPE_UVERSE
    };

    // Types for which Notes Search API can be called
    public static final Set<String> VALID_NOTES_ACCOUNT_TYPES = new Set<String>{
        ACCOUNT_TYPE_WIRELESS, 
        ACCOUNT_TYPE_UVERSE, 
        ACCOUNT_TYPE_ATTTV, 
        ACCOUNT_TYPE_DTVS
    };

    // API identifiers referenced by BWC_Integration_Metadata__mdt and BWC_Callout_Header__mdt for use by BWC_IntegrationUtility
    public static final String NAMEDCR_CUSTOMER_SEARCH = 'Customer_Search';
    public static final String API_CUSTOMER_SEARCH = 'Customer_Search';
    public static final String API_PRODUCT_SEARCH = 'Product_Search';
    public static final String API_BILLING_SUMMARY = 'Billing_Summary';
    public static final String API_NOTES_SEARCH = 'Notes_Search';
    public static final String API_PAYMENT_DETAILS = 'Payment_Details';
    public static final String API_ADD_PAYMENT_PROFILE = 'Add_Payment_Profile';
    public static final String API_ORDER_HISTORY = 'Order_History';
    public static final String API_PROMOTION_DETAILS = 'Promotion_Details';
    public static final String API_BILLING_STATEMENT = 'Billing_Statement';
    public static final String API_BILLING_DETAILS = 'Billing_Details';
    public static final String API_PAYMENT_PROFILE = 'Payment_Profile';
    public static final String API_MAKE_PAYMENT = 'Make_Payment';
    public static final String API_UPDATE_PAYMENT = 'Update_Payment';
    public static final String API_DELETE_PAYMENT = 'Delete_Payment';
    public static final String API_AUTHORIZATION_STATUS = 'Authorization_Status';
    public static final String API_AUTHENTICATION_GENERATE_PIN = 'Authentication_Generate_Pin';
    public static final String API_AUTHENTICATION_VALIDATE_PIN = 'Authentication_Validate_Pin';
    public static final String API_AUTHENTICATION_VALIATE_CREDENTIALS = 'Authentication_Validate_Credentials';
    public static final String API_BILLING_ENROLLMENT_STATUS = 'Billing_Enrollment';
    public static final String API_AUTOPAY_PROFILES_POST = 'AutoPay_Profiles_POST';
    public static final String API_CC_TOKEN = 'CC_Token';
    public static final String API_USER_ASSOCIATIONS = 'User_Associations';
    public static final String API_USER_ASSOCIATIONS_ADD_DELETE = 'User_Associations_Add_Delete';
    public static final String API_CUSTOMER_ACCOUNT = 'Customer_Account';
    public static final String API_CUSTOMER_ACCOUNT_P = 'Customer_Account_P';
    public static final String API_CUSTOMER_ACCOUNT_S = 'Customer_Account_S';
    public static final String API_CUSTOMER_PROFILE = 'Customer_Profile';
    public static final String API_SERVICE_AVAILABILITY = 'Service_Availability';
    public static final String API_MULTI_CLOUD_INTEGRATION = 'Multi_Cloud_Integration';
    public static final String API_RECOMMENDATION = 'BANRecommendations';
    public static final String API_CUSTOMER_USAGE = 'Customer_Usage';
    public static final String API_UPDATE_CONSENT = 'Update_Consent';
    public static final String API_ORDER_DETAILS = 'Order_Details';
    public static final String API_EPA_ENROLL = 'EPA_Enroll';
    public static final String API_COMMUNICATION_HISTORY_DETAILS = 'Communication_History';
    public static final String API_COMMUNICATION_RESEND = 'Communication_Resend';
    public static final String API_RSATOKEN = 'RSAToken';
    public static final String API_IMEI_SEARCH = 'IMEI_Search';
    public static final String API_BILLING_CHARGES = 'Billing_Charges';

     //only to support  Active and Tentative Equipments
     public static final List<String> EQUIPMENT_STATUSES = new List<String>{'Active','Reserved'};

     public static final String STR_CALLOUT = 'callout:';
     public static final Integer HTTP_STATUS_CODE_200 = 200;
     public static final Integer HTTP_STATUS_CODE_404 = 404;
     public static final string HTTP_ERROR_MESSAGE = 'Something went Wrong';

     public static final String HTTP_TRANSACTION_ID_HEADER = 'x-transaction-id';
     public static final String HTTP_CORRELATION_ID_HEADER = 'x-correlation-id';
     public static final String HTTP_ATT_TRANSACTION_ID_HEADER = 'X-ATT-UniqueTransactionId';
     public static final String HTTP_TRACE_ID_HEADER = 'idp-trace-id';

     public static final String ADDRESS_TYPE_BILLING = 'Billing';

     // 09-21-2020 New Service address types
     public static final String ADDRESS_TYPE_SERVICE = 'Service';
     public static final String ADDRESS_TYPE_SERVICE_USPS = 'ServiceUSPS';
     public static final String ADDRESS_TYPE_SERVICE_SAG = 'ServiceSAG';
     public static final String ADDRESS_TYPE_SERVICE_FSP = 'ServiceFSP';

     public static final String CS_BAN_WITH_ACCOUNT_TYPE = 'banWithAccountType';
     public static final String CS_PHONE_NUMBER = 'phoneNumber';
     public static final String CS_USER_ID = 'userId';
     public static final String CS_ADDRESS_ID = 'addressId';
     public static final String CS_ADDRESS_SEARCH = 'address';

     public static final String EQUIPMENT_FIELDSET_NAME = 'RecordDetail';
     public static final String NO_DATA = 'No Data to show';
     public static final String STATUS_SUSPENDED = 'Suspended';
     public static final String SLDS_ERROR = 'slds-text-color_error';

    public static final String EQUIPMENT_TYPE_DEVICE = 'device';
    public static final String EQUIPMENT_TYPE_CONNECTED_CAR = 'connectedCar';

    //conveniencefeeEligibility
    public static final String CONFEEELIG_PRODUCT_CODE = 'CONV';
    public static final String CONFEEELIG_TOPICS = 'convenienceFeeEligibility';

    // API fixed values
    public static final String APP_NAME = 'SFORCECC';
    public static final String SOURCE_SYSTEM = 'SFORCECC';
    public static final String SOURCE_LOCATION = 'CS';
    public static final String SOURCE_SYSTEM_BSSE = 'RTB';
    public static final String SOURCE_LOCATION_BSSE = 'XX';
    public static final String MERCHANT_ID = 'SFORCECC-CON';
    public static final String LOCATION_ID = null;
    public static final String SOURCE_BUSINESS_UNIT = null;
    public static final String CUSTOMER_AGREEMENT = 'TNC_001';

    // Payment method types
    public static final String PAYMENT_METHOD_TYPE_CARD = 'CARD';
    public static final String PAYMENT_METHOD_TYPE_BANKACCOUNT = 'BANKACCOUNT';

    // Notes Search values
    public static final String NOTES_CALLING_APP = 'SALESFORCE';

    // Authorization service
    public static final String AUTHORIZATION_CLIENT_ID = 'SalesForce';
    public static final String AUTHORIZATION_LEVEL_L0 = 'L0';
    public static final String AUTHORIZATION_LEVEL_L1 = 'L1';
    public static final String AUTHORIZATION_LEVEL_BYPASS = 'BYPASS';
    public static final Set<String> AUTHORIZATION_LEVELS_L1_PRIVILEGED = new Set<String>{AUTHORIZATION_LEVEL_L1, AUTHORIZATION_LEVEL_BYPASS};

    // Authenticate methods
    public static final String AUTHENTICATION_METHOD_OTP = 'OTP';
    public static final String AUTHENTICATION_METHOD_BYPASS = 'BYPASS';
    public static final Set<String> AUTHENTICATION_METHODS_OTP_PRIVILEGED = new Set<String>{AUTHENTICATION_METHOD_OTP, AUTHENTICATION_METHOD_BYPASS};

    // Purchase Terms
    public static final String EQUIPMENT_RENT_TERM = 'Rent';
    public static final String EQUIPMENT_LEASE_TERM = 'Lease';
    public static final String EQUIPMENT_PURCHASE_TERM = 'Purchase';

	// Case
    public static final String CASE_PAYMENT_TYPE_CREDIT_CARD = 'Credit / ATM card';
    public static final String CASE_PAYMENT_TYPE_BANK_TRANSFER_EFT = 'Bank Transfer / EFT';
    public static final String CASE_PAYMENT_METHOD_CARD_NUMBER = 'Card  number';
    public static final String CASE_PAYMENT_METHOD_ACCOUNT_NUMBER = 'Account Number';

    //Templates for Nebula
    public static final String NEBULA_MESSAGE_TEMPLATE = 'APINAME: {0} \n Params: {1} \n Result: {2} ';
    public static final String OPUS_NEBULA_MESSAGE_TEMPLATE = 'category=ApexCall|apiName={0}|params={1}|result={2}';
    public static final String WFE_NEBULA_MESSAGE_TEMPLATE = 'category=ApexCall|apiName={0}|method=post|mode=cors|credentials=include|cache=no-cache|Content-Type=application/json|params={1}';
    public static final String TSRM_NEBULA_MESSAGE_TEMPLATE = 'category=ApexCall|apiName={0}|method=post|mode=cors|credentials=include|cache=no-cache|Content-Type=application/json|params={1}';
    
    //Topics for Nebula
    public static final String LIC_OPUS_TOPIC = 'LIC - OPUS';
    public static List<String> LIC_TOPICS = new List<String>{
        LIC_OPUS_TOPIC
    };

    //SLA Work starts
    public class SLA_DATA {
        //SLA/Entitlement 
        public String SLA_INTERNAL{ get; set; }
        public String SLA_EXTERNAL{ get; set; }
        public SLA_DATA() {
            this.SLA_INTERNAL = 'MSS Internal';
            this.SLA_EXTERNAL = 'MSS External';
        }
   	}

    // Customer Usage
    public static final String USAGE_DATA_DEFAULT_UOM = 'GB';
    public static final String USAGE_TEXT_UOM = 'SMS';
    public static final String USAGE_VOICE_UOM = 'Minutes';
    public static final String USAGE_MIX_MATCH_TYPE = 'LINE_LEVEL';

    // These are all different types of charges that can be returned on statement
    public static final String BILLING_CHARGE_TYPE_TAXES = 'TAXES';
    public static final String BILLING_CHARGE_TYPE_SURCHARGES = 'SURCHARGES';
    public static final String BILLING_CHARGE_TYPE_PLAN_CHANGES = 'PLAN_CHANGES';
    public static final String BILLING_CHARGE_TYPE_MONTHLY_CHARGES = 'MONTHLY_CHARGES_DETAILS';
    public static final String BILLING_CHARGE_AMTIND_CR = 'CR';
    
    // Used to determine how far back to look for recent escalation cases.
    public static final Integer ESCALATION_CASE_RECENT_NUMBER_OF_DAYS = 14;
    
    //KM
    public static final String KM_PUBLISH_STATUS_ONLINE = 'Online';
    
    // Value of Employee__c.Work_Country__c
    public static final String COUNTRY_USA = 'USA';
    
    // Case-Email and SMS alerts 
    public static final String CTM_SMS_TEMPLATE = 'Case Open English';
    public static final String CASETYPE_BILING_INQUIRY = 'Billing | Inquiry';
    public static final String CASETYPE_BILING_PAYMENT = 'Billing | Payment';
    public static final String CASETYPE_SERVICES_INQUIRY = 'Services | Inquiry';
    public static final String CASEACTION_DELAYED_BILL = 'Bill Image - Delayed Bill';
    public static final String CASEACTION_OVERPAYMENT = 'Autopay Transaction Issues - Overpayment';
    public static final String CASEACTION_DIGITAL_PAYMENT = 'Digital | PAYMENT';
    public static final String CASERESOLUTION_CORRECTED = 'Corrected';
    public static final String CASERESOLUTION2_PRICING = 'Pricing';
    public static final String CASERESOLUTION2_EDUCATED_CUSTOMER = 'Educated Customer';
    public static final String CASERECORDTYPE_ESCALATION = 'Escalation';
    public static final String CASECLOSENOTE = 'Testing Closure';
    public static final String CASESTATUS_NEW = 'New';
    public static final String CASESTATUS_CLOSED = 'Closed';
    public static final String CASESTATUS_IN_PROGRESS = 'In Progress';
    public static final String TEST_CONTACT_NUMBER = '8434130430';
    public static final String COMMUNICATIONTYPE_NEWCASE = 'New Case';
    public static final String COMMUNICATIONTYPE_CASECLOSED = 'Case Closed';
    public static final String COMMUNICATIONTYPE_EMV = 'External Milestone Violated';
    public static final String LANGUAGE_ENGLISH = 'English';
    public static final String LANGUAGE_SPANISH = 'Spanish';
    public static final String CTM_FROM_EMAIL_NONE = 'None';

    //EmailTemplate Constant
    public static final String RELATEDENTITYTYPE_CASE = 'Case';
}