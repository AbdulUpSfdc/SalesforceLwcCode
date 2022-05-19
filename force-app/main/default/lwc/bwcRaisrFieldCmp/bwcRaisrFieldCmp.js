import { LightningElement, api, track } from "lwc";
import * as ATTEMPT from "./attempts";
import * as RAISR_FIELD_TYPE from "./raisrFieldTypes";
import * as CLS from "./classes";
import * as RAISR_MSG_CH from "c/bwcRaisrMsgPubSubCmp";
import audioIcon from '@salesforce/resourceUrl/audio_wave';

export { RAISR_FIELD_TYPE as FIELD_TYPE };

export const DEF_INPUT_CLASSES = "slds-input";
export const DEF_ICON_CLASSES = "slds-icon slds-input__icon slds-input__icon_right slds-icon-text-default slds-icon_xx-small ";
export const DEF_BUTTON_ICON_CLASSES = "slds-button__icon slds-icon-text-light";

export const ICON_URL = Object.freeze({
  AUDIO: `${audioIcon}#audio-wave`,
  CLOSE: "/_slds/icons/utility-sprite/svg/symbols.svg#close",
  REFRESH: "/_slds/icons/utility-sprite/svg/symbols.svg#refresh",
});

export const CLASSES = CLS;

const defaultHelperPopupStyle = "position: absolute; top: 5em; left: ";
const DEF_INPUT_HELPER_CLASSES = "slds-form-element__help";
const ERROR_CLASS = "slds-has-error";

export const RAISR_ICON_CLASSES = [ 
  "raisr-active", "raisr-recieving", "raisr-complete", "raisr-error", "raisr-disabled" 
];

export const getRaisrFieldType = (ft) => RAISR_FIELD_TYPE.RAISR_FIELD_TYPE[ ft ];
export default class bwcRaisrFieldCmp extends LightningElement {
  _name;
  @api get name() {
    if (!this._name) {
      this._name = this.context + "_" + getRaisrFieldType(this.raisrFieldType);
    }
    return this._name;
  }
  set name(nm) {
    this._name = nm;
  }

  error = "";

  @api context = "N/A";

  _isRaisrActive = true;

  @api required = false;

  _value = "";
  @api get value() {
    return this._value;
  }
  set value(v) {
    this._value = v;
  }
  @api visibleValue = this.value;

  _token = "";
  @api get token() {
    return this._token;
  }
  set token(t) {
    this._token = t;
  }

  _raisrFieldType = "";
  @api get raisrFieldType() {
    return this._raisrFieldType;
  }
  set raisrFieldType(rft) {
    this._raisrFieldType = rft;
  }

  _label = "";
  @api get label() {
    return this._label;
  }
  set label(lbl) {
    this._label = lbl;
  }

  _placeHolder = "";
  @api get placeHolder() {
    return this._placeHolder;
  }
  set placeHolder(ph) {
    this._placeHolder = ph;
  }

  _pattern;
  @api get pattern() {
    return this._pattern;
  }
  set pattern(ptrn) {
    this._pattern = ptrn;
  }

  /*** 
  
  --- Internal properties
  
  ***/
  _icon = {
    icon: ICON_URL.AUDIO,
    classes: DEF_BUTTON_ICON_CLASSES + " raisr-active"
  };
  @api get icon() {
    return this._icon;
  }
  set icon(i) {
    this._icon = i;
  }

  _isFocused = false;

  _inputClasses = DEF_INPUT_CLASSES;
  @api get inputClasses() {
    return this._inputClasses;
  }
  set inputClasses(ic) {
    this._inputClasses = ic;
  }

  _helperPopupStyle = defaultHelperPopupStyle + " 2em";
  @api get helperPopupStyle() {
    const inp = this.template.querySelector("input[ type = 'text' ]");
    if (inp && inp.clientWidth) {
      this._helperPopupStyle =
        defaultHelperPopupStyle + " " + "0" /*inp.clientWidth / 2*/ + "px";
    } else {
      this._helperPopupStyle = defaultHelperPopupStyle + " 2em";
    }
    return this._helperPopupStyle;
  }

