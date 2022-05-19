import {CASE_ACTION_GROUP} from "./caseActions";
import {PAYMENT_SOURCE} from "./stateMachine";
import getCaseRefundPaymentMethod from '@salesforce/apex/BWC_RedactionController.getRefundPaymentMethod';

import { updateRecord } from 'lightning/uiRecordApi';
import CASE_ID_FLD from '@salesforce/schema/Case.Id';
import CASE_PAYMENT_TYPE_FLD from "@salesforce/schema/Case.PaymentType__c"
import CASE_PAYMENT_NAME_ON_ACC_FLD from "@salesforce/schema/Case.NameTiedToPayment__c";
import CASE_REFUND_TYPE_FLD from "@salesforce/schema/Case.RefundType__c"
import CASE_REFUND_NAME_ON_ACC_FLD from "@salesforce/schema/Case.NameTiedToRefund__c";
//import CASE_IS_CASH_FLD from "@salesforce/schema/Case.Original_Payment_Type_is_Cash__c";

export const PAYMENT_TYPE_CASH_VAL = "Cash/ICP";
export const CREDIT_CARD_VAL = "Credit / ATM card";
export const PAYMENT_BANK_VAL = "Bank Transfer / EFT";
export const REFUND_BANK_VAL = "Bank Transfer";

export const PAYMENT_METHOD_TO_CASE_VALUE = Object.freeze({
  CARD: CREDIT_CARD_VAL,
  BANKACCOUNT: PAYMENT_BANK_VAL,
  Cash: PAYMENT_TYPE_CASH_VAL,
  "Cash/ICP": PAYMENT_TYPE_CASH_VAL,
  CREDITCARD: CREDIT_CARD_VAL,
  ACH: PAYMENT_BANK_VAL
});
export const REFUND_METHOD_TO_CASE_VALUE = Object.freeze({
  [PAYMENT_BANK_VAL]: REFUND_BANK_VAL,
  [REFUND_BANK_VAL]: REFUND_BANK_VAL,
  BANKACCOUNT: REFUND_BANK_VAL,
  ACH: REFUND_BANK_VAL,
  CARD: CREDIT_CARD_VAL,
  CREDITCARD: CREDIT_CARD_VAL,
  [CREDIT_CARD_VAL]: CREDIT_CARD_VAL
});

const PAYMENT_METHOD_AUX_FIELD = 'PaymentMethod';

export const States = {
  [PAYMENT_SOURCE.FROM_EXISTING_CREDIT_CARD_PAYMENT]: {
    CASH_NOT_SELECTED: {
      [CASE_ACTION_GROUP.GROUP_1]: {
        PAYMENT_AUX: {
          METHOD_NAME: "paymentFromExistingCreditCard"
        },
        REFUND_AUX: {
          METHOD_NAME: "refundFromExistingCreditCard"
        }
      },
      [CASE_ACTION_GROUP.GROUP_2]: {
        PAYMENT_AUX: {
          METHOD_NAME: "paymentFromExistingCreditCard"
        },
      },
    }
  },
  [PAYMENT_SOURCE.FROM_EXISTING_BANK_PAYMENT]: {
    CASH_NOT_SELECTED: {
      [CASE_ACTION_GROUP.GROUP_1]: {
        PAYMENT_AUX: {
          METHOD_NAME: "paymentFromExistingBank"
        },
        REFUND_AUX: {
          METHOD_NAME: "refundFromRedactionRefund"
        }
      },
      [CASE_ACTION_GROUP.GROUP_2]: {
        PAYMENT_AUX: {
          METHOD_NAME: "paymentFromExistingBank"
        },
      },
    },
  },
  [PAYMENT_SOURCE.FROM_UNIDENTIFIED_PAYMENT]: {
    CASH_SELECTED: {
      [CASE_ACTION_GROUP.GROUP_1]: {
        PAYMENT_AUX: {
          METHOD_NAME: "paymentCash"
        },
        REFUND_AUX : {
          METHOD_NAME: "refundFromRedactionRefund"
        }
      },
      [CASE_ACTION_GROUP.GROUP_2]: {
        PAYMENT_AUX: {
          METHOD_NAME: "paymentCash"
        },
      },
    },
    CASH_NOT_SELECTED: {
      [CASE_ACTION_GROUP.GROUP_1]: {
        PAYMENT_AUX: {
          METHOD_NAME: "paymentFromRedaction"
        },
        REFUND_AUX: {
          METHOD_NAME: "refundFromRedactionOpt"
        }
      },
      [CASE_ACTION_GROUP.GROUP_2]: {
        PAYMENT_AUX: {
          METHOD_NAME: "paymentFromRedaction"
        },
      },
    },
  }
}

