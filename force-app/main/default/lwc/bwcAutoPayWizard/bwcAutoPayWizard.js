import { LightningElement, api, track, wire } from "lwc";
import { publish, MessageContext } from 'lightning/messageService';
import * as BwcConstants from 'c/bwcConstants';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcAccountServices from "c/bwcAccountServices";
import * as BwcPayments from 'c/bwcPayments';
import * as BwcPaymentServices from 'c/bwcPaymentServices';
import * as BwcLabelServices from 'c/bwcLabelServices';
import * as BwcInteractionServices from 'c/bwcInteractionServices';

// Message channels
import REFRESHMC from '@salesforce/messageChannel/BWC_Refresh__c';

// Permissions
import hasEnterCustomerPaymentDetailsPermission from '@salesforce/customPermission/Enter_Customer_Payment_Details';

// Default payment details
const DEFAULT_PAYMENT_DETAILS = {
};

export default class BwcAutoPayWizard extends LightningElement {

    // Public interface
    @api recordId;      // Always passed into component
    @api defaultBan;
    @api editBan;
    @api profileName;

    get isEdit() {return !!this.editBan || !!this.profileName;}
    get isEditBSSe() {return !!this.profileName && this.isBSSeCustomer;}

    // Labels that need to be accessed in template
    labels = BwcLabelServices.labels;

    get inputPaymentMethod() {return this.template.querySelector('c-bwc-input-payment-method');}
    get inputPaymentContext() {return this.isEdit || this.isEditBSSe ? BwcPayments.RaisrContext.AUTOPAY_UPDATE.value : BwcPayments.RaisrContext.AUTOPAY_ENROLL.value;}

    storedProfiles = [];

    //#region Wizard
    /********************************************************************************************************/

    wizardSteps = [
        {
            name: "enroll",
            title: "<b>Enroll in AutoPay</b>",
            panelNumber: 0,
            minHeight: 165,
            finishAction: this.saveAutoPayDetails.bind(this),
            rightButton: {
                name: "review",
                label: "Review",
                action: this.validateAutoPayDetails.bind(this)
            },
            cancelButton:
            {
                name: "cancel",
                label: "Cancel",
                variant: "destructive-text",
                action: this.close.bind(this)
            }
        },
        {
            name: 'review',
            title: '<b>Review AutoPay Enrollment</b>',
            panelNumber: 1,
            minHeight: 165,
            initAction: this.loadReview.bind(this),
            leftButton: {
                name: 'editPaymentDetails',
                label: 'Edit Payment Details'
            },
            rightButton: {
                name: 'completeEnrollment',
                label: 'Complete Enrollment',
                action: this.completeEnrollment.bind(this)
            },
            cancelButton:
            {
                name: "cancel",
                label: "Cancel",
                variant: "destructive-text",
                action: this.close.bind(this)
            }
        },
        {
            name: 'confirmation',
            title: '<b>AutoPay Enrollment Confirmation</b>',
            panelNumber: 2,
            initAction: this.loadConfirmation.bind(this),
            rightButton: {
                name: 'ok',
                label: 'Okay'
            },
            cancelButton:
            {
                name: "cancel",
                label: "Cancel",
                variant: "destructive-text",
                action: this.close.bind(this)
            }
        }

    ];

    get wizard() {return this.template.querySelector('c-bwc-wizard');}

    // Needed to send refresh message
    @wire(MessageContext)
    messageContext;

    isRendered = false;

    renderedCallback() {

        if (!this.isRendered) {

            // Perform actions on first render, that way error report component is rendered and available to show error
            this.isRendered = true;
            this.wizard.open(() => this.initialize());
    
        }

    }

    close() {
        this.wizard.close();
    }

    // Information from the BSSe customer if applicable
    isBSSeCustomer;
    individualId;
    interaction;

    get eligiblePaymentHeaderLabel() {return this.isBSSeCustomer ? '1. Eligible Payment Methods' : '2. Eligible Payment Methods';}

    /*
        Wizard closed -- bubble the close event up to any enclosing quick action.
    */
    handleWizardClose() {
        this.dispatchEvent(new CustomEvent("close"));
    }

