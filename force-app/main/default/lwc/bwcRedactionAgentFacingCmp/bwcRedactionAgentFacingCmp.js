import { LightningElement, api, wire, track } from "lwc";

import getAuxDetails from "@salesforce/apex/BWC_AuxDetailController.getAuxDetails";
import getBAN from "@salesforce/apex/BWC_RedactionController.getBan";
import getCustomer from "@salesforce/apex/BWC_RedactionController.getCustomer";

import { machine, caseActions, redaction } from "c/bwcRedactionUtilsCmp";
import * as BwcUtils from "c/bwcUtils";

import {
  subscribe,
  unsubscribe,
  APPLICATION_SCOPE,
  MessageContext
} from "lightning/messageService";
import completeRedactionMsgChannel from "@salesforce/messageChannel/BWC_Completion__c";

const Mode = Object.freeze({
  EDIT: "EDIT",
  VIEW: "VIEW"
});

const CASE_AUX_DETAILS_PAYMENT_METHOD_FLD = 
  caseActions.CASE_AUX_DETAILS_PAYMENT_METHOD_FLD;

const CASE_ACTION_GROUP = caseActions.CASE_ACTION_GROUP;
const CaseActionsToGroup = caseActions.CaseActionsToGroup;
const RedactionMoneyDetails = redaction.RedactionMoneyDetails;

const EXIST_PAYMENT_METHOD_2_PAYMENT_SOURCE = 
  machine.EXIST_PAYMENT_METHOD_2_PAYMENT_SOURCE;

const TAB_CONSTANTS = Object.freeze({
  PAYMENT_TAB_LABEL: "Collect Payment Method",
  PAYMENT_TAB_ICON: "custom:custom41",
  PAYMENT_TAB_COMPONENT: "c__BWCCollectPaymentMethodPage",
  PAYMENT_TAB_TYPE: "standard__component"
});

const REDACTION_COMMON_MESSAGE = 
  "Trigger Redaction if Refund Method is different than Payment Method";
const REDACTION_MANDATORY_MESSAGE = "Must trigger Redaction to enter Payment Method; and/or Refund Method if applicable";  
const REDACTION_MANDATORY_CASHICP_MESSAGE = 
  "If payment method is cash or ICP, you need to request a Refund Method via Redaction";

export default class BwcRedactionAgentFacingCmp extends LightningElement {
  @api objectApiName;
  @api recordId;

  @api mode = Mode.EDIT;

  error;

  _exisitngPaymentDetails;
  @wire(getAuxDetails, { recordId: "$recordId" })
  existingPaymentDetails({ error, data }) {
    if (data) {
      this._exisitngPaymentDetails = data;
      this.error = undefined;
      this.initState();
    } else {
      this._exisitngPaymentDetails = undefined;
      this.error = error;
      console.error(
        "Failed to get existing payment details",
        JSON.stringify(error),
        error
      );
    }
  }

  @wire(getBAN, { sobjId: "$recordId" })
  billingAccount;

  @wire(getCustomer, { sobjId: "$recordId" })
  customer;

  _currCaseAction;
  @api get caseAction() {
    return this._currCaseAction;
  }
  set caseAction(ca) {
    this._currCaseAction = ca;
    this.initState();
  }

  @track _currState;

  paymentType;
  paymentNameOnAcc;

  refundType;
  refundNameOnAcc;

  isRedactionMessageVisible = false;
  isRedactionUrlVisible = false;
  isCashICPswitchVisible = false;
  isPaymentTypeDetailsVisible = false;
  isRefundTypeDetailsVisible = false;

  // used to send messages about redaction start/stop 
  // if parent need to know about mandatory
  isMandatoryRedactionStarted = false; 

  constructor(...args) {
    super(...args);
    console.debug("--->>> bwcRedactionAgentFacingCmp constructor");
  }

  @wire(MessageContext)
  messageContext;

  completeRedactionSubscription;

  @track
  redactionMessage = REDACTION_COMMON_MESSAGE;
  @track
  redactionClasses = "slds-scoped-notification slds-theme_info";

  adjustRedactionMessage( cashICPChecked ) {
    const isMand = this.isMandatoryRedaction();
    this.redactionMessage = (isMand) ? 
      (
        (cashICPChecked) ? 
          REDACTION_MANDATORY_CASHICP_MESSAGE : REDACTION_MANDATORY_MESSAGE
      )
      : REDACTION_COMMON_MESSAGE;
    this.redactionClasses = ( isMand && cashICPChecked ) ? 
      "slds-scoped-notification slds-theme_warning"
      :
      "slds-scoped-notification slds-theme_info"
      ; 
  }

