import { LightningElement, wire } from "lwc";

import BWC_DEBUG_CP from "@salesforce/customPermission/BWC_Debug";
if (!BWC_DEBUG_CP) {
  console.debug = ()=>{};
  console.log = ()=>{};
}

import { getRecord, getRecordNotifyChange } from "lightning/uiRecordApi";
import USERID from "@salesforce/user/Id";
import ATTUID from "@salesforce/schema/User.ATTUID__c";
import FEDID from "@salesforce/schema/User.FederationIdentifier";

import getRegistrationData from '@salesforce/apex/BWC_RAISRController.getRegistrationData';
import { refreshApex } from '@salesforce/apex';

import * as RAISR_API from "c/bwcRaisrAPI";
import * as RAISR_MSG_CH from "c/bwcRaisrMsgPubSubCmp";

// Enable/Disable RAISR Management Form
import HAS_VOICE_REDACTION from '@salesforce/customPermission/VoiceRedaction';

// Console specific events from LWC channel
import {
  subscribe,
  unsubscribe,
  APPLICATION_SCOPE,
  MessageContext
} from 'lightning/messageService';
import CONSOLE_API_MSG_CH from "@salesforce/messageChannel/BWC_ConsoleApi__c";

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import * as SMART_FLD_REGISTRY from "./fieldsRegistry";

import { consoleApiCall } from "c/bwcPageHelpers";

const INTERACTION_CTXT = Object.freeze({
  TEST: 1,
  CALL: 2,
  RECORDER: 4,
  PLAYER: 8
});

// how many time we try to get CRN from Interaction
//
// we need it because Coral update Interaction__c asynchronously
//
const MAX_CRN_ATTEMPTS = 10; 

const UTILITY_LABEL = "Voice-Masking";
const UTILITY_HEADER_H = 50;

export default class BwcRaisrManagerCmp extends LightningElement {
  consoleApiSubscribtion = null;
  @wire(MessageContext)
  consoleApiMessageContext = null;

  isTester = BWC_DEBUG_CP;

  hasVoiceRedaction = HAS_VOICE_REDACTION;

  callContext = {
    attuid: undefined,
    crn: undefined, // call reference number
    ban: undefined,
    ws: undefined // websocket to SC-SPI
  };

  isRaisrActive = false;

  raisrApi;

  smartFieldsRegistry;

  interactionId = undefined;
  callReferenceNumber = undefined;
  crnAttempt = 0;

  utilityId;

  constructor() {
    super();
    if ( this.hasVoiceRedaction ) {
      window.WebSocket = new Proxy(WebSocket, {
        construct: (target, args) => {
          return new target(...args);
        }
      });
      this.smartFieldsRegistry = new SMART_FLD_REGISTRY.FieldsRegistry();
    }
  }

  connectedCallback() {
    if ( this.hasVoiceRedaction ) {
      this.subscribeToConsoleApiMessageChannel();
    }
  }

  isMsgPubSubRendered = false;
  renderedCallback() {
    if ( !this.hasVoiceRedaction ) {
      return;
    }
    if (!this.isMsgPubSubRendered) {
      if (
        this.sendMessageToRaisrChannel(
          RAISR_MSG_CH.raisrManagerRegistered( this.isRaisrActive )
        )
      ) {
        this.isMsgPubSubRendered = true;
        console.debug("RAISR Manager registration event");
      }
    }
  }

  disconnectedCallback() {
    if ( this.hasVoiceRedaction ) {
      this.unsubscribeFromConsoleApiMessageChannel();
    }
  }

  @wire(getRecord, { recordId: USERID, fields: [ATTUID, FEDID] })
  wireuser({ error, data }) {
    if (error) {
      console.error(
        "ERROR: Cannot get ATTUID for the current User: " +
          JSON.stringify(error.body),
        error
      );
    } else if (data) {
      this.callContext.attuid = data.fields.ATTUID__c.value;
      if (!this.callContext.attuid) {
        this.callContext.attuid = data.fields.FederationIdentifier.value;
      }
    }
  }

