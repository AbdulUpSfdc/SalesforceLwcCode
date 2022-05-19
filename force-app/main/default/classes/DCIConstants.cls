/*
* This class stores the  various constants being used through the Retail track for Digital Checkin codebase
* @Autthor: Reshma Jewrani, Alisha Mundaden
*/
public with sharing class DCIConstants {
    public static final String DCI_HANDLE_TIME = 'DCIHandleTime'; //key for the DCI wait time custom setting
    public static final String HANDLE_TIME = RetailUtil.getRetailCustomSettings(DCI_HANDLE_TIME); //DCI wait time custom setting
    public static final Integer STORE_EWT = HANDLE_TIME != null ? Integer.valueOf(HANDLE_TIME): 10; //minutes //DCI default handle time
    public static final String EWTCalculationMethod = RetailUtil.getRetailCustomSettings('EWTCalculationType'); // DM Added TUF
    public static final String VALIDATION_EXP =  'FIELD_CUSTOM_VALIDATION_EXCEPTION'; 
    public static final String FUTURE =  'Future';
    public static final String SAMEDAY =  'Same Day'; //DCI Checkin Type on Lead as Same Day
    public static final String ONLINE =  'Online';
    public static final String OFFLINE = 'Offline';
    public static final String BOPISREASON =  'Pick up online order';
    public static final String DCIRemoveChangeReason = 'Cancellation';
    public static final Map<String, String> WEEKDAY_EN_TO_ES = New Map<String, String>{
        'Monday' => 'Lunes',
        'Tuesday' => 'Martes',
        'Wednesday' => 'Miércoles',
        'Thursday' => 'Jueves',
        'Friday' => 'Viernes',
        'Saturday ' => 'Sábado',
        'Sunday ' => 'Domingo'};
    public static final Map<String, String> MONTHS_EN_TO_ES = New Map<String, String>{
        'Jan' => 'Ene',
        'Feb' => 'Feb',
        'Mar' => 'Mar',
        'Apr' => 'Abr',
        'May' => 'May',
        'Jun' => 'Jun',
        'Jul' => 'Jul',
        'Aug' => 'Ago',
        'Sep' => 'Set',
        'Oct' => 'Oct',
        'Nov' => 'Nov',
        'Dec' => 'Dic'};
    //Status
    public static final String REMOVE =  'Remove'; //Status when DCI is Removed
    public static final String ACTIVE =  'Engaged'; //Status when DCI is engaged
    public static final String PENDING =  'Pending'; //Status when DCI is checkedin but not in store
    public static final String INSTORE =  'Arrived'; //Status when DCI is checkedin but is in store
    public static final String CANCELLED =  'Cancelled'; //Status when DCI is cancelled 
    public static final String COMPLETED =  'Completed'; //Status when DCI engagement is completed
    public static final String NOSHOW=  'No Show';  //Status when DCI is a No Show
    public static final String CLOSEDERRORTEST= 'Closed-Error/Test'; //Status when DCI is a Closed-Error/Test
    public static final String OTHER=  'Other';    
    public static final List<String> ALLOWED_STATUS_FOR_STORE_CLEANUP =  new list<String> { PENDING , INSTORE, NOSHOW,CANCELLED,COMPLETED,ACTIVE };//Used in Deletion of DCI Records at EOD
    public static final List<String> ALL_PENDING =  new list<String> { PENDING, INSTORE };
    public static final List<String> ALL_PENDING_ENGAGED =  new list<String> { PENDING, INSTORE, ACTIVE };
    public static final List<String> ALL =  new list<String> { PENDING, INSTORE, CANCELLED };
    public static final List<String> AVAILABLE_DCI_PRESENCE_STATUS =  new list<String> { 'Online', 'Busy' };

    //QuickAction
    public static final String MARK_PENDING =  'MarkPending'; //Action to mark status as pending
    public static final String MARK_ARRIVED =  'MarkArrived'; //Action to mark status as arrived
    public static final String HELP_NEXT =  'HelpNextCustomer'; //Action for helping with Next Arrived Customer
    public static final String MOVE_UP = 'MoveUp'; //Action to move customer up in priority list
    public static final String MARK_NOSHOW = 'MarkNoShow';//Action to mark status as no show
    public static final String MARK_REMOVE = 'MarkRemove'; 
    public static final String ASSIGN_CUSTOMER = 'AssignCustomer';   
  
    //DCI SMS Handling
    public static final String DCI_OUTBOUNDTEXT_FLOW ='RetailDCISMSOutbound';
    public static final String GENERIC_CLOSED = 'Y';
    public static final String COMPLETED_CLOSED = 'CC';
    public static final String ENGAGED_CLOSED = 'CE';
    public static final String UNSTOP= 'UNSTOP';
    public static final String SMSBOPIS = 'BOPIS';

    //Profiles
    public static final String REP_PROFILE = 'Retail RSC Rep'; //Profile Name for the Retail Rep
    public static final String SM_PROFILE = 'Retail SM'; //Profile Name for the Store Manager
    public static final String ARSM_PROFILE = 'Retail ARSM'; //Profile Name for the ARSM
    public static final String EMPSTORE_REP_PROFILE = 'RSC-REP'; //Profile ID for the Retail Rep in Emp Store
    public static final String EMPSTORE_SM_PROFILE = 'RSC-MGR'; //Profile ID for the Store Manager in Emp Store
    public static final String EMPSTORE_ARSM_PROFILE = 'ARSM'; //Profile ID for the Area Store Manager in Emp Store
    public static final String SFPROFILE_MEMBERSHIP_KEY = 'SFProfileForMembership';
    public static final String SFPROFILE_MEMBERSHIP = DCIUtil.getRetailCustomSettings(SFPROFILE_MEMBERSHIP_KEY);
    //EventType
    public static final String NO_SHOW =  'No Show'; //Help Next for NoShow Customer 
    public static final String NEW_CHECKIN =  'NewCheckin'; //New checkin
    //att.com Check-in URL
    public static final String DCI_ATTURL_KEY = 'DCIATTURL';
    public static final String DCI_ATTURL = DCIUtil.getRetailCustomSettings(DCI_ATTURL_KEY);
    public static final String DCI_ATT_RESCHEDULE_URL_KEY = 'DCIATTRescheduleURL';
    public static final String DCI_ATT_RESCHEDULE_URL = DCIUtil.getRetailCustomSettings(DCI_ATT_RESCHEDULE_URL_KEY);
    public static final String DCI_OPUS_ROW = 'OPUS_LIC_MobileApp'; 
    public static final String DCI_CUSTOMER_REQ_REP = 'First Available'; 
    public static final String DCI_CUSTOMER_REQ_REP_NAME_USER_ID = 'First Available|';
    public static final String DCI_OPUS_DEFAULT_LEAD_NAME = 'Guest Guest';
    public static final String TUF = 'TUF';

    /**
     * This method fetches the map of transaction time to handle time for the store ids passed in the Set
     * Parameters -> Set<Id> storeIdSet -> Set of Salesforce id of the store for which the map is required
     * Return -> map<string, Decimal> -> StoreId||Transaction Type to Handle time map
    */
    public static map<String, Decimal> getStoreHandleTimeMap(Set<Id> storeIdSet) {
        map<String, Decimal> typeToHandleTimeMap = new map<String, Decimal>();
        List<StoreHandleTime__c> handleTimeList = [SELECT HandleTime__c, TransactionType__c, Store__c 
                                                    FROM StoreHandleTime__c 
                                                    WHERE Store__c IN : storeIdSet WITH SECURITY_ENFORCED];
        for(StoreHandleTime__c handleTime: handleTimeList) {
            typeToHandleTimeMap.put(handleTime.Store__c+'||'+handleTime.TransactionType__c , handleTime.HandleTime__c);
        }
        system.debug('vtypeToHandleTimeMap--->>'+typeToHandleTimeMap);
        return typeToHandleTimeMap;
    }

    /**
     * This method fetches the handle time for the specifiC transaction type and store
     * Parameters -> storeId -> Salesforce id of the store for which the map is required
     * Return -> map<string, Decimal> -> Transaction Type to Handle time map
    */
    public static Decimal getHandleTime(String storeId, String transactionType) {
        Decimal handleTime = STORE_EWT;
        List<StoreHandleTime__c> handleTimeList = [SELECT HandleTime__c, TransactionType__c, Store__c 
                                                    FROM StoreHandleTime__c 
                                                    WHERE Store__c = :storeId AND 
                                                    TransactionType__c = :transactionType WITH SECURITY_ENFORCED];
        if(handleTimeList.size() > 0) {
            handleTime = handleTimeList[0].HandleTime__c;
        }
        system.debug('handleTime--->>'+handleTime);
        return handleTime;
    }

    /**
     * This method fetches handle time from the map of transaction type to handle time for the store id and transactiontype passed.
     * Parameters -> storeId -> Salesforce id of the store for which the map is required
     * Return -> map<string, Decimal> -> StoreId||Transaction Type to Handle time map
    */
    public static Decimal getHandleTime( map<String, Decimal> typeToHandleTimeMap, String transactionType, String storeId) {
        Decimal handleTime = STORE_EWT;
        if(storeId !=null && transactionType != null &&  typeToHandleTimeMap != null) {
            String key = storeId+'||'+transactionType;
            if(typeToHandleTimeMap.containsKey(key))
                handleTime = typeToHandleTimeMap.get(key);
        }
        system.debug('handleTime--->>'+handleTime);
        return handleTime;
    }
   
    public DCIConstants() {
    }
}