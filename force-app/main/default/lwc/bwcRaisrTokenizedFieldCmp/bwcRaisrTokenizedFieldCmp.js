import { api } from "lwc";

import bwcRaisrFieldCmp, {
  FIELD_TYPE,
  ICON_URL,
  getRaisrFieldType,
  CLASSES,
  RAISR_ICON_CLASSES,
} from "c/bwcRaisrFieldCmp";

const DEF_COLLECTING_MESSAGE = "Getting data from RAISR...";

const MASK_SYM = "*";
const SHOW_LAST_N = 4;

const FIELD_TYPE_2_PATTEN = {
  [FIELD_TYPE.RAISR_FIELD_TYPE.CREDIT_CARD]:     
    "^(?:4[0-9]{12}(?:[0-9]{3})?"         // Visa
    + "|(?:5[1-5][0-9]{2}"                // MasterCard
    + "|222[1-9]|22[3-9][0-9]|2[3-6][0-9]{2}|27[01][0-9]|2720)[0-9]{12}"
    + "|3[47][0-9]{13}"                   // American Express
    + "|3(?:0[0-5]|[68][0-9])[0-9]{11}"   // Diners Club
    + "|6(?:011|5[0-9]{2})[0-9]{12}"      // Discover 6225884712861445
    + "|(?:2131|1800|35\\d{3})\\d{11}"      // JCB
    + ")$",
    //"^(?:(4[0-9]{12}(?:[0-9]{3})?)|(5[1-5][0-9]{14})|(6(?:011|5[0-9]{2})[0-9]{12})|(3[47][0-9]{13})|(3(?:0[0-5]|[68][0-9])[0-9]{11})|((?:2131|1800|35[0-9]{3})[0-9]{11}))$",
  [FIELD_TYPE.RAISR_FIELD_TYPE.CVV]:            "^[0-9]{3,4}$",
  [FIELD_TYPE.RAISR_FIELD_TYPE.BANK_ACC]:       "^[0-9]{6,17}$",
  [FIELD_TYPE.RAISR_FIELD_TYPE.BANK_ROUTING]:   "^((0[0-9])|(1[0-2])|(2[1-9])|(3[0-2])|(6[1-9])|(7[0-2])|80)([0-9]{7})$", // "^[0-9]{9,9}$"
};
export default class BwcRaisrTokenizedFieldCmp extends bwcRaisrFieldCmp {

  @api showLastChars = SHOW_LAST_N;

  _isRaisrComplete = false;
  get isRaisrComplete() {
    return this._isRaisrComplete;
  }
  set isRaisrComplete( status ) {
    if ( !status ) {
      this.token = "";
    }
    this._isRaisrComplete = status;
  }

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
        inp.readOnly = (super._isRaisrActive) ? true : false; // without "?" doesn't work somehow
        super.inputClasses = (new CLASSES.CssClasses( super.inputClasses ))
          .addClass( "ro-disabled" ).toString();

        // --- set pattern is not set before
        if ( !super.pattern ) {
          const rft = getRaisrFieldType( super._raisrFieldType );
          super.pattern = FIELD_TYPE_2_PATTEN[ rft ];
        }
      }
    }
  }

  reportValidity() {
    if ( this._isRaisrActive || this.isRaisrComplete ) {
      return ( this.token && this.token.length > 5 );
    }
    let res = !/^\s*$/.test( this.value );
    // const inp = super.template.querySelector("input[ type = 'text' ]");
    if ( res && this.pattern ) {
      const exp = new RegExp( this.pattern );
      res = exp.test( this.value );
    }
    return res;
  }

  checkValidity() {
    return this.reportValidity();
  }

  isAfterFocus = false;

  onfocus(event) {
    if ( !this._isRaisrActive ) {
      this.isAfterFocus = true;
    }
    return super.onfocus(event);
  }

  onblur(event) {
    const res = super.onblur(event);
    if ( this.checkValidity() && this.value.length > this.showLastChars ) {
      const idx = this.value.length - this.showLastChars;
      const showN = this.value.slice( idx );
      this.visibleValue = this.visibleValue.slice( 0, idx ) + showN;
    }
    return res;
  }

  onpaste(event) {
    super.onpaste(event);

    let txt = (event.clipboardData || window.clipboardData).getData('text');
    this.value = "";
    this.oninput( { target: { value: txt } } );
    event.preventDefault();
  }

  onchange(event) {
    if ( !this._isRaisrActive && this.isAfterFocus ) {
      this.cleanupErrorStatus();
      this.isAfterFocus = false;
    }
    return super.onchange(event);
  }

  oninput( event ) {
    if ( !this._isRaisrActive ) {
      this._isRaisrComplete = false;

      let chs = event.target.value.split( '' );
      if ( chs.length === 0 ) {
        this.value = "";
        this.visibleValue = "";
        return;
      }
      let notEsacpedCharIndexes = chs.map((v,i)=>{
        if ( v !== MASK_SYM ) {
          return i;
        }
      }).filter(v=>v !== undefined);

      if ( chs.length < this.value.length ) {
        this.value = this.value.slice( 0, chs.length - this.value.length);
        if ( chs.length === 1 && notEsacpedCharIndexes[ 0 ] === 0 ) {
          this.value = chs[ 0 ];
        }
      }

      notEsacpedCharIndexes.forEach(idx=>{
        if ( idx === this.value.length ) {
          this.value += chs[ idx ];
        }
      });
      this.visibleValue = this.value.replace( /./g, MASK_SYM );
    }
  }

  onRaisrStatus( status ) {
    super.onRaisrStatus( status );
    
    const inp = super.template.querySelector("input[ type = 'text' ]");
    if ( inp ) {
      inp.readOnly = status;
      super.inputClasses = (new CLASSES.CssClasses( super.inputClasses ))
        .addClass( "ro-disabled" ).toString();
    }
    else {
      super.inputClasses = (new CLASSES.CssClasses( super.inputClasses ))
        .removeClasses( "ro-disabled" ).toString();
    }
  }

  currIconClasses = "";

  changeMode( event ) {
    if ( !super._isRaisrActive ) {
      return; // We already in the forever manual mode here
    }

    let icon = "";
    let classes = "";
    if ( event.type === "mouseenter" ) {
      this.currIconClasses = this.icon.classes;
      icon = ICON_URL.REFRESH; 
      classes = (new CLASSES.CssClasses( this.icon.classes ))
        .removeClasses( RAISR_ICON_CLASSES ).addClass( "raisr-active" ).toString();  
    }
    else if ( event.type === "mouseleave" ) {
      icon = ICON_URL.AUDIO;
      classes = this.currIconClasses;
    }
    else if ( event.type === "click" ) {
      this.visibleValue = "";
      this.value = "";
      this.isRaisrComplete = false;
      this.error = "";
      this.attempt = 1;
      this.inputHelp.text = this.error;
      this.inputHelp.classes = (new CLASSES.CssClasses( this.inputHelp.classes ))
        .removeClasses( "error-message" ).toString();
      this.onfocus( {} );
    }
    super.icon = { classes: classes, icon:icon };

    return super.changeMode( event );
  }

  onRaisrComplete(val, token) {
    this.isRaisrComplete = true;
    super.onRaisrComplete( val, token );
  }

  onRaisrDigit(digits) {
    this.isRaisrComplete = false;
    super.onRaisrDigit(digits);
  }

  onRaisrError(error) {
    this.isRaisrComplete = false;
    super.onRaisrError(error);
  }  
}