  getCallReferenceNumber() {
    if ( this.crnAttempt > MAX_CRN_ATTEMPTS && !this.callReferenceNumber ) {
      return;
    }
    getRegistrationData( { interactionId: this.interactionId } )
      .then(interRec=>{
        console.debug( "getCallReferenceNumber:: data " + JSON.stringify( interRec ) );
        let payload;
        if ( !interRec.callReferenceNumber ) {
          this.retryCrnAttempt();
          if ( this.crnAttempt > MAX_CRN_ATTEMPTS ) {
            payload = RAISR_MSG_CH.raisrStatusInternal( false, "Cannot obtain CRN" );
            console.warn( "getCallReferenceNumber", payload );
          }
        }
        else {
          payload = RAISR_MSG_CH.raisrStatusInternal( true, "Connected to the Call " + interRec.callReferenceNumber );        
          console.info( "getCallReferenceNumber got CRN: " + JSON.stringify( interRec ) );
          this.callReferenceNumber = interRec.callReferenceNumber;
          this.crnAttempt = 0;

          this.callContext.crn = this.callReferenceNumber;
          this.callContext.ban = interRec.ban;
          
          this.startRaisr(INTERACTION_CTXT.CALL);      
        }
        this.sendMessageToRaisrChannel( payload );
      })
      .catch(error=>{
        console.error( "ERROR: Failed to get Call Reference Data:", error );
      })    
  }

  retryCrnAttempt() {
    if ( this.crnAttempt > MAX_CRN_ATTEMPTS && !this.callReferenceNumber ) {
      console.warn( 
        "getCallReferenceNumber Cannot get Call Reference Number for Interaction Id=" 
        + this.interactionId + ";" 
      );
      return;
    }
    if ( !this.callReferenceNumber ) {
      const recId2refresh = "" + this.interactionId;
      refreshApex( recId2refresh );
      this.crnAttempt++;
      if ( this.crnAttempt <= MAX_CRN_ATTEMPTS ) {
        setTimeout(
          () => {
            this.getCallReferenceNumber();
            console.debug( "getCallReferenceNumber NEXT CRN ATTEMPT", this.crnAttempt );
          }, 
          1000 * (this.crnAttempt)
        );
      }
    }
  }

  subscribeToConsoleApiMessageChannel() {
    if (!this.consoleApiSubscribtion) {
        this.consoleApiSubscribtion = subscribe(
            this.consoleApiMessageContext,
            CONSOLE_API_MSG_CH,
            (message) => this.handleConsoleApiMessage(message),
            { scope: APPLICATION_SCOPE }
        );
    }
  }

  unsubscribeFromConsoleApiMessageChannel() {
    unsubscribe(this.consoleApiSubscribtion);
    this.consoleApiSubscribtion = null;
  }

  handleConsoleApiMessage( msg ) {
    console.debug( "Got console API event " + JSON.stringify( msg ) );
    if ( msg.eventType === "lightning:tabCreated" ) {
      const newTabId = msg.eventBody.params.tabId;
      const allTabs = msg.eventBody.allTabInfo;
      const interactionTab = allTabs.filter(
        t=>t.tabId === newTabId 
        && t?.pageReference?.attributes?.objectApiName === "Interaction__c"
      );
      // console.debug( "--->>> CONSOLE_API_MESSAGE: " + JSON.stringify( interactionTab ) );
      if ( interactionTab && interactionTab.length === 1 ) {
        const trgTab = interactionTab[ 0 ];
        console.debug( "--->>> FOUND INTERACTION: " + JSON.stringify( trgTab ) );
        this.interactionId = trgTab.pageReference.attributes.recordId;
        this.crnAttempt = 0;
        this.getCallReferenceNumber();
      }
      else {
        this.interactionId = undefined;
        this.callReferenceNumber = undefined;
      }
    }
    else if ( msg.eventType === "onUtilityClick" ) {
      const activeUtility = msg.activeUtility; // {"utilityId":"649:0","panelVisible":true}
      console.debug( "--->>> GOT Active Utiltiy event " + JSON.stringify( activeUtility ) );
      
      const setHeightIfNeeded = () => {
        if ( activeUtility.utilityId === this.utilityId ) {
          this.calcUtilityHeight();
        }
      }

      if ( !this.utilityId ) {
        consoleApiCall( "getAllUtilityInfo" )
          .then( utils => {
            const sfu = utils.filter(u=>u.utilityLabel === UTILITY_LABEL);
            if ( sfu && sfu.length ) {
              this.utilityId = sfu[ 0 ].id;
            }
            setHeightIfNeeded();
          });
      }
      else {
        setHeightIfNeeded();
      }

    }
  }

