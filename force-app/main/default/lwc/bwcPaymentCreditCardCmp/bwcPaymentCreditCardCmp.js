import { LightningElement, api, track } from "lwc";

const TT_VISIBLE = "slds-rise-from-ground";
const TT_HIDDEN = "slds-fall-into-ground";

const SEC_CODE_FIELD = "ccSecurityCode";

const INPUT_FIELDS = [
  "ccName",
  "ccNumber",
  "ccExpiration",
  SEC_CODE_FIELD,
  "ccZip"
];

export default class BwcPaymentCreditCardCmp extends LightningElement {

  //expriration date tracking 
  @track
  exp_date_value = '';

  @api
  labels;

  _fieldsForInput = INPUT_FIELDS;
  @api
  get fieldsForInput() {
    return this._fieldsForInput;
  }

  set fieldsForInput( flds ) {
    console.debug( '--->>> fieldsForInput json: ' + JSON.stringify( flds ), " natural ", flds );
    if ( flds && flds.length > 0 ) {
      this._fieldsForInput = INPUT_FIELDS.filter(f=>flds.includes( f ));
    }
    else {
      this._fieldsForInput = INPUT_FIELDS;
    }
  }

  isRequiredError = false;
  isFormatError = false;
    
  disconnectedCallback() {
  }

  get secCodeGood() {
    // const el = this.template.querySelector("." + SEC_CODE_FIELD);
    return false;
  }

  showSecCodeTooltip() {
    const tt = this.template.querySelector(".secCodeTooltip");
    if ( tt ) {
      tt.classList.replace(TT_HIDDEN, TT_VISIBLE);
    }
  }

  hideSecCodeTooltip() {
    const tt = this.template.querySelector(".secCodeTooltip");
    if ( tt ) {
      tt.classList.replace(TT_VISIBLE, TT_HIDDEN);
    }
  }

  checkCCVError(event) {
    const w = this.template.querySelector( ".sec-code-inp-wrapper" );
    const inp = event.target;
    if ( inp.checkValidity() ) {
      w.classList.remove("slds-has-error");
      this.isRequiredError = false;
      this.isFormatError = false;
    }
    else {
      w.classList.add("slds-has-error");
      if ( inp.value === "" ) {
        this.isRequiredError = true;
        this.isFormatError = false;
      }
      else {
        this.isRequiredError = false;
        this.isFormatError = true;
      }
    }
  }

  closeIfEsc( event ) {
    if ( event.type === "keydown" && event.key === "Escape") {
      this.hideSecCodeTooltip();
    }
  }

  focusSecCodeTrigger( event ) {
    const tt = this.template.querySelector(".secCodeTooltipTrigger");
    if ( tt ) {
      tt.focus();
    }
    event.preventDefault();
    event.stopPropagation();
  }

  @api
  get formData() {
    const res = {};
    // const con = this.template.querySelector(".slds-form-element__control");
    const goodEls = // INPUT_FIELDS.reduce((counter, fnm) => {
        this.fieldsForInput.reduce((counter,fnm) => {
      const inp = this.template.querySelector("." + fnm);
      if (inp) {
        inp.reportValidity();
        if (inp.checkValidity()) {
          res[fnm] = inp.value;
          if (fnm === SEC_CODE_FIELD) {
            this.checkCCVError( { target: inp } );
          }
          counter++;
        } else {
          if (fnm === SEC_CODE_FIELD) {
            this.checkCCVError( { target: inp } );
          }
        }
      }
      return counter;
    }, 0);
//    const finalRes = goodEls === INPUT_FIELDS.length ? res : undefined;
    const finalRes = goodEls === this.fieldsForInput.length ? res : undefined;
    if ( !finalRes ) {
      // this.template.querySelector( ".ccName" ).focus(); // first input may be used...
      const firstFld = this.template.querySelector( "." + this.fieldsForInput[ 0 ] );
      if ( firstFld ) {
        firstFld.focus();
      }
    }
    return finalRes;
  }

  get isSubset() {
    return (this.fieldsForInput && this.fieldsForInput.length < INPUT_FIELDS.length );
  }

  get cvvClasses() {
    const classes = "slds-form-element sec-code-inp-wrapper";
    return (this.isSubset) ? classes + " whole-row" : classes;
  }
  
  //Formating the experation date
  handleExpDateChange(event){
    
    if (event.target.value.length > 2 && !event.target.value.includes('/')) {
      event.target.value = event.target.value.substring(0, 2) + '/' + event.target.value.substring(2);
  }

  }
}