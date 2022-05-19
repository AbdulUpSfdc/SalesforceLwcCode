import {CASE_ACTION_GROUP, CaseActionsToGroup} from "./caseActions"
import * as bwcConst from "c/bwcConstants";

export const REDACTION_CAPABILITY = Object.freeze({
  BANK_NO_CHECK_NUM: "BANK_NO_CHECK_NUM",
  BANK_WITH_CHECK_NUM: "BANK_WITH_CHECK_NUM",
  CREDCARD: "CREDCARD",
  CREDCARD_CVV_ONLY: "CREDCARD_CVV_ONLY",
  REFUND_BANK_NOCHECK_CREDCARD: "REFUND_BANK_NOCHECK_CREDCARD",
  REFUND_BANK_NOCHECK_CREDCARD_NO_PAYMENT:
    "REFUND_BANK_NOCHECK_CREDCARD_NO_PAYMENT"
});

export const PAYMENT_SOURCE = Object.freeze({
  FROM_EXISTING_CREDIT_CARD_PAYMENT: "FROM_EXISTING_CREDIT_CARD_PAYMENT",
  FROM_EXISTING_BANK_PAYMENT: "FROM_EXISTING_BANK_PAYMENT",
  FROM_UNIDENTIFIED_PAYMENT: "FROM_UNIDENTIFIED_PAYMENT",
});

export const EXIST_PAYMENT_METHOD_2_PAYMENT_SOURCE = {
  [bwcConst.BankAccountType.CHECKING.label]:
    PAYMENT_SOURCE.FROM_EXISTING_BANK_PAYMENT,
  [bwcConst.BankAccountType.CHECKING.value]:
    PAYMENT_SOURCE.FROM_EXISTING_BANK_PAYMENT,
  [bwcConst.BankAccountType.SAVINGS.label]:
    PAYMENT_SOURCE.FROM_EXISTING_BANK_PAYMENT,
  [bwcConst.BankAccountType.SAVINGS.value]:
    PAYMENT_SOURCE.FROM_EXISTING_BANK_PAYMENT,
  [bwcConst.CardType.AMEX.label]:
    PAYMENT_SOURCE.FROM_EXISTING_CREDIT_CARD_PAYMENT,
  [bwcConst.CardType.AMEX.value]:
    PAYMENT_SOURCE.FROM_EXISTING_CREDIT_CARD_PAYMENT,
  [bwcConst.CardType.VISA.label]:
    PAYMENT_SOURCE.FROM_EXISTING_CREDIT_CARD_PAYMENT,
  [bwcConst.CardType.VISA.value]:
    PAYMENT_SOURCE.FROM_EXISTING_CREDIT_CARD_PAYMENT,
  [bwcConst.CardType.DINERS.label]:
    PAYMENT_SOURCE.FROM_EXISTING_CREDIT_CARD_PAYMENT,
  [bwcConst.CardType.DINERS.value]:
    PAYMENT_SOURCE.FROM_EXISTING_CREDIT_CARD_PAYMENT,
  [bwcConst.CardType.DISCOVER.label]:
    PAYMENT_SOURCE.FROM_EXISTING_CREDIT_CARD_PAYMENT,
  [bwcConst.CardType.DISCOVER.value]:
    PAYMENT_SOURCE.FROM_EXISTING_CREDIT_CARD_PAYMENT,
  [bwcConst.CardType.MASTERCARD.label]:
    PAYMENT_SOURCE.FROM_EXISTING_CREDIT_CARD_PAYMENT,
  [bwcConst.CardType.MASTERCARD.value]:
    PAYMENT_SOURCE.FROM_EXISTING_CREDIT_CARD_PAYMENT
};

export const AGENT_UI_ELEMS = Object.freeze({
  REDACTION_MSG: "REDACTION_MSG",
  REDACTION_URL: "REDACTION_URL",
  CASH_ICP_SWITCH: "CASH_ICP_SWITCH",
  REDACTION_PAYMENT_TYPE_PAIR: "REDACTION_PAYMENT_TYPE_PAIR",
  REDACTION_REFUND_TYPE_PAIR: "REDACTION_REFUND_TYPE_PAIR"
});

export const CASH_ICP_SWITCH_VALUE = Object.freeze({
  ON : "ON",
  OFF : "OFF"
});

export const REDACTION_CAPABILITIES = "REDACTION_CAPABILITIES";

