import { api, wire } from 'lwc';
import BwcPageElementBase from 'c/bwcPageElementBase';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import * as BwcUtils from 'c/bwcUtils';
import * as BwcConstants from 'c/bwcConstants';
import * as BwcAdjustments from 'c/bwcAdjustments';
import * as BwcAccountServices from 'c/bwcAccountServices';
import * as BwcAssetServices from 'c/bwcAssetServices';
import * as BwcChargeServices from 'c/bwcChargeServices';
import * as BwcChargeCodeServices from 'c/bwcChargeCodeServices';
import * as BwcInteractActivityPublisher from 'c/bwcInteractActivityPublisher';

const DEFAULT_ADJUSTMENT_TYPE = 'Charge';

const DEFAULT_HOW_TO_APPLY_OPTION = { value: 'immediately', label: 'Immediately'};

const DEFAULT_CHARGE_LEVEL_OPTION = { value: 'accountLevel', label: 'Account Level' };

const INTERACTION_FIELDS = [
    'Interaction__c.Authorization_Json__c',
    'Interaction__c.CTI_Call_Identifier__c',
    'Interaction__c.Primary_Contact_Number__c'
]

const BILLING_ACCOUNT_TYPES = [
    BwcConstants.BillingAccountType.WIRELESS.value
];

export default class BwcAddNewChargeWizard extends BwcPageElementBase {

