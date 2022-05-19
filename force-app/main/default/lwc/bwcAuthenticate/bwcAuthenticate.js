import { api, track } from 'lwc';
import BwcPageElementBase from 'c/bwcPageElementBase';
import * as BwcConstants from 'c/bwcConstants';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcBillingAccount from 'c/bwcBillingAccount';
import * as BwcAccountServices from 'c/bwcAccountServices';
import * as BwcInteractionServices from 'c/bwcInteractionServices';
import * as BwcAuthenticationServices from 'c/bwcAuthenticationServices';
import * as BwcLabelServices from 'c/bwcLabelServices';

// Permissions
import hasBypassCustomerAuthenticationPermission from '@salesforce/customPermission/Bypass_Customer_Authentication';

//Import custom Label
import authErrorMessage from '@salesforce/label/c.BWC_Auth_Error';                        //An unexpected error occurred. Try authenticating the customer again or
import unexpectedErrorMessage from '@salesforce/label/c.BWC_Unexpected_Error';            //An unexpected error occurred.
import authenticateErrorMessage from '@salesforce/label/c.Authenticate_in_legacy_system'; //Authenticate in your legacy system.
import passcodeFailedErrorMessage from '@salesforce/label/c.BWC_Passcode_Fail'            //Passcode validation failed: {0}
import pinFailedErrorMessage from '@salesforce/label/c.BWC_Pin_Validation_Failed';        //Pin validation failed: {0}

/*
    Provides initial or step up authentication for the calling user.
*/
export default class BwcAuthenticate extends BwcPageElementBase {

    // Labels
    labels = BwcLabelServices.labels;

    @api isModal;

    isBusy;

    interaction;
    interactionId;
    interactionRecordTypeDeveloperName;
    billingAccounts;                            // All billing accounts for the interaction
    @track billingAccountOptions = [];          // Options for combo box
    selectedBillingAccountId;                   // Currently selected BAN
    selectedBillingAccount;                     // Corresponding billing account for the selected ban
    @track recommendedStepUps;                  // ALL recommended step ups for all bans
    @track selectedBanRecommendedStepUps;       // Step ups for selected ban
    authenticationMethodOptions = [];
    selectedAuthenticationMethod;
    disableBanSelection;
    defaultAuthenticationMethod;

    get isSelectedBanPrepaid() {return this.selectedBillingAccount && this.selectedBillingAccount.Prepaid_Customer__c;}
    get isSelectedBanInvalid() {return this.selectedBillingAccount && this.isSelectedBanPrepaid;}
    get isInbound() {return this.interaction && this.interaction.RecordType.DeveloperName === 'Inbound';}
    get showBypassButton() {return hasBypassCustomerAuthenticationPermission && !this.isInbound && !this.isSelectedBanInvalid;}
    get disableAuthenticationMethodSelection() {return this.isSelectedBanPrepaid || this.defaultAuthenticationMethod;}
    get contentPanelClass() {return this.isModal ? 'content-panel-modal' : 'content-panel';}

    /*
        Container must call this to initialize.
    */
    @api async initialize(interactionId, billingAccountId, disableBanSelection, defaultAuthenticationMethod) {

        this.isBusy = true;

        try {

            this.interactionId = interactionId;
            this.selectedBillingAccountId = billingAccountId;
            this.disableBanSelection = disableBanSelection;
            this.defaultAuthenticationMethod = defaultAuthenticationMethod;
            this.selectedAuthenticationMethod = this.defaultAuthenticationMethod;

            // Get interaction
            this.interaction = await BwcInteractionServices.getInteraction(this.interactionId);

            // Get recommendedStepUps from the interaction record
            const authData = JSON.parse(this.interaction.Authorization_Json__c);
            this.recommendedStepUps = authData && authData.recommendedStepUps ? authData.recommendedStepUps : [];

            // Get all billing accounts
            this.billingAccounts = await BwcAccountServices.getBillingAccounts(this.interactionId, undefined, undefined, undefined, undefined, true);

            // Build options
            this.billingAccountOptions = this.billingAccounts.map(billingAccount => {
                return {
                    label: BwcBillingAccount.BillingAccount.fromRecord(billingAccount).serviceLabel,
                    value: billingAccount.Id,
                    accountType: billingAccount.Account_Type__c,
                    recordId: billingAccount.Id
                };
            });

            // Default to first billing account
            if (!this.selectedBillingAccountId && this.billingAccountOptions.length > 0) {
                this.selectedBillingAccountId = this.billingAccountOptions[0].value;
            }

            // Initialize for selected billing account
            this.handleBillingAccountSelected();

        }
        catch(error) {
            super.handleError(error);
        }
        finally {
            this.isBusy = false;
        }

    }