    /*
        Wizard calls this when opening.
    */
    async initialize() {

        // Reset everything
        this.billingAccounts = [];
        this.billingAccountOptions = [];
        this.selectedBan = undefined;
        this.selectedBillingAccount = {};
        this.paymentDetailsResponses = undefined;
        this.paymentDetailsRetrieved = false;
        this.selectedPaymentDetails = undefined;

        // Check if is BSSe customer
        this.interaction = await BwcInteractionServices.getInteraction(this.recordId);
        this.isBSSeCustomer = this.interaction.Customer__r.Is_Digital_Customer__c;
        this.individualId = this.interaction.Customer__r.Individual_ID__c;

        // Defaults
        this.selectedPaymentDetails = BwcUtils.cloneObject(DEFAULT_PAYMENT_DETAILS);

        // Get all billing accounts for the person account, excluding ones that fall under a unified or of invalid type
        this.billingAccounts = await BwcAccountServices.getBillingAccounts(this.recordId, true, true, BwcConstants.PaymentBillingAccountTypes);

        // Start the calls to get all payment details that might be needed. Don't block because not needed yet.
        this.getPaymentDetails();

        // Build selection list of billing accounts
        this.billingAccountOptions = this.billingAccounts.map(billingAccount => {
            return {
                label: billingAccount.Service_Label__c,
                value: billingAccount.Billing_Account_Number__c
            };
        });

        // Set default selected ban
        if (this.defaultBan || this.editBan) {

            // Default BAN passed in
            this.selectedBan = this.editBan ? this.editBan : this.defaultBan;

        }
        else if (this.billingAccounts.length === 1) {

            // Only one BAN, default to it
            this.selectedBan = this.billingAccounts[0].Billing_Account_Number__c;

        }
        else {

            this.selectedBan = undefined;

        }

        return undefined;

    }

    /********************************************************************************************************/
    //#endregion

    //#region Payment Details from API
    /********************************************************************************************************/

    paymentDetailsResponses;
    paymentDetailsRetrieved;
    @track selectedPaymentDetails = BwcUtils.cloneObject(DEFAULT_PAYMENT_DETAILS);

    /*
        Get payment details for every BAN.
    */
    async getPaymentDetails() {

        let getPaymentDetailsArgs = {};
        
        if (this.isBSSeCustomer) {
            getPaymentDetailsArgs = {
                recordId: this.recordId,
                topics: [
                    BwcConstants.PaymentDetailTopic.PAYMENT_PROFILES.value
                ]
            }
        } else {
            getPaymentDetailsArgs = {
                recordId: this.recordId,
                bans: this.billingAccounts.map(billingAccount => billingAccount.Billing_Account_Number__c),
                topics: [
                    BwcConstants.PaymentDetailTopic.PAYMENT_PROFILES.value,
                    BwcConstants.PaymentDetailTopic.BAN_BILLING_IDS.value,
                    BwcConstants.PaymentDetailTopic.AUTOPAY.value
                ]
            }
        }

        try {

            this.paymentDetailsResponses = await BwcPaymentServices.getPaymentDetails(getPaymentDetailsArgs);
            this.paymentDetailsRetrieved = true;

            // Allow render
            await BwcUtils.nextTick();

            if (!this.isBSSeCustomer && this.selectedBan) {
                // Now that we have payment details, check if there's already a selected ban then handle.
                this.handleBanSelected();
            }

            if (this.isBSSeCustomer && this.profileName) {
                // Now that we have payment details, check if there's already a selected ban/profile then handle.
                this.handleProfileSelected();
            }

        }
        catch(error) {
            this.wizard.reportError(error);
        }
        finally {
            this.paymentDetailsRetrieved = true;
        }

    }

    /********************************************************************************************************/
    //#endregion

    //#region Enroll Panel
    /********************************************************************************************************/

    // All billing accounts for the person account, use for multi-selection
    billingAccounts = [];
    @track billingAccountOptions = [];
    selectedBan;
    selectedBillingAccount = {};
    selectedAccountTypeLabel;
    showPaymentMethods;