export class RedactionMoneyDetails {
  constructor(
    recordId,
    paymentSource,
    caseActionGroup,
    customerObj,
    isCash,
    existingPaymentDetails
  ) {
    this.recordId = recordId;
    this.paymentSource = paymentSource;
    this.customer = customerObj;
    this.isCash = isCash;
    this.caseActionGroup = caseActionGroup;
    this.existingPaymentDetails = existingPaymentDetails;
    this.paymentType = undefined;
    this.paymentNameOnAcc = undefined;
    this.refundType = undefined;
    this.refundNameOnAcc = undefined;
  }

  _parseData( data, typeProp, nameOnAccProp, mapToCase ) {
    if (data) {
      const d = data.messageBody ? data.messageBody : data;
      this[typeProp] = mapToCase[d.paymentMethodType];
      this[nameOnAccProp] = d.card
        ? d.card.cardHolderName
        : d.bankAccount
        ? d.bankAccount.accountHolderName
        : this.customer.data.Name;
    }

  }

  _dataFromExistingPayment( paymentOrRefundPropName, paymentOrRefundNameOnAcc, map ) {
    if ( !this.existingPaymentDetails ) {
      return;
    }
    const existPm = this.existingPaymentDetails.filter(nvp=>nvp.Name__c === PAYMENT_METHOD_AUX_FIELD);
    if ( existPm && existPm.length > 0 ) {
      const pm = existPm[ 0 ].Value__c;
      console.debug( 
        '--->>> _paymentFromExistingPayment. paymentType [' 
        + pm 
        + '] - ' + map[ pm ]
      );
      this[ paymentOrRefundPropName ] = map[ pm ];
      this[ paymentOrRefundNameOnAcc ] = this.customer.data.Name;
    }
  }

  _paymentFromExistingPayment() {
    this._dataFromExistingPayment( "paymentType", "paymentNameOnAcc", PAYMENT_METHOD_TO_CASE_VALUE );
  }

  _refundFromExistingPayment() {
    this._dataFromExistingPayment( "refundType", "refundNameOnAcc", REFUND_METHOD_TO_CASE_VALUE );
  }

  paymentFromExistingCreditCard() {
    this._paymentFromExistingPayment();
  }

  async refundFromExistingCreditCard() {
    this._refundFromExistingPayment();
    return true;
  }

  paymentFromExistingBank() {
    this._paymentFromExistingPayment();
  }


  async refundFromRedactionRefund() {
    console.debug( '--->>> entered refundFromRedactionRefund' );
    const res = await getCaseRefundPaymentMethod({ sobjId: this.recordId })
      .catch((error) => {
        console.error("Error on getCaseRefundPaymentMethod ", error);
      });
    
    if ( res ) {
      const data = JSON.parse(res);
      console.debug("--->>> refund data: ", JSON.stringify(data));
      this._parseData( 
        data, "refundType", "refundNameOnAcc", 
        REFUND_METHOD_TO_CASE_VALUE 
      );  
    }
    if ( !this.refundType ) {
      this._refundFromExistingPayment();
    }
    console.debug( '--->>> leaving refundFromRedactionRefund' );
    return true;  
  }

  paymentFromRedaction() {
    console.debug( 
      'we already have that from the parameter:' 
      + ' paymentType: ' + this.paymentType
      + '; paymentNameOnAcc: ' + this.paymentNameOnAcc
    );
    if ( !this.refundType ) {
      this._paymentFromExistingPayment();
    }
  }

