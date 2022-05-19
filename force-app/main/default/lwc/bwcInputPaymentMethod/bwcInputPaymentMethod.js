import { LightningElement, api, track, wire } from 'lwc';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcPayments from 'c/bwcPayments';
import * as BwcPaymentServices from 'c/bwcPaymentServices';
import * as RAISR_MSG_CH from "c/bwcRaisrMsgPubSubCmp";

//Lightning Message Service
import { subscribe, MessageContext, APPLICATION_SCOPE} from 'lightning/messageService';
import RAISRMC from '@salesforce/messageChannel/BWC_Raisr__c';

// Labels
import label_mailText from '@salesforce/label/c.BWC_PaymentMailText';
import label_agencyText from '@salesforce/label/c.BWC_PaymentAgencyText';
import label_otherText from '@salesforce/label/c.BWC_PaymentOtherText';
import label_paymentMethodTypeNotAllowed from '@salesforce/label/c.BWC_PaymentMethodTypeNotAllowed'

// Custom permissions
import hasEnterCustomerPaymentDetailsPermission from '@salesforce/customPermission/Enter_Customer_Payment_Details';
import hasVoiceRedactionPermission from '@salesforce/customPermission/VoiceRedaction';

const PROMISE_TEXT_MAP = {
    [BwcPayments.PromiseToPayMethod.MAIL.value]: label_mailText,
    [BwcPayments.PromiseToPayMethod.AGENCY.value]: label_agencyText,
    [BwcPayments.PromiseToPayMethod.OTHER.value]: label_otherText
};

export default class BwcInputPaymentMethod extends LightningElement {

    /********************************************************************************************************/
    // Public interface

    @api interactionId;
    @api ban;
    @api context = 'test';

    // Set when editing pending payment: current paymentMethod is shown as a radio option and details are not shown and cannot be edited
    // User can still select a stored profile or enter a new method, but they cannot see/edit details of the existing method
    @api disallowEdit;

    // Payment type options passed in, otherwise defaults to Bank Account and Card
    @track _paymentTypeMethodOptions = [
        BwcPayments.PaymentMethodType.BANKACCOUNT,
        BwcPayments.PaymentMethodType.CARD
    ];
    @api get paymentMethodTypeOptions() {
        return this._paymentTypeMethodOptions;
    }

    // Promise-to-Pay methods -- mail, agency, other
    @track _promiseToPayMethodOptions = [];
    @api get promiseToPayMethodOptions() {
        return this._promiseToPayMethodOptions;
    }

    // Client can set any existing stored profiles to allow user to select
    @api get storedProfiles() {return this._storedProfiles;}

    // Use to retrieve the resulting payment method (if component is valid), or to set existing one
    @api get paymentMethod() {return this.getPaymentMethod();}

    // Use to retrieve the resulting spi data from smart-fields
    @api get spiDataValues() {return this.getSpiData();}

    // Stores all component state, client can use it to easily reload everything in a context such as wizard
    @api get state() {
        return {
            bankProfileOptions: BwcUtils.cloneObject(this.bankProfileOptions),
            cardProfileOptions: BwcUtils.cloneObject(this.cardProfileOptions),
            paymentMethodTypeOptions: BwcUtils.cloneObject(this._paymentTypeMethodOptions),
            promiseToPayMethodOptions: BwcUtils.cloneObject(this._promiseToPayMethodOptions),
            selectedPaymentMethodType: BwcUtils.cloneObject(this.selectedPaymentMethodType),
            isNewBankAccount: this.isNewBankAccount,
            isNewCard: this.isNewCard,
            selectedBankProfileIndex: this.selectedBankProfileIndex,
            selectedCardProfileIndex: this.selectedCardProfileIndex,
            newBankAccount: this.newBankAccount,
            newCard: this.newCard,
            promiseToPay: this.promiseToPay,
            temporaryProfile: this.temporaryProfile,
            profileSecurityCodes: this.profileSecurityCodes,
            profileSecurityCodesRaisr: this.profileSecurityCodesRaisr,
            paymentMethodTypeNotAllowedMessage: this.paymentMethodTypeNotAllowedMessage
        }
    }
    set state(value) {
        this.bankProfileOptions = value.bankProfileOptions;
        this.cardProfileOptions = value.cardProfileOptions;
        this._paymentTypeMethodOptions = value.paymentMethodTypeOptions;
        this._promiseToPayMethodOptions = value.promiseToPayMethodOptions;
        this.selectedPaymentMethodType = 
            value.selectedPaymentMethodType
                ? value.selectedPaymentMethodType
                : (this.paymentMethodTypeOptions && this.paymentMethodTypeOptions.length > 0 ? this.paymentMethodTypeOptions[0].value : undefined);
        this.isNewBankAccount = !!value.isNewBankAccount;
        this.isNewCard = !!value.isNewCard;
        this.selectedBankProfileIndex = value.selectedBankProfileIndex;
        this.selectedCardProfileIndex = value.selectedCardProfileIndex;
        this.newBankAccount = value.newBankAccount ? BwcUtils.cloneObject(value.newBankAccount) : {};
        this.newCard = value.newCard ? BwcUtils.cloneObject(value.newCard) : {};
        this.promiseToPay = value.promiseToPay ? BwcUtils.cloneObject(value.promiseToPay) : {};
        this.temporaryProfile = BwcUtils.cloneObject(value.temporaryProfile);
        this.profileSecurityCodes = value.profileSecurityCodes ? BwcUtils.cloneObject(value.profileSecurityCodes) : [];
        this.profileSecurityCodesRaisr = value.profileSecurityCodesRaisr ? BwcUtils.cloneObject(value.profileSecurityCodesRaisr) : [];
        this.paymentMethodTypeNotAllowedMessage = value.paymentMethodTypeNotAllowedMessage;
    
        if (!this.newCard.billingAddress) {
            this.newCard.billingAddress = {};
        }

        BwcUtils.nextTick().then(() => {this.setSelectedPaymentMethod();});

    }

