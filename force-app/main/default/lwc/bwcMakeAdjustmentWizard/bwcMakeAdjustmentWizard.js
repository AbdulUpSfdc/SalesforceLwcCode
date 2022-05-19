import { api, track } from 'lwc';
import BwcPageElementBase from 'c/bwcPageElementBase';

import * as BwcConstants from 'c/bwcConstants';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcAdjustments from 'c/bwcAdjustments';
import * as BwcCaseServices from 'c/bwcCaseServices';
import * as BwcAdjustmentServices from 'c/bwcAdjustmentServices';

import { AdjustmentLineItem } from './bwcAdjustmentLineItem';
import { createActivity, InteractionActivityValueMapping } from 'c/bwcInteractionActivityService';

export default class BwcMakeAdjustmentWizard extends BwcPageElementBase {

    labels = BwcAdjustments.labels;

    @api isGoodwill;
    @api recordId;
    @api accountNumber;
    @api serviceType;
    @api customerName;
    @api selectedStatementId;
    @api billSequenceNumber;
    @api billStartDate;
    @api billEndDate;
    @api billingPeriod;
    @api billPaymentStatus;
    @api creationDate;
    @api caseId;

    @track adjustmentLineItems = [];
    @track infoPanelText;

    _isRendered = false;
    _isLoading = false;
    _isError = false;

    transactionId;
    
    renderedCallback() {
        if(!this._isRendered) {
            this._isRendered = true;
            this.open();
        }
    }

    get agentDecisionStatus() {
        return BwcAdjustments.AgentDecisionStatus;
    }

    get finalAction() {
        return BwcAdjustments.FinalAction;
    }

    get chargeSelector() {
        return this.template.querySelector('c-bwc-make-adjustment-charge-selector');
    }

    get adjustmentDetails() {
        return [...this.template.querySelectorAll('c-bwc-make-adjustment-detail')];
    }

    /***  UI ***/
    get isLoading() { 
        return this._isLoading 
    }

    set isLoading(val) { 
        this._isLoading = val;
    }

    get isError()  { 
        return this._isError; 
    }

    set isError(val) {
        this.resetUI();
        this._isError = val;
    }

    resetUI() {
        this._isLoading = false;
        this._isError = false;
    }

    /*** Wizard ***/
    get wizardDefaultTitle() {
        return '<b>Make Adjustment</b>';
    }