  /*** 
  
  --- Attempts 

  ***/
  _attempt = 0;
  get attempt() {
    return ATTEMPT.attempt2str(this._attempt);
  }
  set attempt(a) {
    this._attempt++;
  }
  @track _showAttempt = false;
  get attemptClasses() {
    const clss = ATTEMPT.attemptPopClasses(this._showAttempt);
    return clss;
  }

  /*** 
  
  --- Field status related help

  ***/
  _inputHelp = {
    classes: DEF_INPUT_HELPER_CLASSES,
    text: ""
  };
  @api get inputHelp() {
    return this._inputHelp;
  }
  set inputHelp(hlp) {
    this._inputHelp = hlp;
  }

  /***
  
  --- RAISR Help Message
  
  ***/
  @api raisrRecievingHelp;

  /*** 
  
  --- Error messages
  
  ***/
  _messageWhenBadInput = "Bad Input";
  @api get messageWhenBadInput() {
    return this._messageWhenBadInput;
  }
  set messageWhenBadInput(err) {
    this._messageWhenBadInput = err;
  }

  _messageWhenPatternMismatch = "Bad Input Format";
  @api get messageWhenPatternMismatch() {
    return this._messageWhenPatternMismatch;
  }
  set messageWhenPatternMismatch(err) {
    this._messageWhenPatternMismatch = err;
  }

  _messageWhenTypeMismatch = "Wrong Type";
  @api get messageWhenTypeMismatch() {
    return this._messageWhenTypeMismatch;
  }
  set messageWhenTypeMismatch(err) {
    this._messageWhenTypeMismatch = err;
  }

  _messageWhenValueMissing = "Missed value";
  @api get messageWhenValueMissing() {
    return this._messageWhenValueMissing;
  }
  set messageWhenValueMissing(err) {
    this._messageWhenValueMissing = err;
  }

  /***
  
  --- Constructor

  ***/
  constructor() {
    super();
  }

  connectedCallback() {
    this.willValidate = true;
  }

  isMsgPubSubRendered = false;
  renderedCallback() {
    if (!this.isMsgPubSubRendered) {
      if (this.registerRaisrField()) {
        this.isMsgPubSubRendered = true;
      }
    }
  }

  registerRaisrField() {
    const res = this.sendMessageToRaisrChannel(
      RAISR_MSG_CH.smartFieldRegistrationReq(
        this.context,
        getRaisrFieldType(this.raisrFieldType),
        this.name
      )
    );
    return res;
  }

  unregisterRaisrField() {
    const res = this.sendMessageToRaisrChannel(
      RAISR_MSG_CH.smartFieldUnregistrationReq(
        this.context,
        getRaisrFieldType(this.raisrFieldType),
        this.name
      )
    );
  }

  disconnectedCallback() {
    this.unregisterRaisrField();
  }

  /***
  
  --- Events 
  
  ***/
  onfocus(event) {
    this._isFocused = true;
    this._showAttempt = false;
    this.sendMessageToRaisrChannel(
      RAISR_MSG_CH.fieldFocus(
        this.context,
        this.name,
        getRaisrFieldType(this.raisrFieldType)
      )
    );
  }

  cleanupErrorStatus() {
    this.inputClasses = new CLS.CssClasses(this.inputClasses)
      .removeClasses(ERROR_CLASS)
      .toString();
    this.inputHelp = {
      classes: new CLS.CssClasses(this.inputHelp.classes)
        .removeClasses([ERROR_CLASS, "error-message"])
        .toString(),
      text: ""
    };
  }

