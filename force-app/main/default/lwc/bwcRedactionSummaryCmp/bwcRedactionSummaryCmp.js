import { LightningElement, wire, track, api } from 'lwc';
import getSecureInfoSummary from "@salesforce/apex/BWC_RedactionSummaryController.getSecureInfoSummary";
import { getRecord } from 'lightning/uiRecordApi';

import getAuxDetails from "@salesforce/apex/BWC_AuxDetailController.getAuxDetails";

import { machine, caseActions, redaction } from "c/bwcRedactionUtilsCmp";

const CASE_FIELDS = [
  'Case.CaseAction__c',
  // 'Case.Original_Payment_Type_is_Cash__c', we will compare PaymentType__c === 'Cash/ICP' instead
  'Case.PaymentType__c',
  'Case.NameTiedToPayment__c',
  'Case.RefundType__c',
  'Case.NameTiedToRefund__c'
];

const StateMachine = redaction.States;

const PAYMENT_TITLE = "Payment Method";
const REFUND_TITLE = "Refund Method";
const CHECK_NO_LABEL = "Check Number";
export default class BwcRedactionStatusCmp extends LightningElement {
  labels;
  error;

  @api recordId;

  /***
   * Array of the objects:
   * {
   *  title: "Payment" | "Refund",
   *  values: [
   *    {
   *      label: "AAA",
   *      value: "value",
   *    },
   *    ...
   *  ] 
   * }
   */
  @track summary = [];
  
  payment;
  refund;

  case;

  @wire(getRecord, { recordId: '$recordId', fields: CASE_FIELDS })
  getCaseData({ error, data }) {
    if ( data ) {
      this.case = data;
      this.adjustSummary();
    }
    if ( error ) {
      this._error( error, "ERROR getting Case for ID=" + this.recordId + "; " );
    }
  }

  _redactionSummaryData;
  @wire(getSecureInfoSummary, { sobjId: '$recordId' })
  redactionSummaryData({ error, data }) {
      if (data) {
        this._redactionSummaryData = data;
        this.error = undefined;
        this.adjustSummary();
      }
      if (error) {
        this._error( error, "ERROR getting redactionSummaryData ID=" + this.recordId + "; " );
      }
  }
  
  /***
  Name__c:
  Date
  Amount
  BAN
  Method   - 'Checking'
  PaymentMethod 'ACH'
  LastFour
  Type         'PMT'
  Status        POSTED
  ConfirmationNum
  ***/
  _exisitngPaymentDetails;
  @wire(getAuxDetails, { recordId: "$recordId" })
  existingPaymentDetails({ error, data }) {
    if (data) {
      this._exisitngPaymentDetails = data;
      this.error = undefined;
      this.adjustSummary();
    }
    if ( error ) {
      this._exisitngPaymentDetails = undefined;
      this._error( error, "ERROR getting existingPaymentDetails ID=" + this.recordId + "; " );
    }
  }

  _error( error, prefix ) {
    const errPrefix = prefix;
    if (Array.isArray(error.body)) {
        this.error = errPrefix + error.body.map(e => e.message).join(', ');
    } else if (typeof error.body.message === 'string') {
        this.error = errPrefix + error.body.message;
    }      
    console.error( this.error );
  } 

  isUnidentifiedPayment() {
    return this._exisitngPaymentDetails && this._exisitngPaymentDetails.length === 0;
  }

  getPaymentSource() {
    const isNoPayment = this.isUnidentifiedPayment();
        
    const existingPaymentMethod = (!isNoPayment) ? this._exisitngPaymentDetails.filter(
      (v) => v.Name__c === caseActions.CASE_AUX_DETAILS_PAYMENT_METHOD_FLD
    )[0] : undefined;

    const paymentMethod = isNoPayment
      ? machine.PAYMENT_SOURCE.FROM_UNIDENTIFIED_PAYMENT
      : machine.EXIST_PAYMENT_METHOD_2_PAYMENT_SOURCE[existingPaymentMethod.Value__c];
    if ( !paymentMethod ) {
      console.error( 'Unknown PAYMENT METHOD [' + existingPaymentMethod.Value__c + ']' );
    }
    return paymentMethod;
  }

