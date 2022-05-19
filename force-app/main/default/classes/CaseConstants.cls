// Generic class to maintain all the constants used throughout the Case Object.
public with sharing class CaseConstants {
    // SAMPLE
     // public static String << OBJECTNAME_CONSTANTNAME>> = '<< Constant Value>> ';

     // Record Type Constants - Developer Name
     public static final String OOP_RECORD_TYPE = 'OOP';
     public static final String OOP_READ_ONLY_RECORD_TYPE = 'OOPReadOnly';
     public static final String OOP_CLOSED_READ_ONLY_RECORD_TYPE = 'OOPClosedReadOnly';
     public static final String OOP_FIELD_RECORD_TYPE = 'OOPField';
     public static final String OOP_RESPONSE_RECORD_TYPE = 'OOPResponse';
     public static final String OOP_FIELD_READ_ONLY_RECORD_TYPE = 'OOPFieldReadOnly';
     public static final String OOP_RESPONSE_READ_ONLY_RECORD_TYPE = 'OOPResponseReadOnly';
     public static final String OOP_INQUIRY_RECORD_TYPE = 'Inquiry';
     public static final String ESCALATION_RECORD_TYPE = 'Escalation';

     // Case Status Constants
     public static final String NEW_STATUS = 'New';
     public static final String IN_PROGRESS_STATUS = 'In Progress';
     public static final String ON_HOLD_STATUS = 'On Hold';
     public static final String CANCELLED_STATUS = 'Cancelled';
     public static final String RESPONSE_RETURNED_STATUS = 'Response Returned';
     public static final String PENDING_CLOSED_STATUS = 'Pending Closed';
     public static final String CLOSED_STATUS = 'Closed';
     public static final String MERGED_STATUS = 'Merged';
     public static final String PENDING_CLOSE_STATUS = 'Pending Close';
     
      //Case Origin Constants
      public static final String WEB_FORM = 'Web Form';
    
     // Role Name Constants - Role name
     //public static final String ROLE_INTAKE_ADMIN = 'Intake Admin';
     
     // Role Name Constants - Developer name
     public static final String ROLE_DEV_OOP_ADMIN = 'OOPAdmin';
     public static final String ROLE_DEV_INTAKE_ADMIN = 'IntakeAdmin';
     public static final String ROLE_DEV_INTAKE_AGENT = 'IntakeAgent';
     public static final String ROLE_DEV_FIELD_ADMIN = 'FieldAdmin';
     
     // Group Name Constants 
     public static final String GROUP_OOPADMIN = 'OOPAdmins';
     public static final String GROUP_OOPAGENT = 'OOPAgents';
     
    //Route Action Constants
    public static final String ROUTE_ACTION_TIER_1 = 'Tier 1';
    public static final String ROUTE_ACTION_TIER_2_PRE = 'Tier 2: Pre-Dispatch';
    public static final String ROUTE_ACTION_TIER_2_POST = 'Tier 2: Post-Dispatch';
    public static final String ROUTE_ACTION_TIER_3_PRE = 'Tier 3: Pre-Dispatch';
    public static final String ROUTE_ACTION_TIER_3_POST = 'Tier 3: Post-Dispatch';
    public static final String ROUTE_ACTION_TIER_POST = 'Post-Dispatch';
    public static final String ROUTE_ACTION_TIER_PRE = 'Pre-Dispatch';
    public static final String ROUTE_ACTION_TIER_DONE = 'Done';
     
     
     // Case Status Constants
     public static final String CASE_STATUS_NEW = 'New';
     public static final String CASE_STATUS_IN_PROGRESS = 'In Progress';
     public static final String CASE_STATUS_ON_HOLD = 'On Hold';
     public static final String CASE_STATUS_CANCELLED = 'Cancelled';
     public static final String CASE_STATUS_RESPONSE_RETURNED = 'Response Returned';
     public static final String CASE_STATUS_PENDING_CLOSED = 'Pending Closed';
     public static final String CASE_STATUS_CLOSED = 'Closed';
     public static final String CASE_STATUS_MERGED = 'Merged';
     public static final String CASE_STATUS_ACCEPTED = 'Accepted';
     public static final String CASE_STATUS_WORKING = 'Working';

     //Case Type Constants
     public static final String CASE_TYPE_BILLING_INQUIRY = 'Billing | Inquiry';
     public static final String CASE_TYPE_ORDER_FALLOUT = 'Order Action | Online fallout Wireless';
     public static final String CASE_TYPE_HOLD_CASE_REMINDER = 'Hold case reminder';

     //Urgent Case Actions
     public static final String CASE_ACTION_URGENT_INSTALLMENT_ERROR = 'Urgent | Installment Error';
     public static final String CASE_ACTION_URGENT_SIGNATURE_DISCOUNTS = 'Urgent | Signature Discounts';
     public static final String CASE_ACTION_URGENT_UNIFIED_ERRORS = 'Urgent | Unified Errors';
     public static final Set<String> CASE_URGENT_ACTIONS = new Set<String>{CASE_ACTION_URGENT_INSTALLMENT_ERROR, CASE_ACTION_URGENT_SIGNATURE_DISCOUNTS, CASE_ACTION_URGENT_UNIFIED_ERRORS};
          
     // Role Name Constants - Developer name
     public static final String OOP_ROLE_OOP_ADMIN = 'OOPAdmin';
     public static final String OOP_ROLE_INTAKE_ADMIN = 'IntakeAdmin';
     public static final String OOP_ROLE_INTAKE_AGENT = 'IntakeAgent';
     public static final String OOP_ROLE_FIELD_ADMIN = 'FieldAdmin';
     public static final String OOP_ROLE_FIELD_AGENT = 'FieldAgent';
     
     // Group Name Constants 
     public static final String OOP_GROUP_OOPADMIN = 'OOPAdmins';
     public static final String OOP_GROUP_OOPAGENT = 'OOPAgents';
     
     // Group Name Constants 
     public static final String OOP_QUEUE_OOPADMIN = 'OOPAdmins';
     
     // Uverse Billing Account Type
     public static final String BILLING_ACCOUNT_TYPE_UVERSE = 'Uverse';
     
     
     //Run once Check owner and eliminate recursive
     public static boolean runCheckAssignment =true;
     // Role Name Constants 
     public static final String ROLE_INTAKE_ADMIN = 'Intake Admin';
     public static final String ROLE_INTAKE_AGENT = 'Intake Agent';
     
     //For Escalation Cases
     public static final List<String> CASE_TYPE_PRODUCT_SRV_GROUP = new List<String>{ 'Product Service | Feature | Add Change Remove','Product Service | Rate Plan | Add Change Remove'};
     public static final String CASE_TYPE_PRODUCT_SRV_DEVICE = 'Product Service | Device | Upgrade';
     public static final List<String> CASE_ACTION_PRODUCT_SRV_DEVICE_LST = new List<String>{ 'Unable to upgrade WLS device','Unable to swap WLS device'};
     public static final String CASE_PRODUCT_SRV_DEVICE_TYPE = 'Device Type';
     public static final String CASE_PRODUCT_SRV_DEVICE_MAKEMODEL = 'Device Make & Model';     
     public static final String CASE_PRODUCT_SRV_DEVICE_PRODUCTCODE = 'Device Product Code';     
     public static final String CASE_PRODUCT_SRV_DEVICE_MANUFACTURER = 'Device Manufacturer';
     public static final String CASE_PRODUCT_SRV_DEVICE_IMEI = 'Device IMEI';
     public static final String CASE_PRODUCT_SRV_DEVICE_SIM = 'SIM / Smart Chip';
     public static final String CASE_PRODUCT_SRV_SUBSCRIBER_NAME = 'Subscriber Name';
     public static final String CASE_PRODUCT_SRV_SUBSCRIBER_STATUS = 'Subscriber Status';
     public static final String CASE_PRODUCT_SRV_RATE_PLAN_NAME = 'Rate Plan Name';
     public static final String CASE_PRODUCT_SRV_RATE_PLAN_CODE = 'Rate Plan Product Code';
     public static final String CASE_PRODUCT_SUBMARKET = 'SubMarket';
     public static final String CASE_CATEGORY = 'Escalation';
     
     
     //DTV OOP
     public static final String CASE_PRIORITY_VIP = 'VIP';
     public static final String CASE_PRIORITY_HIGH = 'High';
     public static final String CASE_PRIORITY_OUT_OF_SRV = 'Out of Service';
     public static final String CASE_VIDEO_TYPE_OF_OOP = 'Video';
     
     public static final String OOP_QUEUE_DTVVIP = 'DTVVIP';
     public static final String OOP_QUEUE_DTVHIGH = 'DTVHighPriority';
     public static final String OOP_QUEUE_DTVLOW = 'DTVLowPriority';
     public static final String OOP_QUEUE_DTVINTAKE = 'DTVIntake';
     public static final String OOP_QUEUE_DTVINTAKEREASSIGNMENT = 'DTVIntakeReassignment';
     public static final String OOP_QUEUE_DTVREGULATORY = 'DTV_Regulatory_Queue';
     
     //For OOP DTV queue assignment 
     public static final String CASE_QUEUE_MATCHWITHPRODUCTS = 'MatchExists';
     public static final String CASE_QUEUE_NO_MATCHWITHPRODUCTS = 'NoMatchExists';
     
     //Case Routing Override 
     public static final String CASE_ROUTING_OVERRIDE_INTAKE = 'Intake';
     
     //For OOP DTV queue assignment 
     public static final String CASE_RELATED_OOPCASES_EXIST = 'OOPCasesExists';
     public static final String CASE_RELATED_NO_OOPCASES_EXIST = 'NoOOPCasesExists';
     
     //For Case Resolution - Response Returned
     public static final String  CASE_RESOLUTION_RESPONSE_RETURNED = 'Response Returned';
     // for case owner assignment
     public static final string  OOPVIP='OOPVIP';
     public static final string  OOP_HIGH_PRIORITY='OOPHighPriority';
     public static final string  OOP_SPANISH='OOPSpanish';  
     public static final string  OOP_CONSUMER_WIRELESS='OOPConsumerWireless';
     public static final string  OOP_BUSINESS_WIRE_LINE ='OOPBusinessWireline';
     public static final string  OOP_BUSINESS_MOBILITY ='OOP_Business_Mobility';
     public static final string  INTAKEQUEUE='IntakeQueue';
     public static final string  OOP_QUEUE_INTAKEREASSIGNEDQUEUE = 'IntakeReassignedQueue';
     
     public static final string  R_FCC_REBUTTAL='4R-FCC Rebuttal';
     public static final string  BR_BBB_REBUTTAL='7BR-BBB Rebuttal';
     public static final string  SS_4D_FCC_Disability_Rights='4D-FCC Disability Rights';
     public static final string  SS_4_FCCs='4-FCC';
     public static final string  SS_2L_Legal='2L-Legal (Third Party)';
     public static final string  SS_3A_Agency_not_a_Commission='3A-Agency not a Commission';
     public static final string  SS_3C_State_Commission='3C-State Commission';
     public static final string  SS_3G_Attorney_General='3G-Attorney General';
     public static final string  SS_5A_Board_of_Director = '5A-Board of Director';
     public static final string  SPANISH_CODE='es';
     public static final string  CONSUMER='Consumer';
     public static final string  ALL_OR_ANY='All or Any (No Others)';
     public static final List<string> BUSINESS_WIRELINES = new List<String>{'Business (Other)', 'NBM', 'RLBM', 'GEM', 'Global', 'Wholesale'};
     public static final List<string> CONSUMER_WIRELINES=new List<String>{'Wireless', 'Wireless Prepaid','FirstNet','Digital Life'};
     public static final string OOPLOWPRIORITY ='OOPLowPriority';
     public static final string ADJUSTMENT_SUBMIT_FOR_APPROVAL = 'Submit for approval';
     public static final string ADJUSTMENT_STATUS_LEVEL_1 = 'Level 1 (Manager)';
     public static final string ADJUSTMENT_STATUS_LEVEL_2 = 'Level 2';
     public static final string ADJUSTMENT_STATUS_APPROVED = 'Approved';
     public static final string ADJUSTMENT_STATUS_POSTED = 'Posted';
     public static final string ADJUSTMENT_STATUS_POST_FAILED = 'Post Failed';

     public static final string CASE_TYPE_BILLING_ADJUSTMENT = 'Billing | Adjustment';
     public static final string CASE_ROUTING_ACTION_DONE = 'Done';
     public static final string CASE_DESCRIPTION_ADJUSTMENT_CASES = 'Wireless Adjustment Escalation Case';
     
     // For approval process
     public static final string HLA_APPROVAL = 'HLA';
     public static final string COLLECTIONS = 'Collections';
     public static final string MANAGERS_APPROVAL = 'Manager’s Approval';
     public static final string NO_RESPONSE = 'NoResponse';
     public static final string FULL_REJECTION = 'Full Rejection';
     public static final string REJECTED = 'Rejected';
     public static final string STARTED = 'Started';
     public static final string APPROVAL_SUBMITTED = 'Approval Request Submitted';
     public static final string SUBMITTED = 'Submitted';
     public static final string BACKOFFICE_MANAGER_CUSTOM_PERM = 'Credit_Adjustments_Back_Office_Manager';
     public static final string RM_HLA_AUTDIT_Q = 'RM HLA Audit Team';
     public static final string HLA_BOFC_Q = 'HLA BOFC';
     public static final Double WIRELESS_LEVEL_ONE_MANAGER_SOA = 400;

     //For Case OOP routing 
     //public static final string OOP_WORKGROUP_INTAKE_CHECK = 'Intake';
     //public static final string OOP_USER_OWNER_CHECK = '005';
     
     //For Merge Case Script
     public static Boolean isMergeRunValidation = TRUE;
     
     //For upadate Case Owner OOP 
     //public static Boolean OOP_CHECK_UPDATE_OWNER = false;
     
     //For OOP Case Type
     public static final String CASE_TYPE_OOP = 'OOP';
     public static final string OOP_QUEUE_OWNER_CHECK = '00G';

     //Communication Template Mapping Constants
     public static final String EMAIL_TEMPLATE_FOLDER_NAME = 'Escalation Case Auto Communications';

     //Email Custom Permission
      public static final String EMAIL_CUSTOM_PERMISSION ='Email_Comm';
    
     //Profile
     public static final String INT_PROFILE ='Integration Profile';
      
    // Group / Queue
    public static final String GROUP_MAP ='Queue';
    
    //Field APIs
     public static final String BILLING_ACC ='Billing_Account__c';
     public static final String RECORD_COUNT ='recordCount';
     public static final String CASE_ASSIGNMENT ='Case';

    //Asset Status
     public static final String ASSET_STATUS ='Canceled';
    
     //for BWC_AdjustmentAndLineTst Function Params
     public static final String detailRecordWithListOfLineItems ='{"ban":"423432423","caseAction": "", "Type": "",'+
     '"adjustmentData":{"adjType":"Goodwill","adjReasonExplanationCode":"Some Code","adjReasonDescription":"deascriptionData","adjReasonSystemCode":"magenta","adjComments":"stuff about test data"},'+
     '"cdeData":{"overallCDEStatus":"something","cdeApprovedAmount":"5.00","cdeReasonForAgent":"something","cdeReasonForCustomer":"reason data","cdeRecommendationStatus":"Approved with Conditions","isCustomerAccepted":"true","overrideEscalate":"Override","overrideEscalateBy":"Anshul","cdeProductLevelId":"L5000"},'+
     '"billData":{"billDate":"","billSequenceNumber":"1234","chargeCode":"chargeCodeData","chargeType":"Goodwill","chargeSequenceNumber":"241533","chargeDescription":"chargeDescriptionData","chargeAmount":"7500.00","requestAmount":"8500.00","agentAdjustedAmount":"3400"},'+
     '"lineItemDataList":['+
     '{"billDate":"","billSequenceNumber":"1234","chargeCode":"chargeCodeData","chargeType":"Goodwill","chargeSequenceNumber":"241533","chargeDescription":"chargeDescriptionData","chargeAmount":"7500.00","requestAmount":"8500.00","agentAdjustedAmount":"3400"},'+
     '{"billDate":"","billSequenceNumber":"1234","chargeCode":"chargeCodeData","chargeType":"Goodwill","chargeSequenceNumber":"241533","chargeDescription":"chargeDescriptionData","chargeAmount":"7500.00","requestAmount":"8500.00","agentAdjustedAmount":"3400"}]}';
     public static final String detailRecordWithOutListOfLineItems ='{"ban":"423432423","caseAction": "", "Type": "",'+
     '"adjustmentData":{"adjType":"Goodwill","adjReasonExplanationCode":"Some Code","adjReasonDescription":"deascriptionData","adjReasonSystemCode":"magenta","adjComments":"stuff about test data"},'+
     '"cdeData":{"overallCDEStatus":"something","cdeApprovedAmount":"5.00","cdeReasonForAgent":"something","cdeReasonForCustomer":"reason data","cdeRecommendationStatus":"Approved with Conditions","isCustomerAccepted":"true","overrideEscalate":"Override","overrideEscalateBy":"Anshul","cdeProductLevelId":"L5000"},'+
     '"billData":{"billDate":"","billSequenceNumber":"1234","chargeCode":"chargeCodeData","chargeType":"Goodwill","chargeSequenceNumber":"241533","chargeDescription":"chargeDescriptionData","chargeAmount":"7500.00","requestAmount":"8500.00","agentAdjustedAmount":"3400"}}';
}