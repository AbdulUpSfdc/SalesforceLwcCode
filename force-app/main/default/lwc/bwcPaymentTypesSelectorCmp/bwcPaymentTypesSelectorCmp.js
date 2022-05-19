/* eslint-disable use-isnan */
/* eslint-disable @lwc/lwc/no-api-reassignments */
import { LightningElement, api } from "lwc";

const Mode = {
  CREDIT_CARD: "CREDIT_CARD",
  BANK: "BANK"
};

const AVAIL_CAPABILITIES = Object.freeze({
  BANK_NO_CHECK_NUM : "BANK_NO_CHECK_NUM",
  BANK_WITH_CHECK_NUM : "BANK_WITH_CHECK_NUM",
  CREDCARD : "CREDCARD",
  CREDCARD_CVV_ONLY : "CREDCARD_CVV_ONLY",
  REFUND_BANK_NOCHECK_CREDCARD : "REFUND_BANK_NOCHECK_CREDCARD"
});

export default class BwcPaymentTypesSelectorCmp extends LightningElement {
  mode = Mode.CREDIT_CARD;

  @api
  labels; // = LABELS;

  _creditCardButtonLabel = ""; //this.labels.pmCC;
  _creditCardButtonCSS = "stretched";

  capabilitiesArr = [];

  _cardLastFour = "";
  @api
  get cardLastFour() {
    return ( this.capabilities.includes( AVAIL_CAPABILITIES.CREDCARD_CVV_ONLY ) ) ? 
      this.cardLastFour : "";
  }
  set cardLastFour( lastFour ) {
    this._cardLastFour = (lastFour) ? lastFour.replace( /[^\d]/, "" ) : "";
    if ( this._cardLastFour ) {
      this._creditCardButtonLabel = this.labels.cardPaymentMethod + " " + this._cardLastFour;
      this._creditCardButtonCSS = "whole-row"
    }
    else {
      this._creditCardButtonLabel = this.labels.pmCC;
    }
  }

  get creditCardButtonLabel() {
    return this._creditCardButtonLabel;
  }
  
  get creditCardButtonCSS() {
    return this._creditCardButtonCSS;
  }

  @api get capabilities() {
    return this.capabilitiesArr;
  }
  set capabilities( caps ) {
    if ( caps ) {
      console.debug( '--->>> setting capabilities to ' + JSON.stringify( caps ) );
      this.capabilitiesArr = caps;
    }
  }

  get creditCardFields() {
    return ( this.capabilities.includes( AVAIL_CAPABILITIES.CREDCARD_CVV_ONLY ) ) ? 
      ["ccSecurityCode"] : [];
  }

  get isCardVisible() {
    console.debug( '--->>> isCardVisible ' + this.capabilities );
    return this.capabilities.includes( AVAIL_CAPABILITIES.CREDCARD ) ||
     this.capabilities.includes( AVAIL_CAPABILITIES.CREDCARD_CVV_ONLY );
  }

  get isBankVisible() {
    return this.capabilities.includes( AVAIL_CAPABILITIES.BANK_NO_CHECK_NUM )
      ||
      this.capabilities.includes( AVAIL_CAPABILITIES.BANK_WITH_CHECK_NUM );
  }

  get isBankWithCheck() {
    return this.capabilities.includes( AVAIL_CAPABILITIES.BANK_WITH_CHECK_NUM );
  }

  get isRefund() {
    return this.capabilities.includes( AVAIL_CAPABILITIES.REFUND_BANK_NOCHECK_CREDCARD );
  }

  @api
  get isCreditCard() {
    return this.mode === Mode.CREDIT_CARD && this.isCardVisible;
  }

  @api
  get ccButtonVariant() {
    return this.isCreditCard ? "brand" : "neutral";
  }

  @api
  get bankButtonVariant() {
    return !this.isCreditCard ? "brand" : "neutral";
  }

  setMode(event) {
    this.mode = event.target.dataset.id;

    const methodChangedEvent = new CustomEvent("methodchanged", {
      detail: this.mode
    });
    // Dispatches the event.
    this.dispatchEvent(methodChangedEvent);    
  }

  @api get formData() {
    const frm = this.isCreditCard
      ? this.template.querySelector("c-bwc-payment-credit-card-cmp")
      : this.template.querySelector("c-bwc-payment-banking-info-cmp");
    const data = (frm) ? frm.formData : undefined;
    if (!data) {
      return undefined;
    }

    const unifiedData = {
      creditCard: this.mode === Mode.CREDIT_CARD ? data : undefined,
      bankInfo: this.mode === Mode.BANK ? data : undefined
    };

    // const btns = this.template.querySelectorAll("lightning-button");
    // btns.forEach((b) => (b.disabled = true));

    return unifiedData;
  }
}