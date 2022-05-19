import { LightningElement, api } from 'lwc';
import * as BwcConstants from 'c/bwcConstants';
import { AgentDecisionStatus } from 'c/bwcAdjustments';

export default class BwcMakeAdjustmentCdeRecommendations extends LightningElement {
    @api isGoodwill;
    @api lineItemId;
    @api howToApply;
    @api amountRequested;
    @api amountApproved;
    @api readToCustomerText;
    @api decisionStatus;

    _cdeStatus;
    _agentDecisionStatus;
    _isAgentDecisionDisabled = false;

    isApproved = false;
    isApprovedWithCondition = false;
    isRejected = false;
    isAccepted = false;
    isOverridden = false;
    isDiscarded = false;

    get title() {
        return (this.isGoodwill)
            ? 'Goodwill Adjustment'
            : `Selected Charge #${this.lineItemId}`;
    }

    /*** CDE Decision Status UI */
    get cdeStatus() {
        return this._cdeStatus;
    }

    @api set cdeStatus(status) {
        const statuses = BwcConstants.CDEStatus;
        this._cdeStatus = status;
        this.isApproved = false;
        this.isApprovedWithCondition = false;
        this.isRejected = false;

        switch(status) {
            case statuses.APPROVED.value:
                this.isApproved = true;
                break;
            case statuses.APPROVED_WITH_CONDITIONS.value:
                this.isApprovedWithCondition = true;
                break;
            case statuses.REJECTED.value:
                this.isRejected = true;
                break;
        }
    }

    /*** Agent Decision UI */
    get agentDecisionStatus() {
        return this._agentDecisionStatus;
    }

    set agentDecisionStatus(status) {
        this._agentDecisionStatus = status;
        this.isAccepted = false;
        this.isOverridden = false;
        this.isDiscarded = false;

        switch(status) {
            case AgentDecisionStatus.ACCEPTED:
                this.isAccepted = true;
                break;
            case AgentDecisionStatus.OVERRIDDEN:
                this.isOverridden = true;
                break;
            case AgentDecisionStatus.DISCARDED:
                this.isDiscarded = true;
                break;
        }
    }

    get showAcceptAmount() {
        return (( this.decisionStatusApproved || this.decisionStatusApprovedWithConditions ) && !this.isAccepted) ? true: false;
    }

    get showOverride() {
        return (( this.decisionStatusApprovedWithConditions || this.decisionStatusRejected ) && !this.isOverridden) ? true: false;
    }

    get showDiscardItem() {
        return ( this.decisionStatusRejected && !this.isDiscarded) ? true: false;
    }

    get decisionStatusApproved(){
        return this.decisionStatus === BwcConstants.CDEStatus.APPROVED.value;
    }

    get decisionStatusApprovedWithConditions(){
        return this.decisionStatus === BwcConstants.CDEStatus.APPROVED_WITH_CONDITIONS.value;
    }

    get decisionStatusRejected(){
        return this.decisionStatus === BwcConstants.CDEStatus.REJECTED.value;
    }

    /*** Event Dispatchers ***/
    dispatchAgentDecision(status) {

        const detail = {
            status,
            agentAdjustedAmount: this.amountApproved,
            id: this.lineItemId
        };

        this.dispatchEvent(new CustomEvent('agentdecision', { detail } ));
    }

    /*** Event Handlers ***/
    handleAgentDecision(event) {
        const status =  event.target.dataset.status;
        this.agentDecisionStatus = status;
        this.dispatchAgentDecision(status);
    }

}