  async startTest(msg) {
    console.debug(
      "Starting Test: GOT" + JSON.stringify(msg.detail),
      "attuid: " + this.callContext.attuid
    );
    this.callContext.crn = msg.detail.crn;
    this.callContext.ban = msg.detail.ban ? undefined : msg.detail.ban;

    this.startRaisr(INTERACTION_CTXT.TEST);

    const ok = {
      title: 'RAISR TEST STARTED',
      message: "Connected to RAISR simulator for testing",
      variant: "success"
    };
    const event = new ShowToastEvent( ok );
    this.dispatchEvent( event );
  }

  async startRaisr(interactionContext) {
    let callctxt;
    try {
      this.callContext = await RAISR_API.Factory.newWebSocketInstanceAsync(
        this.callContext
      );
      if ( this.callContext.connection_error || !this.callContext.ws ) {
        this.isRaisrActive = false;
        this.sendMessageToRaisrChannel( RAISR_MSG_CH.raisrStatusInternal( this.isRaisrActive ) );
        return;
      }

      this.isRaisrActive = true;
      this.sendMessageToRaisrChannel( RAISR_MSG_CH.raisrStatusInternal( this.isRaisrActive ) );
      this.callContext.ws.addEventListener("message", (msg) => {
        this.onMessageFromRaisr(msg);
      });
      this.callContext.ws.addEventListener("error", (msg) => {
        this.onErrorFromRaisr(msg);
      });
      this.callContext.ws.addEventListener("close", (msg) => {
        this.isRaisrActive = false;
        this.onCloseFromRaisr(msg);
      });
      this.raisrApi = new RAISR_API.RaisrAPI(this.callContext);
    } catch (e) {
      console.error("ERROR starting Raisr interaction", e);
    }
  }

  sendMessageToRaisrChannel(msg) {
    const msgCh = this.template.querySelector("c-bwc-raisr-msg-pub-sub-cmp");
    if (msgCh) {
      msgCh.postMessage(msg);
    }
    return msgCh ? true : false; // may be just (msgCh) suffice, but just in case
  }

  registerFieldIfNeeded( context, name, type ) {
    const isAlreadyRegistered = this.smartFieldsRegistry.isFieldRegistered(
      context, name, type
    );
    if (!isAlreadyRegistered) {
      console.debug( 
        "--->>> NEW FIELD REGISTRATION: context: [" + context
        + "]; name: [" + name + "]; type: [" + type + "];"
      );
      this.smartFieldsRegistry.registerField(
        context, name, type
      );
      const presetFld = this.smartFieldsRegistry.getAndCleanupOutOfCtxtField( type );
      if ( presetFld ) {
        const payload = RAISR_MSG_CH.raisrComplete( 
          context, 
          name, 
          type,
          presetFld.fieldValue,
          presetFld.token
        );
        console.debug( 
          "--->>> SETTING PRESET VALUE: " + JSON.stringify( payload )
        );
        this.sendMessageToRaisrChannel( payload );
      }
    }
    this.updateCurrContextAndField( context, name );
  }

  updateCurrContextAndField( context, name ) {
    this.smartFieldsRegistry.currContext = context;
    this.smartFieldsRegistry.currField = name;
  }

