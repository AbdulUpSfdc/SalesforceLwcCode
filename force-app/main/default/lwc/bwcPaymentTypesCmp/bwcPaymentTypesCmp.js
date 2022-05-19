/* eslint-disable use-isnan */
/* eslint-disable @lwc/lwc/no-api-reassignments */
import { LightningElement, track, api } from "lwc";
import LANG from "@salesforce/i18n/lang";
import savePaymentMethod from "@salesforce/apex/BWC_RedactionPaymentMethodController.savePaymentMethod";
import checkOTPVerficationStatus from "@salesforce/apex/BWC_RedactionPaymentMethodController.checkOTPVerificationStatus";

const OTP_CHECK_INTERVAL = 7000;

const Langs = Object.freeze({
  EN: "en-US",
  ES: "es-MX"
});

const Lang2LabelId = {};
Lang2LabelId[Langs.EN] = "hlinkSpanish";
Lang2LabelId[Langs.ES] = "hlinkEnglish";

const AVAIL_CAPABILITIES = Object.freeze({
  BANK_NO_CHECK_NUM : "BANK_NO_CHECK_NUM",
  BANK_WITH_CHECK_NUM : "BANK_WITH_CHECK_NUM",
  CREDCARD : "CREDCARD",
  REFUND_BANK_NOCHECK_CREDCARD : "REFUND_BANK_NOCHECK_CREDCARD",
  CREDCARD_CVV_ONLY : "CREDCARD_CVV_ONLY",
  REFUND_BANK_NOCHECK_CREDCARD_NO_PAYMENT : "REFUND_BANK_NOCHECK_CREDCARD_NO_PAYMENT",
});
export default class BwcPaymentTypesCmp extends LightningElement {
  @track
  labels; // = LABELS;

  showOtpPollingSpinner = false;

  capabilitiesArr;
  @api get capabilities() {
    console.debug( '--->>> Capabilities ' + JSON.stringify( this.capabilitiesArr ) );
    return this.capabilitiesArr;
  }
  set capabilities( caps ) {
    console.debug( '--->>> setting capabilities:', typeof caps, JSON.stringify( caps ) );
    this.capabilitiesArr = (caps) ? caps : [];
  } 

  isRefundTheSame = true;
  isRefundSwitchedEnabled = false;

  get isRefund() {
    return this.capabilities.includes( AVAIL_CAPABILITIES.REFUND_BANK_NOCHECK_CREDCARD );
  }

  get isRefundOnly() {
    return this.capabilities.includes( AVAIL_CAPABILITIES.REFUND_BANK_NOCHECK_CREDCARD_NO_PAYMENT );
  }

  @api reqId;
  @api type;
  @api ban;
  nextDueDate;
  @api get nextDue() {
    return !this.nextDueDate
      ? ""
      : this.nextDueDate.toLocaleDateString(this.lang, {
          year: "numeric",
          month: "long",
          day: "numeric",
          timeZone: "UTC"
        });
  }
  set nextDue(dd) {
    // console.debug( '--->>> nextDue dd [' + dd + ']', typeof dd );
    this.nextDueDate = dd ? new Date(dd) : undefined;
  }

  @api lang = LANG.EN;

  optChecker;
  isOtpVerifiedFlag;
  @api get isOtpVerified() {
    return this.isOtpVerifiedFlag;
  }
  set isOtpVerified( flg ) {
    if ( typeof flg === "string" ) {
      this.isOtpVerifiedFlag = !("false" === flg);
    }
    else {
      this.isOtpVerifiedFlag = flg; 
    }

    if ( this.isOtpVerifiedFlag ) {
      if ( this.optChecker ) clearInterval( this.optChecker );
    }
  }

  @api get isShowOTPMode() {
    const isErr = (this.errorMessage || this.successMessage);
    return !isErr && !this.isOtpVerified;
  }

  get isTitleAnAccountVisible() {
    return !this.isShowOTPMode && !/^\s*$/.test( this.ban );
  }

  @api otp;

  @api cardLastFour = "";

  @api
  errorMessage;

  @track
  currentErrorMessage;
  errMsgLabelId;

  @track
  successMessage;

  @api get showPaymentForms() {
    const isErr = (this.errorMessage || this.successMessage);
    return ( !isErr && this.isOtpVerified );
  }

  setDifferentRefund() {
    this.isRefundTheSame = false;
  }

  setSameRefund() {
    this.isRefundTheSame = true;
  }

  get languageLabel() {
    return this.labels[Lang2LabelId[this.lang]];
  }

  get primaryCapabilities() {
    return this.capabilities.filter(c=>c !== AVAIL_CAPABILITIES.REFUND_BANK_NOCHECK_CREDCARD);
  }

  onPrimaryMethodChanged( event ) {
    const mode = event.detail;
    if ( mode === "CREDIT_CARD" ) {
      this.isRefundTheSame = true;
      this.isRefundSwitchedEnabled = false;
    }
    else {
      this.isRefundSwitchedEnabled = true;
    }
  }  