  adjustSummary() {
    if ( !this.case || !this._exisitngPaymentDetails || !this._redactionSummaryData ) {
      return;
    }
    this.summary = []; // --- we need to reset, since wired methods can be called for various reasons

    const paymentSource = this.getPaymentSource();

    const isCash = (this.case.fields.PaymentType__c.value === redaction.PAYMENT_TYPE_CASH_VAL);

    const grp = caseActions.CaseActionsToGroup[ this.case.fields.CaseAction__c.value ];

    if ( !paymentSource || !grp ) {
      return;
    }

    const ps = StateMachine[ paymentSource ];
    if ( !ps ) {
      return;
    }

    const cashElem = isCash ? "CASH_SELECTED" : "CASH_NOT_SELECTED";
    const cashDoc = ps[ cashElem ];
    if ( !cashDoc ) {
      return;
    }

    const grpDoc = cashDoc[ grp ];
    if ( !grpDoc ) {
      return;
    }

    const paymentAux = grpDoc.PAYMENT_AUX;
    const paymentClassMethod = (paymentAux) ? paymentAux.METHOD_NAME : undefined;
    if ( paymentClassMethod ) {
      this[ paymentClassMethod ]();
    }

    const refundAux = grpDoc.REFUND_AUX;
    const refundClassMethod = (refundAux) ? refundAux.METHOD_NAME : undefined;
    if ( refundClassMethod ) {
      this[ refundClassMethod ]();
    }

    if ( this.payment ) {
      this.processMethod( PAYMENT_TITLE, this.payment );
    }

    if ( this.refund ) {
      this.processMethod( REFUND_TITLE, this.refund );
    }
  }

  processMethod( title, method ) {
    console.debug( '--->>> title: ' + title + '; method: ', JSON.stringify( method ) );
    const m = {
      title: title,
      values: []
    };

    if ( method.creditCard ) {
      if ( 
        /^\s*$/.test( method.creditCard.cardType ) 
        &&
        /^\s*$/.test( method.creditCard.secureToken )
      ) {
        return;
      }
      m.values.push(
        { 
          label: "Payment Type",
          value: (method.creditCard.paymentType) ? method.creditCard.paymentType : "Credit Or Debit Card"
        }
      );
      m.values.push(
        { 
          label: "Secure Token",
          value: (method.creditCard.secureToken) ? method.creditCard.secureToken : '*******'
        }
      );
      m.values.push(
        {
          label: "Credit Card Type",
          value: method.creditCard.cardType
        }
      );
      if ( method.creditCard.maskedNumber ) {
        m.values.push(
          {
            label: "Credit Card Number",
            value: method.creditCard.maskedNumber
          }
        );
      }
    }
    else if ( method.bank ) {
    /***
     * bank: {
        accountNumber: ""
        checkNumber: ""
        nameOnAccount: ""
        routingNumber: ""
     * }
     */
      if ( 
        /^\s*$/.test( method.bank.routingNumber )
        &&
        /^\s*$/.test( method.bank.accountNumber )
      ) {
        return;
      }
      m.values.push(
        { 
          label: "Payment Type",
          value: (method.bank.paymentType) ? method.bank.paymentType : "Checking"
        }
      );
      m.values.push(
        { 
          label: "Name On The Account",
          value: method.bank.nameOnAccount
        }
      );
      m.values.push(
        { 
          label: "Bank Routing Number",
          value: method.bank.routingNumber
        }
      );
      m.values.push(
        { 
          label: "Bank Account Number",
          value: method.bank.accountNumber
        }
      );
      m.values.push(
        { 
          label: CHECK_NO_LABEL,
          value: method.bank.checkNumber
        }
      );
    }
    if ( method.cash ) {
      m.values.push(
        { 
          label: "Payment Type",
          value: redaction.PAYMENT_TYPE_CASH_VAL
        }
      );
      m.values.push(
        {
          label: "Name On The Account",
          value: this.case.fields.NameTiedToPayment__c.value
        }
      );
    }

    this.summary.push( m );
  }

