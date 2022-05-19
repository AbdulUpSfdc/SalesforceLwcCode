import { api, track } from "lwc";
import bwcRaisrFieldCmp, {
  FIELD_TYPE,
  ICON_URL,
  getRaisrFieldType,
  CLASSES,
  RAISR_ICON_CLASSES
} from "c/bwcRaisrFieldCmp";

const FIELD_TYPE_2_PATTERN = {
  [FIELD_TYPE.RAISR_FIELD_TYPE.ZIP]: "^(\\d{5}(-\\d{4})?|[A-CEGHJ-NPRSTVXY]\\d[A-CEGHJ-NPRSTV-Z] ?\\d[A-CEGHJ-NPRSTV-Z]\\d)$",
  [FIELD_TYPE.RAISR_FIELD_TYPE.EXP_DATE]: "^\\d{2,2}/\\d{2,2}$",
  [FIELD_TYPE.RAISR_FIELD_TYPE.BANK_ROUTING]: "^\\d{9,9}$",
};

const ICON_STATE = Object.freeze({
  RAISR_ON: "RAISR_ON",
  RIASR_OFF: "RAISR_OFF",
  MANUAL_ENTRY: "MANUAL_ENTRY",
});

export default class BwcRaisrClearTextFieldCmp extends bwcRaisrFieldCmp {

  constructor(...args) {
    super(...args);
  }

  _isInputRendered = false;

  renderedCallback() {
    super.renderedCallback();
    if (!this._isInputRendered) {
      const inp = super.template.querySelector("input[ type = 'text' ]");
      if (inp) {
        this._isInputRendered = true;
        inp.readOnly = (super._isRaisrActive) ? true : false;

        if ( !super.pattern ) {
          const rft = getRaisrFieldType( super._raisrFieldType );
          super.pattern = FIELD_TYPE_2_PATTERN[ rft ];
        }
      }
    }
  }

  reportValidity() {
    let res = !/^\s*$/.test( this.value );
    if ( res && this.pattern ) {
      const exp = new RegExp( this.pattern );
      res = exp.test( this.value );
    }
    return res;
  }

  checkValidity() {
    return this.reportValidity();
  }

  onfocus(event) {
    return super.onfocus(event);
  }

  onblur(event) {
    if ( this.currState === ICON_STATE.MANUAL_ENTRY ) {
      this.errorStatusCheck();
    }
    else {
      super.onblur(event);    
    }
  }

  onchange(event) {
    return super.onchange(event);
  }

  onRaisrStatus( isActive ) {
    super.onRaisrStatus( isActive );
    if ( !this._isRaisrActive ) {
      if ( this.currState !== ICON_STATE.MANUAL_ENTRY ) {
        // this.resetStatus();
      }
      const inp = super.template.querySelector("input[ type = 'text' ]");
      if ( inp ) {
        inp.readOnly = false;
      }
    } 
  }

  onRaisrDigit( digits ) {
    if ( this.currState !== ICON_STATE.MANUAL_ENTRY ) {
      super.onRaisrDigit( digits );
    }
  }

  onRaisrComplete( val, token ) {
    if ( this.currState !== ICON_STATE.MANUAL_ENTRY ) {
      super.onRaisrComplete( val, token );
    }
  }

  // AUDIO->STOP(onmouseenter->click)->STOP->RETRY(onhover->click)->AUDIO
  currState = (super._isRaisrActive) ? ICON_STATE.RAISR_ON : ICON_STATE.RIASR_OFF;
  currIconClasses = super.icon.classes;

  changeMode( event ) {
    if ( !super._isRaisrActive ) {
      return; // We already in the forever manual mode here
    }

    let icon = "";
    let classes = ""
    if ( event.type === "mouseenter" ) {
      this.currIconClasses = this.icon.classes;
      if ( this.currState === ICON_STATE.RAISR_ON ) {
        icon = ICON_URL.CLOSE;
      }
      else if ( this.currState === ICON_STATE.MANUAL_ENTRY ) {
        icon = ICON_URL.REFRESH;
      }
      classes = (new CLASSES.CssClasses( this.icon.classes ))
        .removeClasses( RAISR_ICON_CLASSES ).addClass( "raisr-active" ).toString();
    }
    else if ( event.type === "mouseleave" ) {
      classes = this.currIconClasses;
      if ( this.currState === ICON_STATE.RAISR_ON ) {
        icon = ICON_URL.AUDIO;
      }
      else if ( this.currState === ICON_STATE.MANUAL_ENTRY ) {
        icon = ICON_URL.CLOSE;
      }
    }
    else if ( event.type === "click" ) {
      const inp = super.template.querySelector("input[ type = 'text' ]");

      if ( this.currState === ICON_STATE.RAISR_ON ) {
        icon = ICON_URL.CLOSE;
        this.currState = ICON_STATE.MANUAL_ENTRY;
        inp.readOnly = false;
      }
      else if ( this.currState === ICON_STATE.MANUAL_ENTRY ) {
        icon = ICON_URL.AUDIO;
        this.currState = ICON_STATE.RAISR_ON;
        this.attempt = 1; // increment inside method
        inp.readOnly = true;
      }
  
      this.resetStatus();

      if ( inp ) {
        inp.focus();
      }
    }

    super.icon = { classes: classes, icon:icon };

    return super.changeMode( event );
  }

  resetStatus() {
    this.value = "";
    this.visibleValue = "";
    this.error = "";
    this.inputHelp.text = this.error;
    this.inputHelp.classes = (new CLASSES.CssClasses( this.inputHelp.classes ))
      .removeClasses( "error-message" ).toString();
  }
}