  handleRaisrChannelEvent(message) {
    const msg = message.detail.message;
    console.debug("handleRaisrChanelEvent", JSON.stringify(msg));
    /**
     * {"messageSource":"RAISR_FIELD","messageType":"FIELD_REGISTER_REQ","messageBody":{"fieldIdOrName":"CC1_Zip","context":"new payment","raisrFieldType":"ZIP"}}
     */
    if (msg.messageSource === RAISR_MSG_CH.MSG_SOURCE.RAISR_FIELD) {
      const ctxt = msg.messageBody.context;
      const fname = msg.messageBody.fieldIdOrName;
      const ftype = msg.messageBody.raisrFieldType;

      if (msg.messageType === RAISR_MSG_CH.MSG_TYPE.FIELD_UNREGISTER_REQ) {
        console.debug( `Field unregister context: ${ctxt}; fieldName: ${fname}; FieldType: ${ftype};` );
        this.smartFieldsRegistry.unregisterField( ctxt, fname, ftype );
      }
      else {
        this.registerFieldIfNeeded( ctxt, fname, ftype );
      }

      if (msg.messageType === RAISR_MSG_CH.MSG_TYPE.FIELD_REGISTER_REQ) {
        console.debug( "Field Registration " );
        let payload = RAISR_MSG_CH.raisrStatusInternal( this.isRaisrActive, "Response for registration" );
        this.sendMessageToRaisrChannel( payload );
      } else if (msg.messageType === RAISR_MSG_CH.MSG_TYPE.FIELD_FOCUS) {
        // this.raisrApi?.focus( msg.messageBody.raisrFieldType );
        this.raisrApi?.focus( ftype );
      }
    }
    if (msg.messageSource === RAISR_MSG_CH.MSG_SOURCE.RAISR_DROP_DOWN_CONTROL) {
      if (msg.messageType === RAISR_MSG_CH.MSG_TYPE.RAISR_STATUS) {
        console.debug(
          "Changing Raisr Status from " +
            this.isRaisrActive +
            " to " +
            msg.messageBody.isRaisrActive +
            ";"
        );
        this.isRaisrActive = msg.messageBody.isRaisrActive;
        this.raisrApi?.override( msg.messageBody.reason );
      }
      else if ( msg.messageType === RAISR_MSG_CH.MSG_TYPE.RAISR_CONTROL_FORM_STARTED_INTERNAL ) {
        const payload = 
          RAISR_MSG_CH.raisrStatusInternal( this.isRaisrActive, "Response for registration" );
        this.sendMessageToRaisrChannel( payload );
      }
    }
  }

  forwardRaisrMsgToSF( raisrMsg, sfMsg ) {
    console.debug( 
      "forwardRaisrMsgToSF raisrMsg [" + JSON.stringify( raisrMsg ) 
      + "] sfMsg [" + JSON.stringify( sfMsg ) + "]" 
    );
    const fldType = raisrMsg.fieldName;
    const trgField = this.smartFieldsRegistry.findFieldByType( fldType );
    console.debug( 
      "Found Field for EVENT from RAISR: " + JSON.stringify( trgField ), 
      "currContext:", this.smartFieldsRegistry.currContext 
    );
    this.sendMessageToRaisrChannel( sfMsg );
  }