  errorStatusCheck() {
    this.reportValidity();
    if (this.checkValidity()) {
      // No error
      this.cleanupErrorStatus();
    } else {
      this.inputClasses = new CLS.CssClasses(this.inputClasses)
        .addClass(ERROR_CLASS)
        .toString();
      let txt = this.messageWhenBadInput;
      if (/^\s*$/.test(this.value)) {
        txt = this.messageWhenValueMissing;
      } else if (!/^\s*$/.test(this.pattern)) {
        txt = this.messageWhenPatternMismatch;
      }
      this.inputHelp = {
        classes: new CLS.CssClasses(this.inputHelp.classes)
          .addClass("error-message")
          .toString(),
        text: txt
      };
    }
  }

  onblur(event) {
    this._isFocused = false;
    if (!this._isRaisrActive) {
      this.errorStatusCheck();
    }
  }

  onpaste(event) {}

  onchange(event) {
    // this.value = event.target.value;
  }

  oninput(event) {
    this.value = event.target.value;
    this.visibleValue = this.value;
  }

  onKeyDown(event) {
  }

  onKeyUp(event) {
  }

  onKeyPress(event) {
  }

  onmouseenter(event) {
    if (!this._isFocused && this._isRaisrActive) {
      this._showAttempt = true;
    }
    if (!this._isRaisrActive || this._isFocused) {
      this._showAttempt = false;
    }
  }

  onmouseleave(event) {
    // if ( !this._isFocused ) {
    this._showAttempt = false;
    // }
  }

  changeMode(event) {
  }

  @api willValidate = false;
  @api setCustomValidity(message) {
    const inp = this.template.querySelector("input[ type = 'text' ]");
    if (inp) {
      return inp.setCustomValidity(message);
    }
  }
  @api get validity() {
    const inp = this.template.querySelector("input[ type = 'text' ]");
    if (inp) {
      return inp.validity;
    }
  }
  @api checkValidity() {
    const inp = this.template.querySelector("input[ type = 'text' ]");
    if (inp) {
      return inp.checkValidity();
    }
  }
  @api reportValidity() {
    const inp = this.template.querySelector("input[ type = 'text' ]");
    if (inp) {
      return inp.reportValidity();
    }
  }

  sendMessageToRaisrChannel(msg) {
    const raisrMsgCh = this.template.querySelector(
      "c-bwc-raisr-msg-pub-sub-cmp"
    );
    if (raisrMsgCh) {
      raisrMsgCh.postMessage(msg);
    }
    return raisrMsgCh ? true : false; // will (raisrMgCh) work without "?" ? it should, but just in case
  }

  onRaisrStatus(isActive) {
    if (!this._isRaisrActive) {
      return;
    }
    if (this._isRaisrActive) {
      this._isRaisrActive = isActive; // isActive should be false always
    }
    if (!this._isRaisrActive) {
      this.icon = {
        icon: ICON_URL.AUDIO,
        classes: new CLS.CssClasses(this.icon.classes)
          .removeClasses(RAISR_ICON_CLASSES)
          .addClass("raisr-disabled")
          .toString()
        //DEF_BUTTON_ICON_CLASSES + " raisr-disabled"
      };
    }
  }

  onRaisrPrompt() {
    if (!this._isRaisrActive) {
      return;
    }
    const inp = this.template.querySelector("input[ type = 'text' ]");
    if (inp) {
      inp.focus();
    }
    this.icon = {
      icon: ICON_URL.AUDIO,
      classes: new CLS.CssClasses(this.icon.classes)
        .removeClasses(RAISR_ICON_CLASSES)
        .addClass("raisr-active")
        .toString()
      // DEF_BUTTON_ICON_CLASSES + " raisr-active"
    };
  }

  onRaisrDigit(digits) {
    if (!this._isRaisrActive) {
      return;
    }
    this.visibleValue = digits;
    this.value = digits;
    this.inputClasses = new CLS.CssClasses(this.inputClasses)
      .removeClasses(ERROR_CLASS)
      .toString();
    this.icon = {
      icon: ICON_URL.AUDIO,
      classes: new CLS.CssClasses(this.icon.classes)
        .removeClasses(RAISR_ICON_CLASSES)
        .addClass("raisr-recieving")
        .toString()
      // DEF_BUTTON_ICON_CLASSES + " raisr-recieving"
    };
    this.inputHelp = {
      classes: new CLS.CssClasses(this.inputHelp.classes)
        .removeClasses([ERROR_CLASS, "error-message"])
        .toString(),
      text: this.raisrRecievingHelp
    };
  }