    @track autoPayDetails = {
        paymentMethod: {
            billingAddress: {}
        }
    };
    paymentMethod;

    /*
        Set the payment details for the selected ban.
    */
    async handleBanSelected(event) {

        try {

            this.wizard.clearError();
            this.showPaymentMethods = false;

            this.selectedPaymentDetails = BwcUtils.cloneObject(DEFAULT_PAYMENT_DETAILS);

            if (event) {
                this.selectedBan = event.target.value;
            }

            // Find corresponding billing account record
            this.selectedBillingAccount = this.billingAccounts.find(billingAccount => billingAccount.Billing_Account_Number__c === this.selectedBan);
            this.selectedAccountTypeLabel = BwcConstants.BillingAccountType.getLabelForValue(this.selectedBillingAccount.Account_Type__c);

            // Find details for ban
            this.selectedPaymentDetails = this.paymentDetailsResponses.find(paymentDetailsResponse => paymentDetailsResponse.ban === this.selectedBan);

            // Update all step titles to include BAN
            this.wizard.setStepTitle('enroll', this.isEdit ? `<b>Edit AutoPay Details</b>` : `<b>Enroll in AutoPay</b>`);
            this.wizard.setStepTitle('review', `<b>Review AutoPay Enrollment</b>`);
            this.wizard.setStepTitle('confirmation', `<b>AutoPay Enrollment Confirmation</b>`);

            if (!this.selectedPaymentDetails) {
                throw new Error('Payment Details not found for this Account, unable to continue.');
            }

            // Check for partial errors for payment details topics that are required to proceed:

            // System and Division Ids
            if (this.selectedPaymentDetails.errorbanBillingIds) {
                BwcUtils.error(JSON.stringify(this.selectedPaymentDetails.errorbanBillingIds));
                throw new Error('Error retrieving banBillingIds, unable to continue.');
            }

            // Saved profiles
            if (this.selectedPaymentDetails.errorpaymentProfiles) {
                BwcUtils.error(new Error('Error retrieving stored profiles.'), JSON.stringify(this.selectedPaymentDetails.errorpaymentProfiles) );
            }

            // Autopay details
            if (this.selectedPaymentDetails.errorautopay) {
                BwcUtils.error(JSON.stringify(this.selectedPaymentDetails.errorautopay));
                throw new Error('Error retrieving autopay details, unable to continue.');
            }

            this.autoPayDetails.paymentMethodTypeOptions = [];
            if (this.selectedPaymentDetails.autopay.paymentPlanEligibility.paymentMethodAllowed.bank) {
                this.autoPayDetails.paymentMethodTypeOptions.push(BwcPayments.PaymentMethodType.BANKACCOUNT);
            }
            if (this.selectedPaymentDetails.autopay.paymentPlanEligibility.paymentMethodAllowed.card) {
                this.autoPayDetails.paymentMethodTypeOptions.push(BwcPayments.PaymentMethodType.CARD);
            }

            const storedProfiles = this.selectedPaymentDetails.paymentProfiles ? this.selectedPaymentDetails.paymentProfiles.paymentProfileList : [];
    
            // For cards, only verified profiles can be used unless agent has permission to enter details (i.e. no redaction)
            this.storedProfiles = storedProfiles.filter(profile => hasEnterCustomerPaymentDetailsPermission || profile.paymentMethodType !== BwcPayments.PaymentMethodType.CARD.value || profile.card.verified);

            if (!this.isEdit) {

                // *********************
                // ENROLL NEW AUTOPAY
                // *********************

                // Default billing information
                this.autoPayDetails.paymentMethod = {
                    paymentMethodType: BwcPayments.PaymentMethodType.CARD.value,
                    card: {
                        cardHolderName: this.selectedBillingAccount.First_Name__c + ' ' + this.selectedBillingAccount.Last_Name__c,
                        billingAddress: {
                            zipCode: this.selectedBillingAccount.Billing_Zipcode__c
                                ? this.selectedBillingAccount.Billing_Zipcode__c.substring(0, 5)
                                : undefined
                        }
                    },
                    bankAccount: {
                        accountType: BwcPayments.BankAccountType.CHECKING.value,
                        accountHolderName: this.selectedBillingAccount.First_Name__c + ' ' + this.selectedBillingAccount.Last_Name__c
                    }
                };

                this.showPaymentMethods = true;

                // Wait for render
                await BwcUtils.nextTick();

                this.inputPaymentMethod.initialize(
                    this.autoPayDetails.paymentMethodTypeOptions, 
                    this.storedProfiles, 
                    undefined, 
                    undefined,
                    this.getDefaultBankAccount(), 
                    this.getDefaultCard());

            }
            else {

                // *********************
                // EDIT EXISTING AUTOPAY
                // *********************

                // Construct standard payment method form autopay info
                const paymentPlanInfo = this.selectedPaymentDetails.autopay?.paymentPlanInfo?.[0];
                const currentPaymentMethod = {
                    card: paymentPlanInfo?.card,
                    bankAccount: paymentPlanInfo?.bankAccount
                };

                if (currentPaymentMethod.card) {
                    currentPaymentMethod.type = BwcPayments.PaymentMethodType.CARD.value;
                    currentPaymentMethod.card.billingAddress = {
                        zipCode: currentPaymentMethod.card.zipCode
                    };

                }
                else if (currentPaymentMethod.bankAccount) {
                    currentPaymentMethod.type = BwcPayments.PaymentMethodType.BANKACCOUNT.value;
                }

                this.showPaymentMethods = true;

                // Wait for render
                await BwcUtils.nextTick();

                this.inputPaymentMethod.initialize(
                    this.autoPayDetails.paymentMethodTypeOptions, 
                    this.storedProfiles, 
                    undefined, 
                    currentPaymentMethod, 
                    this.getDefaultBankAccount(), 
                    this.getDefaultCard());

            }

        }
        catch (error) {
            this.wizard.reportError(error);
        }

    }

