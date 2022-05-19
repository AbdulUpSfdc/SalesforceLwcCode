/*
    Common code for working with Billing_Account__c custom object.
*/
public inherited sharing class BWC_BillingAccount {

    public static final Map<String, String> ACCOUNT_TYPE_LABEL_MAP = new Map<String, String>{
        'WIRELESS' => 'Wireless',
        'wireless' => 'Wireless',
        'UVERSE' => 'Uverse',
        'uverse' => 'Uverse',
        'DTVNOW' => 'DIRECTV STREAM',
        'dtvnow' => 'DIRECTV STREAM',
        'DTVS' => 'DIRECTV LEGACY',
        'dtvs' => 'DIRECTV LEGACY',
        'WATCHTV' => 'WatchTV',
        'watchtv' => 'WatchTV',
        'DTV' => 'Direct TV',
        'dtv' => 'Direct TV',
        'POTS' => 'POTS',
        'pots' => 'POTS'
    };

    // Permission set required to work with FirstNet billing accounts as an agent
    public static final String FIRSTNET_PERMISSION = 'FirstNet_Access';

    // FirstNet Identifiers -- values of fnType which indicate FirstNet account
    public static final String FIRST_NET_UTF = 'utf';
    public static final String FIRST_NET_LEGACY = 'legacy';
    public static final Set<String> FIRST_NET_TYPES = new Set<String>{
        FIRST_NET_LEGACY,
        FIRST_NET_UTF
    };

    // Billing_Account__c.Customer_Liability__c picklist values
    public static final String CUSTOMER_LIABILITY_ILB = 'ILB';
    public static final String CUSTOMER_LIABILITY_IRU = 'IRU';
    public static final String CUSTOMER_LIABILITY_CRU = 'CRU';
    public static final String CUSTOMER_LIABILITY_CLB = 'CLB';

    /*
        Indicates whether current agent should be able to work with the billing account.
    */
    public static Boolean agentHasAccess(Billing_Account__c billingAccount) {

        if (billingAccount.Is_FirstNet__c == true && !FeatureManagement.checkPermission(FIRSTNET_PERMISSION)) {
            // First net hidden unless user has explicit permission
            return false;
        }
        return true;

    }

    /*
        Return display label for any account type that might come from API or enumeration value.
    */
    public static String getBillingAccountTypeLabel(String accountType) {
        
        String label = ACCOUNT_TYPE_LABEL_MAP.get(accountType);
        if (String.isEmpty(label)) {
            return accountType;
        }
        return label;

    }

    /*
        Return all valid billing accounts for the interaction.
    */
    public static List<Billing_Account__c> getBillingAccounts(Interaction__c interaction) {

        if (interaction == null) {
            throw new BWC_Exception('Argument required: interaction');
        }

        if (interaction.Customer__c == null) {
            throw new BWC_Exception('No Customer set on Interaction: ' + interaction.Id);
        }

        return getBillingAccounts(interaction.Customer__c);

    }

    /*
        Return all valid billing accounts for the case.
    */
    public static List<Billing_Account__c> getBillingAccounts(Case caseRecord) {

        if (caseRecord == null) {
            throw new BWC_Exception('Argument required: case');
        }

        if (case.AccountId == null) {
            throw new BWC_Exception('No AccountId set on Case: ' + case.Id);
        }

        return getBillingAccounts(caseRecord.AccountId);

    }

    /*
        Get billing account records associated with the specified Account.
    */
    public static List<Billing_Account__c> getBillingAccounts(Id accountId) {

        if (accountId == null) {
            throw new BWC_Exception('Argument required: accountId');
        }

        // Get all billing account relationships for the interaction customer
        List<Customer_Account_Relation__c> relations = [
            SELECT
                Id, Billing_Account__c, Billing_Account__r.Display_Sequence__c, Billing_Account__r.CTI_Call_Identifier__c, Billing_Account__r.Billing_Account_Number__c,
                Billing_Account__r.Service_Name__c, Billing_Account__r.Service_Type_Name__c, Billing_Account__r.Service_Label__c,
                Billing_Account__r.Is_Unified__c, Billing_Account__r.Unified_BAN__c, Billing_Account__r.Wireless_BAN__c,
                Billing_Account__r.First_Name__c, Billing_Account__r.Last_Name__c, Billing_Account__r.Billing_Zipcode__c,
                Billing_Account__r.Account_Type__c, Billing_Account__r.Account_Status__c, Billing_Account__r.Email__c, 
                Billing_Account__r.CPNI_Preference__c, Billing_Account__r.Billing_Address__c, Billing_Account__r.Product_Name_360__c, 
                Billing_Account__r.Contact_Number__c, Billing_Account__r.Alternate_Phone_Number__c, Billing_Account__r.Prepaid_Customer__c, Billing_Account__r.HBO_Max_Entitlement__c,
                Billing_Account__r.DigitalLife__c, Billing_Account__r.Suspension_Status__c, Billing_Account__r.Service_Start_Date__c, Billing_Account__r.Field_Set_Name__c,
                Billing_Account__r.Is_FirstNet__c, Billing_Account__r.Customer_Liability__c, Billing_Account__r.FirstNet_Type__c
            FROM
                Customer_Account_Relation__c
            WHERE
                Customer__c = :accountId
        ];
        
        List<Billing_Account__c> billingAccounts = new List<Billing_Account__c>();
        Set<Id> billingAccountIds = new Set<Id>();
        for (Customer_Account_Relation__c relation : relations) {

            // If the Id already exists, it's a duplicate record.
            if(billingAccountIds.contains(relation.Billing_Account__c)){
                continue;
            }

            billingAccountIds.add(relation.Billing_Account__c);
            billingAccounts.add(relation.Billing_Account__r);

        }

        return billingAccounts;

    }

    /*
        Mask all BAN numbers on various Billing_Account__c fields. 
    */
    public static void maskBillingAccountBans(Billing_Account__c billingAccount) {

        billingAccount.Billing_Account_Number__c = maskBan(billingAccount.Billing_Account_Number__c);
        billingAccount.Unified_Ban__c = maskBan(billingAccount.Unified_Ban__c);
        billingAccount.Wireless_Ban__c = maskBan(billingAccount.Wireless_Ban__c);

    }

    /*
        Return masked version of BAN.
    */
    public static String maskBan(String valueToMask) {

        if (String.isEmpty(valueToMask)) {
            return valueToMask;
        }

        System.Pattern banMatchPattern = Pattern.compile('\\D*(\\d*)\\D*');        
        System.Matcher theMatcher = banMatchPattern.matcher(valueToMask);
        if (theMatcher.find()) {
            String ban = theMatcher.group(1);
            String maskedBan = '****' + theMatcher.group(1).right(4);
            return valueToMask.replace(ban, maskedBan);
        }
        return valueToMask;

    }

}