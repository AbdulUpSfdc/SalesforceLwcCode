public with sharing class BWC_AuthenticationService {

    public static final String CALLING_SYSTEM_ID = 'Salesforce';
    public static final String IDENTIFICATION_TYPE = 'CTNAUTH';
    public static final String IDENTIFICATION_TYPE_EMAIL = 'EMAILPIN';
    public static final String INTERACTION_ACTIVITY_ACTION = 'Inquiry | Authentication';

    /*************************************************************************
     generatePin
    **************************************************************************/

    public class GeneratePinService extends BWC_InteractionServiceBase {

        public BWC_AuthenticationCallout.DeliveryMethods deliveryMethods;
        public BWC_AuthenticationCallout.GeneratePinRequest request;
        public BWC_AuthenticationCallout.GeneratePinResponse response;

        public GeneratePinService(Id interactionId, Id billingAccountId, BWC_AuthenticationCallout.DeliveryMethods deliveryMethods) {

            super(interactionId, billingAccountId);

            this.deliveryMethods = deliveryMethods;
            this.buildRequest();

        }

        public void buildRequest() {

            if (deliveryMethods?.sms?.smsPhoneNumber == null && deliveryMethods?.email?.emailAddress == null) {
                throw new BWC_Exception('deliveryMethods.sms.smsPhoneNumber or deliveryMethods.email.emailAddress are required.');
            }

            Boolean deliveryMethodIsSms = true;
            if (deliveryMethods?.email?.emailAddress != null) {
                deliveryMethodIsSms = false;
            }

            // Validate allowed delivery method
            String identificationType = '';
            if (deliveryMethodIsSms) {
                String otpPhoneNumber = this.authorizationContent.getValidOtpPhoneNumber(billingAccountId, deliveryMethods.sms.smsPhoneNumber);
                if (otpPhoneNumber == null) {
                    throw new BWC_Exception('Phone number is not a valid OTP phone number.', BWC_Authentication.INVALID_OTP_PHONE);
                }
                deliveryMethods.sms.smsPhoneNumber = otpPhoneNumber;
                identificationType = IDENTIFICATION_TYPE;
            } else {
                String otpEmail = this.authorizationContent.getValidOtpEmailAddress(billingAccountId, deliveryMethods.email.emailAddress);
                if (otpEmail == null) {
                    throw new BWC_Exception('Email is not a valid OTP email address.', BWC_Authentication.INVALID_OTP_EMAIL);
                }
                deliveryMethods.email.emailAddress = otpEmail;
                identificationType = IDENTIFICATION_TYPE_EMAIL;
            }

            // Build request
            this.request = new BWC_AuthenticationCallout.GeneratePinRequest();
            this.request.accountId = this.billingAccount.Billing_Account_Number__c;
            this.request.callingSystemId = CALLING_SYSTEM_ID;
            this.request.identificationType = identificationType;
            this.request.agentId = BWC_Utils.getCurrentUserAttId();
            this.request.deliveryMethods = deliveryMethods;
            if (FeatureManagement.checkPermission('BWC_Debug')) {
                this.request.returnSecurityCode = 'Y';
            }

            this.callout = new BWC_AuthenticationCallout.GeneratePinCallout(this.request);

        }

        protected override Object buildResponse() {

            this.response = (BWC_AuthenticationCallout.GeneratePinResponse)this.callout.getResponse();
            return this.response;

        }

    }

    /*************************************************************************
     validatePin
    **************************************************************************/

    public class ValidatePinService extends BWC_InteractionServiceBase {

        public String securityCode;
        public String identificationType;
        public String otpContactMethod;
        public BWC_AuthenticationCallout.ValidatePinRequest request;
        public BWC_AuthenticationCallout.ValidatePinResponse response;

        public ValidatePinService(Id interactionId, Id billingAccountId, String securityCode, String identificationType, String otpContactMethod) {

            super(interactionId, billingAccountId);

            this.securityCode = securityCode;
            this.identificationType = identificationType;
            this.otpContactMethod = otpContactMethod;
            this.buildRequest();

        }

        public void buildRequest() {

            // Build request
            this.request = new BWC_AuthenticationCallout.ValidatePinRequest();
            this.request.callingSystemId = CALLING_SYSTEM_ID;
            if (identificationType == 'sms') {
                this.request.identificationType = IDENTIFICATION_TYPE;
            } else {
                this.request.identificationType = IDENTIFICATION_TYPE_EMAIL;
            }
            this.request.agentId = BWC_Utils.getCurrentUserAttId();
            this.request.ivrSessionId = this.interaction.CTI_Call_Identifier__c;
            this.request.commonConversationId = this.interaction.Id + '-' + this.billingAccount.Billing_Account_Number__c;
            this.request.accountType = this.billingAccount.Account_Type__c;
            this.request.accountId = this.billingAccount.Billing_Account_Number__c;
            this.request.securityCode = securityCode;
            this.request.deletePINOnSuccess = 'ALL';

            this.callout = new BWC_AuthenticationCallout.ValidatePinCallout(this.request);

        }

        protected override Object buildResponse() {

            this.response = (BWC_AuthenticationCallout.ValidatePinResponse)this.callout.getResponse();

            String contactValue = '';
            if(identificationType == 'sms'){
                contactValue = this.authorizationContent.getValidOtpPhoneNumber(this.billingAccountId, otpContactMethod);
            }else{
                contactValue = this.authorizationContent.getValidOtpEmailAddress(this.billingAccountId, otpContactMethod);
            }

            if (this.response.appStatusMsg == 'SUCCESS') {

                // Validation was successful, update authentication method on the interaction. TODO add contact value
                updateManualAuthentication(this.interactionId, this.billingAccountId, BWC_Authentication.AUTHENTICATION_METHOD_OTP, identificationType, contactValue);

            }

            AuthInteractionActivity details = new AuthInteractionActivity();
            details.recordId = this.interactionId;
            details.authenticationType = BWC_Authentication.AUTHENTICATION_METHOD_OTP;
            details.contactMethod = identificationType == 'sms' ? 'SMS' : 'EMAIL';
            details.contactValue = contactValue;
            details.status = this.response.appStatusMsg == 'SUCCESS' ? 'success' : 'failed';

            // Log interaction activity
            createInteractionActivity(this.interactionId, INTERACTION_ACTIVITY_ACTION, JSON.serialize(details, true), this.billingAccountId);

            return this.response;
            
        }

    }

    /*************************************************************************
     validateCredentials
    **************************************************************************/

    public class ValidateCredentialsService extends BWC_InteractionServiceBase {

        public BWC_AuthenticationCallout.AccountCredentials accountCredentials;
        public BWC_AuthenticationCallout.ValidateCredentialsRequest request;
        public BWC_AuthenticationCallout.ValidateCredentialsResponse response;

        public ValidateCredentialsService(Id interactionId, Id billingAccountId, BWC_AuthenticationCallout.AccountCredentials accountCredentials) {

            super(interactionId, billingAccountId);
            this.accountCredentials = accountCredentials;
            this.buildRequest();

        }

        public void buildRequest() {

            if (accountCredentials == null) {
                throw new BWC_Exception('accountCredentials is required.');
            }

            // Build request
            this.request = new BWC_AuthenticationCallout.ValidateCredentialsRequest();
            this.request.callingSystemId = CALLING_SYSTEM_ID;
            this.request.identificationType = IDENTIFICATION_TYPE;
            this.request.agentId = BWC_Utils.getCurrentUserAttId();
            this.request.ivrSessionId = this.interaction.CTI_Call_Identifier__c;
            this.request.commonConversationId = this.interaction.Id + '-' + this.billingAccount.Billing_Account_Number__c;
            this.request.accountType = this.billingAccount.Account_Type__c;
            this.request.accountInvariantId = this.billingAccount.Billing_Account_Number__c;
            this.request.accountCredentials = this.accountCredentials;

            this.callout = new BWC_AuthenticationCallout.ValidateCredentialsCallout(this.request);

        }

        protected override Object buildResponse() {

            this.response = (BWC_AuthenticationCallout.ValidateCredentialsResponse)this.callout.getResponse();

            if (this.response.appStatusMsg == 'SUCCESS') {

                // Validation was successful, update authentication method on the interaction
                updateManualAuthentication(this.interactionId, this.billingAccountId, BWC_Authentication.AUTHENTICATION_METHOD_PASSCODE);

                // passcode authentication succeeded, update the interaction Passcode Authentication Failed field to false only if it was true
                updatePasscodeAuthenticationFailed(this.interactionId, false);

            } else {

                // passcode authentication failed, update the interaction Passcode Authentication Failed field to true only if it was false
                updatePasscodeAuthenticationFailed(this.interactionId, true);
            }

            AuthInteractionActivity details = new AuthInteractionActivity();
            details.recordId = this.interactionId;
            details.authenticationType = BWC_Authentication.AUTHENTICATION_METHOD_PASSCODE;
            details.status = this.response.appStatusMsg == 'SUCCESS' ? 'success' : 'failed';

            // Log interaction activity
            createInteractionActivity(this.interactionId, INTERACTION_ACTIVITY_ACTION, JSON.serialize(details, true), this.billingAccountId);

            return this.response;

        }

    }

    private static void updateManualAuthentication(Id interactionId, Id billingAccountId, String authenticationMethod) {
        updateManualAuthentication(interactionId, billingAccountId, authenticationMethod, null, null);
    }

    /*
        Update the Manual_Authentication_Json__c field containing the manual authentication method used for the specified billing account.
    */
    private static void updateManualAuthentication(Id interactionId, Id billingAccountId, String authenticationMethod, String identificationType, String otpContactMethod) {

        // Validation was successful, update authentication method on the interaction
        Interaction__c interaction = [SELECT Id, Is_Authorized__c, Manual_Authentication_Json__c, Manual_Authentication_Method__c FROM Interaction__c WHERE Id = :interactionId];

        if (billingAccountId != null) {
            Map<Id, String> authenticationMap = new Map<Id, String>();
            if (String.isNotEmpty(interaction.Manual_Authentication_Json__c)) {
                authenticationMap = (Map<Id, String>)JSON.deserialize(interaction.Manual_Authentication_Json__c, Map<Id, String>.class);
            }
            authenticationMap.put(billingAccountId, authenticationMethod);
            interaction.Manual_Authentication_Json__c = JSON.serialize(authenticationMap, true);
        }

        if (interaction.Is_Authorized__c != true) {
            // This is first authentication
            interaction.Manual_Authentication_Method__c = authenticationMethod;
        }

        if(identificationType == BWC_Authentication.SMS_IDENTIFICATION_TYPE){
            interaction.Authenticated_Phone_Number__c = otpContactMethod;
        } else if(identificationType == BWC_Authentication.EMAIL_IDENTIFICATION_TYPE){
            interaction.Authenticated_Email_Address__c = otpContactMethod;
        }

        update interaction;

    }

    /*************************************************************************
     Bypass
    **************************************************************************/

    /*
        Set the interaction authentication to Bypass -- only for specific billing account if specified
    */
    public static void bypassAuthentication(Id interactionId, Id billingAccountId) {

        // Re-check for privilege
        if (FeatureManagement.checkPermission(BWC_Authorization.PERM_BYPASS_INTERACTION_AUTHORIZATION) ||
            FeatureManagement.checkPermission(BWC_Authentication.PERM_BYPASS_CUSTOMER_AUTHENTICATION)) {

            // Verify billingAccountId is associated with the interaction
            BWC_Interaction.verifyInteractionBillingAccount(interactionId, billingAccountId);

            // Do the bypass update
            updateManualAuthentication(interactionId, billingAccountId, BWC_Authentication.AUTHENTICATION_METHOD_BYPASS);
    
            AuthInteractionActivity details = new AuthInteractionActivity();
            details.recordId = interactionId;
            details.status = 'bypassed';

            // Log interaction activity
            createInteractionActivity(interactionId, INTERACTION_ACTIVITY_ACTION, JSON.serialize(details, true), billingAccountId);

        }
        else {

            throw new BWC_Exception('User does not have permission to bypass.');

        }

    }

    /*************************************************************************
     Passcode Authentication Failed
    **************************************************************************/

    /*
        Set the interaction Passcode Authentication Failed to TRUE when passcode authentication failed and they authenticate using an alternate method
    */
    public static void updatePasscodeAuthenticationFailed(Id interactionId, Boolean failed) {

        // Validation was successful, update authentication method on the interaction
        Interaction__c interaction = [SELECT Id, Passcode_Authentication_Failed__c FROM Interaction__c WHERE Id = :interactionId];

        if (interaction.Passcode_Authentication_Failed__c != failed) {
            // This is first authentication
            interaction.Passcode_Authentication_Failed__c = failed;
            update interaction;
        }

    }

    public static void createInteractionActivity(Id interactionId, String action, String detailRecord, Id billingAccountId){

        Interaction_Activity__c interactionActivity = new Interaction_Activity__c(
            Interaction__c = interactionId,
            Billing_Account__c = billingAccountId,
            Type__c = 'Inquiry',
            Action__c = action,
            Detail_Record__c = detailRecord
        );

        insert interactionActivity;

    }

    public class AuthInteractionActivity{
        public String recordId;
        public String authenticationType;
        public String contactMethod;
        public String contactValue;
        public String status;
    }

}