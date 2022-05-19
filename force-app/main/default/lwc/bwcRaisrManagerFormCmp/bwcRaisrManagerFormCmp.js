import { LightningElement, api } from 'lwc';

// Import Custom Labels
import * as BwcLabelServices from 'c/bwcLabelServices';

import * as RAISR_MSG_CH from "c/bwcRaisrMsgPubSubCmp";

// Custom permissions
import hasEnterCustomerPaymentDetailsPermission from '@salesforce/customPermission/Enter_Customer_Payment_Details';

const OPTS = Object.freeze({
  AUDIO_QUALITY: "Audio quality issue",
  SYS_NOT_RESPONDING: "System not responding",
  MULTIPLE_ATTEMPTS_FAILED: "Multiple attempts failed",
  IRATE_CUSTOMER: "Irate customer",
  PAYMENT_RESEARCH_CASE: "Payment Research/Case",
  LANG_LINE_CALL: "Language line call"
});

const WFH_OVERRIDE_REASON = 'RAISR disabled by WHF';

export const domElementHeight = ( elem ) => {
  let h;
  const styles = window.getComputedStyle( elem );
  const margin = parseFloat(styles['marginTop']) +
               parseFloat(styles['marginBottom']);

  h = Math.ceil( elem.offsetHeight + margin );
  return h;
} 

export default class BwcRaisrManagerFormCmp extends LightningElement {

  value;
  toggleChecked = true;

  btnDisabled = true;
  isDisabled = false;
  isDisabledByAgent = false;

  get isEnabledForWHO() {
    return !this.isDisabled && this.isWorkingFromHomeAgent;
  }

  isWorkingFromHome = false;
  labels = BwcLabelServices.labels;

  get options() {
    const res = [];
    for ( const p in OPTS ) {
      res.push( { label: OPTS[ p ], value: OPTS[ p ] } );
    }
    return res;    
  }

  // If user does not have permission, is WFH
  get isWorkFromHomeAgent() { return !hasEnterCustomerPaymentDetailsPermission; }

  isRendered = false;
  renderedCallback() {
    if ( this.isWorkFromHomeAgent && !this.isRendered ) {
      this.isRendered = true;
      this.btnDisabled = false;
      this.value = WFH_OVERRIDE_REASON;
    }
  }

  handleOverride(event) {

    this.value = event.detail.value;
    const btn = this.template.querySelector( ".disable-wfo-btn" );
    if (!btn) {
      return; 
    }

    if (this.value) {
      // Enable 'Override' button
      this.btnDisabled = false;
      btn.classList.add( "override-text" );
    } else {
      // Disable button if they unselected the option
      this.btnDisabled = true;
      btn.classList.remove( "override-text" );
    }

  }

  handleDisable(event) {

    // Uncheck the toggle input
    this.toggleChecked = false;

    // Disable form
    this.isDisabled = true;
    this.isDisabledByAgent = true;

    if ( !this.value && !this.isWorkFromHomeAgent ) {
      this.value = WFH_OVERRIDE_REASON;
    }
    this.sendMessageToRaisrChannel(
      RAISR_MSG_CH.raisrStatus( !this.isDisabled, this.value )
    );
  }

  sendMessageToRaisrChannel( msg ) {
    const raisrCh = this.template.querySelector( "c-bwc-raisr-msg-pub-sub-cmp" );
    if ( raisrCh ) {
      raisrCh.postMessage( msg );
    }
  }

  onRaisrEvent( event ) {

    const msg = event.detail.message;
    const isStatusChange = 
      (
        msg.messageSource === RAISR_MSG_CH.MSG_SOURCE.RAISR_DROP_DOWN_CONTROL
        ||
        msg.messageSource === RAISR_MSG_CH.MSG_SOURCE.RAISR_UTIL_BAR_CONTROL
      )
      && (
        msg.messageType === RAISR_MSG_CH.MSG_TYPE.RAISR_STATUS
        || msg.messageType === RAISR_MSG_CH.MSG_TYPE.RAISR_STATUS_INTERNAL
        || msg.messageType === RAISR_MSG_CH.MSG_TYPE.RAISR_MANAGER_STARTED
      );
    
    if ( isStatusChange ) {
      const prevIsDisabled = this.isDisabled;
      this.isDisabled = !msg.messageBody.isRaisrActive;
      this.toggleChecked = !this.isDisabled;
      if ( msg.messageType === RAISR_MSG_CH.MSG_TYPE.RAISR_STATUS_INTERNAL ) {
        this.isDisabledByAgent = !msg.messageBody.isRaisrActive;
      }
      this.notifyParentAboutNewHeight();
    }
  }

  @api get ioFormHeight() {
    const frm = this.template.querySelector( ".mgr-ioform" );
    let h = -1;
    if ( frm ) {
      h = domElementHeight( frm );
    }
    return h;
  }

  notifyParentAboutNewHeight() {
    setTimeout(() => {
      const payload = {
        height: this.ioFormHeight
      };
      const evt = new CustomEvent("dimensionchanged", {
        detail: payload
      });
      this.dispatchEvent( evt );
    });
  }

  disableRaisrForWHO(event) {
    this.handleDisable(event);
  }
}