    // Causes all validity to be checked.
    @api checkValidity() {

        // Redaction?
        const securePaymentAgent = this.template.querySelector('c-bwc-secure-payment-agent:not(.slds-hide)');
        if (securePaymentAgent) {
            return securePaymentAgent.checkValidity();
        }

        const isValid = BwcUtils.checkValidity(this.template, `c-bwc-input-card-number, c-bwc-input-bank-account-number, 
                                                                c-bwc-notification, c-bwc-raisr-tokenized-field-cmp, 
                                                                c-bwc-raisr-clear-text-field-cmp`);
        const isCustomValid = this.customValidate();
        return isValid && isCustomValid;

    }

    // Causes all validity to be checked and any errors displayed.
    @api reportValidity() {

        this.customValidate();

        // Redaction?
        const securePaymentAgent = this.template.querySelector('c-bwc-secure-payment-agent:not(.slds-hide)');
        if (securePaymentAgent) {
            return securePaymentAgent.reportValidity();
        }
        return BwcUtils.reportValidity(this.template, `c-bwc-input-card-number, c-bwc-input-bank-account-number, 
                                                        c-bwc-notification, c-bwc-raisr-tokenized-field-cmp:not(.slds-hide), 
                                                        c-bwc-raisr-clear-text-field-cmp`);

    }

    /********************************************************************************************************/
    // Private members

    // State
    selectedPaymentMethodType;
    isNewBankAccount;
    isNewCard;
    selectedBankProfileIndex;
    selectedCardProfileIndex;
    @track newBankAccount = {};
    @track newCard = {billingAddress: {}};
    @track promiseToPay = {};
    @track profileSecurityCodes = [];
    @track profileSecurityCodesRaisr = [{}];
    paymentMethodTypeNotAllowedMessage;

    // Stored profiles
    @track _storedProfiles;
    @track bankProfileOptions = [];
    @track cardProfileOptions = [];
    @track temporaryProfile;

    // Input status 
    isBSSeCustomer;
    mode;
    get editInputDisabled() { return this.mode === BwcPaymentServices.PostPaymentProfileMode.UPDATE && this.isBSSeCustomer === true }

    // Raisr
    useVoice = false;
    get showVoiceRedactionButton() {return hasVoiceRedactionPermission;}
    get contextSecurityCode() {return this.context + ' CVV';}

    /********************************************************************************************************/
    // Computed properties
    get useRedaction() {return !hasEnterCustomerPaymentDetailsPermission;}
    get isCard() {return this.selectedPaymentMethodType === BwcPayments.PaymentMethodType.CARD.value;}
    get isBankAccount() {return this.selectedPaymentMethodType === BwcPayments.PaymentMethodType.BANKACCOUNT.value;}
    get isPromiseToPay() {return this.selectedPaymentMethodType === BwcPayments.PaymentMethodType.PROMISE_TO_PAY.value;}
    get isUseNew() {return !this._storedProfiles || (this.isBankAccount ? this.isNewBankAccount : (this.isCard ? this.isNewCard : this.isPromiseToPay));}
    get cardTypeOptions() {return BwcPayments.CardTypeOptions;}
    get bankAccountTypeOptions() {return BwcPayments.BankAccountTypeOptions;}
    get selectedPaymentTypeText() {return PROMISE_TEXT_MAP[this.promiseToPay.method];}
    get selectedPaymentTypeTextDisableLinkify() {return this.promiseToPay.method === BwcPayments.PromiseToPayMethod.OTHER.value;}
    get cardExpirationDate() {
        return this.newCard.expireMonth && this.newCard.expireYear
            ?  `${this.newCard.expireMonth}/${this.newCard.expireYear}`
            : '';
    }
    get showStoredProfiles() {return !!this._storedProfiles && this.selectedPaymentMethodType !== BwcPayments.PaymentMethodType.PROMISE_TO_PAY.value;}
    get selectedProfileOptions() {return this.isBankAccount ? this.bankProfileOptions : this.cardProfileOptions;}
    get showVoiceRecognition() {return this.useVoice && this.isUseNew;}
    get showRedaction() {return this.isUseNew && (this.useRedaction && !this.isPromiseToPay) && !this.useVoice;}
    get showEntryDetails() {return this.isUseNew && (!this.useRedaction || this.isPromiseToPay) && !this.useVoice;}
    get useNewLabel() {return this.selectedPaymentMethodType ? BwcPayments.PaymentMethodType[this.selectedPaymentMethodType].addLabel : undefined;}
    get profileSecurityCode() {return this.profileSecurityCodes[this.selectedCardProfileIndex];}
    get raisrProfileSecurityCode() {
        return this.selectedCardProfileIndex !== -1 && this.profileSecurityCodesRaisr[this.selectedCardProfileIndex] && this.profileSecurityCodesRaisr[this.selectedCardProfileIndex].profileSecurityCode 
        ? this.profileSecurityCodesRaisr[this.selectedCardProfileIndex].profileSecurityCode 
        : '';
    }
    get raisrProfileSecurityCodeToken() {
        return this.selectedCardProfileIndex !== -1 && this.profileSecurityCodesRaisr[this.selectedCardProfileIndex] && this.profileSecurityCodesRaisr[this.selectedCardProfileIndex].profileSecurityCodeToken
        ? this.profileSecurityCodesRaisr[this.selectedCardProfileIndex].profileSecurityCodeToken 
        : '';
    }
    get raisrProfileSecurityCodeVisibleValue() {
        return this.selectedCardProfileIndex !== -1 && this.profileSecurityCodesRaisr[this.selectedCardProfileIndex] && this.profileSecurityCodesRaisr[this.selectedCardProfileIndex].profileSecurityCodeVisibleValue 
        ? this.profileSecurityCodesRaisr[this.selectedCardProfileIndex].profileSecurityCodeVisibleValue 
        : '';
    }
    get capabilities() {return [];}