    get showNoAuthenticationMethods() {

        if (!this.selectedBillingAccountId) {
            // No ban selected yet
            return false;
        }

        if (this.isSelectedBanInvalid) {
            // Invalid anyway
            return false;
        }

        if (!this.selectedBanRecommendedStepUps || this.selectedBanRecommendedStepUps.length === 0) {
            // No step ups provided
            return true;
        }
        if (this.selectedBanRecommendedStepUps.length === 1 && 
            this.selectedBanRecommendedStepUps[0].stepUpType === BwcConstants.AuthenticationMethod.OTP.value &&
            ((!this.selectedBanRecommendedStepUps[0].otpPhoneNumber || this.selectedBanRecommendedStepUps[0].otpPhoneNumber.length === 0)
            || (!this.selectedBanRecommendedStepUps[0].otpEmail || this.selectedBanRecommendedStepUps[0].otpEmail.length === 0))) {

            // Only OTP provided and no otp numbers or otp emails
            return true;

        }
        return false;

    }

    get isNoAuthenticationMethods() {
        if (!this.selectedBanRecommendedStepUps || this.selectedBanRecommendedStepUps.length === 0) {
            // No step ups provided
            return true;
        }
        if (this.selectedBanRecommendedStepUps.length === 1 && 
            this.selectedBanRecommendedStepUps[0].stepUpType === BwcConstants.AuthenticationMethod.OTP.value &&
            ((!this.selectedBanRecommendedStepUps[0].otpPhoneNumber || this.selectedBanRecommendedStepUps[0].otpPhoneNumber.length === 0)
            || (!this.selectedBanRecommendedStepUps[0].otpEmail || this.selectedBanRecommendedStepUps[0].otpEmail.length === 0))) {

            // Only OTP provided and no otp numbers or otp emails
            return true;

        }
        return false;
    }
    get showAuthenticationMethods() {return this.selectedBillingAccountId && !this.showNoAuthenticationMethods && !this.isSelectedBanInvalid;}
    get isAuthenticationMethodPasscode() {return this.selectedAuthenticationMethod === BwcConstants.AuthenticationMethod.PASSCODE.value;}
    get isAuthenticationMethodOtp() {return this.selectedAuthenticationMethod === BwcConstants.AuthenticationMethod.OTP.value;}

    /*
        BAN has been selected.
    */
    async handleBillingAccountSelected(event) {

        if (event) {
            this.selectedBillingAccountId = event.target.value;
        }

        // Clear values from authentication method options combobox
        this.authenticationMethodOptions = [];

        // Get corresponding billing account record
        this.selectedBillingAccount = this.billingAccounts.find(billingAccount => billingAccount.Id === this.selectedBillingAccountId);

        // Get authentication options for the selected ban
        this.selectedBanRecommendedStepUps = this.recommendedStepUps.filter(stepUp => stepUp.billingAccountId === this.selectedBillingAccountId);
        this.selectedBanRecommendedStepUps.forEach(stepUp => {
            // Current supported authentication methods: Passcode and OTP
            if (stepUp.stepUpType === BwcConstants.AuthenticationMethod.PASSCODE.value || stepUp.stepUpType === BwcConstants.AuthenticationMethod.OTP.value) {
                this.authenticationMethodOptions.push({value: stepUp.stepUpType, label: BwcConstants.AuthenticationMethod.getLabel(stepUp.stepUpType)});
            }
        });
    
        // Default auth method if not already set and if there is only 1 available
        if (!this.selectedAuthenticationMethod) {
            this.selectedAuthenticationMethod = this.authenticationMethodOptions.length === 1 ? this.authenticationMethodOptions[0].value : undefined;
        }
        this.resetAuthenticationMethod();

    }

