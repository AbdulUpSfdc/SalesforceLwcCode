import { LightningElement, api, wire } from "lwc";
import audioIcon from "@salesforce/resourceUrl/audio_wave";

import * as RAISR_MSG_CH from "c/bwcRaisrMsgPubSubCmp";
import { DEF_INPUT_CLASSES, DEF_BUTTON_ICON_CLASSES } from "c/bwcRaisrFieldCmp";

const DEF_ICON_CLASSES = "slds-button__icon slds-button__icon_right";

export default class BwcRaisrFormCtrlCmp extends LightningElement {
  audioIcon = `${audioIcon}#audio-wave`;

  hasPopup = false;
  expanded = true;

  _iconClasses = DEF_ICON_CLASSES;
  @api get iconClasses() {
    return this._iconClasses;
  }
  set iconClasses(clss) {
    this._iconClasses = clss;
  }

  _isButtonRendered = false;

  renderedCallback() {
    if ( !this._isButtonRendered ) {
      const btn = this.template.querySelector( ".form-trigger" );
      if ( btn ) {
        this._isButtonRendered = true;
        const payload = RAISR_MSG_CH.raisrCtrlFormButtonRegistration();
        this.sendMessageToRaisrChannel( payload );
      }
    }
  }

  sendMessageToRaisrChannel(msg) {
    const msgCh = this.template.querySelector("c-bwc-raisr-msg-pub-sub-cmp");
    if (msgCh) {
      msgCh.postMessage(msg);
    }
    return msgCh ? true : false; // may be just (msgCh) suffice, but just in case
  }

  showRaisrManager() {
    const mgr = this.template.querySelector("section");
    if (mgr) {
      mgr.classList.toggle("slds-popover_hide");
    }
  }

  onRaisrEvent( event ) {
    // {"message":{"messageSource":"RAISR_DROP_DOWN_CONTROL","messageType":"RAISR_STATUS","messageBody":{"isRaisrActive":false,"messageNum":3}}}
    if ( event && event.detail ) {
      const msg = event.detail.message;
      if ( !msg ) {
        return;
      }
      const isStatusChange = 
        (
          msg.messageSource === RAISR_MSG_CH.MSG_SOURCE.RAISR_DROP_DOWN_CONTROL
          || msg.messageSource === RAISR_MSG_CH.MSG_TYPE.RAISR_UTIL_BAR_CONTROL
        )
        && (
          msg.messageType === RAISR_MSG_CH.MSG_TYPE.RAISR_STATUS
          || msg.messageType === RAISR_MSG_CH.MSG_TYPE.RAISR_STATUS_INTERNAL 
          || msg.messageType === RAISR_MSG_CH.MSG_TYPE.RAISR_MANAGER_STARTED
        );
      const isRaisrActive = msg.messageBody.isRaisrActive;  
      if ( isStatusChange ) {
        this._iconClasses = (isRaisrActive) ? 
        DEF_ICON_CLASSES : DEF_ICON_CLASSES + " raisr-disabled";
        const btn = this.template.querySelector( ".form-trigger" );
        // if ( btn && !isRaisrActive ) {
        //   btn.classList.add( "disable-button-text" );
        // }
        // else {
        //   btn.classList.remove( "disable-button-text" );
        // }
      } 
    }
  }
}