    // Tells Secure Payment Agent which payment types should be allowed
    get secureAgentCapabilities() {
        const capabilities = [];
        if (this._paymentTypeMethodOptions.find(option => option.value === BwcPayments.PaymentMethodType.BANKACCOUNT.value)) {
            capabilities.push('BANK_NO_CHECK_NUM');
        }
        if (this._paymentTypeMethodOptions.find(option => option.value === BwcPayments.PaymentMethodType.CARD.value)) {
            capabilities.push('CREDCARD');
        }
        return capabilities;
    }

    get cvvOnlyCapabilities() {return ['CREDCARD_CVV_ONLY'];}

    /********************************************************************************************************/
    // Message Channel
    @wire(MessageContext)
    messageContext;

    isRendered;
    renderedCallback() {
        if (!this.isRendered) {
            this.isRendered = true;

            const payload = RAISR_MSG_CH.raisrCtrlFormButtonRegistration();
            this.sendMessageToRaisrChannel( payload );
        }

    }

    sendMessageToRaisrChannel(msg) {
        const msgCh = this.template.querySelector("c-bwc-raisr-msg-pub-sub-cmp");
        if (msgCh) {
          msgCh.postMessage(msg);
        }
        return msgCh ? true : false; // may be just (msgCh) suffice, but just in case
    }

    onRaisrEvent(event) {
        if (event.detail.message.messageType === RAISR_MSG_CH.MSG_TYPE.RAISR_STATUS 
            || event.detail.message.messageType === RAISR_MSG_CH.MSG_TYPE.RAISR_STATUS_INTERNAL  
            || event.detail.message.messageType === RAISR_MSG_CH.MSG_TYPE.RAISR_MANAGER_STARTED) {
            this.useVoice = (event.detail.message.messageBody.isRaisrActive && hasVoiceRedactionPermission) 
                        || (hasVoiceRedactionPermission && hasEnterCustomerPaymentDetailsPermission);   
            BwcUtils.log(`onRaisrEvent useVoice: ${this.useVoice}`);
        }
    }

    /********************************************************************************************************/
    // Methods

    /*
        Called by container to reset everything.
    */
    @api initialize(paymentMethodTypeOptions, storedProfiles, promiseToPayMethodOptions, paymentMethod, defaultBankAccount, defaultCard, isBSSeCustomer) {

        // Set payment method type options and initial default
        if (paymentMethodTypeOptions) {
            this._paymentTypeMethodOptions = paymentMethodTypeOptions;
        }
        this.selectedPaymentMethodType = this.paymentMethodTypeOptions[0].value;

        // Set stored profiles and initial defaults
        this.setStoredProfiles(storedProfiles);

        // Step promise to pay method options
        if (promiseToPayMethodOptions) {
            this._promiseToPayMethodOptions = promiseToPayMethodOptions;
        }

        this.profileSecurityCodes = [];
        this.temporaryProfile = undefined;

        if (defaultBankAccount) {
            this.newBankAccount = BwcUtils.cloneObject(defaultBankAccount);
        }

        if (defaultCard) {
            this.newCard = BwcUtils.cloneObject(defaultCard);
        }

        if (paymentMethod) {
            if (paymentMethod.bankAccount) {
                paymentMethod.bankAccount.accountType = paymentMethod.bankAccount.accountType.toUpperCase();
            }
            this.mode = BwcPaymentServices.PostPaymentProfileMode.UPDATE;
            this.setPaymentMethod(BwcUtils.cloneObject(paymentMethod));
        }

        if (isBSSeCustomer) {
            this.isBSSeCustomer = isBSSeCustomer;
        }

        this.firePaymentMethodChanged();
        BwcUtils.nextTick().then(() => {this.setSelectedPaymentMethod();});

    }

    /*
        All custom input validation not automatically done by components.
    */
    customValidate() {

        let isValid = true;

        if (this.isCard) {

            const cardProfileOption =  this.cardProfileOptions[this.selectedCardProfileIndex];
            
            if (cardProfileOption?.hasRedactedSecurityCode) {

                const notification = this.template.querySelector(`c-bwc-notification[data-index="${cardProfileOption.index + ''}"]`);

                // Check if Collect CVV is ongoing or not started
                const securePaymentAgent = this.template.querySelector(`c-bwc-secure-payment-agent[data-index="${cardProfileOption.index + ''}"]`);
                if (securePaymentAgent.classList.contains('slds-hide')) {
                    notification.setCustomValidity('You must Collect CVV to use this payment method.');
                    isValid = false;
                }
                else {
                    notification.setCustomValidity(undefined);
                }

            }

            this.template.querySelectorAll(`lightning-input[data-security-code]`).forEach(input => {

                // Allow != to convert string to integer
                // eslint-disable-next-line eqeqeq
                if (this.isNewCard || input.dataset.securityCode != this.selectedCardProfileIndex) {
                    input.setCustomValidity('');
                }
                else {
                    isValid &= this.validateSecurityCode(input);
                }

            });
    
        }

        return isValid;

    }

