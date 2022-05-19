import { LightningElement, track, api } from 'lwc';
import { createRecord } from 'lightning/uiRecordApi';
import * as BwcConstants from 'c/bwcConstants';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcAccountServices from 'c/bwcAccountServices';
import * as BwcInteractionServices from 'c/bwcInteractionServices';
import * as BwcCaseServices from 'c/bwcCaseServices';
import * as BwcPaymentRedactionServices from 'c/bwcPaymentRedactionServices';

// Labels
import label_smsConsent from '@salesforce/label/c.BWC_PaymentSecureLinkSmsConsent';
import label_workFromHomeRequiresSecure from '@salesforce/label/c.BWC_WorkFromHomeRequiresSecure';
import label_secureLinkSent from '@salesforce/label/c.BWC_PaymentSecureLinkSent';
import label_secureEntryComplete from '@salesforce/label/c.BWC_PaymentSecureEntryComplete';

// Object and fields
import INTERACTION_ACTIVITY_OBJECT from '@salesforce/schema/Interaction_Activity__c';
import INTERACTION_FIELD from '@salesforce/schema/Interaction_Activity__c.Interaction__c';
import TYPE_FIELD from '@salesforce/schema/Interaction_Activity__c.Type__c';
import ACTION_FIELD from '@salesforce/schema/Interaction_Activity__c.Action__c';
import CUSTOMER_FIELD from '@salesforce/schema/Interaction_Activity__c.Customer__c';
import BILLING_ACCOUNT_FIELD from '@salesforce/schema/Interaction_Activity__c.Billing_Account__c';

const LANGUAGE_OPTIONS = [{value: 'en-US', label: 'English'}, {value: 'es-MX', label: 'Spanish'}];
const SEND_METHODS = {sms: {value: 'sms', label: 'SMS'}, email: {value: 'email', label: 'Email'}};
const LINK_EXPIRATION_MINUTES = 5;

export default class TempSecurePaymentAgent extends LightningElement {

    label = {
        smsConsent: label_smsConsent
    };

    // If parent is Interaction
    @api interactionId;
    _ban;
    @api get ban() {return this.ban;}
    set ban(value) {
        this._ban = value;
        this.isInitialized = false;
        this.initialize();
    }

    // If parent is Case
    @api caseId;                // Uses Billing_Account__c lookup

    @api paymentProfileName;    // For CVV-only

    get parentRecordId() {return this.caseId ? this.caseId : this.interactionActivityRecord.id;}

    // Controls what is shown to the customer for payment types, etc.
    @api capabilities;

    // The temporary payment profile
    _paymentProfile;
    @api get paymentProfile() {return this._paymentProfile;}
    set paymentProfile(value) {
        // Caller is setting existing profile
        this._paymentProfile = value;
        this.initialize();
    }

    //#region Initialization and common
    isInitialized;
    isBusy;
    get errorReport() {return this.template.querySelector('c-bwc-error-report');}
    @track messageBarMessage;
    
    interactionRecord;
    billingAccountRecord;
    customerAccountRecord;
    interactionActivityRecord;
    caseRecord;
    @track phoneNumberOptions = [];
    selectedPhoneNumber;
    get useOtherPhoneNumber() {return this.selectedPhoneNumber === 'other';}
    otherPhoneNumber;

    @track emailAddressOptions = [];
    selectedEmailAddress;
    get useOtherEmailAddress() {return this.selectedEmailAddress === 'other';}
    otherEmailAddress;

    get isCvvOnly() {return this.capabilities && this.capabilities.includes('CREDCARD_CVV_ONLY');}

    renderedCallback() {

        // Init on first render if not already initialized
        if (!this.isInitialized && ((this.interactionId  && this._ban) || this.caseId)) {
            this.initialize();
        }

    }