    labels = BwcAdjustments.labels;

    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: INTERACTION_FIELDS }) 
    interaction;

    get authorizationData() {
        // Authorization_JSON__c returns a json object that must be parsed before use.
        return this.interaction.data 
            ? JSON.parse(getFieldValue(this.interaction.data, 'Interaction__c.Authorization_Json__c')) 
            : '';
    }

    get batchId() {
        return getFieldValue(this.interaction.data, 'Interaction__c.CTI_Call_Identifier__c');
    }

    get primaryContactNumber() {
        return getFieldValue(this.interaction.data, 'Interaction__c.Primary_Contact_Number__c');
    }

    /* Select BAN Form */
    billingAccounts = [];
    billingAccountOptions = [];
    selectedBillingAccount;
    get selectedBan() { return this.selectedBillingAccount.Billing_Account_Number__c; }
    /* Add New Charge Top Form */
    customerFirstName;
    customerLastName;
    serviceType;
    creationDate;
    /* Add New Charge Bottom Form */
    adjustmentType;
    chargeReasons = []; // based on the billing account market
    howToApplyOptions = []; // Apply to account level or specific CTN
    chargeLevels = [];
    chargeAmount;
    chargeReasonOptions = [];

    /***  UI ***/
    _isRendered = false;
    isLoading = false;
    chargeAmountDisabled = false;

    get form() { 
        return this.template.querySelector('div[data-name="addNewChargeForm"]'); 
    }

    getField(dataId) {
        return this.template.querySelector("[data-id='" + dataId + "']");
    }

    get filteredChargeReasonOptions() {
        return this.chargeReasons
        .filter( chargeReason => chargeReason.Charge_Level__c === this.chargeLevel)
        .map( chargeReason => {
            return {
                label: chargeReason.Charge_Code__c + ' - ' + chargeReason.Charge_Code_Description__c,
                value: chargeReason.Charge_Code__c
            }
        });
    }

    get selectedChargeReason() {
        return this.getField("chargeReason").value;
    }

    // alias
    get chargeCode() {
        return this.selectedChargeReason;
    }

    get chargeId() {
        return this.chargeReasons.find(chargeReason => chargeReason.Charge_Code__c === this.chargeCode).Id;
    }

    get selectedHowToApply() {
        return this.getField("howToApply").value;
    }

    get selectedChargeLevel() {
        return this.getField("chargeLevel").value;
    }

    get selectedChargeAmount() {
        return this.getField("chargeAmount").value.replace(/\$|,/g, '');
    }

    get chargeLevel() {
        return this.selectedChargeLevel === DEFAULT_CHARGE_LEVEL_OPTION.value ? 'B' : 'S';
    }

    get subscriberNumber() {
        return this.selectedChargeLevel === DEFAULT_CHARGE_LEVEL_OPTION.value ? '' : this.selectedChargeLevel;
    }

    get comments() {
        return this.getField("comments").value;
    }

    /***  LWC Callbacks ***/
    renderedCallback() {
        
        if(!this._isRendered) {

            this._isRendered = true;
            
            this.open();
        }
    }
    
    /*** Wizard ***/
    get wizardDefaultTitle() {
        return '<b>Add New Charge</b>';
    } 

    wizardSteps = [
        {
            name: 'selectBan',
            title: '<b>Add New Charge:</b> Select BAN',
            panelNumber: 0,
            minHeight: 165,
            rightButton: {
                name: "continue",
                label: "Continue",
                action: this.selectBan.bind(this)
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
            name: 'addNewCharge',
            title: `<b>Add New Charge:</b> ${this.labels.account}# `, // + this.selectedBan ,
            panelNumber: 1,
            minHeight: 165,
            leftButton: {
                name: "back",
                label: "Back"
            },
            rightButton: {
                name: "submit",
                label: "Submit",
                action: this.addNewCharge.bind(this)
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

    open() {
        this.wizard.open(() => this.initialize());
    }

    close() {
        this.wizard.close();
    }

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

        this.selectedBillingAccount = null;
        this.adjustmentType = DEFAULT_ADJUSTMENT_TYPE;

        // Build selection list of billing accounts
        this.billingAccounts = await BwcAccountServices.getBillingAccounts(this.recordId, true, false, BILLING_ACCOUNT_TYPES)
        
        this.billingAccountOptions = this.billingAccounts.map(billingAccount => {
            return {
                label: billingAccount.Service_Label__c,
                value: billingAccount.Billing_Account_Number__c
            }
        });

        if(this.billingAccountOptions.length === 0) {

            super.showToast(null, this.labels.noBillingAccountWithAuthorization, 'error');

            this.close();
        }

        this.wizard.enableStep('addNewCharge');
        this.wizard.enableButton('addNewCharge', 'right', true);

        if(this.billingAccountOptions.length > 1) {
            // Enable first step if they need to select a billing account
            this.wizard.enableStep('selectBan');
            // Disable next step until an account is selected.
            this.wizard.enableButton('selectBan', 'right', false);
        }
        else if(this.billingAccountOptions.length === 1) {
            // Skip this step if we only have a single account
            this.wizard.enableStep('selectBan', false);
            this.selectedBillingAccount = this.billingAccounts[0];            
            this.initAddNewCharge();
        }

        // Set all cancel button labels
        this.wizard.setButtonLabel('selectBan', 'cancel', 'Cancel');
    }

    /*
        Called from Continue button for Select BAN panel
    */
    async selectBan() {
        this.initAddNewCharge();

        this.wizard.gotoNextEnabledStep();
    }
    
    /*
        Set Add New Charge Data based on selected Billing Account
    */
    async initAddNewCharge() 
    {
        this.isLoading = true;
        this.wizard.setStepTitle('addNewCharge', `<b>Add New Charge:</b> ${this.labels.account}# ${this.selectedBillingAccount.Billing_Account_Number__c}`);

        this.customerFirstName = this.selectedBillingAccount.First_Name__c;
        this.customerLastName = this.selectedBillingAccount.Last_Name__c;
        this.serviceType = BwcConstants.BillingAccountType.getLabelForValue(this.selectedBillingAccount.Account_Type__c);
        this.creationDate = Date.now();

        try {
            this.chargeReasons = await BwcChargeCodeServices.getChargeCodesByMarket(this.selectedBillingAccount.Billing_Market__c);

            this.chargeReasonOptions = this.filteredChargeReasonOptions;

            this.howToApplyOptions = [ DEFAULT_HOW_TO_APPLY_OPTION ];

            // Set the charge levels
            let chargeLevels = [ DEFAULT_CHARGE_LEVEL_OPTION ];

            let products = await BwcAssetServices.getAssetsForBillingAccounts( 
                [this.selectedBillingAccount.Id] 
            );

            products.forEach(product => {
                const ctn = product.Phone_Number__c;
                chargeLevels.push({
                    label: BwcUtils.formatPhone(ctn),
                    value: ctn
                });
            });

            this.chargeLevels = chargeLevels;

            this.wizard.enableButton('addNewCharge', 'right', false);

            this.isLoading = false;

        } catch( error ) {
            
            super.showToast(null, this.labels.noBillingMarketCharges, 'error');
            
            this.wizard.close();
        }
    }

    /*
        Called from Submit button for Add New Charge panel
    */
    async addNewCharge() {
        
        this.isLoading = true;
        this.wizard.enableButton('addNewCharge', 'right', false);
        this.wizard.enableButton('addNewCharge', 'cancel', false);

        const request = {
            accountNumber: this.selectedBillingAccount.Billing_Account_Number__c,
            accountType: this.selectedBillingAccount.Account_Type__c,
            marketCode: this.selectedBillingAccount.Billing_Market__c,
            chargeInfo: [
                {
                    chargeId: this.chargeId,
                    batchId: this.batchId,
                    chargeAmount: this.selectedChargeAmount,
                    chargeCode: this.chargeCode,
                    effectiveDate: this.selectedHowToApply === DEFAULT_HOW_TO_APPLY_OPTION.value ? BwcUtils.toIsoDate(new Date()) : this.selectedHowToApply,
                    chargeLevel: this.chargeLevel,
                    transactionId: BwcUtils.generateUUID(),
                    userBillText: this.comments
                }
            ]
        };
        
        if(this.chargeLevel === 'S') {
            request.chargeInfo[0].subscriberNumber = this.subscriberNumber;
        }

        try {
            
            let result = await BwcChargeServices.createCharge(this.recordId, request);

            this.isLoading = false;
            
            if(result.errors) {

                throw new Error(this.labels.failedToCreateCharge);

            }
            
            // Create Interaction Activity Record of Charge
            BwcInteractActivityPublisher.publishMessage(
                this.recordId, 
                BwcConstants.InteractionActivityValueMapping.BillingAdjustmentsAdjustmentsAddCharge.action, 
                JSON.stringify({
                    recordId: this.recordId,
                    ban: this.accountNumber,
                    chargeInfo: {
                        chargeAmount: this.selectedChargeAmount,
                        chargeCode: this.chargeCode,
                        chargeLevel: this.chargeLevel,
                        subscriberNumber: this.subscriberNumber
                    }
                }), 
                null
            );

            super.sendLmsRefresh(this.recordId, 'pendingChargesCredits');

            const message = 'A Charge of ' + BwcUtils.formatCurrency(this.selectedChargeAmount) + ' has successfully been posted to account ' + this.selectedBan;

            super.showToast(null, message, 'success');

            this.close();
            
        } catch(error) {
            
            this.isLoading = false;

            this.wizard.enableButton('addNewCharge', 'cancel', true);

            super.handleError(error, this.labels.unexpectedError, 'Add New Charge Wizard', 'inline');
        }
    }
    /*** End Wizard ***/

    /*** Error Reporting ***/
    checkValidity(template) {
        return BwcUtils.checkValidity(template, 'lightning-textarea');
    }

    reportValidity(template) {
        return BwcUtils.reportValidity(template, 'lightning-textarea');
    }

    /*** Event Handlers ***/
    handleBillingAccountSelected(event) {

        // Match the selected BAN to the Billing Account
        this.selectedBillingAccount = this.billingAccounts.find(billingAccount => billingAccount.Billing_Account_Number__c === event.detail.value);

        this.wizard.enableButton('selectBan', 'right', true);
    }

    async handleInputOnChange() {

        await BwcUtils.nextTick();

        if(this.checkValidity(this.form)) {
            
            this.reportValidity(this.form);

            this.wizard.enableButton('addNewCharge', 'right', true);

        } else {

            this.wizard.enableButton('addNewCharge', 'right', false);
        }
    }

    handleChargeLevelOnChange() {
        
        this.chargeReasonOptions = this.filteredChargeReasonOptions;

        this.getField('chargeReason').value = null;

        this.chargeAmount = null;

        this.chargeAmountDisabled = false;

        this.handleInputOnChange();
    }

    handleChargeReasonOnChange(event) {
    
        // Reset Default Values
        this.chargeAmount = null;

        this.chargeAmountDisabled = false;

        const chargeReason = this.chargeReasons.find( reason => reason.Charge_Code__c === event.detail.value );

        // Set the dollar amount if available and disable input
        if(chargeReason.Charge_Amount__c  > 0) {
            
            this.chargeAmount = chargeReason.Charge_Amount__c;
            
            this.chargeAmountDisabled = true;            
        }

        this.handleInputOnChange();
    }

    /*** Custom Validation to check for $0.00 or 0 */
    handleChargeAmountOnChange(event) {

        const field = event.target;

        const value = typeof field.value === 'string'
            ? field.value.replace(/\$|,/g, '')
            : field.value;
            
        const amount = BwcUtils.toCurrency(value);

        if( !isNaN(amount) && amount === 0) {
            field.setCustomValidity(this.labels.positiveChargeAmount);
        } else {
            field.setCustomValidity('');
        }

        this.handleInputOnChange();
    }
}