    /*
        Reset everything for the new method.
    */
    resetAuthenticationMethod() {
        this.clearNotifications();
        this.passcodeEntered = undefined;
        this.otpContactMethod = undefined;
        this.isOtpSent = false;
        this.otpPinEntered = undefined;
        this.calculateConfirmDisabled();
    }

    // Show legacy authenticate button
    get showLicButton() {
        return (this.isNoAuthenticationMethods || this.hasErrorNotifications) && !this.isSelectedBanInvalid;
    }

    // Tells container whether confirm is possible or not.
    isDisabledConfirm = true;    
    calculateConfirmDisabled() {

        this.isDisabledConfirm = !((this.isAuthenticationMethodPasscode && this.passcodeEntered) || (this.isAuthenticationMethodOtp && this.isOtpSent && this.otpPinEntered));
        
        // Tell modal that value might have changed
        this.dispatchEvent(new CustomEvent('confirmdisabled', {detail: {disabled: this.isDisabledConfirm}}));

    }

    // Passcode
    passcodeEntered;
    otpContactMethod;

    // OTP
    isOtpSent;
    otpPinEntered;
    get isDisabledSendOtp() {return !(this.isAuthenticationMethodOtp && this.otpContactMethod);}
    get isDisabledOtpEntry() {return !(this.isAuthenticationMethodOtp && this.isOtpSent);}
    identificationTypeMap = {};
    get otpContactMethodOptions() {

        if (this.recommendedStepUps) {
            const otpStepUp = this.recommendedStepUps.find(stepUp => stepUp.stepUpType === BwcConstants.AuthenticationMethod.OTP.value && stepUp.billingAccountId === this.selectedBillingAccountId);
            if (otpStepUp) {
                let phoneContactOptions = [];
                if (otpStepUp.otpHashedPhoneNumber) {
                    phoneContactOptions = otpStepUp.otpHashedPhoneNumber.map(phoneNumber => {
                        this.identificationTypeMap[phoneNumber.value] = 'sms';
                        return { label: phoneNumber.label, value: phoneNumber.value };
                     })
                }
                let emailContactOptions = [];
                if (otpStepUp.otpHashedEmail) {
                    emailContactOptions = otpStepUp.otpHashedEmail.map(hashedEmail => {
                        this.identificationTypeMap[hashedEmail.value] = 'email';
                        return { label: hashedEmail.label, value: hashedEmail.value };
                    })
                }
                return phoneContactOptions.concat(emailContactOptions);
            }
        }
        return [];

    }

    /*
        Authentication type combo box.
    */
    handleAuthenticationMethodChange(event) {

        this.selectedAuthenticationMethod = event.detail.value;
        this.resetAuthenticationMethod();

    }

    /*
        Entered passcode has changed.
    */    
    handlePasscodeChange(event) {
        this.passcodeEntered = event.target.value;
        this.calculateConfirmDisabled();
    }

    /*
        Selected OTP phone number changed.
    */
    handleOtpContactMethodChange(event) {

        // Reset for new number
        this.otpContactMethod = event.detail.value;
        this.isOtpSent = false;
        this.otpPinEntered = undefined;
        this.calculateConfirmDisabled();

    }

    /*
        Send OTP button.
    */
    async handleSendOtp() {

        this.otpPinEntered = undefined;

        try {

            super.clearNotifications();
            this.isBusy = true;

            let deliveryMethods = {};

            let identificationType = this.identificationTypeMap[this.otpContactMethod];

            if (identificationType === 'sms') {
                deliveryMethods = {"sms": {"smsPhoneNumber": this.otpContactMethod}};
            } else {
                deliveryMethods = {"email": {"emailAddress": this.otpContactMethod}};
            }
            const response = await BwcAuthenticationServices.generatePin(this.interactionId, this.selectedBillingAccountId, deliveryMethods);

            if (response.appStatusMsg === 'SUCCESS') {
                this.isOtpSent = true;
            }
            else {
                super.addScopedNotification('Failed to generate PIN', 'error');
            }

        }
        catch(error) {
            super.handleError(error, unexpectedErrorMessage);
        }
        finally {
            this.isBusy = false;
        }

        this.calculateConfirmDisabled();

    }

