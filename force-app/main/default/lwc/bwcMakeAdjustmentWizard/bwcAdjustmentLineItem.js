import * as BwcUtils from 'c/bwcUtils';
import { CDEStatus } from 'c/bwcConstants';
import { AgentDecisionStatus, FinalAction } from 'c/bwcAdjustments';
let idCounter = 0;

export class AdjustmentLineItem {

    generateUniqueId() {
        idCounter++;
        return idCounter;
    }

    static resetIdCounter() {
        idCounter = 0;
    }

    /* Phase 1 Constructor & Getters */

    constructor(
        isGoodwill,
        accountNumber,
        billStartDate,
        billEndDate,
        billSequenceNumber,
        serviceType,
        serviceProduct,
        chargeSequenceNumber,
        chargeCode,
        chargeDescription,
        chargeAmount,
        chargeLevel,
        subscriberNumber
    ) {
        this._id = this.generateUniqueId();
        this._isGoodwill = isGoodwill;
        this._accountNumber = accountNumber;
        this._billStartDate = billStartDate;
        this._billEndDate = billEndDate;
        this._billSequenceNumber = billSequenceNumber;
        this._serviceType = serviceType;
        this._serviceProduct = serviceProduct;
        this._chargeSequenceNumber = chargeSequenceNumber;
        this._chargeDescription = chargeDescription;
        this._chargeCode = chargeCode;
        this._chargeAmount = chargeAmount;
        this._chargeLevel = chargeLevel;
        this._subscriberNumber = subscriberNumber;
    }

    get id() {
        return this._id;
    }

    get isGoodwill() {
        return this._isGoodwill;
    }

    get accountNumber() {
        return this._accountNumber;
    }

    get billStartDate() {
        return this._billStartDate;
    }

    get billEndDate() {
        return this._billEndDate;
    }

    get billSequenceNumber() { 
        return this._billSequenceNumber;
    }

    get serviceType() {
        return this._serviceType;
    }

    get serviceProduct() {
        return this._serviceProduct;
    }

    get chargeSequenceNumber() {
        return this._chargeSequenceNumber;
    }

    get chargeCode() {
        return this._chargeCode;
    }
    
    get chargeDescription() {
        return this._chargeDescription;
    }

    get chargeAmount() {
        return this._chargeAmount;
    }

    get chargeLevel() {
        return this._chargeLevel;
    }

    get subscriberNumber() {
        return this._subscriberNumber;
    }

    /* Phase 2 Constructor, Getters, Request Builder */

    setAgentAdjustmentValues(
        validated,
        adjustmentReason,
        adjustmentAmount,
        howToApply,
        comments
    ) {
        this._validated = validated;
        this._adjustmentReason = adjustmentReason;
        this._adjustmentAmount = adjustmentAmount;
        this._howToApply = howToApply;
        this._comments = comments;
    }

    get validated() {
        return this._validated;
    }

    get adjustmentReason() {
        return this._adjustmentReason;
    }

    get howToApply() {
        return this._howToApply;
    }

    get adjustmentAmount() {
        return this._adjustmentAmount;
    }

    get comments() {
        return this._comments;
    }

    get cdeRecommendationsRequest() {

        const dtf = new Intl.DateTimeFormat('en-US', { 
            day: '2-digit',
            month: '2-digit',
            year: 'numeric'
        });

        const startDate = Date.parse(this.billStartDate + 'T00:00:00');
        const endDate = Date.parse(this.billEndDate + 'T00:00:00');

        const request = {
            isGoodwill: this.isGoodwill,
            productType: this.serviceType,
            billStartDate: dtf.format(startDate),
            billEndDate: dtf.format(endDate),
            billStatementDate: dtf.format(endDate),
            adjustmentReasonId: this.adjustmentReason.id,
            adjustmentExplanationCode: this.adjustmentReason.explanationCode,
            requestCreditAmount: this.adjustmentAmount,
            chargeCode: this.chargeCode,
            sequenceNumber: this.chargeSequenceNumber
        }

        return request;
    }

    /* Phase 3 Constructor & Getters */

    setCdeRecommendationValues(
        transactionId,
        overallCDEStatus,
        overallCDEApprovedAmount,
        overallCDERequestedAmount,
        overallCdeReasonForAgent,
        overallCdeReasonForCustomer,
        sequenceNumber,
        productLevelId,
        decisionStatus,
        cdeReasonForAgent,
        cdeReasonForCustomer,
        requestedAmount,
        approvedAmount,
        rulesApplied = '',
    ) {
        this._transactionId = transactionId;
        this._overallCDEStatus = overallCDEStatus;
        this._overallCDEApprovedAmount = overallCDEApprovedAmount;
        this._overallCDERequestedAmount = overallCDERequestedAmount;
        this._overallCdeReasonForAgent = overallCdeReasonForAgent;
        this._overallCdeReasonForCustomer = overallCdeReasonForCustomer;
        this._sequenceNumber = sequenceNumber;
        this._productLevelId = productLevelId;
        this._decisionStatus = decisionStatus; //previously cdeStatus
        this._cdeReasonForAgent = cdeReasonForAgent;
        this._cdeReasonForCustomer = cdeReasonForCustomer;
        this._requestedAmount = requestedAmount;
        this._approvedAmount = approvedAmount;
        this._rulesApplied = rulesApplied;
    }

    get transactionId() {
        return this._transactionId;
    }

    get overallCDEStatus() {
        return this._overallCDEStatus;
    }

    get overallCDEApprovedAmount() {
        return this._overallCDEApprovedAmount;
    }

    get overallCDERequestedAmount() {
        return this._overallCDERequestedAmount;
    }