    /*
        Set the payment details for the selected ban.
    */
    async handleProfileSelected() {

        try {

            this.wizard.clearError();
            this.showPaymentMethods = false;

            this.selectedPaymentDetails = BwcUtils.cloneObject(DEFAULT_PAYMENT_DETAILS);

            // Find details for ban
            this.selectedPaymentDetails = this.paymentDetailsResponses.find(paymentDetailsResponse => paymentDetailsResponse.individualId === this.individualId);

            // Update all step titles to include BAN
            this.wizard.setStepTitle('enroll', this.isEdit ? `<b>Edit AutoPay Details</b>` : `<b>Enroll in AutoPay</b>`);
            this.wizard.setStepTitle('review', `<b>Review AutoPay Enrollment</b>`);
            this.wizard.setStepTitle('confirmation', `<b>AutoPay Enrollment Confirmation</b>`);

            if (!this.selectedPaymentDetails) {
                throw new Error('Payment Details not found for Account, unable to continue.');
            }

            // Check for partial errors for payment details topics that are required to proceed:

            // Saved profiles
            if (this.selectedPaymentDetails.errorpaymentProfiles) {
                BwcUtils.error(new Error('Error retrieving stored profiles.'), JSON.stringify(this.selectedPaymentDetails.errorpaymentProfiles) );
            }

            this.autoPayDetails.paymentMethodTypeOptions = [];
            this.autoPayDetails.paymentMethodTypeOptions.push(BwcPayments.PaymentMethodType.BANKACCOUNT);
            this.autoPayDetails.paymentMethodTypeOptions.push(BwcPayments.PaymentMethodType.CARD);

            const storedProfiles = this.selectedPaymentDetails.paymentProfiles ? this.selectedPaymentDetails.paymentProfiles.paymentProfileList : [];
    
            // For cards, only verified profiles can be used unless agent has permission to enter details (i.e. no redaction)
            this.storedProfiles = storedProfiles.filter(profile => hasEnterCustomerPaymentDetailsPermission || profile.paymentMethodType !== BwcPayments.PaymentMethodType.CARD.value || profile.card.verified);

            if (!this.isEdit) {

                // *********************
                // ENROLL NEW AUTOPAY
                // *********************

                // Default billing information
                this.autoPayDetails.paymentMethod = {
                    paymentMethodType: BwcPayments.PaymentMethodType.CARD.value,
                    card: {
                        cardHolderName: this.selectedBillingAccount.First_Name__c + ' ' + this.selectedBillingAccount.Last_Name__c,
                        billingAddress: {
                            zipCode: this.selectedBillingAccount.Billing_Zipcode__c
                                ? this.selectedBillingAccount.Billing_Zipcode__c.substring(0, 5)
                                : undefined
                        }
                    },
                    bankAccount: {
                        accountType: BwcPayments.BankAccountType.CHECKING.value,
                        accountHolderName: this.selectedBillingAccount.First_Name__c + ' ' + this.selectedBillingAccount.Last_Name__c
                    }
                };

                this.showPaymentMethods = true;

                // Wait for render
                await BwcUtils.nextTick();

                this.inputPaymentMethod.initialize(
                    this.autoPayDetails.paymentMethodTypeOptions, 
                    this.storedProfiles, 
                    undefined, 
                    undefined,
                    this.getDefaultBankAccount(), 
                    this.getDefaultCard());

            }
            else {

                // *********************
                // EDIT EXISTING AUTOPAY
                // *********************

                // Construct standard payment method form autopay info
                const paymentPlanInfo = this.storedProfiles.find(storedProfile => storedProfile.profileName === this.profileName);
                BwcUtils.log(`paymentPlanInfo: ${JSON.stringify(paymentPlanInfo)}`);
                const currentPaymentMethod = {
                    card: paymentPlanInfo?.card,
                    bankAccount: paymentPlanInfo?.bankAccount
                };

                if (currentPaymentMethod.card) {
                    currentPaymentMethod.type = BwcPayments.PaymentMethodType.CARD.value;
                    currentPaymentMethod.card.billingAddress = {
                        zipCode: currentPaymentMethod.card.zipCode
                    };

                }
                else if (currentPaymentMethod.bankAccount) {
                    currentPaymentMethod.type = BwcPayments.PaymentMethodType.BANKACCOUNT.value;
                }

                this.showPaymentMethods = true;

                // Wait for render
                await BwcUtils.nextTick();

                BwcUtils.log('init inputPaymentMethod');
                this.inputPaymentMethod.initialize(
                    this.autoPayDetails.paymentMethodTypeOptions, 
                    this.storedProfiles, 
                    undefined, 
                    currentPaymentMethod, 
                    this.getDefaultBankAccount(), 
                    this.getDefaultCard());

            }

        }
        catch (error) {
            this.wizard.reportError(error);
        }

    }