  _fromExistingCC() {
    const m = this._exisitngPaymentDetails.filter(v=>v.Name__c === 'Method');
    const paymentTypeArr = this._exisitngPaymentDetails.filter(v=>v.Name__c === "PaymentMethod");
    const last4Arr = this._exisitngPaymentDetails.filter(v=>v.Name__c === 'LastFour');
    return { 
      creditCard: {
        cardType: (m && m.length === 1) ? m[ 0 ].Value__c : '',
        secureToken: 'N/A',
        paymentType: (paymentTypeArr && paymentTypeArr[ 0 ] ) ? paymentTypeArr[ 0 ].Value__c : undefined,
        maskedNumber: (last4Arr && last4Arr[0]) ? '***********' + last4Arr[ 0 ].Value__c : undefined
      } 
    };
  }

  paymentFromExistingCreditCard() {
    this.payment = this._fromExistingCC();
  }

  refundFromExistingCreditCard() {
    this.refund = this._fromExistingCC();
  }

  _fromExistingBank() {
    const last4Arr = this._exisitngPaymentDetails.filter(v=>v.Name__c === 'LastFour');
    const paymentTypeArr = this._exisitngPaymentDetails.filter(v=>v.Name__c === "PaymentMethod");
    return {
      bank: {
        nameOnAccount: this.case.fields.NameTiedToPayment__c.value,
        accountNumber: (last4Arr && last4Arr[ 0 ]) ? '*****' + last4Arr[0].Value__c : "",
        paymentType: (paymentTypeArr && paymentTypeArr[ 0 ]) ? paymentTypeArr[ 0 ].Value__c : undefined
      }
    }
  }

  paymentFromExistingBank() {
    this.payment = this._fromExistingBank();
  }

  /***
  'Case.CaseAction__c',
  'Case.PaymentType__c',
  'Case.NameTiedToPayment__c',
  'Case.RefundType__c',
  'Case.NameTiedToRefund__c'
   */
  refundFromRedactionRefund() {
    this.refund = this._redactionSummaryData.refund;
    if ( !this.refund ) {
      this.refund = this.payment;
    }
  }

  paymentCash() {
    this.payment = { cash: {} };
  }

  paymentFromRedaction() {
    this.payment = this._redactionSummaryData.payment;
    if ( !this.payment ) {
      if ( !this._exisitngPaymentDetails ) {
        return;
      }
      let pm = this._exisitngPaymentDetails.filter(v=>v.Name__c === 'PaymentMethod')[ 0 ];
      pm = (pm) ? pm.Value__c : undefined;
      let pm4cv = redaction.PAYMENT_METHOD_TO_CASE_VALUE[ pm ];
      if ( !pm4cv ) {
        pm4cv = redaction.REFUND_METHOD_TO_CASE_VALUE[ pm ];
      }
      if ( pm4cv ) {
        /**
          PAYMENT_TYPE_CASH_VAL = "Cash/ICP";
          CREDIT_CARD_VAL = "Credit / ATM card";
          PAYMENT_BANK_VAL = "Bank Transfer / EFT";
          REFUND_BANK_VAL = "Bank Transfer";
         */
        switch (pm4cv) {
          case redaction.CREDIT_CARD_VAL:
            this.payment = this._fromExistingCC();
            break;
          case redaction.PAYMENT_BANK_VAL:
          case redaction.REFUND_BANK_VAL: 
            this.payment = this._fromExistingBank();
            break;
          default:
            console.warn( "Do not expect UNKNOWN payment here" );
            break;
        }
      }
    }
  }

  refundFromRedactionOpt() {
    this.refundFromRedactionRefund();
  }
}