    /*
        Set stored profiles from client.
    */
    setStoredProfiles(storedProfiles) {

        this.bankProfileOptions = [];
        this.cardProfileOptions = [];

        this.isNewBankAccount = true;
        this.selectedBankProfileIndex = -1;
        this.isNewCard = true;
        this.selectedCardProfileIndex = -1;

        if (!storedProfiles) {
            return;
        }

        this._storedProfiles = BwcUtils.cloneObject(storedProfiles);

        // Build option lists for radio buttons -- split into card and bank accounts
        this._storedProfiles.forEach(storedProfile =>  {

            // Basic option
            const option = {
                storedProfile: storedProfile,
                label: BwcUtils.buildPaymentMethodLabel(storedProfile)
            }

            switch(storedProfile.paymentMethodType) {

                case BwcPayments.PaymentMethodType.BANKACCOUNT.value:
                    option.index = this.bankProfileOptions.length;
                    this.bankProfileOptions.push(option);
                    break;

                case BwcPayments.PaymentMethodType.CARD.value:
                    option.index = this.cardProfileOptions.length;
                    option.hasVoiceSecurityCode = this.useVoice && !storedProfile.card.verified; // CVV using Voice Redaction
                    option.hasSecurityCode = !this.useVoice && hasEnterCustomerPaymentDetailsPermission && !storedProfile.card.verified; // CVV using normal input
                    option.hasRedactedSecurityCode = !this.useVoice && !hasEnterCustomerPaymentDetailsPermission && !storedProfile.card.verified; // CVV using redaction
                    option.raisrContext = `${this.context} CVV ${this.cardProfileOptions.length + 1}`;
                    option.fieldName = `profileSecurityCode-${this.cardProfileOptions.length}`;
                    this.cardProfileOptions.push(option);
                    break;

                default:
                    BwcUtils.error('Unexpected stored profile paymentMethodType: ' + storedProfile.paymentMethodType);
                    break;

            }

            option.key = 'paymentMethodOption' + option.index;

        });

        if (this.bankProfileOptions.length > 0) {
            this.isNewBankAccount = false;
            this.selectedBankProfileIndex = 0;
        }

        if (this.cardProfileOptions.length > 0) {
            this.isNewCard = false;
            this.selectedCardProfileIndex = 0;
        }

    }

    /*
        Set the correct radios for the current state.
    */
    setSelectedPaymentMethod() {

        if (this._storedProfiles) {

            if (this.isBankAccount) {

                this.template.querySelector(`input[data-index="${this.selectedBankProfileIndex}"]`).checked = true;

            }

            if (this.isCard) {

                this.template.querySelector(`input[data-index="${this.selectedCardProfileIndex}"]`).checked = true;
                const securityCode = this.template.querySelector(`div[data-security-code="${this.selectedCardProfileIndex}"]`);
                if (securityCode) {
                    securityCode.classList.remove('slds-hide');
                }

                const notification = this.template.querySelector(`c-bwc-notification[data-index="${this.selectedCardProfileIndex}"]`);
                if (notification) {
                    notification.classList.remove('slds-hide');
                }

            }

        }

        this.highlightSelectedPaymentMethod();
        this.refreshCardProfileList();

    }