  subscribeToMessageChannel() {
    console.debug("--->>> subscribeToMessageChannel");
    if (!this.completeRedactionSubscription) {
      this.completeRedactionSubscription = subscribe(
        this.messageContext,
        completeRedactionMsgChannel,
        (message) => this.completeRedactionMessageHandler(message),
        { scope: APPLICATION_SCOPE }
      );
    }
  }

  unsubscribeToMessageChannel() {
    unsubscribe(this.completeRedactionSubscription);
    this.completeRedactionSubscription = null;
  }

  connectedCallback() {
    this.subscribeToMessageChannel();
  }

  disconnectedCallback() {
    this.unsubscribeToMessageChannel();
  }

  isUnidentifiedPayment() {
    return (
      this._exisitngPaymentDetails && this._exisitngPaymentDetails.length === 0
    );
  }

  getCashICPFieldValue(cashICPChecked) {
    let res = cashICPChecked;
    if (!res) {
      res = this.isCashSelected();
    }
    return res
      ? machine.CASH_ICP_SWITCH_VALUE.ON
      : machine.CASH_ICP_SWITCH_VALUE.OFF;
  }

  getPaymentSource() {
    const existingPaymentMethod = !this.isUnidentifiedPayment()
      ? this._exisitngPaymentDetails.filter(
          (v) => v.Name__c === CASE_AUX_DETAILS_PAYMENT_METHOD_FLD
        )[0]
      : undefined;
    console.debug( 
      '--->>> existingPaymentMethod ' 
      + JSON.stringify( existingPaymentMethod ) 
    );
    const pm = this.isUnidentifiedPayment()
      ? machine.PAYMENT_SOURCE.FROM_UNIDENTIFIED_PAYMENT
      : EXIST_PAYMENT_METHOD_2_PAYMENT_SOURCE[existingPaymentMethod.Value__c];
    if (!pm) {
      throw new Error(
          "Unknown payment method for state machine [" +
            JSON.stringify( existingPaymentMethod ) +
            "]"
      );
    }
    return pm;
  }

  initState(cashICPChecked) {
    this.notifyParentRedactionFinished( cashICPChecked );

    if (!this.caseAction || !this._exisitngPaymentDetails) {
      return;
    }

    const paymentSource = this.getPaymentSource();

    const newState = new machine.RedactionState(
      paymentSource,
      this.caseAction,
      this.getCashICPFieldValue(cashICPChecked)
    );
    this.setState(newState.state);

    this.notifyParentRedactionStarted();

    // {
    //   "REDACTION_MSG":{"visible":false},
    //   "REDACTION_URL":{"visible":false},
    //   "CASH_ICP_SWITCH":{"visible":false}
    //   "REDACTION_PAYMENT_TYPE_PAIR":{"visible":true},
    //   "REDACTION_REFUND_TYPE_PAIR":{"visible":true},
    //   "REDACTION_CAPABILITIES":[]
    // }    
    // if ( this._currState && !this._currState.REDACTION_URL.visible ) { 
    this.completeRedactionMessageHandler( this._exisitngPaymentDetails );
    // } 
    this.adjustRedactionMessage( cashICPChecked );
  }

  setState(newState) {
    this._currState = newState;
    console.debug("--->>> new State: " + JSON.stringify(this._currState));

    this.isRedactionMessageVisible = this.checkVisibility(
      machine.AGENT_UI_ELEMS.REDACTION_MSG
    );
    this.isRedactionUrlVisible = this.checkVisibility(
      machine.AGENT_UI_ELEMS.REDACTION_URL
    );
    this.isCashICPswitchVisible = this.checkVisibility(
      machine.AGENT_UI_ELEMS.CASH_ICP_SWITCH
    );
    this.isPaymentTypeDetailsVisible = this.checkVisibility(
      machine.AGENT_UI_ELEMS.REDACTION_PAYMENT_TYPE_PAIR
    );
    this.isRefundTypeDetailsVisible = this.checkVisibility(
      machine.AGENT_UI_ELEMS.REDACTION_REFUND_TYPE_PAIR
    );
  }

  checkVisibility(uiElem) {
    console.debug("--->>> checkVisibility UI-ELEM [" + uiElem + "]");
    let res = false;
    if (this._currState) {
      res = this._currState[uiElem].visible;
    }
    return res;
  }