    @api async initialize() {

        this.isInitialized = true;

        try {

            this.isBusy = true;
            const phoneNumberOptions = [];
            const emailAddressOptions = [];

            if (this.interactionId) {

                // Get customer account
                this.customerAccountRecord = await BwcAccountServices.getCustomerAccount(this.interactionId);

                // Get interaction record
                this.interactionRecord = await BwcInteractionServices.getInteraction(this.interactionId);

                // Check if customer is not BSSe to get related billing account
                if (!this.customerAccountRecord.Is_Digital_Customer__c) {
                    // Get billing account record
                    this.billingAccountRecord = await BwcAccountServices.getBillingAccountForBan(this._ban);
                }

            }
            else if (this.caseId) {

                // Get case record
                this.caseRecord  = await BwcCaseServices.getCaseById(this.caseId);

                // Get billing account record
                this.billingAccountRecord = this.caseRecord.Billing_Account__r;

            }

            if (this.billingAccountRecord) {

                // Set phone options
                if (this.billingAccountRecord.Contact_Number__c) {
                    phoneNumberOptions.push({
                        label: `${BwcUtils.formatPhone(this.billingAccountRecord.Contact_Number__c)} - Primary`,
                        value: this.billingAccountRecord.Contact_Number__c
                    });
                }
                if (this.billingAccountRecord.Alternate_Phone_Number__c) {
                    phoneNumberOptions.push({
                        label: BwcUtils.formatPhone(this.billingAccountRecord.Alternate_Phone_Number__c),
                        value: this.billingAccountRecord.Alternate_Phone_Number__c
                    });
                }

                // Set email options
                if (this.billingAccountRecord.Email__c) {
                    emailAddressOptions.push({
                        label: `${this.billingAccountRecord.Email__c} - Primary`,
                        value: this.billingAccountRecord.Email__c
                    });
                }

            }

            // If it's interaction and is BSSe Customer, fill values from PersonAccount
            if (this.interactionId && this.customerAccountRecord.Is_Digital_Customer__c) {

                // Set phone options
                if (this.customerAccountRecord.Phone) {
                    phoneNumberOptions.push({
                        label: `${BwcUtils.formatPhone(this.customerAccountRecord.Phone)} - Primary`,
                        value: this.customerAccountRecord.Phone
                    });
                }
                if (this.customerAccountRecord.PersonMobilePhone) {
                    phoneNumberOptions.push({
                        label: BwcUtils.formatPhone(this.customerAccountRecord.PersonMobilePhone),
                        value: this.customerAccountRecord.PersonMobilePhone
                    });
                }

                // Set email options
                if (this.customerAccountRecord.PersonEmail) {
                    emailAddressOptions.push({
                        label: `${this.customerAccountRecord.PersonEmail} - Primary`,
                        value: this.customerAccountRecord.PersonEmail
                    });
                }

            }

            phoneNumberOptions.push({label: 'Other', value: 'other'});
            this.selectedPhoneNumber = phoneNumberOptions[0].value;
            emailAddressOptions.push({label: 'Other', value: 'other'});
            this.selectedEmailAddress = emailAddressOptions[0].value;

            this.phoneNumberOptions = phoneNumberOptions;
            this.emailAddressOptions = emailAddressOptions;

            if (this._paymentProfile && this._paymentProfile.profileOwnerId) {
                // Process has already been completed
                this.setPhase('completed');
            }
            else {
                // Start processes
                this.setPhase('sendSecureLink');
                this.selectedSendMethod = SEND_METHODS.sms.value;
            }

        }
        catch (error) {
            this.errorReport.reportError(error);
        }
        finally {
            this.isBusy = false;
        }

    }

    /*
        Caller uses to tell if process is complete.
    */
    @api reportValidity() {
        if (this.checkValidity()) {
            return true;
        }
        this.errorReport.reportError(new Error('Secure payment process is not complete.'));
        return false;
    }

    /*
        Caller uses to tell if process is complete.
    */
    @api checkValidity() {
        if (this._paymentProfile && this.paymentProfile.profileOwnerId) {
            return true;
        }
        return false;
    }

    /*
        Display error to user.
    */
    reportError(error) {

        // If there's no error message, then the error is due to field validation failures, which are already shown on the page.
        // So if there's no message, do nothing.
        if (error.message || error.body) {

            this.errorReport.reportError(error, false);

        }

    }

    reportUnexpectedError(error) {
        this.reportError(error);
    }

    /*
        Insert the Interaction_Activity__c for this redaction.
    */
    async createInteractionActivity() {

        if (!this.interactionActivityRecord) {

            // Create the interaction activity
            const recordInput = {
                apiName: INTERACTION_ACTIVITY_OBJECT.objectApiName,
                fields: {
                    [INTERACTION_FIELD.fieldApiName]: this.interactionRecord.Id,
                    [CUSTOMER_FIELD.fieldApiName]: this.interactionRecord.Customer__c,
                    [BILLING_ACCOUNT_FIELD.fieldApiName]: this.billingAccountRecord ? this.billingAccountRecord.Id : undefined,
                    [TYPE_FIELD.fieldApiName]: 'Billing | Payment',
                    [ACTION_FIELD.fieldApiName]: 'Redaction'
                }
            }

            BwcUtils.log('Creating Interaction Activity: ' + JSON.stringify(recordInput));
            this.interactionActivityRecord = await createRecord(recordInput);
            BwcUtils.log('Created Interaction Activity: ' + JSON.stringify(this.interactionActivityRecord));

        }

    }

