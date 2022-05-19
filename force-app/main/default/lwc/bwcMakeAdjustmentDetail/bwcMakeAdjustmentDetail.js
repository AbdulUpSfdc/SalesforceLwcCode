import { LightningElement, api, track } from 'lwc';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcAdjustments from 'c/bwcAdjustments';
import { BillingAccountType } from 'c/bwcConstants';
import { getGoodwillAdjustmentReasons, getReasonForChargeCode } from 'c/bwcChargeCodeServices';

const DEFAULT_HOW_TO_APPLY_OPTIONS = [
    { label: 'Immediately', value: 'Immediately' }
];
const DEFAULT_HOW_TO_APPLY = 'Immediately';

const STEP_NAME = 'adjustmentDetails';

export default class BwcMakeAdjustmentDetail extends LightningElement {
    @api lineItemId;
    @api isGoodwill;
    @api serviceType;
    @api serviceProduct;
    @api chargeCode;
    @api chargeAmount;

    adjustmentReasons;

    @track adjustmentAmount;
    @track adjustmentReasonOptions;
    @track howToApplyOptions;
    @track howToApply;

    get title() {
        return `Charge #${this.lineItemId}`;
    }

    get form() {
        return this.template.querySelector('div [data-name="form"]');
    }

    get serviceTypeLabel() {
        return BillingAccountType.getLabelForValue(this.serviceType);
    }

    async connectedCallback() {

        this.howToApplyOptions = DEFAULT_HOW_TO_APPLY_OPTIONS;
        this.howToApply = DEFAULT_HOW_TO_APPLY;

    }

    @api async initialize() {

        try {
            if(this.isGoodwill) {
                this.adjustmentReasons = await getGoodwillAdjustmentReasons();
                this.howToApplyOptions = DEFAULT_HOW_TO_APPLY_OPTIONS;
                this.howToApply = DEFAULT_HOW_TO_APPLY;
            } else {
                this.adjustmentReasons = await getReasonForChargeCode( this.chargeCode );
            }
        } catch(error) {
            this.addError('Failed to Load Adjustment Reasons.', error);
        }

        if(this.adjustmentReasons.length === 0) {
            this.addError('No Adjustment Reasons found for the selected Charge.');
            return;
        }
        
        this.adjustmentReasons = this.adjustmentReasons.map(a => {
            return {
                id: a.Id,
                explanationCode: a.Adj_Reason_Explanation_Code__c,
                systemCode: a.Adj_Reason_System_Code__c,
                description: a.Adj_Reason_Description__c,
                chargeCode: a.Charge_Code__c,
                chargeType: a.Charge_Type__c
            };
        });

        this.adjustmentReasonOptions = this.adjustmentReasons.map(a => {
            return {
                label: `${a.description}`,
                value: a.explanationCode
            };
        });
    }

    @api get fields() {

        const fields = {};
        const inputTypes = 'lightning-input, lightning-combobox, lightning-textarea';

        this.form.querySelectorAll(inputTypes).forEach(input => {
            switch (input.name) {
                case 'adjustmentAmount': 
                    // Trim adjustmentAmount of $ and ,
                    fields[input.name] = (input.value || '').replace(/\$|,/g, '');
                    break;
                case 'adjustmentReason':
                    fields[input.name] = this.adjustmentReasons.find(
                        a => a.explanationCode === input.value
                    )
                    break;
                default:
                    fields[input.name] = input.value;
            }
        });
        return fields;
    }

    /*** Event Dispatchers ***/
    dispatchValidationStatus(success) {

        const detail = {
            success,
            id: this.lineItemId,
            fields: this.fields
        };

        this.dispatchEvent(new CustomEvent('validation', { detail } ));
    }

    /*** Event Handlers ***/
    async handleInputOnChange(event) {
        const field = event.target;

        this.submitFormValidity(field);
    }

    async handleAdjustmentAmountChange(event) {

        const field = event.target;
        const adjustmentAmount = BwcUtils.toCurrency(
            ( field.value || '').replace(/\$|,/g, '')
        );

        if( this.isGoodwill && adjustmentAmount >= BwcAdjustments.MaxAdjustment.value ) {
            field.setCustomValidity(`Adjustment Amount must be < ${BwcAdjustments.MaxAdjustment.label}`);
        } else if( !this.isGoodwill && adjustmentAmount > this.chargeAmount ) {
            field.setCustomValidity('Amount must be less than or equal to Charge Amount.');
        } else {
            field.setCustomValidity('');
        } 

        this.submitFormValidity(field);
    }

    handleRemoveEntireCharge(event) {
        const field = this.getField('adjustmentAmount');

        if(event.detail.checked) {
            field.value = this.chargeAmount;
            field.disabled = true;
            // Turn off any errors that were present on the adjustmentAmount field
            field.reportValidity();
        } else {
            field.value = null;
            field.disabled = false;
        }

        this.submitFormValidity(field);
    }

    getField(dataId) {
        return this.template.querySelector("[data-id='" + dataId + "']");
    }

    /*** Error Reporting ***/
    addError(message, details) {
        this.dispatchError(message, details);
    }
    
    checkValidity(template) {
        return BwcUtils.checkValidity(template, 'lightning-textarea');
    }

    reportValidity(template) {
        return BwcUtils.reportValidity(template, 'lightning-textarea');
    }

    async submitFormValidity(field) {
        // Allow the form to be populated with values before validating
        await BwcUtils.nextTick();

        if(this.checkValidity(this.form)) {
            field.reportValidity();
            this.isValid = true;
        } else {
            this.isValid = false;
        }
        this.dispatchValidationStatus(this.isValid);
    }

    /*** Event Dispatchers ***/
    dispatchError(message, details) {
    
        const detail = { 
            stepName: STEP_NAME,
            message, details,
        };

        this.dispatchEvent(new CustomEvent( 'error', { detail } ));
    }

}