  onRaisrComplete(val, token) {
    this.value = val;
    this.visibleValue = val;
    this.token = token;
    this.error = "";
    this.inputClasses = new CLS.CssClasses(this.inputClasses)
      .removeClasses(ERROR_CLASS)
      .toString();
    this.icon = {
      icon: ICON_URL.AUDIO,
      classes: new CLS.CssClasses(this.icon.classes)
        .removeClasses(RAISR_ICON_CLASSES)
        .addClass("raisr-complete")
        .toString()
      // DEF_BUTTON_ICON_CLASSES + " raisr-complete"
    };
    this.inputHelp = {
      classes: new CLS.CssClasses(this.inputHelp.classes)
        .removeClasses([ERROR_CLASS, "error-message"])
        .toString(),
      // DEF_INPUT_HELPER_CLASSES,
      text: ""
    };
    const inp = this.template.querySelector("input[ type = 'text' ]");
    if (inp) {
      inp.blur();
    }
  }

  onRaisrError(error) {
    this.inputHelp.text = error;
    this.inputHelp.classes = new CLS.CssClasses(this.inputHelp.classes)
      .addClass("error-message")
      .toString();
    this.error = error;
    this.inputClasses = new CLS.CssClasses(this.inputClasses)
      .addClass(ERROR_CLASS)
      .toString();
    this.icon = {
      icon: ICON_URL.AUDIO,
      classes: new CLS.CssClasses(this.icon.classes)
        .removeClasses(RAISR_ICON_CLASSES)
        .addClass("raisr-error")
        .toString()
    };
    this.value = "";
    this.visibleValue = this.value;
    this.token = "";
  }

  // Events from Raisr Message channel
  onRaisrEvent(event) {
    const msg = event.detail.message;
    const isFromCtrl =
      msg.messageSource === RAISR_MSG_CH.MSG_SOURCE.RAISR_DROP_DOWN_CONTROL ||
      msg.messageSource === RAISR_MSG_CH.MSG_SOURCE.RAISR_UTIL_BAR_CONTROL;
    const isCtrlRegister =
      msg.messageType === RAISR_MSG_CH.MSG_TYPE.RAISR_MANAGER_STARTED ||
      msg.messageType === RAISR_MSG_CH.MSG_TYPE.RAISR_CONTROL_FORM_STARTED;
    const isCtrlStatus =
      msg.messageType === RAISR_MSG_CH.MSG_TYPE.RAISR_STATUS ||
      msg.messageType === RAISR_MSG_CH.MSG_TYPE.RAISR_STATUS_INTERNAL;
    const isPrompt = msg.messageType === RAISR_MSG_CH.MSG_TYPE.RAISR_PROMPT;
    const isDigit = msg.messageType === RAISR_MSG_CH.MSG_TYPE.RAISR_DIGITS;
    const isComplete = msg.messageType === RAISR_MSG_CH.MSG_TYPE.RAISR_COMPLETE;
    const isError = msg.messageType === RAISR_MSG_CH.MSG_TYPE.RAISR_ERROR;

    if (isFromCtrl) {
      if (isCtrlRegister || isCtrlStatus) {
        this.onRaisrStatus(msg.messageBody.isRaisrActive);
      } else if (
        this.name !== msg.messageBody.fieldIdOrName ||
        this.context !== msg.messageBody.context
      ) {
        return;
      }
      if (isPrompt) {
        this.onRaisrPrompt();
      } else if (isDigit) {
        this.onRaisrDigit(msg.messageBody.fieldValue);
      } else if (isComplete) {
        this.onRaisrComplete(msg.messageBody.fieldValue, msg.messageBody.token);
      } else if (isError) {
        this.onRaisrError(msg.messageBody.errorDescr);
      }
    }
  }
}