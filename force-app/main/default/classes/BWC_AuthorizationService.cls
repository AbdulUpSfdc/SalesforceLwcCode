public with sharing class BWC_AuthorizationService {

    /**************************************************************************
      checkAuthorizationStatus
    **************************************************************************/

    /*
        Service has it's own response because it's not just passing through the API callout response.
    */
    public class CheckAuthorizationStatusResponse extends BWC_Service.ServiceResponse {
        public Boolean isAuthorized;                                         // The call resulted in successful authorization for the interaction and specified BAN
        public List<BWC_AuthorizationCallout.AssociatedAccount> updatedAccounts;    // List of all associated accounts whose authorization status changed due to the re-check
    }

    /*
        Service class for checkAuthorizationStatus.
    */
    public class CheckAuthorizationStatusService extends BWC_InteractionServiceBase {

        // Request state
        public BWC_AuthorizationCallout.AuthorizationStatusRequest request;
        public Boolean isFirstAuthorization;
        public Boolean isAlreadyAuthorized;
        public String authenticationMethod;
        public Boolean isFullBypass;                // All auth is being bypassed during first authorization
        public Boolean isBanBypass;                 // One billing account is being bypassed after first authorization
        public Boolean isInvalidAccountType;

        // Response state
        BWC_AuthorizationCallout.AuthorizationStatusResponse response;

        public CheckAuthorizationStatusService(Id interactionId, Id billingAccountId) {

            super(interactionId, billingAccountId);

            // Build request
            this.buildRequest();

        }

        public void buildRequest() {

            if (String.isEmpty(this.billingAccount.Account_Type__c)) {
                throw new BWC_Exception('No Account_Type__c set on Billing Account.');
            }
            if (String.isEmpty(this.billingAccount.Billing_Account_Number__c)) {
                throw new BWC_Exception('No Billing_Account_Number__c set on Billing Account.');
            }

            this.isFirstAuthorization = this.interaction.Is_Authorized__c != true;
            this.isAlreadyAuthorized = 
                this.interaction.Is_Authorized__c == true &&
                this.billingAccountId == this.interaction.Billing_Account__c &&
                this.authenticationMethod == this.interaction.Authentication_Method_Used__c;

            if (this.isAlreadyAuthorized) {
                return;
            }

            if (this.isFirstAuthorization &&
                FeatureManagement.checkPermission(BWC_Authorization.PERM_BYPASS_INTERACTION_AUTHORIZATION) ||
                ((FeatureManagement.checkPermission(BWC_Authentication.PERM_BYPASS_CUSTOMER_AUTHENTICATION) || Test.isRunningTest()) && 
                  this.interaction.Manual_Authentication_Method__c == BWC_Authentication.AUTHENTICATION_METHOD_BYPASS)) {

                // Caller has special permissions and/or has bypassed manually based on permission
                this.isFullBypass = true;

            }
            else {

                if (this.isFirstAuthorization == true) {

                    this.authenticationMethod = this.interaction.Authentication_Method_Used__c;

                    if (!BWC_Authorization.VALID_ACCOUNT_TYPES.contains(this.billingAccount.Account_Type__c)) {

                        // We will be choosing different billing account so current authentication does not apply
                        this.authenticationMethod = BWC_Authentication.AUTHENTICATION_METHOD_NONE;

                        // Default is not a valid account type for the authorization status API, see if we can call for some other ban on the same account which does have a valid type
                        for (Billing_Account__c billingAccount : this.billingAccounts) {
                            if (BWC_Authorization.VALID_ACCOUNT_TYPES.contains(billingAccount.Account_Type__c)) {
                                // Found one
                                this.billingAccount = billingAccount;
                                break;
                            }
                        }

                    }

                }
                else {

                    // Get authentication method from JSON field
                    if (String.isNotEmpty(this.interaction.Manual_Authentication_Json__c)) {
                        Map<Id, String> authenticationMap = (Map<Id, String>)JSON.deserialize(interaction.Manual_Authentication_Json__c, Map<Id, String>.class);
                        this.authenticationMethod = authenticationMap.get(this.billingAccountId);
                    }
                    if (this.authenticationMethod == null) {
                        this.authenticationMethod = BWC_Authentication.AUTHENTICATION_METHOD_NONE;
                    }

                }

                if (this.authenticationMethod == BWC_Authentication.AUTHENTICATION_METHOD_BYPASS) {
                    // It's bypass for one BAN, we don't need to call to authorization service
                    this.isBanBypass = true;
                    return;
                }

                this.isInvalidAccountType = !BWC_Authorization.VALID_ACCOUNT_TYPES.contains(this.billingAccount.Account_Type__c);

                if (this.isInvalidAccountType != true) {

                    // Check for required values
                    if (String.isEmpty(this.interaction.CTI_Call_Identifier__c)) {
                        throw new BWC_Exception('No CTI_Call_Identifier__c set on Interaction.');
                    }
                    if (String.isEmpty(this.interaction.Authentication_Method_Used__c)) {
                        throw new BWC_Exception('No Authentication_Method_Used__c set on Interaction.');
                    }

                    // Can attempt the API call

                    // Build base request
                    this.request = new BWC_AuthorizationCallout.AuthorizationStatusRequest();
                    this.request.authenticatedIdType = this.billingAccount.Account_Type__c.toLowerCase();
                    this.request.authenticatedId = this.billingAccount.Billing_Account_Number__c;
                    this.request.unifiedBan = this.billingAccount.Wireless_BAN__c;
                    this.request.clientId = BWC_Constants.AUTHORIZATION_CLIENT_ID;
                    this.request.ivrSessionId = this.interaction.CTI_Call_Identifier__c;
                    this.request.aniTelephoneNumber = this.interaction.ANI__c;
                    this.request.authenticationMethod = this.authenticationMethod;
                    this.request.commonConversationId = this.interaction.Id + '-' + this.request.authenticatedId;

                    if(String.isNotBlank(this.interaction.Customer__r?.Individual_ID__c)){
                        this.request.individualId = this.interaction.Customer__r.Individual_ID__c;
                        this.request.authenticatedEmailAddress = this.interaction.Authenticated_Email_Address__c;
                        this.request.authenticatedPhoneNumber = this.interaction.Authenticated_Phone_Number__c;
                    }

                    this.callout = new BWC_AuthorizationCallout.GetAuthorizationStatusCallout(this.request);

                }

            }

        }

        public override Object buildResponse() {

            CheckAuthorizationStatusResponse checkStatusResponse = new CheckAuthorizationStatusResponse();
            checkStatusResponse.updatedAccounts = new List<BWC_AuthorizationCallout.AssociatedAccount>();

            if (this.isAlreadyAuthorized) {
                checkStatusResponse.isAuthorized = true;
                return checkStatusResponse;
            }
            else if (this.isFullBypass == true) {

                // Set Bypass for all billing accounts
                this.authorizationContent.associatedAccounts = new List<BWC_AuthorizationCallout.AssociatedAccount>();
                for (Billing_Account__c billingAccount : this.billingAccounts) {
                    BWC_AuthorizationCallout.AssociatedAccount associatedAccount = new BWC_AuthorizationCallout.AssociatedAccount();
                    associatedAccount.billingAccountId = billingAccount.Id;
                    associatedAccount.accountBan = billingAccount.Billing_Account_Number__c;
                    associatedAccount.accountType = billingAccount.Account_Type__c.toUpperCase();
                    associatedAccount.authorizationLevel = BWC_Constants.AUTHORIZATION_LEVEL_BYPASS;
                    associatedAccount.authenticationMethod = BWC_Constants.AUTHENTICATION_METHOD_BYPASS;
                    this.authorizationContent.associatedAccounts.add(associatedAccount);

                    checkStatusResponse.updatedAccounts.add(associatedAccount);
                }

                this.interaction.Is_Authorized__c = true;
                this.interaction.Wireless_Authorization_Level__c = BWC_Authentication.AUTHENTICATION_METHOD_BYPASS;

            }
            else if (this.isBanBypass == true) {

                // Set Bypass for one billing account
                BWC_AuthorizationCallout.AssociatedAccount associatedAccount = this.authorizationContent.getAssociatedAccount(this.billingAccountId);
                associatedAccount.authorizationLevel = BWC_Constants.AUTHORIZATION_LEVEL_BYPASS;
                associatedAccount.authenticationMethod = BWC_Constants.AUTHENTICATION_METHOD_BYPASS;
                checkStatusResponse.updatedAccounts.add(associatedAccount);

            }
            else if (this.isInvalidAccountType != true) {

                // Process callout response
                this.response = (BWC_AuthorizationCallout.AuthorizationStatusResponse)this.callout.getResponse();
                BWC_AuthorizationCallout.AuthorizationStatusContent newAuthorizationContent = this.response.content;
                this.maskBans(newAuthorizationContent);

                // Merge new into existing content
                checkStatusResponse.updatedAccounts = this.authorizationContent.mergeFrom(newAuthorizationContent, this.authenticationMethod);

            }

            // Default empty array
            if (this.authorizationContent.associatedAccounts == null) {
                this.authorizationContent.associatedAccounts = new List<BWC_AuthorizationCallout.AssociatedAccount>();
            }

            for (Billing_Account__c billingAccount : this.billingAccounts) {

                BWC_AuthorizationCallout.AssociatedAccount associatedAccount = this.authorizationContent.getAssociatedAccount(this.billingAccount.Id);

                if (!BWC_Authorization.VALID_ACCOUNT_TYPES.contains(billingAccount.Account_Type__c) && associatedAccount == null) {

                    // Add L1 for non-valid account type, since there's no way to step them up
                    associatedAccount = new BWC_AuthorizationCallout.AssociatedAccount();
                    associatedAccount.accountBan = billingAccount.Billing_Account_Number__c;
                    associatedAccount.accountType = billingAccount.Account_Type__c;
                    associatedAccount.authorizationLevel = BWC_Authorization.AUTHORIZATION_LEVEL_L1;
                    associatedAccount.billingAccountId = billingAccount.Id;
                    this.authorizationContent.associatedAccounts.add(associatedAccount);
    
                }
                else if (associatedAccount != null) {
                    // Record authentication method
                    associatedAccount.authenticationMethod = this.authenticationMethod;
                }

            }

            //
            // Authorization content is now up-to-date for all billing accounts, finish up
            //

            if (this.isFirstAuthorization) {

                // Did we get authorized?
                if (this.authorizationContent.getAssociatedAccount(this.billingAccount.Id) != null) {

                    this.interaction.Is_Authorized__c = true;

                    // Determine Wireless_Authorization_Level__c
                    if (this.isFullBypass == true) {

                        this.interaction.Wireless_Authorization_Level__c = BWC_Authorization.AUTHORIZATION_LEVEL_BYPASS;

                    }
                    else {

                        // Default to L0
                        this.interaction.Wireless_Authorization_Level__c = BWC_Authorization.AUTHORIZATION_LEVEL_L0;
                        // Use first found
                        if (this.authorizationContent.associatedAccounts != null) {
                            for (BWC_AuthorizationCallout.AssociatedAccount associatedAccount : this.authorizationContent.associatedAccounts) {
                                if (associatedAccount.accountType == BWC_Constants.ACCOUNT_TYPE_WIRELESS) {
                                    this.interaction.Wireless_Authorization_Level__c = associatedAccount.authorizationLevel;
                                    break;
                                }
                            }
                        }

                    }

                }

            }

            if (this.isFirstAuthorization && this.interaction.Is_Authorized__c == true) {

                // Insert interaction activity
                Map<String, Object> detailFields = new Map<String, Object>();
                detailFields.put('Id', this.interaction.Id);
                detailFields.put('Authorization_Json__c', this.interaction.Authorization_Json__c);
                detailFields.put('Is_Authorized__c', this.interaction.Is_Authorized__c);
                detailFields.put('Wireless_Authorization_Level__c', this.interaction.Wireless_Authorization_Level__c);

                Interaction_Activity__c interactionActivity = new Interaction_Activity__c(
                    Interaction__c = this.interaction.Id,
                    Customer__c = this.interaction.Customer__c,
                    Billing_Account__c = this.interaction.Billing_Account__c,
                    Type__c = 'Inquiry',
                    Action__c = this.isFullBypass == true ? 'Authentication Bypassed' : 'Authentication',
                    Detail_Record__c = JSON.serialize(detailFields, true)
                );

                insert interactionActivity;

            }

            // Update the interaction record with the results
            if (this.isFirstAuthorization == true) {
                // Initial authorization -- set the billing account used to authorize
                interaction.Billing_Account__c = this.billingAccount.Id;
            }
            interaction.Authorization_Json__C = JSON.serializePretty(this.authorizationContent, true);
            update interaction;

            checkStatusResponse.isAuthorized = this.interaction.Is_Authorized__c;
            return checkStatusResponse;
 
        }

        /*
            Mask outbound bans and set corresponding billing account record IDs.
        */
        private void maskBans(BWC_AuthorizationCallout.AuthorizationStatusContent authorizationContent) {

            if (authorizationContent.associatedAccounts != null) {
                for (BWC_AuthorizationCallout.AssociatedAccount associatedAccount : authorizationContent.associatedAccounts) {
                    associatedAccount.billingAccountId = this.getBillingAccountIdForBan(associatedAccount.accountBan);
                    associatedAccount.accountBan = this.getMaskedBan(associatedAccount.accountBan);
                }
            }

            if (authorizationContent.recommendedStepUps != null) {
                for (BWC_AuthorizationCallout.RecommendedStepUp recommendedStepUp : authorizationContent.recommendedStepUps) {
                    recommendedStepUp.billingAccountId = this.getBillingAccountIdForBan(recommendedStepUp.accountBan);
                    recommendedStepUp.accountBan = this.getMaskedBan(recommendedStepUp.accountBan);
                }
            }

        }

    }

    /**************************************************************************
      isAuthenticatedWithOtp
    **************************************************************************/

    /*
        Tell whether specified billingAccountId is authenticated using OTP on the interaction.
    */    
    public static Boolean isAuthenticatedWithOtp(Id interactionId, Id billingAccountId) {

        Interaction__c interaction = BWC_Interaction.getInteraction(interactionId);

        // Verify billingAccountId is associated with the interaction
        BWC_Interaction.verifyInteractionBillingAccount(interactionId, billingAccountId);

        // Deserialize authorizations
        if (String.isNotEmpty(interaction.Authorization_Json__c)) {

            BWC_AuthorizationCallout.AuthorizationStatusContent authorizationContent = 
                (BWC_AuthorizationCallout.AuthorizationStatusContent)JSON.deserialize(interaction.Authorization_Json__c, BWC_AuthorizationCallout.AuthorizationStatusContent.class);

            // Map authorizations by ban
            if (authorizationContent.associatedAccounts != null) {
                for (BWC_AuthorizationCallout.AssociatedAccount associatedAccount : authorizationContent.associatedAccounts) {
                    if (associatedAccount.billingAccountId == billingAccountId &&
                        (associatedAccount.authorizationLevel == BWC_Authorization.AUTHORIZATION_LEVEL_BYPASS ||
                         associatedAccount.authenticationMethod == BWC_Authentication.AUTHENTICATION_METHOD_BYPASS ||
                         (associatedAccount.authorizationLevel == BWC_Authorization.AUTHORIZATION_LEVEL_L1 &&
                          associatedAccount.authenticationMethod == BWC_Authentication.AUTHENTICATION_METHOD_OTP))) {

                        // BAN is OTP authenticated
                        return true;

                    }

                }
            }

        }

        // BAN is not OTP authenticated
        return false;

    }

    /**************************************************************************
      setNoAuthentication
    **************************************************************************/

    /*
        Set indicator that agent used legacy system and authentication did not complete.
    */
    public static void setNoAuthentication(Id interactionId) {

        Interaction__c interaction = BWC_Interaction.getInteraction(interactionId);

        // Insert interaction activity
        Map<String, Object> detailFields = new Map<String, Object>();
        detailFields.put('Id', interaction.Id);
        detailFields.put('Authorization_Json__c', interaction.Authorization_Json__c);
        detailFields.put('Is_Authorized__c', interaction.Is_Authorized__c);
        detailFields.put('Wireless_Authorization_Level__c', interaction.Wireless_Authorization_Level__c);

        Interaction_Activity__c interactionActivity = new Interaction_Activity__c(
            Interaction__c = interaction.Id,
            Customer__c = interaction.Customer__c,
            Billing_Account__c = interaction.Billing_Account__c,
            Type__c = 'Inquiry',
            Action__c = 'No Authentication',
            Detail_Record__c = JSON.serialize(detailFields, true)
        );

        insert interactionActivity;

    }

    /**************************************************************************
      getFullAuthorizationStatus
    **************************************************************************/

    /*
        Returns a full bypass response for use on auto-interaction creation for cases.
    */
    public static BWC_AuthorizationCallout.AuthorizationStatusResponse getFullAuthorizationStatus(Id interactionId) {

        BWC_AuthorizationCallout.AuthorizationStatusResponse response = new BWC_AuthorizationCallout.AuthorizationStatusResponse();
        response.content = new BWC_AuthorizationCallout.AuthorizationStatusContent();
        response.content.associatedAccounts = new List<BWC_AuthorizationCallout.AssociatedAccount>();

        Interaction__c interaction = BWC_Interaction.getInteraction(interactionId);
        List<Billing_Account__c> billingAccounts = BWC_BillingAccount.getBillingAccounts(interaction);

        // Set Bypass for all billing accounts
        for (Billing_Account__c billingAccount : billingAccounts) {
            BWC_AuthorizationCallout.AssociatedAccount associatedAccount = new BWC_AuthorizationCallout.AssociatedAccount();
            associatedAccount.accountBan = billingAccount.Billing_Account_Number__c;
            associatedAccount.accountType = billingAccount.Account_Type__c.toUpperCase();
            associatedAccount.authorizationLevel = BWC_Constants.AUTHORIZATION_LEVEL_BYPASS;
            associatedAccount.authenticationMethod = BWC_Constants.AUTHENTICATION_METHOD_BYPASS;
            response.content.associatedAccounts.add(associatedAccount);
        }
        
        return response;

    }

}