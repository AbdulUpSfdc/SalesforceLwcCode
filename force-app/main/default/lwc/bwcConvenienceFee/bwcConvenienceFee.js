import { LightningElement, api } from 'lwc';

export default class BwcConvenienceFee extends LightningElement {

    @api message;
    @api isWaivable;
    @api waiveReasonOptions = [];

    _waiveReason = "";
    _isWaived = false;
    _isAccepted = false;
    errorMessage;

    @api get waiveReason() {return this._waiveReason;}
    @api get isWaived() {return this._isWaived;}
    @api get isAccepted() {return this._isAccepted;}

    get waiveReasonDisabled() {return this._isAccepted || this._isWaived;}
    get waiveFeeDisabled() {return this._isAccepted || this._waiveReason === "";}
    get acceptFeeDisabled() {return this._waiveReason !== "";}

    @api get state() {
        return {
            waiveReason: this._waiveReason,
            isWaived: this._isWaived,
            isAccepted: this._isAccepted
        };
    }
    set state(value) {
        this._waiveReason = value ? value.waiveReason : "";
        this._isWaived = value ? value.isWaived : "";
        this._isAccepted = value ? value.isAccepted : "";
    }

    /*
        Caller uses to tell if process is complete.
    */
    @api reportValidity() {
        if (this.checkValidity()) {
            this.errorMessage = undefined;
            return true;
        }
        this.errorMessage = "Convenience fee must be accepted or waived before submitting your payment.";
        return false;
    }

    /*
        Caller uses to tell if process is complete.
    */
    @api checkValidity() {
        // It's valid if it's been waived or accepted.
        return this._isWaived || this._isAccepted;
    }

    handleSelectWaiveReason(event) {
        this._waiveReason = event.detail.value;
    }

    handleWaiveFee() {
        this._isWaived = true;
        this.errorMessage = undefined;
    }

    handleUnwaiveFee() {
        this._isWaived = false;
        this._waiveReason = "";
    }

    handleAcceptFee() {
        this._isAccepted = true;
        this.errorMessage = undefined;
    }

    handleUnacceptFee() {
        this._isAccepted = false;
    }

}