    /*
        Return the resulting payment method, ready to use in API.
    */
    getPaymentMethod() {

        let paymentMethod;
        if (this.useRedaction && this.temporaryProfile) {

            // Using temporary profile
            paymentMethod =  {
                type: BwcPayments.PaymentMethodType.PAYMENT_PROFILE.value,
                paymentProfile: {
                    paySource: BwcUtils.cloneObject(this.temporaryProfile.paySource),
                    profileOwnerId: this.temporaryProfile.profileOwnerId,
                    profileName: this.temporaryProfile.profileName
                },
                bankAccount: this.temporaryProfile.bankAccount ?
                    {
                        accountType: this.temporaryProfile.bankAccount.accountType,
                        bankAccountNumber: this.temporaryProfile.bankAccount.bankAccountNumber
                    }
                    : undefined,
                card: this.temporaryProfile.card ?
                    {
                        cardType: this.temporaryProfile.card.cardType,
                        cardNumber: this.temporaryProfile.card.cardNumber      
                    }
                    : undefined,

            };

        }
        else if (this.isBankAccount && this.isNewBankAccount) {

            if (this.useVoice) {

                const smartFields = this.template.querySelector('div[data-name="voiceRecognition"]');

                if (smartFields) {
                    
                    const inputTypes = 'c-bwc-raisr-clear-text-field-cmp, c-bwc-raisr-tokenized-field-cmp';

                    // Get all values and tokes from inputs
                    smartFields.querySelectorAll(inputTypes).forEach(input => {
                        if (input.name === BwcPayments.PaymentSmartFields.ROUTING_NUMBER) {
                            this.newBankAccount.routingNumber = input.value;
                        }
                        if (input.name === BwcPayments.PaymentSmartFields.BANK_ACCOUNT_NUMBER) {
                            this.newBankAccount.bankAccountNumber = input.token ? input.token : input.value;
                            this.newBankAccount.bankAccountNumberVisibleValue = input.visibleValue ? input.visibleValue : input.value;
                            this.newBankAccount.bankAccountNumberToken = input.token ? input.token : '';
                        }
                    });

                }

            }

            paymentMethod = {
                type: BwcPayments.PaymentMethodType.BANKACCOUNT.value,
                bankAccount: this.newBankAccount
            };

        }
        else if (this.isCard && this.isNewCard) {

            if (this.useVoice) {

                const smartFields = this.template.querySelector('div[data-name="voiceRecognition"]');

                if (smartFields) {
                    // Get all values and tokes from inputs
                    const inputTypes = 'c-bwc-raisr-clear-text-field-cmp, c-bwc-raisr-tokenized-field-cmp';

                    smartFields.querySelectorAll(inputTypes).forEach(input => {
                        if (input.name === BwcPayments.PaymentSmartFields.ZIP_CODE) {
                            this.newCard.billingAddress.zipCode = input.value;
                        }
                        if (input.name === BwcPayments.PaymentSmartFields.CARD_NUMBER) {
                            this.newCard.cardNumber = input.token ? input.token : input.value;
                            this.newCard.cardNumberVisibleValue = input.visibleValue ? input.visibleValue : input.value;
                            this.newCard.cardNumberToken = input.token ? input.token : '';
                        }
                        if (input.name === BwcPayments.PaymentSmartFields.EXPIRATION_DATE) {
                            this.newCard.expireMonth = input.value.substring(0, 2);
                            this.newCard.expireYear = input.value.substring(3).length === 2 ? '20' + input.value.substring(3) : input.value.substring(3);
                            this.newCard.expirationDate = input.value;
                        }
                        if (input.name === BwcPayments.PaymentSmartFields.SECURITY_CODE) {
                            this.newCard.securityCode = input.token ? input.token : input.value;
                            this.newCard.securityCodeVisibleValue = input.visibleValue ? input.visibleValue : input.value;
                            this.newCard.securityCodeToken = input.token ? input.token : '';
                        }
                    });
                }
                
            }

            paymentMethod = {
                type: BwcPayments.PaymentMethodType.CARD.value,
                card: this.newCard
            };

        }
        else if (this.isPromiseToPay) {

            paymentMethod = {
                type: BwcPayments.PaymentMethodType.PROMISE_TO_PAY.value,
                promiseToPay: this.promiseToPay
            };

        }
        else if (this.isBankAccount && this.selectedBankProfileIndex !== -1) {

            const profileOption = this.bankProfileOptions[this.selectedBankProfileIndex];
            if (profileOption.paymentMethod) {

                // It's current payment method, just return it
                paymentMethod = profileOption.paymentMethod;

            }
            else {

                const storedProfile = profileOption.storedProfile;
                paymentMethod =  {
                    type: BwcPayments.PaymentMethodType.PAYMENT_PROFILE.value,
                    paymentProfile: {
                        paySource: BwcUtils.cloneObject(storedProfile.paySource),
                        profileOwnerId: storedProfile.profileOwnerId,
                        profileName: storedProfile.profileName
                    },
                    bankAccount: {
                        accountType: storedProfile.bankAccount.accountType,
                        bankAccountNumber: storedProfile.bankAccount.bankAccountNumber
                    }                    
                };

            }

        }
        else if (this.isCard && this.selectedCardProfileIndex !== -1) {

            const profileOption = this.cardProfileOptions[this.selectedCardProfileIndex];

            let profileSecurityCode;
            if (this.useVoice) {
                const profileCvvSmartField = this.template.querySelector('c-bwc-raisr-tokenized-field-cmp[data-name="profileSecurityCode"]');
                if (profileCvvSmartField) {
                    profileSecurityCode = profileCvvSmartField.token ? profileCvvSmartField.token : profileCvvSmartField.value;
                }
            }

            if (profileOption.paymentMethod) {

                // It's current payment method, just return it
                paymentMethod = profileOption.paymentMethod;
                if (profileSecurityCode) {
                    paymentMethod.paymentProfile.securityCode = profileSecurityCode;
                }

            }
            else {

                const storedProfile = profileOption.storedProfile;
                paymentMethod =  {
                    type: BwcPayments.PaymentMethodType.PAYMENT_PROFILE.value,
                    paymentProfile: {
                        paySource: BwcUtils.cloneObject(storedProfile.paySource),
                        profileOwnerId: storedProfile.profileOwnerId,
                        profileName: storedProfile.profileName,
                        securityCode: profileSecurityCode ? profileSecurityCode : this.profileSecurityCodes[this.selectedCardProfileIndex]
                    },
                    card: {
                        cardType: storedProfile.card.cardType,
                        cardNumber: storedProfile.card.cardNumber
                    }
                };

            }

        }
        else {
            paymentMethod = {};
        }

        return paymentMethod;

    }

