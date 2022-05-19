import { LightningElement, api, track, wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import * as BwcConstants from 'c/bwcConstants';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcAccountServices from 'c/bwcAccountServices';
import * as BwcPayments from 'c/bwcPayments';
import * as BwcPaymentServices from 'c/bwcPaymentServices';
import * as BwcLabelServices from 'c/bwcLabelServices';
import REFRESHMC from '@salesforce/messageChannel/BWC_Refresh__c';
import { createActivity, InteractionActivityValueMapping } from 'c/bwcInteractionActivityService';

// Labels
import label_profileNameExists from '@salesforce/label/c.BWC_ProfileNameExists';

const DEFAULT_MIN_HEIGHT = 240;      // Pixels, min height of a panel, needed to manage scrolling behavior
const AUTOPAY_SUCCESS_CODE = '1';
const AUTOPAY_PAYMENT_PLAN_TYPE = 'RECURRING';

export default class BwcPaymentProfileAddEdit extends LightningElement {

    // Labels
    labels = BwcLabelServices.labels;

    // Needed to send refresh message
    @wire(MessageContext)
    messageContext;

    interactionId;
    profileToEdit;
    mode = BwcPaymentServices.PostPaymentProfileMode.ADD;

    @track paymentMethod = {
        type: BwcPayments.PaymentMethodType.BANKACCOUNT.value,
        paymentMethodType: BwcPayments.PaymentMethodType.BANKACCOUNT.value,
        card: {
            billingAddress: {}
        },
        bankAccount: {}
    };

    // Controls the displayed steps
    @track steps = [
        {
            name: 'selectAccount',
            title: '<b>Select Account</b>',
            panelNumber: 0,
            minHeight: DEFAULT_MIN_HEIGHT,
            isDisabled: true,
            rightButton: {
                name: 'continue',
                label: 'Continue',
                action: this.selectAccount.bind(this)
            }
        },
        {
            name: 'addEdit',
            panelNumber: 1,
            minHeight: DEFAULT_MIN_HEIGHT,
            leftButton: {
                name: 'previous',
                label: 'Previous'
            },
            rightButton: {
                name: 'continue',
                label: 'Continue',
                action: this.validateProfile.bind(this)
            },
        },
        {
            name: 'review',
            panelNumber: 2,
            minHeight: DEFAULT_MIN_HEIGHT,
            initAction: this.initReview.bind(this),
            leftButton: {
                name: 'editPaymentInfo',
                label: 'Edit Profile Info'
            },
            rightButton: {
                name: 'saveProfile',
                label: 'Save Profile',
                action: this.saveProfile.bind(this)
            }
        }

    ];

    // All billing accounts for the person account, use for multi-selection
    billingAccounts = [];
    @track billingAccountOptions = [];
    selectedBan;
    selectedBillingAccount = {};
    selectedAccountType;
    selectedService;

    // Information from the BSSe customer if applicable
    isBSSeCustomer;
    selectedIndividualId; // Individual ID from Person Account
    selectedCustomer; // Person account record 

    // Billing account's existing saved payment profiles
    @track existingProfiles = [];

    // Terms and conditions
    tncVerbiage;
    tncId;
    tncKey;

    // Autopay
    enrollInAutopay; //value from checkbox
    alreadyEnrolledAutopay; //Value from API
    get showEnrollInAutopay() { return this.isBSSeCustomer ? false : true; }
    get autoPayLabel() {
        return this.alreadyEnrolledAutopay ? this.labels.updateAutoPay : this.labels.enrollAutoPay;
    }

    //banBillingIds. system & division Id
    banBillingIds;

    // RAISR
    get raisrContext() {
        return this.mode === BwcPaymentServices.PostPaymentProfileMode.ADD ? BwcPayments.RaisrContext.ADD_PAYMENT_PROFILE.value : BwcPayments.RaisrContext.UPDATE_PAYMENT_PROFILE.value;
    }
    spiData = {
        spiDataList: []
    }

    // Components
    get wizard() {return this.template.querySelector('c-bwc-wizard');}
    get inputPaymentMethod() {return this.template.querySelector('c-bwc-input-payment-method');}

    /*
        Called from host component to open with specified person account.
    */
    @api async open(interactionId, profileToEdit, isBSSeCustomer) {

        this.profileToEdit = BwcUtils.cloneObject(profileToEdit);
        
        if (this.profileToEdit) {

            BwcUtils.log(`Profile to edit: ${JSON.stringify(profileToEdit)}`);

            if (this.profileToEdit.card) {
                this.profileToEdit.card.billingAddress = {
                    zipCode: this.profileToEdit.card.zipCode
                };
                this.profileToEdit.card.zipCode = undefined;
            }

        }

        this.interactionId = interactionId;
        this.isBSSeCustomer = isBSSeCustomer;
        this.mode = profileToEdit ? BwcPaymentServices.PostPaymentProfileMode.UPDATE : BwcPaymentServices.PostPaymentProfileMode.ADD;
        this.wizard.defaultTitle = this.mode === BwcPaymentServices.PostPaymentProfileMode.ADD ? '<b>Add a New Payment Profile</b>' : '<b>Edit Payment Profile</b>';
        this.wizard.setStepTitle('addEdit', this.mode === BwcPaymentServices.PostPaymentProfileMode.ADD ? '<b>Add a New Payment Profile</b>' : '<b>Edit Payment Profile</b>');
        this.wizard.setStepTitle('review', this.mode === BwcPaymentServices.PostPaymentProfileMode.ADD ? '<b>Review New Payment Profile</b>' : '<b>Review Updated Payment Profile</b>');
        this.wizard.open(() => this.initialize());

    }

    close() {
        this.wizard.close();
    }

    /*
        Called by open to initialize component.
    */
    async initialize() {

        // Reset everything
        this.paymentMethod = {
            type: BwcPayments.PaymentMethodType.BANKACCOUNT.value,
            paymentMethodType: BwcPayments.PaymentMethodType.BANKACCOUNT.value,
            card: {
                billingAddress: {}
            },
            bankAccount: {}
        };

        this.existingProfiles = [];
        this.tncKey = undefined;
        this.tncId = undefined;
        this.tncVerbiage = undefined;
        this.enrollInAutopay = false;

        this.spiData = {
            spiDataList: []
        }

        // if BSSe Customer, relate payment to individual
        if (this.isBSSeCustomer) {

            this.selectedIndividualId = undefined;
            this.selectedCustomer = {};

            this.selectedCustomer = await BwcAccountServices.getCustomerAccount(this.interactionId);

            if (this.mode === BwcPaymentServices.PostPaymentProfileMode.UPDATE) {
                // Initialize the payment method
                this.paymentMethod = {
                    type: this.profileToEdit.paymentMethodType,
                    card: this.profileToEdit.card ? this.profileToEdit.card : undefined,
                    bankAccount: this.profileToEdit.bankAccount ? this.profileToEdit.bankAccount : undefined
                };
            }

            await this.setSelectedBSSeCustomer(this.selectedCustomer);

        } 
        // Non BSSe customer, use original process with billing accounts
        else {

            this.selectedBillingAccount = {};
            this.billingAccounts = [];
            this.billingAccountOptions = [];

            // Get all billing accounts for the person account
            this.billingAccounts = await BwcAccountServices.getBillingAccounts(this.interactionId, true, true, BwcConstants.PaymentBillingAccountTypes);

            if (this.mode === BwcPaymentServices.PostPaymentProfileMode.ADD) {

                if (this.billingAccounts.length === 1) {

                    // There's only one billing account, just use it without requiring selection

                    // Don't need selection step
                    this.wizard.enableStep('selectAccount', false);

                    // This will reset busy when completed
                    await this.setSelectedBillingAccount(this.billingAccounts[0]);

                }
                else {

                    // There's multiple, need to select
                    this.wizard.enableStep('selectAccount');

                    // Build selection list of billing accounts
                    this.billingAccountOptions = this.billingAccounts.map(billingAccount => {
                        return {
                            label: billingAccount.Service_Label__c,
                            value: billingAccount.Billing_Account_Number__c
                        };
                    });

                    this.wizard.setBusy(false);

                }
            }
            else {

                // Editing a profile, don't need account selection step because it's related to a single ban
                this.wizard.enableStep('selectAccount', false);

                // Find billing account corresponding to the profile being edited
                const billingAccount = this.billingAccounts.find(account => account.Billing_Account_Number__c === this.profileToEdit.ban);
                if (!billingAccount) {
                    throw new Error('Unable to find billing account corresponding to the profile.');
                }

                // Initialize the payment method
                this.paymentMethod = {
                    type: this.profileToEdit.paymentMethodType,
                    card: this.profileToEdit.card ? this.profileToEdit.card : undefined,
                    bankAccount: this.profileToEdit.bankAccount ? this.profileToEdit.bankAccount : undefined
                };

                await this.setSelectedBillingAccount(billingAccount);

            }
        }

        return undefined;

    }

    /*
        Called from Continue button for Select Account panel.
    */
    async selectAccount() {

        // Get Select Account panel
        const panel = this.template.querySelector('div[data-name="selectAccount"');

        // Validate all inputs on Select Account panel
        let isValid = BwcUtils.reportValidity(panel);

        if (!isValid) {
            throw new Error();
        }

        // Get billing account
        const billingAccount = this.billingAccounts.find(account => account.Billing_Account_Number__c === this.selectedBan);

        return this.setSelectedBillingAccount(billingAccount);

    }

    /*
        Set billing account as selected by user.
    */
    async setSelectedBillingAccount(billingAccount) {

        this.selectedBan = billingAccount.Billing_Account_Number__c;
        this.selectedBillingAccount = billingAccount;
        this.selectedAccountType = billingAccount.Account_Type__c;
        this.selectedService = billingAccount.Service_Label__c;

        const defaultBankAccount = {
            accountType: BwcConstants.BankAccountType.CHECKING.value,
            accountHolderName: this.selectedBillingAccount.First_Name__c + ' ' + this.selectedBillingAccount.Last_Name__c,
            routingNumber: '',
            bankAccountNumber: '',
            bankAccountNumberVisibleValue: '',
            bankAccountNumberToken: ''
        };
        const defaultCard = {
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

        const banLabel = `${this.labels.account} #${this.selectedBan} (${BwcConstants.BillingAccountType.getLabelForValue(this.selectedAccountType)})`;
        this.wizard.setStepTitle('addEdit', this.mode === BwcPaymentServices.PostPaymentProfileMode.ADD 
            ? `<b>Add a New Payment Profile:</b> ${banLabel}`
            : `<b>Edit Payment Profile:</b> ${banLabel}`);
        this.wizard.setStepTitle('review', this.mode === BwcPaymentServices.PostPaymentProfileMode.ADD
            ? `<b>Review New Payment Profile:</b> ${banLabel}`
            : `<b>Review Updated Payment Profile:</b> ${banLabel}`);

        // Get existing profiles to prevent duplication
        await this.getExistingProfiles();

        this.inputPaymentMethod.initialize(undefined, undefined, undefined, this.mode === BwcPaymentServices.PostPaymentProfileMode.ADD ? undefined : this.paymentMethod, defaultBankAccount, defaultCard, undefined);

    }

    /*
        Set billing account as selected by user.
    */
    async setSelectedBSSeCustomer(customerAccount) {

        this.selectedIndividualId = customerAccount.Individual_ID__c;

        const defaultBankAccount = {
            accountType: BwcConstants.BankAccountType.CHECKING.value,
            accountHolderName: customerAccount.FirstName + ' ' + customerAccount.LastName,
            routingNumber: '',
            bankAccountNumber: '',
            bankAccountNumberToken: ''
        };
        const defaultCard = {
            cardHolderName: customerAccount.FirstName + ' ' + customerAccount.LastName,
            billingAddress: {
                zipCode: customerAccount.PersonMailingPostalCode
                    ? customerAccount.PersonMailingPostalCode.substring(0, 5)
                    : undefined
            },
            cardNumber: '',
            cardNumberToken: '',
            expirationDate: '',
            securityCode: '',
            securityCodeToken: ''
        };

        this.wizard.setStepTitle('addEdit', this.mode === BwcPaymentServices.PostPaymentProfileMode.ADD 
            ? `<b>Add a New Payment Profile</b>`
            : `<b>Edit Payment Profile</b>`);
        this.wizard.setStepTitle('review', this.mode === BwcPaymentServices.PostPaymentProfileMode.ADD
            ? `<b>Review New Payment Profile</b>`
            : `<b>Review Updated Payment Profile</b>`);

        // Get existing profiles to prevent duplication
        await this.getExistingProfiles();

        this.inputPaymentMethod.initialize(undefined, undefined, undefined, this.mode === BwcPaymentServices.PostPaymentProfileMode.ADD ? undefined : this.paymentMethod, defaultBankAccount, defaultCard, this.isBSSeCustomer);

    }

    /*
        Retrieve all existing saved profiles.
    */
    async getExistingProfiles() {

        this.wizard.setBusy(true);
        try {

            const topics = [BwcConstants.PaymentDetailTopic.PAYMENT_PROFILES.value];

            if(!this.isBSSeCustomer){
                topics.push(
                    BwcConstants.PaymentDetailTopic.BAN_BILLING_IDS.value,
                    BwcConstants.PaymentDetailTopic.AUTOPAY.value
                );
            }

            const getPaymentDetailsResponses = await BwcPaymentServices.getPaymentDetails({
                recordId: this.interactionId,
                bans: [this.selectedBillingAccount.Billing_Account_Number__c],
                topics,
            });

            if (getPaymentDetailsResponses[0].paymentProfiles) {
                this.existingProfiles = getPaymentDetailsResponses[0].paymentProfiles.paymentProfileList;
            }
            else {
                this.existingProfiles = [];
            }

            if (!this.existingProfiles) {
                this.existingProfiles = [];
            }

            this.alreadyEnrolledAutopay = getPaymentDetailsResponses[0].autopay?.responseCode === AUTOPAY_SUCCESS_CODE;

            this.banBillingIds = getPaymentDetailsResponses[0].banBillingIds;

        }
        finally {
            this.wizard.setBusy(false);
        }

    }

    async validateProfile() {

        // Get panel
        const panel = this.template.querySelector('div[data-name="addNewPaymentProfile"');

        // Validate all inputs on panel
        let isValid = BwcUtils.reportValidity(panel, 'c-bwc-input-payment-method');

        BwcUtils.log(`validateProfile this.inputPaymentMethod.paymentMethod: ${JSON.stringify(this.inputPaymentMethod.paymentMethod)}`);

        if (!isValid) {
            throw new Error();
        }

        // Retrieve updated values
        this.paymentMethod = new BwcPayments.PaymentMethod(this.inputPaymentMethod.paymentMethod);

        const spiData = this.inputPaymentMethod.spiDataValues;

        // Check for duplicate
        // Check if adding new, or if editing and the name is changing because it might conflict with existing
        if ((this.mode === BwcPaymentServices.PostPaymentProfileMode.ADD ||
            (this.mode === BwcPaymentServices.PostPaymentProfileMode.UPDATE && this.profileToEdit.profileName !== this.paymentMethod.getProfileName(spiData))) &&
            this.existingProfiles.find(profile => profile.profileName === this.paymentMethod.getProfileName(spiData))) {
            throw new Error(label_profileNameExists);

        }

    }

    /*
        Get terms and conditions and any other init for the review panel.
    */
    async initReview() {

        // Determine single paymentEventType based upon autopay conditions
        const paymentEventType = this.enrollInAutopay ? BwcConstants.PaymentEventType.AP.value : BwcConstants.PaymentEventType.PP.value;

        this.tncId = undefined;
        this.tncKey = undefined;
        this.tncVerbiage = undefined;

        this.spiData = this.inputPaymentMethod.spiDataValues;

        try {

            const termsAndConditions = await BwcPaymentServices.getTermsAndConditions(paymentEventType);
            this.tncId = parseInt(termsAndConditions.tncId__c, 10);
            this.tncKey = termsAndConditions.tncKey__c;
            this.tncVerbiage = termsAndConditions.tncVerbiage__c;

        }
        catch (e) {

            this.tncVerbiage = `<span style="color: red;">${e.message}</span>`;

        }

    }

    async saveProfile() {
        
        // Verify checkbox
        const agreeToTerms = this.template.querySelector('lightning-input[data-name="agreeToTerms"]');
        if (!agreeToTerms.checked) {

            agreeToTerms.setCustomValidity(this.labels.paymentAgreementVerify);
            agreeToTerms.reportValidity();
            throw new Error();

        }
        else {

            agreeToTerms.setCustomValidity('');
            agreeToTerms.reportValidity();

        }

        // Get payment method
        const paymentMethod = new BwcPayments.PaymentMethod(this.inputPaymentMethod.paymentMethod);

        // Build profile
        let paymentProfile = {};
        if (this.selectedBillingAccount.Billing_Account_Number__c) {

            paymentProfile = {
                accountType: this.selectedBillingAccount.Account_Type__c,
                lastName: this.selectedBillingAccount.Last_Name__c,
                firstName: this.selectedBillingAccount.First_Name__c,
                accountId: this.selectedBillingAccount.Billing_Account_Number__c,
                storeTermsAndConditionsConsent: false,
                tncId: this.tncId,
                customerAgreement: this.tncKey,
                profileName: paymentMethod.getProfileName(this.spiData),
                paymentMethod: BwcUtils.cloneObject(paymentMethod)

            };

        } else {

            paymentProfile = {
                individualId: this.selectedIndividualId,
                tncId: this.tncId,
                profileName: paymentMethod.getProfileName(this.spiData),
                storeTermsAndConditionsConsent: false,
                customerAgreement: this.tncKey,
                paymentMethod: BwcUtils.cloneObject(paymentMethod),
                paySource: {
                    sourceSystem: BwcPayments.PaymentProfilePaySource.BSSE_CUSTOMERS.SOURCE_SYSTEM,
                    sourceLocation: BwcPayments.PaymentProfilePaySource.BSSE_CUSTOMERS.SOURCE_LOCATION
                }
            };

        }
        // BSSe
        if (this.mode === BwcPaymentServices.PostPaymentProfileMode.UPDATE && !this.selectedBillingAccount.Billing_Account_Number__c) {

            // Remove masked fields for update
            delete paymentProfile.paymentMethod.card?.cardNumber;

            // Since it's update set previous profile name
            paymentProfile.profileName = this.profileToEdit.profileName;

            // Update payment profile
            const updateResponse = await BwcPaymentServices.postPaymentProfileRaisr(paymentProfile, BwcPaymentServices.PostPaymentProfileMode.UPDATE, this.spiData);

            if (updateResponse.content.responseCode !== '1') {
                throw new Error(updateResponse.content.message);
            }
            this.logInteractionActivityUpdate();
        }
        // Non BSSe
        else if (this.mode === BwcPaymentServices.PostPaymentProfileMode.UPDATE && paymentProfile.profileName !== this.profileToEdit.profileName) {

            // Add new
            const addResponse = await BwcPaymentServices.postPaymentProfileRaisr(paymentProfile, BwcPaymentServices.PostPaymentProfileMode.ADD, this.spiData);

            if (addResponse.content.responseCode !== '1') {
                throw new Error(addResponse.content.message);
            }

            // Delete old
            let profileToDelete = {
                accountType: this.selectedBillingAccount.Account_Type__c,
                lastName: this.profileToEdit.lastName,
                firstName: this.profileToEdit.firstName,
                accountId: this.selectedBillingAccount.Billing_Account_Number__c,
                profileName: this.profileToEdit.profileName
            }

            const deleteResponse = await BwcPaymentServices.postPaymentProfileRaisr(profileToDelete, BwcPaymentServices.PostPaymentProfileMode.DELETE, this.spiData);

            if (deleteResponse.content.responseCode !== '1') {
                throw new Error(deleteResponse.content.message);
            }
            this.logInteractionActivityUpdate();
        }
        else {

            const response = await BwcPaymentServices.postPaymentProfileRaisr(paymentProfile, this.mode, this.spiData);

            if (response.content.responseCode !== '1') {
                throw new Error(response.content.message);
            }

        }

        // Only for non BSSe. if user checks autopay, either create or update the autopay profile.
        if(this.enrollInAutopay && this.selectedBillingAccount.Billing_Account_Number__c){

            await this.postAutoPay(paymentProfile, this.alreadyEnrolledAutopay);
        }

        if (this.mode === BwcPaymentServices.PostPaymentProfileMode.ADD) {
            this.logInteractionActivityAdd();

            this.dispatchEvent(new ShowToastEvent({
                message: `Payment Profile "${paymentProfile.profileName}" has been successfully added.`,
                variant: 'success'
            }));

        }

        if (this.mode === BwcPaymentServices.PostPaymentProfileMode.UPDATE) {

            this.dispatchEvent(new ShowToastEvent({
                message: `Payment Profile "${paymentProfile.profileName}" has been successfully updated.`,
                variant: 'success'
            }));

        }

        // Refresh Payment Profiles table
        publish(this.messageContext, REFRESHMC, {scope: 'paymentProfiles', recordId: this.interactionId});

        // Refresh AutoPay Profiles table
        publish(this.messageContext, REFRESHMC, {scope: 'autoPayProfiles', recordId: this.recordId});

        this.close();

    }

    /*
        Any custom validation.
    */
    handleInputValidate(event) {
     
        switch(event.target.name) {

            case 'agreeToTerms':
                // Clear validity check each time it's changed
                event.target.setCustomValidity('');
                event.target.reportValidity();
                break;

            default:
                break;

        }

    }

    /*
        Input or combo changed.
    */
    handleInputCommit(event) {

        // Don't take new value unless valid
        if (!event.target.checkValidity()) {
            return;
        }

        switch(event.target.name) {

            case 'selectBillingAccount':
                this.selectedBan = event.target.value;
                break;

            case 'enrollInAutopay':
                this.enrollInAutopay = event.target.checked;
                break;

            default:
                break;

        }

    }

    /*
        Wizard closed -- bubble the close event up to any enclosing quick action.
    */
    handleWizardClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    /**
     * @param  {Object} profile payment profile that will be created/updated
     * @param  {Boolean} isEdit flag to identify whether we need to update or create the autopay profile
     */
    async postAutoPay(profile, isEdit) {

        const autoPayProfile = {
            paymentPlanType: AUTOPAY_PAYMENT_PLAN_TYPE,
            systemId: this.banBillingIds?.systemId,
            divisionId: this.banBillingIds?.divisionId,
            accountNumber: this.selectedBillingAccount.Billing_Account_Number__c,
            accountType: this.selectedBillingAccount.Account_Type__c,
            storeTermsConditionConsent: true,
            tncId: this.tncId,
            customerAgreement: this.tncKey,
            paymentMethod: profile.paymentMethod,
        };

        const response = await BwcPaymentServices.postAutoPayProfileRaisr(autoPayProfile, isEdit ? 'update' : 'add', this.spiData);

        // Check status
        if (response.content.responseCode !== '1') {
            throw new Error(response.content.message);
        }

    }

       
    async logInteractionActivityAdd(){
        let detailRecord;
        let paymentMethodInput = JSON.stringify(this.inputPaymentMethod.paymentMethod.type);

        if(this.isBSSeCustomer === true){
            detailRecord = {
                "recordId": this.interactionId,
                "individualId": this.selectedIndividualId, 
                "paymentMethod": paymentMethodInput, 
                "status": 'Success', 
                "errorMessage": '' ,
            }
        }

        if(this.isBSSeCustomer === false) {
            detailRecord = {
                "recordId": this.interactionId,
                "service": this.selectedAccountType,                        
                "serviceName": this.selectedService,                                                       
                "ban": this.selectedBan,           
                "paymentMethod": paymentMethodInput,
                "status": 'Success', 
                "errorMessage": '' ,
            }
        }
        createActivity(this.interactionId, InteractionActivityValueMapping.BillingPaymentAddProfile, detailRecord);
    }

    async logInteractionActivityUpdate(){
        let detailRecord;
        let paymentMethodInput = JSON.stringify(this.inputPaymentMethod.paymentMethod.type);

        if(this.isBSSeCustomer === true){ 
            detailRecord = {
                "recordId": this.interactionId,
                "individualId": this.selectedIndividualId,                                                        
                "paymentMethodOld": this.profileToEdit.paymentMethodType,                  
                "paymentMethodNew": paymentMethodInput,                
                "status": 'Success', 
                "errorMessage": '' ,
            }
        } 

        if(this.isBSSeCustomer === false) {
            detailRecord = {
                "recordId": this.interactionId,
                "service": this.selectedAccountType,       
                "serviceName": this.selectedService,                                            
                "ban": this.profileToEdit.ban,
                "paymentMethodOld": this.profileToEdit.paymentMethodType,                    
                "paymentMethodNew": paymentMethodInput,                    
                "status": 'Success', 
                "errorMessage": '' ,
            }
        }
        createActivity(this.interactionId, InteractionActivityValueMapping.BillingPaymentUpdateProfile, detailRecord);
    } 
}