  onMessageFromRaisr(message) {
    const msg = JSON.parse( message.data );
    console.debug(`onMessageFromRaisr ${JSON.stringify(msg)}`);

    const fldType = msg.fieldName;
    const trgField = this.smartFieldsRegistry.findFieldByType( fldType );

    if ( msg.name === "PROMPT" && trgField ) {
      this.sendMessageToRaisrChannel(
        RAISR_MSG_CH.raisrPrompt( 
          this.smartFieldsRegistry.currContext, 
          trgField.name, 
          trgField.type 
        )
      );
    } else if ( msg.name === "DIGIT" && trgField ) {
      let payload;
      if ( msg.hasOwnProperty( "success" ) && !msg.success ) {
        payload = RAISR_MSG_CH.raisrError( 
          this.smartFieldsRegistry.currContext, 
          trgField.name, 
          trgField.type, 
          (msg.reasonCode) ? msg.reasonCode : "00000-TEST",
          (msg.reason) ? msg.reason : "Unknown Error",  
        );
      }
      else {
        payload = RAISR_MSG_CH.raisrDigits( 
          this.smartFieldsRegistry.currContext, 
          trgField.name, 
          trgField.type,
          msg.fieldValue
        );
      }
      this.sendMessageToRaisrChannel( payload );
    } else if ( msg.name === "COMPLETE" ) {
      let payload;
        if ( msg.hasOwnProperty( "success" ) && !msg.success ) {
          payload = RAISR_MSG_CH.raisrError( 
            this.smartFieldsRegistry.currContext, 
            trgField.name, 
            trgField.type, 
            (msg.reasonCode) ? msg.reasonCode : "00000-TEST",
            (msg.reason) ? msg.reason : "Unknown Error",  
          );
        }
        else { // SUCCESS
          if ( !trgField ) {
            this.smartFieldsRegistry.addOutOfCtxtField(
              msg.fieldName, msg.fieldValue, msg.token
            );
          }
          else {
            payload = RAISR_MSG_CH.raisrComplete( 
              this.smartFieldsRegistry.currContext, 
              trgField.name, 
              trgField.type,
              msg.fieldValue,
              msg.token
            );
          }
        }
        this.sendMessageToRaisrChannel( payload );
    } else if ( msg.name === "ERROR" ) {
      // console.debug( "Recieved ERROR: " + JSON.stringify( msg ) );
      const err = {
        title: 'Restricted Access',
        message: msg.reason,
        variant: "error"
      };
      console.debug( "Error Toast payload: " + JSON.stringify( err ) );
      const event = new ShowToastEvent( err );
      this.dispatchEvent( event );
    }
  }

  onErrorFromRaisr(msg) {
    console.error("WebSocket");
  }

  onCloseFromRaisr(msg) {
    console.debug("Closing RAISR websocket...");
    const payload = RAISR_MSG_CH.raisrStatusInternal( 
      this.isRaisrActive, 
      "Disconnected from the call " + this.callContext?.crn 
    );
    this.sendMessageToRaisrChannel( payload );
  }

  calcUtilityHeight() {
    let info = consoleApiCall( "getAllUtilityInfo" )
      .then( utils => {
        const sfu = utils.filter(u=>u.utilityLabel === UTILITY_LABEL);
        console.debug( "GOT smart-field utility " + JSON.stringify( sfu ) + ";" );
        let h;
        if ( sfu && sfu.length ) {
          const testFrm = this.template.querySelector( "c-bwc-raisr-tester-cmp" );
          const raisrFrm = this.template.querySelector( "c-bwc-raisr-manager-form-cmp" );
          const tstH = (testFrm) ? parseInt( testFrm.ioFormHeight ) : 0;
          const raisrH = (raisrFrm) ? parseInt( raisrFrm.ioFormHeight ) : 0; 
          h = (isNaN(tstH) ? 0 : tstH) + (isNaN(raisrH) ? 0 : raisrH) + UTILITY_HEADER_H;
          this.utilityId = sfu[ 0 ].id;
        }
        return Promise.resolve( { h: h, id: sfu[0].id } );
      })
      .catch( ex => {
        console.error( "Failed to get Smart-Field Utility height", ex );
      });

      info.then((v) => {
        console.debug( "Terget INFO = " + JSON.stringify( v ) + ";" );
        if ( v.h >= 0 ) {
          consoleApiCall( "setPanelHeight", { heightPX: v.h, utilityId: v.id } )
          .then( res => {
            console.debug( "Result of the Height set: " + res );
          });
        }
      })
      .catch( ex => {
        console.error( "Failed to set Smart-Field Utility height", ex );
      });

      // consoleApiCall( "setPanelHeight", { heightPX: h, utilityId: sfu[0].id } )
      // .then( res => {
      //   console.debug( "res: " + res );
      // });
    }

  testFormDimensionChanged( event ) {
    console.debug( "GOT RAISR TEST FORM dimensionchanged event: " + JSON.stringify( event.detail ) + ";" );
    this.calcUtilityHeight();
  }

  raisrControlFormDimensionChanged( event ) {
    console.debug( "GOT RAISR CONTROL FORM dimensionchanged event: " + JSON.stringify( event.detail ) + ";" );
    this.calcUtilityHeight();
  }
}