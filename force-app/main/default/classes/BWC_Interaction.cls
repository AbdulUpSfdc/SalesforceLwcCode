/*
    Common code for working with Interaction__c custom object.
*/
public inherited sharing class BWC_Interaction {

    public static final String RECORD_TYPE_INBOUND = 'Inbound';
    public static final String RECORD_TYPE_OUTBOUND = 'Outbound';
    public static final String RECORD_TYPE_OFFLINE = 'Offline';
    
    public static Interaction__c getInteraction(Id interactionId) {

        if (interactionId == null) {
            throw new BWC_Exception('Argument required: interactionId');
        }
        
        List<Interaction__c> interactions = [
            SELECT
                Id, RecordTypeId, RecordType.DeveloperName, CTI_Call_Identifier__c, Is_Manual_Search__c,
                Customer__c, Customer__r.PersonEmail, Customer__r.Primary_BAN__c, Is_Nonserviceable_Customer__c, 
                Customer__r.Is_Prepaid_Only__c, Customer__r.isFirstNet__c, Customer__r.Is_Business_Customer__c,
                Billing_Account__c, Billing_Account_Type__c, Billing_Account_Number__c, Unified_BAN__c, Wireless_BAN__c,
                Is_Authorized__c, Authorization_Json__c, Manual_Authentication_Method__c, Manual_Authentication_Json__c,
                Authentication_Method_Used__c, Wireless_Authorization_Level__c,
                Authorized_User_Id__c, Authorized_User_First_Name__c, Authorized_User_Last_Name__c,
                User_Account_Number__c, User_TIG_Acct_Num__c, User_Uverse_Account_Number__c, User_DTV_Account_Number__c, User_Telephone_Number__c,
                User_Order_Num__c, User_Action_Object__c,
                ANI__c, Formatted_Phone__c, Masked_Ban__c, Passcode_Authentication_Failed__c, Cpni_Consent__c,
                Authenticated_Email_Address__c, Authenticated_Phone_Number__c,
                Customer__r.Is_Digital_Customer__c, Customer__r.Individual_ID__c
            FROM
                Interaction__c
            WHERE
                Id = :interactionId
        ];

        if (interactions.isEmpty()) {
            throw new BWC_Exception('Interaction not found: ' + interactionId);
        }

        return interactions[0];

    }

    /*
        Throw exception if the billing account is not associated with the interaction
    */
    public static void verifyInteractionBillingAccount(Id interactionId, Id billingAccountId) {

        Interaction__c interaction = getInteraction(interactionId);
        List<Billing_Account__c> billingAccounts = BWC_BillingAccount.getBillingAccounts(interaction);
        for (Billing_Account__c billingAccount : billingAccounts) {
            if (billingAccount.Id == billingAccountId) {
                // Valid
                return;
            }
        }

        // Not valid
        throw new BWC_Exception('Specified Billing Account is not associated with the specified Interaction.' + interactionId + ' ' + billingAccountId);

    }

    /*
        Throw exception if the BAN is not associated with the interaction
    */
    public static void verifyInteractionBan(Id interactionId, String ban) {

        Interaction__c interaction = getInteraction(interactionId);
        List<Billing_Account__c> billingAccounts = BWC_BillingAccount.getBillingAccounts(interaction);
        for (Billing_Account__c billingAccount : billingAccounts) {
            if (billingAccount.Billing_Account_Number__c == ban) {
                // Valid
                return;
            }
        }

        // Not valid
        throw new BWC_Exception('Specified BAN is not associated with the specified Interaction.' + interactionId + ' ' + ban);

    }

    /*
        Deserialize authorization JSON for the interaction.
    */
    public static BWC_AuthorizationCallout.AuthorizationStatusContent getAuthorizationContent(Interaction__c interaction) {

        if (String.isNotEmpty(interaction.Authorization_Json__c)) {
            return (BWC_AuthorizationCallout.AuthorizationStatusContent)JSON.deserialize(interaction.Authorization_Json__c, BWC_AuthorizationCallout.AuthorizationStatusContent.class);
        }
        else {
            return new BWC_AuthorizationCallout.AuthorizationStatusContent();
        }
        
    }

}