  handleCashICPChange(event) {
    const cashICPChecked = event.target.checked;
    console.debug(
      "--->>> handleCashICPChange cashICP.checked=" + cashICPChecked
    );
    // clean up previously set values
    this.paymentType = this.paymentNameOnAcc = 
    this.refundType = this.refundNameOnAcc = undefined;
    this.setPaymentTypeDetails( 
      "payment-type", "", 
      "payment-name-on-acc", "" 
    );
    this.setPaymentTypeDetails( 
      "refund-type", "", 
      "refund-name-on-acc", "" 
    );
    this.initState(cashICPChecked);
  }

  sendEventToParent( eventName, eventPayload = undefined ) {
    const evt = new CustomEvent( 
      eventName,  
      { 
        detail: (eventPayload) ? eventPayload : eventName  
      } 
    );
    this.dispatchEvent( evt );    
  }

  notifyParentRedactionStarted() {
    if ( this.isMandatoryRedaction() ) {
      this.isMandatoryRedactionStarted = true;
      this.sendEventToParent( "redactionstarted" );
    }
  }

  isCashSelected() {
    const fld = this.template.querySelector( ".cash-icp" );
    return (fld && fld.checked);
  }

  isMandatoryRedaction() {
    return this.isUnidentifiedPayment() && this.isRedactionUrlVisible;
  }

  notifyParentRedactionFinished( cashICPChecked ) {
    if ( this.isMandatoryRedactionStarted ) {
      this.isMandatoryRedactionStarted = false;
      this.sendEventToParent( "redactionfinished" );
    }
  }

  startRedaction() {

    let capabilities = this._currState[machine.REDACTION_CAPABILITIES];
    if (capabilities && capabilities.length === 0) {
      capabilities = undefined;
    } else {
      capabilities = JSON.stringify(capabilities);
    }
    const message = {
      pageReference: {
        type: TAB_CONSTANTS.PAYMENT_TAB_TYPE,
        attributes: {
          componentName: TAB_CONSTANTS.PAYMENT_TAB_COMPONENT
        },
        state: {
          c__recordId: this.recordId,
          c__capabilities: capabilities,
          c__defaultBan: this.billingAccount.data.Billing_Account_Number__c
        }
      },
      label: TAB_CONSTANTS.PAYMENT_TAB_LABEL,
      icon: TAB_CONSTANTS.PAYMENT_TAB_ICON
    };
    BwcUtils.openSubTab(message);
  }

  completeRedactionMessageHandler(message) {
    const caseActionGroup = CaseActionsToGroup[ this.caseAction ];
    const rmd = new RedactionMoneyDetails(
      this.recordId,
      this.getPaymentSource(),
      caseActionGroup,
      this.customer,
      this.isCashSelected(),
      this._exisitngPaymentDetails
    );

    rmd.getDetails( message ).then(redactionDetails=>{
      
      this.paymentType = redactionDetails.paymentType;
      this.paymentNameOnAcc = redactionDetails.paymentNameOnAcc;
      this.refundType = redactionDetails.refundType;
      this.refundNameOnAcc = redactionDetails.refundNameOnAcc;

      this.setPaymentTypeDetails( 
        "payment-type", redactionDetails.paymentType, 
        "payment-name-on-acc", redactionDetails.paymentNameOnAcc 
      );
      this.setPaymentTypeDetails( 
        "refund-type", redactionDetails.refundType, 
        "refund-name-on-acc", redactionDetails.refundNameOnAcc 
      );
      // We got empty array when redaction has not happen yet
      if ( Array.isArray( message ) && message.length === 0 ) {
        return;
      }
      this.notifyParentRedactionFinished( this.isCashSelected() );
    });    
  }

  setPaymentTypeDetails(typeFieldClass, typeValue, nameFieldClass, nameOnAcc) {
    if ( !typeValue ) {
      nameOnAcc = ""; // enforce empty, since customer always has name, but without
      // refund/payment it does not make sense to print it
    }
    const pt = this.template.querySelector("." + typeFieldClass);
    if (pt) {
      pt.value = typeValue;
      console.debug(
        "--->>> setPaymentTypeDetails: typeValue: " + typeValue + ";"
      );
    }

    const pn = this.template.querySelector("." + nameFieldClass);
    if (pn) {
      pn.value = nameOnAcc;
      console.debug(
        "--->>> setPaymentTypeDetails: nameOnAcc: " + nameOnAcc + ";"
      );
    }
  }
}