    getDefaultBankAccount() {
        if (!this.isBSSeCustomer && this.selectedBan) {
            BwcUtils.log('getDefaultBankAccount has selectedBan: ' + this.selectedBan);
            return {
                accountType: BwcConstants.BankAccountType.CHECKING.value,
                accountHolderName: this.selectedBillingAccount.First_Name__c + ' ' + this.selectedBillingAccount.Last_Name__c,
                routingNumber: '',
                bankAccountNumber: '',
                bankAccountNumberVisibleValue: '',
                bankAccountNumberToken: ''
            };
        } else {
            return {
                accountType: BwcConstants.BankAccountType.CHECKING.value,
                accountHolderName: this.interaction.Customer__r.FirstName + ' ' + this.interaction.Customer__r.LastName,
                routingNumber: '',
                bankAccountNumber: '',
                bankAccountNumberVisibleValue: '',
                bankAccountNumberToken: ''
            };
        }
    }

    getDefaultCard() {
        if (!this.isBSSeCustomer && this.selectedBan) {
            BwcUtils.log('getDefaultCard has selectedBan: ' + this.selectedBan);
            return {
                cardHolderName: this.selectedBillingAccount.First_Name__c + ' ' + this.selectedBillingAccount.Last_Name__c,
                billingAddress: {
                    zipCode: this.selectedBillingAccount.Billing_Zipcode__c
                        ? this.selectedBillingAccount.Billing_Zipcode__c.substring(0, 5)
                        : undefined
                },
                cardNumber: '',
                cardNumberVisibleValue: '',
                cardNumberToken: '',
                expirationDate: '',
                securityCode: '',
                securityCodeVisibleValue: '',
                securityCodeToken: ''
            };
        } else {
            return {
                cardHolderName: this.interaction.Customer__r.FirstName + ' ' + this.interaction.Customer__r.LastName,
                billingAddress: {
                    zipCode: this.interaction.Customer__r.PersonMailingPostalCode
                        ? this.interaction.Customer__r.PersonMailingPostalCode.substring(0, 5)
                        : undefined
                },
                cardNumber: '',
                cardNumberVisibleValue: '',
                cardNumberToken: '',
                expirationDate: '',
                securityCode: '',
                securityCodeVisibleValue: '',
                securityCodeToken: ''
            };
        }
    }