    /*
        Set state from payment method passed in by client.
    */
    setPaymentMethod(paymentMethod) {

        this.paymentMethodTypeNotAllowedMessage = undefined;

        const bankAccountMatches = (a, b) =>  {
            return a.accountType === b.accountType &&
                a.routingNumber === b.routingNumber &&
                a.bankAccountNumber === b.bankAccountNumber
        };

        const cardMatches = (a, b) =>  {
            return a.cardNumber === b.cardNumber &&
                a.expireMonth === b.expireMonth &&
                a.expireYear === b.expireYear;
        };

        if (paymentMethod.promiseToPay) {
            this.promiseToPay = BwcUtils.cloneObject(paymentMethod.promiseToPay ? paymentMethod.promiseToPay : {});
        }

        switch (paymentMethod.type) {

            case BwcPayments.PaymentMethodType.BANKACCOUNT.value:

                if (this.isPaymentMethodTypeAllowed(BwcPayments.PaymentMethodType.BANKACCOUNT.value)) {

                    this.selectedPaymentMethodType = BwcPayments.PaymentMethodType.BANKACCOUNT.value;
                    this.selectedBankProfileIndex = -1;

                    // See if there's matching stored profile
                    if (this._storedProfiles) {
                        this.selectedBankProfileIndex = this.bankProfileOptions.findIndex(
                            option => bankAccountMatches(option.storedProfile ? option.storedProfile.bankAccount : option.paymentMethod.bankAccount, paymentMethod.bankAccount));
                        if (this.selectedBankProfileIndex === -1) {

                            if (this.disallowEdit) {

                                // Add a "fake" stored profile entry to represent the current payment method on payment being edited
                                const option = {
                                    paymentMethod: paymentMethod,
                                    label: BwcUtils.buildPaymentMethodLabel(paymentMethod),
                                    index: this.bankProfileOptions.length,
                                    key: 'paymentMethodOption' + this.bankProfileOptions.length
                                }
                                this.bankProfileOptions.push(option);
                                this.selectedBankProfileIndex = this.bankProfileOptions.length - 1;
                                this.isNewBankAccount = false;

                            }
                            else {
                                this.isNewBankAccount = true;
                                this.newBankAccount = BwcUtils.cloneObject(paymentMethod.bankAccount ? paymentMethod.bankAccount : {});
                            }

                        }
                        else {
                            this.isNewBankAccount = false;
                        }
                    }
                    else {
                        this.isNewBankAccount = true;
                        this.newBankAccount = BwcUtils.cloneObject(paymentMethod.bankAccount ? paymentMethod.bankAccount : {});
                        // Set RAISR Visible Values
                        if (this.useVoice) {
                            this.newBankAccount.bankAccountNumberVisibleValue = this.newBankAccount.bankAccountNumber ? this.newBankAccount.bankAccountNumber : '';
                        }
                    }
                }
                else {
                    this.paymentMethodTypeNotAllowedMessage = label_paymentMethodTypeNotAllowed.replace('{0}', BwcPayments.PaymentMethodType.BANKACCOUNT.label);
                }

                break;

            case BwcPayments.PaymentMethodType.CARD.value:

                if (this.isPaymentMethodTypeAllowed(BwcPayments.PaymentMethodType.CARD.value)) {

                    this.selectedPaymentMethodType = BwcPayments.PaymentMethodType.CARD.value;
                    this.selectedCardProfileIndex = -1;

                    // See if there's matching stored profile
                    if (this._storedProfiles) {
                        this.selectedCardProfileIndex = this.cardProfileOptions.findIndex(
                            option => cardMatches(option.storedProfile ? option.storedProfile.card : option.paymentMethod.card, paymentMethod.card));
                        if (this.selectedCardProfileIndex === -1) {

                            if (this.disallowEdit) {

                                // Add a "fake" stored profile entry to represent the current payment method on payment being edited
                                const option = {
                                    paymentMethod: paymentMethod,
                                    label: BwcUtils.buildPaymentMethodLabel(paymentMethod),
                                    index: this.cardProfileOptions.length,
                                    key: 'paymentMethodOption' + this.cardProfileOptions.length
                                }
                                this.cardProfileOptions.push(option);
                                this.selectedCardProfileIndex = this.cardProfileOptions.length - 1;
                                this.isNewCard = false;

                            }
                            else{
                                this.selectedCardProfileIndex = -1;
                                this.isNewCard = true;
                                this.newCard = BwcUtils.cloneObject(paymentMethod.card ? paymentMethod.card : {});
                            }

                        }
                        else {
                            this.isNewCard = false;
                        }
                    }
                    else {
                        this.newCard = BwcUtils.cloneObject(paymentMethod.card ? paymentMethod.card : {});
                        // Set RAISR Visible Values
                        if (this.useVoice) {
                            this.newCard.cardNumberVisibleValue = this.newCard.cardNumber ? this.newCard.cardNumber : '';
                            this.newCard.expirationDate = this.newCard.expireMonth && this.newCard.expireYear ? this.newCard.expireMonth + '/' + this.newCard.expireYear.slice(-2) : '';
                            this.newCard.securityCodeVisibleValue = this.newCard.securityCode ? this.newCard.securityCode : '';
                        }
                    }
                }
                else {
                    this.paymentMethodTypeNotAllowedMessage = label_paymentMethodTypeNotAllowed.replace('{0}', BwcPayments.PaymentMethodType.CARD.label);
                }

                break;

            case BwcPayments.PaymentMethodType.PROMISE_TO_PAY.value:

                if (this.isPaymentMethodTypeAllowed(BwcPayments.PaymentMethodType.PROMISE_TO_PAY.value)) {
                    this.selectedPaymentMethodType = BwcPayments.PaymentMethodType.PROMISE_TO_PAY.value;
                }
                else {
                    this.paymentMethodTypeNotAllowedMessage = label_paymentMethodTypeNotAllowed.replace('{0}', BwcPayments.PaymentMethodType.PROMISE_TO_PAY.label);
                }
                break;

            default:
                // There's no use case for initializing from stored profile
                break;

        }

        if (this.selectedPaymentMethodType === BwcPayments.PaymentMethodType.PROMISE_TO_PAY.value) {
            this.firePromiseToPayMethodChanged(this.promiseToPay.method);
        }

    }

    isPaymentMethodTypeAllowed(paymentMethodType) {
        return !!this._paymentTypeMethodOptions.find(option => option.value === paymentMethodType);
    }