  async refundFromRedactionOpt() { // if refund empty copy from payment to show they are the same
    console.debug( '--->>> entering refundFromRedactionOpt' );
    await this.refundFromRedactionRefund();
    if ( !this.refundType ) {
      this.refundType = REFUND_METHOD_TO_CASE_VALUE[ this.paymentType ];
      this.refundNameOnAcc = this.paymentNameOnAcc;
    }
    console.debug( '--->>> leaving refundFromRedactionOpt' );
    return true;
  }

  paymentCash() {
    this.paymentType = PAYMENT_METHOD_TO_CASE_VALUE[ PAYMENT_TYPE_CASH_VAL ];
    this.paymentNameOnAcc = this.customer.data.Name;
  }

  _error( err, needThrow = false ) {
    console.error( err );
    if ( needThrow ) {
      throw new Error( err );
    }
  }

  async getDetails( data ) {
    let res = {};
    const ps = States[ this.paymentSource ];
    if ( !ps ) {
      console.warn( "Unknown PAYMENT SOURCE: [" + this.paymentSource + "]" );  
      return res;
    }

    const cashStatus = (!this.isCash) ?
      ps.CASH_NOT_SELECTED : ps.CASH_SELECTED;
    if ( !cashStatus ) {
      console.debug( 
        'paymentSource [' + JSON.stringify( ps ) 
        + '] no state for isCash: ' +this.isCash 
      );
      return res; 
    }
    
    const grp = cashStatus[ this.caseActionGroup ];
    if ( !grp ) {
      console.debug( 
        'No state for the case action group: ' 
        + this.caseActionGroup 
        + "; paymentSource states " 
        + JSON.stringify( ps ) 
      );
      return res;
    }

    const pmAux = grp.PAYMENT_AUX;
    if ( pmAux ) {
      this._parseData( 
        data, "paymentType", "paymentNameOnAcc", 
        PAYMENT_METHOD_TO_CASE_VALUE 
      );
      if ( pmAux.METHOD_NAME ) {
        this[ pmAux.METHOD_NAME ]();
      }  
    }

    console.debug( '--->>> before obtainRefund' );
    res = await this.obtainRefund( grp );
    console.debug( '--->>> after obtainRefund: ' + JSON.stringify( res ) );
    return res;
  }

  async obtainRefund( grp ) {
    console.debug( '--->>> enterd obtainRefund' );
    const res = {};

    const refundAux = grp.REFUND_AUX;
    if ( refundAux ) {
      if ( refundAux.METHOD_NAME ) {
        await this[ refundAux.METHOD_NAME ]();
      }
    }

    await this.updateCase();
    
    console.debug( '--->>> obtainRefund forming result...' );
    res.paymentType = this.paymentType
    res.paymentNameOnAcc = this.paymentNameOnAcc;
    res.refundType = this.refundType
    res.refundNameOnAcc = this.refundNameOnAcc;

    return res;
  }

  async updateCase() {
    const fields = {};
    fields[CASE_ID_FLD.fieldApiName] = this.recordId;
    fields[CASE_PAYMENT_TYPE_FLD.fieldApiName] = 
      (this.paymentType) ? this.paymentType : "";
    fields[CASE_PAYMENT_NAME_ON_ACC_FLD.fieldApiName] = 
      (this.paymentNameOnAcc) ? this.paymentNameOnAcc : "";
    fields[CASE_REFUND_TYPE_FLD.fieldApiName] = 
      (this.refundType) ? this.refundType : "";
    fields[CASE_REFUND_NAME_ON_ACC_FLD.fieldApiName] = 
      (this.refundNameOnAcc) ? this.refundNameOnAcc : "";
    // fields[CASE_IS_CASH_FLD.fieldApiName] = 
    //   (this.isCash) ? true : false; // do not want null or undefned  

    const res = await updateRecord( { fields } )
      .catch(err=>console.error( 
        "Failed to update case: " + JSON.stringify( err )
        + "; data: " + JSON.stringify( fields ) + ";"
      )); 
    console.debug( "update result", res );
  }
}