    /*
        Called from Continue button for Make Payment panel.
    */
    spiData = {spiDataList: []};
    async validateAutoPayDetails() {

        if (!this.showPaymentMethods) {
            throw new Error('No payment methods are available.');
        }

        // Get panel
        const panel = this.template.querySelector('div[data-name="enroll"');

        // Validate all inputs on payment panel
        let isValid = BwcUtils.reportValidity(panel, 'c-bwc-input-payment-method');

        if (!isValid) {
            throw new Error();
        }

    }

    /*
        Save the value from the input payment method component before moving to another step.
    */
    async saveAutoPayDetails() {

        // Get the payment method 
        this.paymentMethod = this.inputPaymentMethod.paymentMethod;

        this.spiData = this.inputPaymentMethod.spiDataValues;
        BwcUtils.log(`bwcAutoPayWizard spiData: ${JSON.stringify(this.spiData)}`);

    }

    /********************************************************************************************************/
    //#endregion

    //#region Review Payment Panel
    /********************************************************************************************************/

    tncVerbiage;
    tncId;
    tncKey;

    // Shown in yellow message bar
    get agreeToTermsCheckbox() {return this.template.querySelector('lightning-input[data-name="agreeToTerms"]');}

    /*
        Get terms and conditions and any other init for the review panel.
    */
    async loadReview() {

        // Always require re-confirm
        this.agreeToTermsCheckbox.checked = false;

        // Determine paymentEventType based upon whether saving profile
        const paymentEventType = this.autoPayDetails.savePaymentProfile ? BwcConstants.PaymentEventType.AP.value : BwcConstants.PaymentEventType.AE.value;

        this.tncId = undefined;
        this.tncKey = undefined;
        this.tncVerbiage = undefined;

        try {

            const termsAndConditions = await BwcPaymentServices.getTermsAndConditions(paymentEventType);

            this.tncId = parseInt(termsAndConditions.tncId__c, 10);
            this.tncKey = termsAndConditions.tncKey__c;
            this.tncVerbiage = termsAndConditions.tncVerbiage__c;

        }
        catch(e) {
            BwcUtils.error(e);
            this.tncVerbiage = `<span style="color: red;">${e.message ? e.message : JSON.stringify(e)}</span>`;
        }

    }

    /*
        Agree to terms checkbox clicked.
    */
    handleAgreeToTermsChange() {
     
        // Clear validity check each time it's changed
        const agreeToTerms = this.agreeToTermsCheckbox;
        agreeToTerms.setCustomValidity('');
        agreeToTerms.reportValidity();

    }

    /*
        Called from Submit Payment button for Review Payment panel.
    */    
    async completeEnrollment() {

        // Verify checkbox
        const agreeToTerms = this.agreeToTermsCheckbox;
        if (!agreeToTerms.checked) {

            agreeToTerms.setCustomValidity(this.labels.paymentAgreementVerify);
            agreeToTerms.reportValidity();
            throw new Error();

        }
        else {

            agreeToTerms.setCustomValidity('');
            agreeToTerms.reportValidity();

        }

        await this.postAutoPay();

    }