    /*
        Custom validate security code on demand, instead of using built-in validations, because otherwise causes problems with hidden security code inputs.
    */
    validateSecurityCode(input) {

        if (!input.value) {
            input.setCustomValidity('Security code required.');
            return false;
        }
        else if (input.value.length < 3 || input.value.length > 4) {
            input.setCustomValidity('Must be 3 or 4 digits.');
            return false;
        }
        input.setCustomValidity('');
        return true;

    }

    /********************************************************************************************************/
    // Event handlers

    /*
        Payment type radio buttons changed.
    */
    async handlePaymentMethodTypeChange(event) {

        this.selectedPaymentMethodType = event.target.value; 

        await BwcUtils.nextTick();

        this.setSelectedPaymentMethod();

        this.firePaymentMethodChanged();

        if (this.selectedPaymentMethodType === BwcPayments.PaymentMethodType.PROMISE_TO_PAY.value) {
            this.firePromiseToPayMethodChanged(this.promiseToPay.method);
        }

        await BwcUtils.nextTick();

        this.highlightSelectedPaymentMethod();

    }

    /*
        Selected payment type (stored profile or Use New) was changed.
    */
    async handlePaymentMethodChange(event) {

        const selectedIndex = parseInt(event.target.dataset.index, 10);
        const isNew = selectedIndex === -1;

        if (this.isBankAccount) {
            this.isNewBankAccount = isNew;
            this.selectedBankProfileIndex = selectedIndex;
        }
        else if (this.isCard) {

            this.isNewCard = isNew;
            this.selectedCardProfileIndex = selectedIndex;

            const raisrSecurityCodes = this.template.querySelectorAll('c-bwc-raisr-tokenized-field-cmp[data-security-code]');
            raisrSecurityCodes.forEach(securityCode => {
                if (this.isNewCard) {
                    securityCode.classList.add('slds-hide');
                }
                else if (securityCode.dataset.securityCode == event.target.dataset.index) {
                    securityCode.classList.remove('slds-hide');
                }
                else {
                    securityCode.classList.add('slds-hide');
                }
            });

            const securityCodesDivs = this.template.querySelectorAll('div[data-security-code]');
            securityCodesDivs.forEach(securityCode => {
                if (this.isNewCard) {
                    securityCode.classList.add('slds-hide');
                }
                else if (securityCode.dataset.securityCode == event.target.dataset.index) {
                    securityCode.classList.remove('slds-hide');
                }
                else {
                    securityCode.classList.add('slds-hide');
                }
            });

            // Show/hide notifications
            const notifications = this.template.querySelectorAll('c-bwc-notification[data-index]');
            notifications.forEach(notification => {
                if (notification.dataset.index === event.target.dataset.index) {
                    notification.classList.remove('slds-hide');
                    notification.setCustomValidity(undefined);
                }
                else {
                    notification.classList.add('slds-hide');
                }
            });

            // Hide secure agents for CVV
            const secureAgents = this.template.querySelectorAll('c-bwc-secure-payment-agent[data-index]');
            secureAgents.forEach(secureAgent => {
                secureAgent.classList.add('slds-hide');
            });

            // Re-enable Collect CVV buttons
            const collectCVVButtons = this.template.querySelectorAll('lightning-button[data-index]');
            collectCVVButtons.forEach(button => {
                button.disabled = false;
            });

        }

        this.highlightSelectedPaymentMethod();

        this.firePaymentMethodChanged();

    }

    @api refreshCardProfileList() {

        if (this.isCard) {

            this.selectedCardProfileIndex = this.state.selectedCardProfileIndex;
            this.isNewCard = this.state.isNewCard;

            const raisrSecurityCodes = this.template.querySelectorAll('c-bwc-raisr-tokenized-field-cmp[data-security-code]');
            raisrSecurityCodes.forEach(securityCode => {
                if (this.isNewCard) {
                    securityCode.classList.add('slds-hide');
                }
                else if (securityCode.dataset.securityCode == this.selectedCardProfileIndex) {
                    securityCode.classList.remove('slds-hide');
                }
                else {
                    securityCode.classList.add('slds-hide');
                }
            });

            const securityCodesDivs = this.template.querySelectorAll('div[data-security-code]');
            securityCodesDivs.forEach(securityCode => {
                if (this.isNewCard) {
                    securityCode.classList.add('slds-hide');
                }
                else if (securityCode.dataset.securityCode == this.selectedCardProfileIndex) {
                    securityCode.classList.remove('slds-hide');
                }
                else {
                    securityCode.classList.add('slds-hide');
                }
            });
        }
    }

    highlightSelectedPaymentMethod() {

        // Highlight the selected section, unhighlight others
        this.template.querySelectorAll('div[data-section-index]').forEach(div => {

            if (this.isBankAccount) {
                // eslint-disable-next-line eqeqeq
                if (div.dataset.sectionIndex == this.selectedBankProfileIndex) {
                    div.classList.add('selected');
                }
                else {
                    div.classList.remove('selected');
                }
            }
            else if (this.isCard) {
                // eslint-disable-next-line eqeqeq
                if (div.dataset.sectionIndex == this.selectedCardProfileIndex) {
                    div.classList.add('selected');
                }
                else {
                    div.classList.remove('selected');
                }
            }

        });

    }

    /*
        c-bwc-input-card-number has detected a changed card type.
    */
    handleCardTypeChange(event) {

        this.newCard.cardType = event.detail.cardType;

    }

    /*
        Automate slash in date.
    */    
    handleExpirationDateChange(event) {

        if (event.target.value.length > 2 && !event.target.value.includes('/')) {
            event.target.value = event.target.value.substring(0, 2) + '/' + event.target.value.substring(2);
        }

    }