// using computed property names, since eslint does not like plain ones
const stateMachine = {

  [PAYMENT_SOURCE.FROM_EXISTING_CREDIT_CARD_PAYMENT]: {
    [CASE_ACTION_GROUP.GROUP_1]: {
      [AGENT_UI_ELEMS.REDACTION_MSG]: { visible: false },
      [AGENT_UI_ELEMS.REDACTION_URL]: { visible: false },
      [AGENT_UI_ELEMS.CASH_ICP_SWITCH]: { visible: false },
      [AGENT_UI_ELEMS.REDACTION_PAYMENT_TYPE_PAIR]: { visible: true }, 
      [AGENT_UI_ELEMS.REDACTION_REFUND_TYPE_PAIR]: { visible: true },
      REDACTION_CAPABILITIES: []
    },
    [CASE_ACTION_GROUP.GROUP_2]: {
      [AGENT_UI_ELEMS.REDACTION_MSG]: { visible: false },
      [AGENT_UI_ELEMS.REDACTION_URL]: { visible: false },
      [AGENT_UI_ELEMS.CASH_ICP_SWITCH]: { visible: false },
      [AGENT_UI_ELEMS.REDACTION_PAYMENT_TYPE_PAIR]: { visible: true }, 
      [AGENT_UI_ELEMS.REDACTION_REFUND_TYPE_PAIR]: { visible: false },
      REDACTION_CAPABILITIES: []
    },
    [CASE_ACTION_GROUP.GROUP_3]: {
      [AGENT_UI_ELEMS.REDACTION_MSG]: { visible: false },
      [AGENT_UI_ELEMS.REDACTION_URL]: { visible: false },
      [AGENT_UI_ELEMS.CASH_ICP_SWITCH]: { visible: false },
      [AGENT_UI_ELEMS.REDACTION_PAYMENT_TYPE_PAIR]: { visible: false }, 
      [AGENT_UI_ELEMS.REDACTION_REFUND_TYPE_PAIR]: { visible: false },
      REDACTION_CAPABILITIES: []
    },
  },
  
  [PAYMENT_SOURCE.FROM_EXISTING_BANK_PAYMENT]: {
    [CASE_ACTION_GROUP.GROUP_1]: {
      [AGENT_UI_ELEMS.REDACTION_MSG]: { visible: true },
      [AGENT_UI_ELEMS.REDACTION_URL]: { visible: true },
      [AGENT_UI_ELEMS.CASH_ICP_SWITCH]: { visible: false },
      [AGENT_UI_ELEMS.REDACTION_PAYMENT_TYPE_PAIR]: { visible: true },
      [AGENT_UI_ELEMS.REDACTION_REFUND_TYPE_PAIR]: { visible: true },
      REDACTION_CAPABILITIES: [REDACTION_CAPABILITY.REFUND_BANK_NOCHECK_CREDCARD_NO_PAYMENT]
    },
    [CASE_ACTION_GROUP.GROUP_2]: {
      [AGENT_UI_ELEMS.REDACTION_MSG]: { visible: false },
      [AGENT_UI_ELEMS.REDACTION_URL]: { visible: false },
      [AGENT_UI_ELEMS.CASH_ICP_SWITCH]: { visible: false },
      [AGENT_UI_ELEMS.REDACTION_PAYMENT_TYPE_PAIR]: { visible: true },
      [AGENT_UI_ELEMS.REDACTION_REFUND_TYPE_PAIR]: { visible: false },
      REDACTION_CAPABILITIES: []
    },
    [CASE_ACTION_GROUP.GROUP_3]: {
      [AGENT_UI_ELEMS.REDACTION_MSG]: { visible: false },
      [AGENT_UI_ELEMS.REDACTION_URL]: { visible: false },
      [AGENT_UI_ELEMS.CASH_ICP_SWITCH]: { visible: false },
      [AGENT_UI_ELEMS.REDACTION_PAYMENT_TYPE_PAIR]: { visible: false }, // should be visible and have data
      [AGENT_UI_ELEMS.REDACTION_REFUND_TYPE_PAIR]: { visible: false },
      REDACTION_CAPABILITIES: []
    },
  },

  [PAYMENT_SOURCE.FROM_UNIDENTIFIED_PAYMENT]: {
    [CASE_ACTION_GROUP.GROUP_1]: {
      [AGENT_UI_ELEMS.CASH_ICP_SWITCH]: { 
        visible: true,
        initState: CASH_ICP_SWITCH_VALUE.OFF,
        states: {
          [CASH_ICP_SWITCH_VALUE.ON]: {
            [AGENT_UI_ELEMS.REDACTION_MSG]: { visible: true },
            [AGENT_UI_ELEMS.REDACTION_URL]: { visible: true },
            [AGENT_UI_ELEMS.CASH_ICP_SWITCH]: { visible: true, initState: CASH_ICP_SWITCH_VALUE.ON },
            [AGENT_UI_ELEMS.REDACTION_PAYMENT_TYPE_PAIR]: { visible: true },
            [AGENT_UI_ELEMS.REDACTION_REFUND_TYPE_PAIR]: { visible: true },
            REDACTION_CAPABILITIES: [
              REDACTION_CAPABILITY.REFUND_BANK_NOCHECK_CREDCARD_NO_PAYMENT
            ]
          },
          [CASH_ICP_SWITCH_VALUE.OFF]: {
            [AGENT_UI_ELEMS.REDACTION_MSG]: { visible: true },
            [AGENT_UI_ELEMS.REDACTION_URL]: { visible: true },
            [AGENT_UI_ELEMS.CASH_ICP_SWITCH]: { visible: true, initState: CASH_ICP_SWITCH_VALUE.OFF },
            [AGENT_UI_ELEMS.REDACTION_PAYMENT_TYPE_PAIR]: { visible: true },
            [AGENT_UI_ELEMS.REDACTION_REFUND_TYPE_PAIR]: { visible: true },
            REDACTION_CAPABILITIES: [
              REDACTION_CAPABILITY.BANK_WITH_CHECK_NUM,
              REDACTION_CAPABILITY.CREDCARD,
              REDACTION_CAPABILITY.REFUND_BANK_NOCHECK_CREDCARD
            ]
          }  
        } 
      },
    },
    [CASE_ACTION_GROUP.GROUP_2]: {
      [AGENT_UI_ELEMS.CASH_ICP_SWITCH]: { 
        visible: true,
        initState: CASH_ICP_SWITCH_VALUE.OFF,
        states: {
          [CASH_ICP_SWITCH_VALUE.ON]: {
            [AGENT_UI_ELEMS.REDACTION_MSG]: { visible: false },
            [AGENT_UI_ELEMS.REDACTION_URL]: { visible: false },
            [AGENT_UI_ELEMS.CASH_ICP_SWITCH]: { visible: true, initState: CASH_ICP_SWITCH_VALUE.ON },
            [AGENT_UI_ELEMS.REDACTION_PAYMENT_TYPE_PAIR]: { visible: true },
            [AGENT_UI_ELEMS.REDACTION_REFUND_TYPE_PAIR]: { visible: false },
            REDACTION_CAPABILITIES: []
          },
          [CASH_ICP_SWITCH_VALUE.OFF]: {
            [AGENT_UI_ELEMS.REDACTION_MSG]: { visible: true },
            [AGENT_UI_ELEMS.REDACTION_URL]: { visible: true },
            [AGENT_UI_ELEMS.CASH_ICP_SWITCH]: { visible: true, initState: CASH_ICP_SWITCH_VALUE.OFF },
            [AGENT_UI_ELEMS.REDACTION_PAYMENT_TYPE_PAIR]: { visible: true },
            [AGENT_UI_ELEMS.REDACTION_REFUND_TYPE_PAIR]: { visible: false },
            REDACTION_CAPABILITIES: [
              REDACTION_CAPABILITY.BANK_WITH_CHECK_NUM,
              REDACTION_CAPABILITY.CREDCARD
            ]
          }  
        },
      }
    },
    [CASE_ACTION_GROUP.GROUP_3]: {
      [AGENT_UI_ELEMS.REDACTION_MSG]: { visible: false },
      [AGENT_UI_ELEMS.REDACTION_URL]: { visible: false },
      [AGENT_UI_ELEMS.CASH_ICP_SWITCH]: { visible: false },
      [AGENT_UI_ELEMS.REDACTION_PAYMENT_TYPE_PAIR]: { visible: false },
      [AGENT_UI_ELEMS.REDACTION_REFUND_TYPE_PAIR]: { visible: false },
      REDACTION_CAPABILITIES: []
    },
  },

};