    /*
        Call API to make the payment.
    */
    async postAutoPay() {

        const autoPayProfile = {
            paymentPlanType: 'RECURRING',
            systemId: this.selectedPaymentDetails.banBillingIds.systemId,
            divisionId: this.selectedPaymentDetails.banBillingIds.divisionId,        
            accountNumber: this.selectedBan,
            accountType: this.selectedBillingAccount.Account_Type__c,
            storeTermsConditionConsent: true,
            tncId: this.tncId,
            customerAgreement: this.tncKey,
            paymentMethod: this.paymentMethod
        };

        try {

            this.wizard.setBusy(true);

            const response = await BwcPaymentServices.postAutoPayProfileRaisr(autoPayProfile, this.isEdit ? 'update' : 'add', this.spiData);

            // Check status
            if (response.content.responseCode !== '1') {
                throw new Error(response.content.message);
            }

            // Something succeeded, refresh
            publish(this.messageContext, REFRESHMC, {scope: 'autoPayProfiles', recordId: this.recordId});

        }
        finally {

            this.wizard.setBusy(false);

        }

    }

    /*
        Call API to update the payment profile.
    */
    async updateAutoPay() {

        const autoPayProfile = {
            paymentPlanType: 'RECURRING',
            systemId: this.selectedPaymentDetails.banBillingIds.systemId,
            divisionId: this.selectedPaymentDetails.banBillingIds.divisionId,        
            accountNumber: this.selectedBan,
            accountType: this.selectedBillingAccount.Account_Type__c,
            storeTermsConditionConsent: true,
            tncId: this.tncId,
            customerAgreement: this.tncKey,
            paymentMethod: this.paymentMethod
        };

        try {

            this.wizard.setBusy(true);

            const response = await BwcPaymentServices.postAutoPayProfileRaisr(autoPayProfile, this.isEdit ? 'update' : 'add', this.spiData);

            // Check status
            if (response.content.responseCode !== '1') {
                throw new Error(response.content.message);
            }

            // Something succeeded, refresh
            publish(this.messageContext, REFRESHMC, {scope: 'autoPayProfiles', recordId: this.recordId});

        }
        finally {

            this.wizard.setBusy(false);

        }

    }

    /********************************************************************************************************/
    //#endregion

    //#region Confirmation Panel
    /********************************************************************************************************/    

    confirmationMessage;

    /*
        Set values for rendering of confirmation panel.
    */
    loadConfirmation() {

        let last4;
        if (this.paymentMethod.card) {
            last4 = this.cardLast4;
        }
        else if (this.paymentMethod.bankAccount) {
            last4 = this.bankAccountLast4;
        }

        this.confirmationMessage = this.labels.enrollmentSuccessMessage.replace('{0}', last4);

    }

    get cardLast4() {
        if (this.spiData.spiDataList && this.spiData.spiDataList.length > 0) {
            const cardNumber = this.spiData.spiDataList.find(data => data.name === BwcPayments.PaymentSmartFields.CARD_NUMBER);
            return cardNumber.value ? cardNumber.value.substring(cardNumber.value.length - 4) : undefined;
        } else {
            const cardNumber = this.paymentMethod.card.cardNumber;
            return cardNumber ? cardNumber.substring(cardNumber.length - 4) : undefined;
        }
    }

    get bankAccountLast4() {
        if (this.spiData.spiDataList && this.spiData.spiDataList.length > 0) {
            const accountNumber = this.spiData.spiDataList.find(data => data.name === BwcPayments.PaymentSmartFields.BANK_ACCOUNT_NUMBER);
            return accountNumber.value ? accountNumber.value.substring(accountNumber.value.length - 4) : undefined;
        } else {
            const accountNumber = this.paymentMethod.bankAccount.bankAccountNumber;
            return accountNumber ? accountNumber.substring(accountNumber.length - 4) : undefined;
        }
    }

    /********************************************************************************************************/    
    //#endregion

}