    wizardSteps = [
        {
            name: 'chargeSelector',
            title: '',
            panelNumber: 0,
            minHeight: 165,
            initAction: this.loadBillingStatement.bind(this),
            rightButton: {
                name: 'prepareAdjustmentLineItems',
                label: 'Next',
                action: this.prepareAdjustmentLineItems.bind(this)
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
            name: 'adjustmentDetails',
            title: '',
            panelNumber: 1,
            minHeight: 165,
            initAction: this.prepareAdjustmentLineItems.bind(this),
            rightButton: {
                name: 'submitAdjustmentLineItems',
                label: 'Next',
                action: this.submitAdjustmentLineItems.bind(this)
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
            name: 'cdeRecommendations',
            title: '',
            panelNumber: 2,
            minHeight: 165,
            rightButton: {
                name: "postAdjustments",
                label: "Submit",
                action: this.postAdjustments.bind(this)
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

    get wizard() {
        return this.template.querySelector('c-bwc-wizard');
    }

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
        
        this.isLoading = true;
        this.creationDate = BwcUtils.formatDateShort(Date.now());

        // Reset boolean value for isGoodwill. browser refresh resets to string
        this.isGoodwill = ( this.isGoodwill === true || this.isGoodwill === 'true' );

        this.wizard.enableButton('chargeSelector', 'right', false);
        this.wizard.enableButton('adjustmentDetails', 'right', false);
        this.wizard.enableButton('cdeRecommendations', 'right', false);

        if(this.isGoodwill) {

            this.wizard.enableStep('chargeSelector', false);

            const adjustmentLineItems = [
                new AdjustmentLineItem(
                    true,
                    this.accountNumber,
                    this.billStartDate,
                    this.billEndDate,
                    this.billSequenceNumber,
                    this.serviceType,
                    this.serviceType,
                    '0', // Default for goodwill
                    null, // chargeDescription not used by goodwill
                    null, // chargeCode not used by goodwill
                    null, // chargeAmount not used by goodwill
                    'B', // default chargeLevel for goodwill
                    null // subscriberNumber not used by goodwill
                )
            ];

            this.adjustmentLineItems = adjustmentLineItems;

            this.prepareAdjustmentLineItems();

            this.wizard.setStepTitle('adjustmentDetails', `<b>Make Goodwill Adjustment</b>: BAN# ${this.accountNumber}`);
            this.wizard.setStepTitle('cdeRecommendations', `<b>Make Goodwill Adjustment</b>: BAN# ${this.accountNumber}`);

        } else {

            this.wizard.setStepTitle('chargeSelector', `<b>Make Billing Adjustment</b>: BAN# ${this.accountNumber}`);
            this.wizard.setStepTitle('adjustmentDetails', `<b>Make Billing Adjustment</b>: BAN# ${this.accountNumber}`);
            this.wizard.setStepTitle('cdeRecommendations', `<b>Make Billing Adjustment</b>: BAN# ${this.accountNumber}`);

        }

        this.isLoading = false;
    }

    /*
        Wizard calls these functions when submit is selected
    */

    loadBillingStatement() {
        this.chargeSelector.loadBillingStatement();
    }

    prepareAdjustmentLineItems() { 
        this.adjustmentDetails.forEach(li => {
            li.initialize();
        });
    }

    async submitAdjustmentLineItems() {
        this.isLoading = true;
        
        try {

            const result = await BwcAdjustmentServices.getCdeRecommendations(this.recordId, this.cdeRecommendationsRequest)

            this.transactionId = result.transactionId;
            this.overallCdeStatus = result.overallCDEStatus;
            if(result.product.some(p => p.decisionStatus !== result.overallCDEStatus)) {
                this.infoPanelText = result.displayTextForReps;
            }

            result.product.forEach( (p, i) => {
                
                if(p.decisionStatus === 'ApprovedWithCondition') {
                    p.decisionStatus = BwcConstants.CDEStatus.APPROVED_WITH_CONDITIONS.value;
                }

                this.adjustmentLineItems[i].setCdeRecommendationValues(
                    result.transactionId,
                    result.overallCDEStatus,
                    result.overallCDEApprovedAmount,
                    result.overallCDERequestedAmount,
                    result.displayTextForReps,
                    result.displayTextForCustomer,
                    p.sequenceNumber,
                    p.productLevelId,
                    p.decisionStatus,
                    p.displayTextForReps,
                    p.displayTextForCustomer,
                    p.requestCreditAmount,
                    p.approvedAmount,
                    p.rulesApplied
                );
            });
        } catch( error ) {
            super.handleError(error, this.labels.cdeRecommendationsError, 'Adjustment Wizard', 'inline');
        } finally {
            this.isLoading = false;
        }
    }

    postAdjustments() {
        
        this.isLoading = true;

        const acceptedAdjustments = this.adjustmentLineItems.filter(
            li => li.finalDecision === this.finalAction.POST_ADJUSTMENT
        );

        const overriddenAdjustments = this.adjustmentLineItems.filter(
            li => li.finalDecision === this.finalAction.MANAGER_APPROVAL
        );

        const discardedAdjustments = this.adjustmentLineItems.filter(
            li => li.agentDecisionStatus === this.agentDecisionStatus.DISCARDED
        );

        // if agent decides to discard all adjustments
        if( discardedAdjustments.length === this.adjustmentLineItems.length ) {
            this.discardAdjustments();
        } 
        // if agent has accepted or rejected all adjustments
        else if( acceptedAdjustments.length + discardedAdjustments.length === this.adjustmentLineItems.length ) {
            this.acceptAdjustments(acceptedAdjustments);
        }
        // create escalation case for mixed
        else {
            const adjustmentsToEscalate = [
                ...acceptedAdjustments,
                ...overriddenAdjustments
            ];

            this.overrideAdjustments(adjustmentsToEscalate);
        }

        this.createInteractionActivity(this.adjustmentLineItems);
    }

    discardAdjustments() {

        const message = (this.adjustmentLineItems.length === 1) 
            ? this.labels.discardAdjustment
            : this.labels.discardAdjustments;

        super.showToast(null, message, 'success');

        this.close();
    }
    
    async acceptAdjustments(adjustments) {

        const interactionId = this.recordId;
        const request = {
            accountNumber: this.accountNumber,
            accountType: this.serviceType,
            decisionUpdateTrnsId: this.transactionId,
            billSeqNo: this.billSequenceNumber,
            lineItems: [],
            interactionId,
        };

        adjustments.forEach(a => {
            request.lineItems.push( a.postRequest );
        });

        try {
            
            await BwcAdjustmentServices.postAdjustments( this.recordId, request );
        
            const message = this.labels.postAdjustmentsSuccess + this.accountNumber;

            super.showToast(null, message, 'success');

            super.sendLmsRefresh(this.recordId, 'pendingChargesCredits');
    
            this.close();

        } catch( error ) {
            
            super.handleError(error, this.labels.postAdjustmentsError, 'Adjustment Wizard', 'inline');
            
            this.isLoading = false;
        }
        
    }

    async overrideAdjustments(adjustments) {

        let toastMessage;

        if(adjustments.length === 1) {
            toastMessage = `Charge #${adjustments[0].id} has been selected for case creation.`;
        } else {
            toastMessage = adjustments.reduce( (acc,b) => { 
                return acc + ` #${b.id},` 
            }, 'Charges');
            toastMessage += ' have been selected for case creation.';
        }

        this.infoPanelText = toastMessage;

        try {
            
            const caseId = await BwcCaseServices.createEscalationCase(this.recordId, 'Billing','Adjustment' , this.caseRequest);
            
            await BwcAdjustments.openEscalationCase(this, caseId, this.recordId, true);

            this.close();

        } catch( error ) {
            
            super.handleError(error, this.labels.escalateAdjustmentsError, 'Adjustment Wizard', 'inline');
            
            this.isLoading = false;
        }
    }
    /*** End Wizard ***/

    /*** Event Handlers ***/
    handleSubcomponentError(event) {
        const error = event.detail;

        super.clearNotifications();

        this.wizard.enableButton(error.stepName, 'right', false);

        super.handleError( error.message, error.message, `Adjustment Wizard ${error.stepName} Subcomponent`, 'inline' );
    }

    handleSubcomponentLoading(event) {
        this.isLoading = event.detail.isLoading;
    }

    handleChargeSelection(event) {
        
        super.clearNotifications();

        const selectedLineItems = event.detail.selectedLineItems;
        const adjustmentLineItems = [];

        AdjustmentLineItem.resetIdCounter();

        selectedLineItems.forEach(li => {

            const serviceProduct = BwcAdjustments.ServiceProduct.getValueFromType(li.service);
            const chargeLevel = 'B';

            adjustmentLineItems.push(new AdjustmentLineItem(
                this.isGoodwill,
                this.accountNumber,
                this.billStartDate,
                this.billEndDate,
                li.billSequenceNumber,
                li.service,
                serviceProduct,
                li.chargeSequenceNumber,
                li.chargeCode,
                li.description,
                li.selectedBillAmount,
                chargeLevel,
                li.ctn
            ));
        });

        this.adjustmentLineItems = adjustmentLineItems;

        this.wizard.enableButton('chargeSelector', 'right', true);
    }

    handleAdjustmentDetailValidation(event) {

        const {id, fields} = event.detail;

        // Find adjustment line item by id
        const adjustmentLineItem = this.adjustmentLineItems.find(li => li.id === id);

        // update validation status
        adjustmentLineItem.setAgentAdjustmentValues(
            event.detail.success,
            fields.adjustmentReason,
            fields.adjustmentAmount,
            fields.howToApply,
            fields.comments
        );

        // if all line items are valid, enable submit button
        if(this.adjustmentLineItems.every(li => li.validated)) {
            this.wizard.enableButton('adjustmentDetails', 'right', true);
        } else {
            this.wizard.enableButton('adjustmentDetails', 'right', false);
        }
    }

    handleAgentDecision(event) {

        const { id, status, agentAdjustedAmount } = event.detail;

        const adjustmentLineItem = this.adjustmentLineItems.find(li => li.id === id);

        adjustmentLineItem.setAgentDecisionStatus(
            status,
            agentAdjustedAmount
        );

        // check if all line item decisions are made
        if(!this.adjustmentLineItems.every(li => 
            li.agentDecisionStatus === this.agentDecisionStatus.ACCEPTED ||
            li.agentDecisionStatus === this.agentDecisionStatus.OVERRIDDEN ||
            li.agentDecisionStatus === this.agentDecisionStatus.DISCARDED
        )) {
            this.wizard.enableButton('cdeRecommendations', 'right', false);
            return;
        }

        // rename is all adjustments are discarded
        if(this.adjustmentLineItems.every(li => li.agentDecisionStatus === this.agentDecisionStatus.DISCARDED)) {
            this.wizard.setButtonLabel('cdeRecommendations', 'right', 'Close Tab');
        } else {
            this.wizard.setButtonLabel('cdeRecommendations', 'right', 'Submit');
        }

        this.wizard.enableButton('cdeRecommendations', 'right', true);
    }

    async createInteractionActivity(adjustments){

        const detailRecord = {
            recordId: this.recordId,
            ban: this.accountNumber
        };

        detailRecord['adjustmentInfo'] = adjustments.map(adj=>{

            return {
                adjustmentAmount: adj.adjustmentAmount,
                reasonCode: adj.adjustmentReason,
                chargeCode: adj.chargeCode,
                chargeSeqNbr: adj.chargeSequenceNumber,
                chargeAmt: adj.chargeAmount,
                status: adj.agentDecisionStatus,
            };
        });

        try{
            await createActivity(this.recordId, InteractionActivityValueMapping.BillingAdjustmentWireless, detailRecord);
        } catch(error) {
            BwcUtils.error(error);
        }

    }

     /* Request Object Getters */
    get cdeRecommendationsRequest() {
        let request = {
            accountNumber: this.accountNumber,
            accountType: this.serviceType,
            product: []
        };

        this.adjustmentLineItems.forEach(li => {
            request.product.push(li.cdeRecommendationsRequest);
        });

        return request;
    }

    get caseRequest() {

        const request = {
            ban: this.accountNumber,
            transactionId: this.transactionId,
            caseAction: BwcConstants.AdjustmentType,
            type: 'Billing', // check
            oldCaseId: this.caseId,
            statementId: this.selectedStatementId,
            lineItemDataList: []
        }

        if(this.isGoodwill) {

            request.caseAction = BwcConstants.AdjustmentCaseAction.GOODWILL;
            
            this.adjustmentLineItems.forEach(li => {
                
                request.adjustmentData = {
                    adjType:'Goodwill',
                    adjReasonExplanationCode: li.adjustmentReason.explanationCode,
                    adjReasonDescription: li.adjustmentReason.description,
                    adjReasonSystemCode: li.adjustmentReason.systemCode,
                    adjComments: li.comments
                };

                request.lineItemDataList.push( li.caseRequest );

                request.cdeData = {
                    overallCDEStatus: this.overallCdeStatus,
                    cdeReasonForAgent: this.infoPanelText,
                    cdeApprovedAmount: li.amountApproved,
                    cdeReasonForCustomer: li.readToCustomerText,
                    cdeRecommendationStatus: li.cdeStatus
                };

                request.billData = {
                    billDate: '', // dont have during goodwill
                    billSequenceNumber: '', // dont have during goodwill
                    chargeCode: li.adjustmentReason.chargeCode,
                    chargeType:'Goodwill',
                    chargeDescription: 'Goodwill Adjustment', 
                    chargeSequenceNumber:'',
                    chargeAmount: li.amountApproved,
                    requestAmount: li.amountRequested,
                    agentAdjustedAmount: '', // dont have during goodwill
                };
            });

        } else {

            request.caseAction = BwcConstants.AdjustmentCaseAction.LINEITEM;

            this.adjustmentLineItems.forEach(li => {
                request.lineItemDataList.push( li.caseRequest );
            });
        }

        return request;
    }
}