    get overallCdeReasonForAgent() {
        return this._overallCdeReasonForAgent;
    }

    get overallCdeReasonForCustomer() {
        return this._overallCdeReasonForCustomer;
    }

    get sequenceNumber() {
        return this._sequenceNumber;
    }

    get productLevelId() {
        return this._productLevelId;
    }

    get decisionStatus() {
        return this._decisionStatus;
    }

    get cdeReasonForAgent() {
        return this._cdeReasonForAgent;
    }

    get cdeReasonForCustomer() {
        return this._cdeReasonForCustomer;
    }

    get requestedAmount() {
        return this._requestedAmount;
    }

    get approvedAmount() {
        return this._approvedAmount;
    }

    get rulesApplied() {
        return this._rulesApplied;
    }

    get readToCustomerText() {
        return (this.decisionStatus === CDEStatus.APPROVED_WITH_CONDITIONS.value) 
            ? this.cdeReasonForCustomer
            : this.overallCdeReasonForCustomer;
    }

    /* Phase 4 Constructor, Getters & Request Builders */
    setAgentDecisionStatus(
        agentDecisionStatus,
        agentAdjustedAmount
    ) {
        this._agentDecisionStatus = agentDecisionStatus;
        this._agentAdjustedAmount = agentAdjustedAmount;
    }

    get agentDecisionStatus() {
        return this._agentDecisionStatus;
    }

    get agentAdjustedAmount() {
        return this._agentAdjustedAmount;
    }

    get postRequest() {
        let request = {
            isGoodwill: this.isGoodwill,
            productLevelId: this.productLevelId,
            billerAdjustmentStatus: 'POSTED',
            billDate: this.billEndDate,
            billSeqNo: this.billSequenceNumber,
            billChrgSeqNo: this.chargeSequenceNumber,
            effectiveDate: BwcUtils.toIsoDate(new Date()),
            adjAmountType: 'A',
            adjustmentReasonCode: this.adjustmentReason.systemCode,
            adjustedAmount: this.agentAdjustedAmount,
            chargeLevel: this.chargeLevel,
            subscriberNbr: this.subscriberNumber,
            overridden: false
        };

        if(request.chargeLevel === 'B') {
            delete request.subscriberNbr;
        }

        return request;
    }

    get caseRequest() {

        if(this.isGoodwill) {
            return {
                billDate: this.billEndDate,
                billSequenceNumber: this.billSequenceNumber,
                chargeCode: this.adjustmentReason.chargeCode,
                chargeType: 'Goodwill',
                chargeDescription: 'Goodwill Adjustment',
                chargeSequenceNumber: this.sequenceNumber,
                chargeAmount: this.approvedAmount,
                productLevelId: this.productLevelId,
                requestAmount: this.requestedAmount,
                agentAdjustedAmount: this.agentAdjustedAmount,
            };
        }

        else {
            return {
                // initial constructor data from bill viewer
                accountNumber: this.accountNumber,
                billStartDate: this.billStartDate,
                billEndDate: this.billEndDate,
                billSequenceNumber: this.billSequenceNumber, //check for this, don't have currently
                serviceType: this.serviceType,
                // After charge selection from billing services
                chargeSequenceNumber: this.chargeSequenceNumber,
                chargeCode: this.chargeCode,
                chargeDescription: this.chargeDescription,
                chargeAmount: this.chargeAmount,
                // adjustment line item details
                adjustmentType: this.adjustmentType, //check for this
                chargeType: this.adjustmentReason.chargeType,
                adjustmentReasonExplanationCode: this.adjustmentReason.explanationCode,
                adjustmentReasonSystemCode: this.adjustmentReason.systemCode,
                adjustmentReasonDescription: this.adjustmentReason.description,
                adjustmentAmount: this.adjustmentAmount,
                howToApply: this.howToApply,
                comments: this.comments,
                // CDE Recommendations results
                // overall
                transactionId: this.transactionId,
                overallCdeStatus: this.overallCdeStatus,
                overallCdeApprovedAmount: this.overallCdeApprovedAmount,
                overallCdeRequestedAmount: this.overallCdeRequestedAmount,
                overallCdeReasonForAgent: this.overallCdeReasonForAgent,
                overallCdeReasonForCustomer: this.overallCdeReasonForCustomer,
                // line item
                sequenceNumber: this.sequenceNumber,
                productLevelId: this.productLevelId,
                decisionStatus: this.decisionStatus,
                cdeReasonForAgent: this.cdeReasonForAgent,
                cdeReasonForCustomer: this.cdeReasonForCustomer,
                requestAmount: this.requestedAmount, //should be same as adjustment amount above.
                approvedAmount: this.approvedAmount,
                rulesApplied: this.rulesApplied, // need to create
                // Agent decision based on CDE recommendations
                agentDecisionStatus: this.agentDecisionStatus,
                agentAdjustedAmount: this.agentAdjustmentAmount, // Need to add
                subscriberNumber: this.subscriberNumber
            }
        }
    }

    get finalDecision(){

        if( this.agentDecisionStatus === AgentDecisionStatus.ACCEPTED
            && ( this.overallCDEStatus ===  CDEStatus.APPROVED.value || this.overallCDEStatus ===  CDEStatus.APPROVED_WITH_CONDITIONS.value ) ){
            return FinalAction.POST_ADJUSTMENT;
        }

        if( this.agentDecisionStatus === AgentDecisionStatus.OVERRIDDEN ){
            return FinalAction.MANAGER_APPROVAL;
        }

        if( this.agentDecisionStatus === AgentDecisionStatus.ACCEPTED
            && this.overallCDEStatus === CDEStatus.REJECTED.value ){

            return FinalAction.MANAGER_APPROVAL;
        }

    }
}