    /*
        Entered pin has changed.
    */
    handleOtpEntryChange(event) {
        this.otpPinEntered = event.target.value;
        this.calculateConfirmDisabled();
    }

    /*
        Confirm button clicked.
    */
    @api async handleConfirm() {

        try {

            super.clearNotifications();
            this.isBusy = true;

            if (this.isAuthenticationMethodPasscode) {

                // Validate passcode
                const accountCredentials = {"passcode": this.passcodeEntered};
                const response = await BwcAuthenticationServices.validateCredentials(this.interactionId, this.selectedBillingAccountId, accountCredentials);

                if (response.appStatusMsg !== 'SUCCESS') {
                    const message = response.appInfo ? response.appInfo : unexpectedErrorMessage;
                    throw BwcUtils.errorWithDetails(passcodeFailedErrorMessage.replace("{0}", message), JSON.stringify(response));
                }

            }
            else if (this.isAuthenticationMethodOtp) {

                // Validate pin
                const response = await BwcAuthenticationServices.validatePin(
                    this.interactionId,
                    this.selectedBillingAccountId,
                    this.otpPinEntered,
                    this.identificationTypeMap[this.otpContactMethod],
                    this.otpContactMethod
                );

                if (response.appStatusMsg !== 'SUCCESS') {
                    const message = response.appInfo ? response.appInfo : unexpectedErrorMessage;
                    throw BwcUtils.errorWithDetails(pinFailedErrorMessage.replace("{0}", message), JSON.stringify(response));
                } 

            }
            else {
                throw new Error('Unexpected authentication method: ' + this.selectedAuthenticationMethod);
            }

            // Fire authenticated event 
            this.dispatchEvent(new CustomEvent('authenticated', 
                {
                    detail: {
                        billingAccountId: this.selectedBillingAccountId,
                        authenticationMethod: this.selectedAuthenticationMethod
                    }
                }));

        }
        catch(error) {
            // if is step up authentication, only display simple error message
            const isErrorWithDetails = Object.prototype.hasOwnProperty.call(error,'details');
            const unexpectedError = unexpectedErrorMessage;
            const authError = authErrorMessage;

            if (this.isModal) {
                super.handleError(error, isErrorWithDetails ? null : unexpectedError);
            } 
            // if is initial authentication, display custom message with link to authenticate in legacy system
            else {
                let action = {
                    name: 'legacyAuth',
                    message: authenticateErrorMessage,
                    icon: {
                        name: 'utility:new_window'
                    }
                }
                super.handleError(error, isErrorWithDetails ? null : authError, 'Authentication', null, action);
            }
        }
        finally {
            this.isBusy = false;
        }

    }

    handleActionClick(event) {
        this.handleLic();
    }

    /*
        Launch OPUS button.
    */
   handleLic() {

        // Fire lic event 
        this.dispatchEvent(new CustomEvent('lic', 
            {
                detail: {
                    ban: this.selectedBillingAccount.Billing_Account_Number__c, // Replace when BAN masking is introduced
                    accountType: this.accountType,
                }
            }));

    }

    /*
        Agent clicked Bypass button.
    */
    async handleBypass() {

        try {

            super.clearNotifications();
            this.isBusy = true;

            await BwcAuthenticationServices.bypassAuthentication(this.interactionId, this.selectedBillingAccountId);

            // Fire authenticated event 
            this.dispatchEvent(new CustomEvent('authenticated', 
                {
                    detail: {
                        billingAccountId: this.selectedBillingAccountId,
                        authenticationMethod: this.selectedAuthenticationMethod
                    }
                }));

        }
        catch(error) {
            super.handleError(error);
        }
        finally {
            this.isBusy = false;
        }

    }

}