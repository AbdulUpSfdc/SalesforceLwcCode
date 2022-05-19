/*
    Allows an LWC to retrieve account details including related lists.
*/
public inherited sharing class BWC_AccountService {

    public static final String EXCEPTION_NOT_AUTHORIZED = 'NOT_AUTHORIZED';
    public static final String EXCEPTION_BILLING_ACCOUNT_NOT_FOUND = 'BILLING_ACCOUNT_NOT_FOUND';

    /**
     * @description Return the Billing Accounts associated with Interaction or Account:
     * @param  recordId         Interaction ID
     * @param  requestedTypes   Filter to only these account types
     * @param  requestedBans    Filter to only these bans
     * @param  onlyL1           If it's interaction, then only return those that are L1 authorized
     * @param  excludeUnified   For some billing APIs we don't want to send if it's a unified account so leave them out
     * @param  maskUnauthorized Return masked BAN number if the billing account is not L1 or Bypass on the interaction
     * @return                  List of Billing_Account__c meeting the filter criteria
     */
    public static List<Billing_Account__c> getBillingAccounts(Id recordId, Set<String> requestedTypes, Set<String> requestedBans, Boolean onlyL1, Boolean excludeUnified, Boolean maskUnauthorized) {

        if (recordId == null) {
            throw new BWC_Exception('Argument required: recordId');
        }

        Id accountId;
        Set<String> authorizedBans;

        if (recordId.getSobjectType() == Interaction__c.getSobjectType()) {

            // Get the interaction and authorization data
            Interaction__c interaction = [
                SELECT
                    Id, Customer__c, Is_Authorized__c, Authorization_Json__c
                FROM
                    Interaction__c
                WHERE
                    Id = :recordId
            ];

            accountId = interaction.Customer__c;

            if (accountId == null) {
                throw new BWC_Exception('Customer__c not set on Interaction__c: ' + recordId);
            }

            if (onlyL1 == true || maskUnauthorized == true) {

                // Need to get bans from authorization data which is stored in Authorization_Json__c on interaction
                authorizedBans = new Set<String>();
                if (interaction.Is_Authorized__c == true && !String.isEmpty(interaction.Authorization_Json__c)) {

                    BWC_AuthorizationCallout.AuthorizationStatusContent authorizationData = (BWC_AuthorizationCallout.AuthorizationStatusContent)JSON.deserialize(interaction.Authorization_Json__c, BWC_AuthorizationCallout.AuthorizationStatusContent.class);

                    if (authorizationData.associatedAccounts != null) {

                        // Get only L1 bans
                        for (BWC_AuthorizationCallout.AssociatedAccount associatedAccount : authorizationData.associatedAccounts) {
                            if (BWC_Constants.AUTHORIZATION_LEVELS_L1_PRIVILEGED.contains(associatedAccount.authorizationLevel)) {
                                authorizedBans.add(associatedAccount.accountBan);
                            }
                        }

                    }

                }    

            }

            if (onlyL1 == true && authorizedBans.isEmpty()) {

                // No L1 bans, just return empty list now
                return new List<Billing_Account__c>();
    
            }

        }
        else if (recordId.getSobjectType() == Account.getSobjectType()) {

            // Directly from account, no auth check ata ll
            accountId = recordId;

        }
        else {
            throw new BWC_Exception('recordId not Interaction__c or Account: ' + recordId);
        }
        
        // Query for the billing accounts
        List<Customer_Account_Relation__c> customerAccountRelations = [
            SELECT
                Id, Billing_Account__r.Id, Billing_Account__r.Billing_Account_Number__c, Billing_Account__r.Service_Name__c, 
                Billing_Account__r.Service_Type_Name__c, Billing_Account__r.Service_Label__c, Billing_Account__r.Product_Name_360__c,
                Billing_Account__r.Is_Unified__c, Billing_Account__r.Unified_BAN__c, Billing_Account__r.Wireless_BAN__c,
                Billing_Account__r.First_Name__c, Billing_Account__r.Last_Name__c, Billing_Account__r.Billing_Zipcode__c,
                Billing_Account__r.Account_Type__c, Billing_Account__r.Account_Status__c, Billing_Account__r.Email__c, Billing_Account__r.CPNI_Preference__c,
                Billing_Account__r.Service_Start_Date__c,Billing_Account__r.Customer_Type__c,
                Billing_Account__r.Contact_Number__c, Billing_Account__r.Alternate_Phone_Number__c, Billing_Account__r.Billing_Market__c,
                Billing_Account__r.Prepaid_Customer__c, Billing_Account__r.HBO_Max_Entitlement__c, Billing_Account__r.Default_Payment_Profile__c,
                Billing_Account__r.Is_FirstNet__c
            FROM
                Customer_Account_Relation__c
            WHERE
                Customer__c = :accountId
            ORDER BY
                Billing_Account__r.Display_Sequence__c
            ];

        List<Billing_Account__c> results = new List<Billing_Account__c>();
        Set<Id> billingAccountIds = new Set<Id>();

        // Filter as needed
        for (Customer_Account_Relation__c customerAccountRelation : customerAccountRelations) {

            Billing_Account__c billingAccount = customerAccountRelation.Billing_Account__r;

            // Avoid duplicate billing accounts due to duplicate Customer_Account_Relation__c records
            if(billingAccountIds.contains(billingAccount.Id)){
                continue;
            }

            billingAccountIds.add(billingAccount.Id);

            if (requestedTypes != null && !requestedTypes.isEmpty() && !requestedTypes.contains(billingAccount.Account_Type__c)) {

                // Not in requested types, don't add
                continue;                

            }

            if (requestedBans != null && !requestedBans.isEmpty() && !requestedBans.contains(billingAccount.Billing_Account_Number__c)) {

                // Not in requested bans, don't add
                continue;

            }

            if (onlyL1 == true && authorizedBans != null && !authorizedBans.contains(customerAccountRelation.Billing_Account__r.Billing_Account_Number__c)) {

                // Not L1, don't add
                continue;

            }

            if (excludeUnified == true && 
                customerAccountRelation.Billing_Account__r.Account_Type__c == BWC_Constants.ACCOUNT_TYPE_WIRELESS && 
                customerAccountRelation.Billing_Account__r.Is_Unified__c == true && 
                String.isNotEmpty(customerAccountRelation.Billing_Account__r.Unified_BAN__c)) {

                // It's unified, don't add
                continue;

            }

            if (BWC_BillingAccount.agentHasAccess(customerAccountRelation.Billing_Account__r) != true) {

                // It's FirstNet and agent does not have permission, or other reason agent should not see this account
                continue;                

            }

            if (maskUnauthorized == true && !authorizedBans.contains(customerAccountRelation.Billing_Account__r.Billing_Account_Number__c)) {

                // Unauthorized BANs must be masked
                BWC_BillingAccount.maskBillingAccountBans(customerAccountRelation.Billing_Account__r);

            }

            // Mask unified BAN even if Current BAN is Authorized.
            if(maskUnauthorized == true && !authorizedBans.contains(customerAccountRelation.Billing_Account__r.Unified_Ban__c)){

                customerAccountRelation.Billing_Account__r.Unified_Ban__c = BWC_BillingAccount.maskBan(customerAccountRelation.Billing_Account__r.Unified_Ban__c);

            }
    
            // Made it through filters, add
            results.add(customerAccountRelation.Billing_Account__r);

        }

        return results;

    }

    /*
        Temporary override until full ban masking is in place.
    */
    public static List<Billing_Account__c> getBillingAccounts(Id recordId, Set<String> requestedTypes, Set<String> requestedBans, Boolean onlyL1, Boolean excludeUnified) {
        return getBillingAccounts(recordId, requestedTypes, requestedBans, onlyL1, excludeUnified, false);
    }

    /*
        Retrieve account record by billing account number.
    */
    public static Billing_Account__c getBillingAccountForBan(String ban) {

        if (String.isEmpty(ban)) {
            throw new BWC_Exception('Argument required: ban');
        }

        List<Billing_Account__c> billingAccounts = [
            SELECT
                Id, Billing_Account_Number__c, Service_Name__c, Service_Label__c,
                Is_Unified__c, Unified_BAN__c, Wireless_BAN__c, First_Name__c, Last_Name__c, Billing_Zipcode__c,
                Account_Type__c, Account_Status__c, Email__c, CPNI_Preference__c, Billing_Address__c, Product_Name_360__c, Contact_Number__c, Alternate_Phone_Number__c,
                Prepaid_Customer__c, Billing_Market__c, Security_Question__c, Customer_Type__c, Is_FirstNet__c
            FROM
                Billing_Account__c
            WHERE
                Billing_Account_Number__c = :ban
            WITH SECURITY_ENFORCED
        ];

        if (billingAccounts.isEmpty()) {
            throw new BWC_Exception('No Billing Account record found for BAN: ' + ban, EXCEPTION_BILLING_ACCOUNT_NOT_FOUND);
        }
        
        return billingAccounts[0];

    }

    /*
        Retrieve account record by billing account number.
    */
    public static Billing_Account__c getBillingAccountForId(String billingAccountId) {

        if (String.isEmpty(billingAccountId)) {
            throw new BWC_Exception('Argument required: billingAccountId');
        }

        List<Billing_Account__c> billingAccounts = [
            SELECT
                Id, Billing_Account_Number__c, Service_Name__c, Service_Label__c,
                Is_Unified__c, Unified_BAN__c, Wireless_BAN__c, First_Name__c, Last_Name__c, Billing_Zipcode__c,
                Account_Type__c, Account_Status__c, Email__c, CPNI_Preference__c, Billing_Address__c, Product_Name_360__c, Contact_Number__c, Alternate_Phone_Number__c,
                Prepaid_Customer__c, Is_FirstNet__c
            FROM
                Billing_Account__c
            WHERE
                Id = :billingAccountId
            WITH SECURITY_ENFORCED
        ];

        if (billingAccounts.isEmpty()) {
            throw new BWC_Exception('No Billing Account record found for Id: ' + billingAccountId, EXCEPTION_BILLING_ACCOUNT_NOT_FOUND);
        }

        return billingAccounts[0];

    }

    /**
     * @description Retrieve billing account which must be associated with the specified interaction and must be L1 or BYPASS authorized on the interaction.
     * @param  interactionId
     * @param  billingAccountId
     * @return The Billing_Account__c record
     */
    public static Billing_Account__c getInteractionBillingAccount(Id interactionId, Id billingAccountId) {

        // Retrieve interaction record
        Interaction__c interaction = BWC_Interaction.getInteraction(interactionId);

        // Get all billing accounts mapped by ID, and find the requested one.
        Map<Id, Billing_Account__c> billingAccountMap = new Map<Id, Billing_Account__c>(BWC_BillingAccount.getBillingAccounts(interaction));
        Billing_Account__c billingAccount = billingAccountMap.get(billingAccountId);

        if (billingAccount == null) {
            throw new BWC_Exception('No valid Billing Account record found for Id: ' + billingAccountId + ' on Interaction: ' + interactionId, EXCEPTION_BILLING_ACCOUNT_NOT_FOUND);
        }

        // Deserialize auth content and check for L1.
        BWC_AuthorizationCallout.AuthorizationStatusContent authContent = BWC_Interaction.getAuthorizationContent(interaction);
        if (authContent.isL1Authorized(billingAccountId) != true) {
            throw new BWC_Exception('Billing account is not L1 authorized.', EXCEPTION_NOT_AUTHORIZED);
        }

        // OK to return
        return billingAccount;

    }

    /*
        Retrieve person account record from interaction id.
    */
    public static Account getCustomerAccount(String interactionId) {

        if (String.isEmpty(interactionId)) {
            throw new BWC_Exception('Argument required: interactionId');
        }

        Interaction__c interaction = [
            SELECT
                Id, Customer__c, Customer__r.FirstName, Customer__r.LastName, Customer__r.PersonMailingPostalCode, Customer__r.Individual_ID__c,
                Customer__r.Phone, Customer__r.PersonMobilePhone, Customer__r.PersonEmail, Customer__r.Is_Digital_Customer__c
            FROM
                Interaction__c
            WHERE
                Id = :interactionId
            WITH SECURITY_ENFORCED
        ];

        if (interaction.Customer__r == null) {
            throw new BWC_Exception('No Customer Account record found for Interaction: ' + interactionId, EXCEPTION_BILLING_ACCOUNT_NOT_FOUND);
        }

        return interaction.Customer__r;

    }

}