    /*
        Common input handling.
    */
    handleInputCommit(event) {

        this.errorReport.clearError();

        switch(event.target.name) {

            case 'phoneNumbers':
                this.selectedPhoneNumber = event.target.value;
                break;

            case 'otherPhoneNumber':
                BwcUtils.validatePhone(event.target);
                this.otherPhoneNumber = event.target.value;
                break;

            case 'emailAddresses':
                this.selectedEmailAddress = event.target.value;
                break;

            case 'otherEmailAddress':
                this.otherEmailAddress = event.target.value;
                break;

            case 'customerToken':
                event.target.setCustomValidity('');
                this.customerToken = event.target.value;
                break;

            default:
                break;

        }

        event.target.reportValidity();

    }

    //#endregion

    //#region Phase

    // Phase
    currentPhase;
    get isPhaseSendSecureLink() {return this.currentPhase === 'sendSecureLink';}
    get isPhaseConfirmToken() {return this.currentPhase === 'confirmToken';}
    get isPhaseWaitForPaymentInfo() {return this.currentPhase === 'waitForPaymentInfo';}
    get isPhaseCompleted() {return this.currentPhase === 'completed';}

    setPhase(phase) {

        this.errorReport.clearError();
        this.currentPhase = phase;
        switch (this.currentPhase) {

            case 'sendSecureLink':
                this.messageBarMessage = {
                    variant: 'info',
                    text: label_workFromHomeRequiresSecure
                }
                break;

            case 'confirmToken':
                this.messageBarMessage = {
                    variant: 'success-light',
                    text: label_secureLinkSent.replace('{0}', SEND_METHODS[this.selectedSendMethod].label).replace('{1}', LINK_EXPIRATION_MINUTES)
                }
                break;

            case 'waitForPaymentInfo':
                this.messageBarMessage = {
                    variant: 'success-light',
                    text: label_secureLinkSent.replace('{0}', SEND_METHODS[this.selectedSendMethod].label).replace('{1}', LINK_EXPIRATION_MINUTES)
                }
                break;

            case 'completed':
                this.messageBarMessage = {
                    variant: 'success-blue',
                    text: label_secureEntryComplete
                };
                break;

            default:
                break;

        }

    }

    //#endregion Phase

    //#region sendSecureLink

    selectedSendMethod;
    get isSendMethodSms() {return this.selectedSendMethod === 'sms';}
    get isDisabledSms() {return !this.isSendMethodSms;}
    get isSendMethodEmail() {return this.selectedSendMethod === 'email';}
    get isDisabledEmail() {return !this.isSendMethodEmail;}
    languageOptions = LANGUAGE_OPTIONS;
    selectedLanguageOption = this.languageOptions[0].value;
    get phoneNumber() {return this.useOtherPhoneNumber ? this.otherPhoneNumber : this.selectedPhoneNumber;}
    get emailAddress() {return this.useOtherEmailAddress ? this.otherEmailAddress : this.selectedEmailAddress;}

    /*
        Radio switch between SMS and Email.
    */
    async handleSendTypeChange(event) {

        this.errorReport.clearError();

        this.selectedSendMethod = event.target.value;

        // Allow disable to take effect
        await BwcUtils.nextTick();

        // Clear any failed validity on now disabled controls
        BwcUtils.resetDisabledValidity(this.template);

    }

    /*
        Radio switch between languages.
    */
    handleLanguageOptionChange(event) {

        this.errorReport.clearError();
        this.selectedLanguageOption = event.target.value;

    }

    /*
        Sends the token to the customer via email or phone.
    */
    async handleSendSecureLink() {

        // SMS
        const smsAgreementCheckbox = this.template.querySelector('lightning-input[data-name="smsAgreement"');
        smsAgreementCheckbox.setCustomValidity('');
        if (this.isSendMethodSms && !smsAgreementCheckbox.checked) {
            smsAgreementCheckbox.setCustomValidity('Agreement is required.');
        }

        // Standard validation
        let isValid = BwcUtils.reportValidity(this.template);

        if (isValid) {

            try {

                this.isBusy = true;

                if (this.interactionId) {
                    // Will create if needed
                    await this.createInteractionActivity();
                }

                // Send
                await this.sendLink();

                // Success
                this.setPhase('confirmToken');

            }
            catch(error) {
                this.reportUnexpectedError(error);
            }
            finally {
                this.isBusy = false;
            }

        }

    }