    getSpiData() {

        let data = {spiDataList: []};

        const smartFields = this.template.querySelector('div[data-name="voiceRecognition"]');

        const inputTypes = 'c-bwc-raisr-clear-text-field-cmp, c-bwc-raisr-tokenized-field-cmp';

        if (smartFields) {
            // Get all values and tokes from inputs
            smartFields.querySelectorAll(inputTypes).forEach(input => {
                data.spiDataList.push({
                    name: input.name,
                    token : input.token,
                    value : input.token ? input.visibleValue : input.value
                });
            });
        }

        return data;
    }

    /*
        Process changes to inputs.
    */
    handleInputCommit(event) {

        switch (event.target.name) {

            case 'cardNumber':
                // Save token if any
                if (event.target.token) {
                    this.newCard[event.target.name + 'Token'] = event.target.token;
                }
                // Save value/visibleValue for card 
                this.newCard[event.target.name] = event.target.value;
                break;

            case 'cardType':
            case 'cardHolderName':
                this.newCard[event.target.name] = event.target.value;
                break;

            case 'securityCode':
                this.validateSecurityCode(event.target);
                if (event.target.token) {
                    this.newCard[event.target.name + 'Token'] = event.target.token;
                }
                this.newCard[event.target.name] = event.target.value;
                break;

            case 'zipCode':
                this.newCard.billingAddress[event.target.name] = event.target.value;
                break;

            case 'expirationDate':
                this.newCard.expireMonth = event.target.value.substring(0, 2);
                this.newCard.expireYear = event.target.value.substring(3);
                this.newCard.expirationDate = event.target.value;
                break;

            case 'accountType':
            case 'accountHolderName':
            case 'routingNumber':
                this.newBankAccount[event.target.name] = event.target.value;
                break;

            case 'bankAccountNumber':
                if (event.target.token) {
                    this.newBankAccount[event.target.name + 'Token'] = event.target.token;
                }
                this.newBankAccount[event.target.name] = event.target.value;
                break;

            case 'method':
                this.promiseToPay[event.target.name] = event.target.value;
                this.firePromiseToPayMethodChanged(event.target.value);
                break;

            case 'profileSecurityCode':
                this.validateSecurityCode(event.target);
                this.profileSecurityCodes[this.selectedCardProfileIndex] = event.target.token ? event.target.token : event.target.value;
                break;

            default:
                break;

        }

    }

    @api saveProfileSecurityCodes() {

        if (this.isCard && this.selectedCardProfileIndex !== -1) {

            const profileCvvSmartFields = this.template.querySelectorAll('c-bwc-raisr-tokenized-field-cmp[data-security-code]');

            if (profileCvvSmartFields) {
                // Get all values and tokes from inputs
                profileCvvSmartFields.forEach(profileCvvSmartField => {
                    if (profileCvvSmartField.dataset.securityCode == this.selectedCardProfileIndex) {
                        // Store information from profile cvv smart-field
                        this.profileSecurityCodesRaisr[this.selectedCardProfileIndex] = {
                            profileSecurityCode : profileCvvSmartField.token ? profileCvvSmartField.token : profileCvvSmartField.value,
                            profileSecurityCodeVisibleValue : profileCvvSmartField.visibleValue ? profileCvvSmartField.visibleValue : profileCvvSmartField.value,
                            profileSecurityCodeToken : profileCvvSmartField.token ? profileCvvSmartField.token : ''
                        }
                        BwcUtils.log('Added RAISR Profile Security Code: ' + JSON.stringify(this.profileSecurityCodesRaisr[this.selectedCardProfileIndex]));
                    }
                });
            }
        }
    }

    /*
        Agent clicked Collect CVV button
    */
    async handleCollectCvvClick(event) {

        // Collect CVV button is disabled now as long as they are on the payment method
        event.target.disabled = true;

        // Clear any validation error
        const notification = this.template.querySelector(`c-bwc-notification[data-index="${event.target.dataset.index}"]`);
        notification.setCustomValidity(undefined);

        // Get the corresponding secure payment agent and unhide it
        const securePaymentAgent = this.template.querySelector(`c-bwc-secure-payment-agent[data-index="${event.target.dataset.index}"]`);
        securePaymentAgent.classList.remove('slds-hide');

        // Set the profile name whose CVV will be set via redaction process
        securePaymentAgent.paymentProfileName = this.cardProfileOptions[this.selectedCardProfileIndex].storedProfile.profileName;

        // Reset
        securePaymentAgent.initialize();

    }

    /*
        Redaction component has created a temporary profile.
    */
    handleSecurePaymentCompleted(event) {

        if (!event.detail.isCvvOnly) {

            // Redaction succeeded and temporary profile is available
            this.temporaryProfile = BwcUtils.cloneObject(event.detail.paymentProfile);

            // Make sure selected type matches type they used
            this.selectedPaymentMethodType = this.temporaryProfile.paymentMethodType;

            // Tell client there is a new temporary profile available
            this.dispatchEvent(new CustomEvent('newtemporaryprofile', {detail: this.temporaryProfile}));

        }

    }

    firePaymentMethodChanged() {
        this.dispatchEvent(new CustomEvent('paymentmethodchange', {detail: {paymentMethod: this.paymentMethod, state: this.state}}));
    }
 
    firePromiseToPayMethodChanged(newValue) {
        this.dispatchEvent(new CustomEvent('promisetopaymethodchange', {detail: {newValue: newValue}}));
    }    

}