  get refundCapabilities() {
    const caps = this.capabilities
      .filter(c=>c !== AVAIL_CAPABILITIES.REFUND_BANK_NOCHECK_CREDCARD)
      .map(c=>
        ( c === AVAIL_CAPABILITIES.BANK_WITH_CHECK_NUM ) ?
          AVAIL_CAPABILITIES.BANK_NO_CHECK_NUM
          :
          c
      );
    if ( this.isRefundOnly ) {
      if ( !caps.includes( AVAIL_CAPABILITIES.BANK_NO_CHECK_NUM ) ) {
        caps.push( AVAIL_CAPABILITIES.BANK_NO_CHECK_NUM );
      }
      if ( !caps.includes( AVAIL_CAPABILITIES.CREDCARD ) ) {
        caps.push( AVAIL_CAPABILITIES.CREDCARD );
      }
    }
    console.debug( '--->>> refundCapabilities prepared: ' + JSON.stringify( caps ) );  
    return caps;  
  }
  renderedCallback() {
    if (!this.labels) {
      const lbls = this.template.querySelector("c-bwc-redaction-labels");
      if ( lbls ) {
        this.labels = lbls.labels;
        if ( this.lang !== LANG ) {
          this.enforceTranslate( lbls );
        }
        this.currentErrorMessage = this.labels.currentErrorMsg; // comes when we save payment data
        this.errMsgLabelId = "currentErrorMsg";
      }
    }
    if ( !this.isOtpVerified && !this.optChecker && !this.errorMessage ) {
      // eslint-disable-next-line @lwc/lwc/no-async-operation
      this.optChecker = setInterval(this.checkOtpStatus.bind(this), 
        OTP_CHECK_INTERVAL 
      );
    }
  }

  checkOtpStatus() {
    this.showOtpPollingSpinner = true;
    checkOTPVerficationStatus({hash: this.reqId})
    .then(r=>{
      this.isOtpVerified = r;
      this.showOtpPollingSpinner = !this.isOtpVerified;
      console.debug( '--->>> Checked OTP Verification Status: ' + this.isOtpVerified, "response type", typeof r );
    })
    .catch(err=>{
      console.error(JSON.stringify( err ), err );
      // {"status":500,"body":{"exceptionType":"BWC_RedactionService.RedactionServiceException","isUserDefinedException":true,"message":"Expired","stackTrace":"Class.BWC_RedactionService.Service.checkRecordAccess: line 631, column 1\nClass.BWC_RedactionService.Service.checkOTPVerificationStatus: line 513, column 1\nClass.BWC_RedactionPaymentMethodController.checkOTPVerificationStatus: line 90, column 1"},"headers":{}}     });        
      if ( err.status === 500 && err.body.message === "Expired" ) {
        clearInterval( this.optChecker );
        console.debug( 'No MORE Polling!!!' );
        this.currentErrorMessage = this.labels.cardSubmitErrorMsg;
        this.errMsgLabelId = "cardSubmitErrorMsg";
        this.errorMessage = this.labels.cardSubmitExceptionMsg;
      } 
    });
  }

  submitData() {
    const isRefundOnly = this.isRefundOnly;
    const primaryFrm = this.template.querySelector( ".primary-payment" );
    const primaryData = (primaryFrm) ? primaryFrm.formData : undefined;
    if ( !isRefundOnly && !primaryData ) {
      return;
    }
    const refundFrm = this.template.querySelector( ".refund-payment" );
    const refundData = (refundFrm) ? refundFrm.formData : undefined;

    if ( refundFrm && !refundData ) {
      return;
    }

    const reqData = (isRefundOnly) ? 
      {
        primary: refundData,
        secondary : undefined
      } 
      : {
        primary: primaryData,
        secondary: (refundData) ? refundData : undefined
      };

    const btns = this.template.querySelectorAll("lightning-button");
    btns.forEach((b) => (b.disabled = true));
    const submitBtn = this.template.querySelector(".submit-payment");
    const originalLabel = submitBtn.label;
    submitBtn.label = "Working";

    const req = {
      hash: this.reqId,
      paymentMethods: reqData
    };
    savePaymentMethod(req)
      .then(() => {
        this.successMessage = this.labels.cardSubmitSuccessMsg;
      })
      .catch((err) => {
        this.currentErrorMessage = this.labels.cardSubmitErrorMsg;
        this.errMsgLabelId = "cardSubmitErrorMsg";
        this.errorMessage = this.labels.cardSubmitExceptionMsg;
        console.error("--->>> savePaymentMethod FAILED: ", JSON.stringify(err));
      });
    submitBtn.label = originalLabel;
  }

  enforceTranslate( redactionLabelsCmp ) {
    if (redactionLabelsCmp ) {
      redactionLabelsCmp.translateLabels(this.lang).then((ls) => {
        if ( "{}" === JSON.stringify( ls ) ) { // force retry
          const lbls = this.template.querySelector("c-bwc-redaction-labels");
          this.enforceTranslate( lbls );
          return;
        }
        this.labels = ls;
        if (this.currentErrorMessage) {
          this.currentErrorMessage = this.labels[this.errMsgLabelId];
        }
        if (this.successMessage) {
          this.successMessage = this.labels.cardSubmitSuccessMsg;
        }
      });
    }
  }

  toggleLanguage() {
    if (this.lang === Langs.EN) {
      this.lang = Langs.ES;
    } else {
      this.lang = Langs.EN;
    }
    const lbls = this.template.querySelector("c-bwc-redaction-labels");
    this.enforceTranslate( lbls );
  }
}