    /*
        Sends the secure link to the customer via email or phone.
    */    
    async sendLink() {

        if (!this.isCvvOnly) {

            if (this.isSendMethodSms) {
                await BwcPaymentRedactionServices.startSMSSecureXchange(this.parentRecordId, BwcUtils.parsePhoneToDigits(this.phoneNumber), this.selectedLanguageOption, this.capabilities);
            }
            else if (this.isSendMethodEmail) {
                await BwcPaymentRedactionServices.startEmailSecureXchange(this.parentRecordId, this.emailAddress, this.selectedLanguageOption, this.capabilities);
            }
            else {
                throw new Error('Send method not determined.')
            }

        }
        else {

            const request = {
                sobjId: this.parentRecordId,
                capabilities: this.capabilities,
                language: this.selectedLanguageOption,
                auxNvp: {
                    PAYMENT_METHOD: this.paymentProfileName
                }
            };

            if (this.isSendMethodSms) {
                request.targetAddress = BwcUtils.parsePhoneToDigits(this.phoneNumber);
                await BwcPaymentRedactionServices.startSMSSecureXchangeAux(request);
            }
            else if (this.isSendMethodEmail) {
                request.targetAddress = this.emailAddress;
                await BwcPaymentRedactionServices.startEmailSecureXchangeAux(request);
            }
            else {
                throw new Error('Send method not determined.')
            }

        }

    }

    //#endregion sendSecureLink

    //#region confirmToken

    // The token as entered by the agent
    customerToken;

    /*
        Confirm the token and send the link to the customer.
    */
    async handleConfirmCustomer() {

        // Standard validation
        let isValid = BwcUtils.reportValidity(this.template);

        if (isValid) {

            try {

                this.isBusy = true;

                let isTokenValid = await this.verifyOtp();

                if (!isTokenValid) {
                    const customerTokenInput = this.template.querySelector('lightning-input[data-name="customerToken"]');
                    customerTokenInput.setCustomValidity('Token is not valid.');
                    customerTokenInput.reportValidity();
                }
                else {
                    this.setPhase('waitForPaymentInfo');    
                }

            }
            catch(error) {
                this.reportUnexpectedError(error);
            }
            finally {
                this.isBusy = false;
            }

        }

    }

    /*
        Sends the token to the customer via email or phone.
    */    
    async verifyOtp() {

        const isValid = await BwcPaymentRedactionServices.verifyOTP(this.parentRecordId, this.customerToken, BwcUtils.parsePhoneToDigits(this.phoneNumber), this.selectedLanguageOption);
        return isValid;

    }

    async handleResendLink() {

        try {

            this.isBusy = true;

            await this.sendLink();

            // Go back to token entry
            this.setPhase('confirmToken');

        }
        catch(error) {
            this.reportUnexpectedError(error);
        }
        finally {
            this.isBusy = false;
        }

    }

    //#endregion confirmToken

    //#region waitForPaymentInfo

    async handleRefreshForPaymentDetails() {

        try {

            this.isBusy = true;
            this._paymentProfile = await BwcPaymentRedactionServices.paymentInfoEntered(this.parentRecordId);

            if (this._paymentProfile && (!this.isCvvOnly || this._paymentProfile.card?.verified)) {

                // We got a profile
                this.setPhase('completed');
                this.dispatchEvent(new CustomEvent('completed', {detail: {paymentProfile: this._paymentProfile, cvvOnly: this.isCvvOnly}}));

            }

        }
        catch(error) {
            this.reportError(error);
        }
        finally {
            this.isBusy = false;
        }

    }

    //#endregion waitForPaymentInfo

    //#region completed

    /*
        Card type used for logo display
    */
    get displayCardType() {

        if (this._paymentProfile && this._paymentProfile.card) {
            return this._paymentProfile.card.cardType;
        }
        return undefined;

    }

    /*
        Card / bank number last 4
    */
    get displayPaymentInfo() {

        if (!this._paymentProfile) {
            return undefined;
        }

        if (this._paymentProfile.card) {
            const last4 = this._paymentProfile.card.cardNumber.substring(this._paymentProfile.card.cardNumber.length - 4);
            return `${BwcConstants.CardType.getLabel(this._paymentProfile.card.cardType)} ending in <b>${last4}</b>`;
        }
        else if (this._paymentProfile.bankAccount) {
            const last4 = this._paymentProfile.bankAccount.bankAccountNumber.substring(this._paymentProfile.bankAccount.bankAccountNumber.length - 4);
            return `${BwcConstants.BankAccountType.getLabel(this._paymentProfile.bankAccount.accountType)} ending in <b>${last4}</b>`;
        }

        return undefined;

    }

    get displayExpiration() {

        if (this._paymentProfile && this._paymentProfile.card) {
            return `Expires <b>${this._paymentProfile.card.expireMonth}/${this._paymentProfile.card.expireYear}</b>`;
        }
        return undefined;

    }

    //#endregion completed

}