export class RedactionState {

  constructor( 
    paymentSource,
    caseAction,
    cashIcpSwitchValue
  ) {  
    this.paymentSource = paymentSource;
    this.caseAction = caseAction;
    this.cashIcpSwitchValue = cashIcpSwitchValue;
    if ( 
      this.cashIcpSwitchValue
      && !Object.keys(CASH_ICP_SWITCH_VALUE).includes( this.cashIcpSwitchValue ) 
    ) {
      throw new Error(
        "Expected one of CASH_ICP_SWITCH_VALUE values. Got: [" 
        + this.cashIcpSwitchValue + "]" 
      );
    }
    this._state = this.initState();
  }

  get state() {
    return this._state;
  }

  _error( err, needThrow = true ) {
    console.error( err );
    if ( needThrow ) {
      throw new Error( err );
    }
  }

  initState() {
    const pm = stateMachine[ this.paymentSource ];
    if ( !pm ) {
      this._error( 'Unknown payment source [' + this.paymentSource + ']' );
    }

    const grp = CaseActionsToGroup[ this.caseAction ];
    if ( !grp ) {
      this._error( "Unknown case action [" + this.caseAction + "]", false );
      return undefined;
    }

    // {
    //   "REDACTION_MSG":{"visible":false},
    //   "REDACTION_URL":{"visible":false},
    //   "CASH_ICP_SWITCH":{"visible":false}
    //   "REDACTION_PAYMENT_TYPE_PAIR":{"visible":true},
    //   "REDACTION_REFUND_TYPE_PAIR":{"visible":true},
    //   "REDACTION_CAPABILITIES":[]
    // }    
    const res = {};
    const cashSwitchState = pm[ grp ][ AGENT_UI_ELEMS.CASH_ICP_SWITCH ];
    let stateStartNode = pm[ grp ];
    if ( cashSwitchState.states ) {
      stateStartNode = cashSwitchState.states[ this.cashIcpSwitchValue ];
    }
    Object.keys(stateStartNode).forEach(fld=>{
      if ( 'visible' in stateStartNode[ fld ] ) {
        res[ fld ] = { visible: stateStartNode[ fld ].visible };
      }
      if ( Array.isArray( stateStartNode[ fld ] ) ) {
        res[ fld ] = stateStartNode[ fld ];
      }
    });
    return res;
  }
}