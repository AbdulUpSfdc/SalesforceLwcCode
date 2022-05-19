import { LightningElement, wire, api } from "lwc";
import {
  publish,
  subscribe,
  unsubscribe,
  APPLICATION_SCOPE,
  MessageContext
} from "lightning/messageService";
import RAISR_MSG_CH from "@salesforce/messageChannel/BWC_Raisr__c";

import * as MSG_FACTORY from "./messageFactory";

export const MSG_TYPE = MSG_FACTORY.MSG_TYPE;
export const MSG_SOURCE = MSG_FACTORY.MSG_SORCE;
export const raisrCtrlFormButtonRegistration = MSG_FACTORY.raisrCtrlFormButtonRegistration;
export const smartFieldRegistrationReq = MSG_FACTORY.smartFieldRegistrationReq;
export const smartFieldUnregistrationReq = MSG_FACTORY.smartFieldUnregistrationReq;
export const raisrManagerRegistered = MSG_FACTORY.raisrManagerRegistered;
export const raisrStatus = MSG_FACTORY.raisrStatus;
export const raisrStatusInternal = MSG_FACTORY.raisrStatusInternal;
export const fieldFocus = MSG_FACTORY.fieldFocus;
export const raisrPrompt  = MSG_FACTORY.raisrPrompt;
export const raisrDigits = MSG_FACTORY.raisrDigits;
export const raisrComplete = MSG_FACTORY.raisrComplete;
export const raisrError = MSG_FACTORY.raisrError;
export default class BwcRaisrMsgPubSubCmp extends LightningElement {

  @api parentId;

  @wire(MessageContext)
  messageContext;

  static messageCounter = 0;
  lastProcessedMessage = 0;

  @api
  postMessage( message ) {
    // Augment message with counter
    if ( message && message.messageBody && !message.messageBody.messageNum ) {
      message.messageBody.messageNum = BwcRaisrMsgPubSubCmp.messageCounter++;
      console.debug( 
        "BwcRaisrMsgPubSubCmp::postMessage(): parentId=" 
        + this.parentId + "; message=" + JSON.stringify( message ) 
      );
      try {
        publish(this.messageContext, RAISR_MSG_CH, message );
      }
      catch ( e ) {
        console.error( "Publish to RAISR Channel failed: ", e );
      }
    }
  }

  subscribeToMessageChannel() {
    if (!this.subscription) {
      this.subscription = subscribe(
        this.messageContext,
        RAISR_MSG_CH,
        (message) => this.handleMessage(message),
        { scope: APPLICATION_SCOPE }
      );
    }
  }

  unsubscribeToMessageChannel() {
    unsubscribe(this.subscription);
    this.subscription = null;
  }

  // Handler for message received by component
  handleMessage(message) {
    // Send event to the parent
    console.debug( 
      "--->>> bwcRaisrMsgPubSubCmp::handleMessage() parentId=" 
      + this.parentId + "; message: " + JSON.stringify( message ) 
    );
    if ( this.lastProcessedMessage < BwcRaisrMsgPubSubCmp.messageCounter ) {
      this.lastProcessedMessage = message.messageBody.messageNum;
      const payload = {
        detail: {
          message: message
        }
      }
      const evt = new CustomEvent( "raisrevent", payload );
      this.dispatchEvent( evt );
      // this.dispatchEvent( new CustomEvent( "raisrevent", {
      //   detail: message
      // }));    
    }
    else {
      console.warn( "Skipping message parentId=" + this.parentId + "; message: " + JSON.stringify( message ) );
    }
  }

  // Standard lifecycle hooks used to subscribe and unsubsubscribe to the message channel
  connectedCallback() {
    this.subscribeToMessageChannel();
  }

  disconnectedCallback() {
    this.unsubscribeToMessageChannel();
  }
}