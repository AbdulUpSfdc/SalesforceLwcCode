export const CA_AUTOPAY_OVERPAYMENT = 'Autopay Transaction Issues - Overpayment'; 
export const CA_PAYMT_INQ_UNKNWN_CHARGE = 'Payment Inquiry - Customer Does Not Recognize Charge';
export const CA_PAYMT_INQ_DUP_CHARGE = 'Payment Inquiry - Duplicate Charges Service';
export const CA_PAYMT_INQ_DUP_EQUIP_CHARGE = 'Payment Inquiry - Duplicate Charges Equipment'; 
export const CA_PAYMT_INQ_HOLD_RELZ_LTTR_REQ = 'Payment Inquiry - Hold Release Letter Request';
export const CA_PAYMT_INQ_POSTED_WRNG_AMOUNT = 'Payment Inquiry - Posted for Incorrect Amount';
export const CA_PAYMT_INQ_UNKNWN_PAYMNET = 'Payment Inquiry - Unrecognized Payment';
export const CA_DEP_REMOVAL = 'Deposits - Deposit Removal / Waiver';
export const CA_REFUND_BANKRUPTCY_REQ = 'Refund Request - Bankruptcy Refund Request';
export const CA_REFUND_REFUNT_REQ = 'Refund Request - Payment refund request';
export const CA_REFUND_NO_CHECK = 'Refund Request - Check Not Made Out To AT&T Mobility'
export const CA_REFUND_STATUS_OR_STOP = 'Refund Request - Refund Status/Stop Payment Request';

export const CA_DEPS_TRANSFER = 'Deposits - Deposit Transfers';
export const CA_DEPS_WRNG_DEPOSIT = 'Deposits - Misapplied Deposit Payment';
export const CA_PAYMT_PAYMT_BLK_REMOVE = 'Payment Block Removal';
export const CA_TRNSFR_PAYMENT_OR_FUNDS = 'Transfer Payment or Funds';
export const CA_SBP_TRANSACTION_ISSUE = 'SBP Transaction Issue';

export const CA_NSF_DISPUTE = 'NSF - NSF Dispute';
export const CA_NSF_NSF_REFUND = 'NSF-Refund Of NSF Fees';

export const CASE_ACTION_GROUP = Object.freeze({
  GROUP_1: "GROUP_1",
  GROUP_2: "GROUP_2",
  GROUP_3: "GROUP_3"
});

export const CASE_AUX_DETAILS_PAYMENT_METHOD_FLD = "Method";

export const CaseActionsToGroup = Object.freeze({

  [CA_AUTOPAY_OVERPAYMENT]: CASE_ACTION_GROUP.GROUP_1,
  [CA_PAYMT_INQ_UNKNWN_CHARGE]: CASE_ACTION_GROUP.GROUP_1,
  [CA_PAYMT_INQ_DUP_CHARGE]: CASE_ACTION_GROUP.GROUP_1,
  [CA_PAYMT_INQ_DUP_EQUIP_CHARGE]: CASE_ACTION_GROUP.GROUP_1,
  [CA_PAYMT_INQ_HOLD_RELZ_LTTR_REQ]: CASE_ACTION_GROUP.GROUP_1,
  [CA_PAYMT_INQ_POSTED_WRNG_AMOUNT]: CASE_ACTION_GROUP.GROUP_1,
  [CA_PAYMT_INQ_UNKNWN_PAYMNET]: CASE_ACTION_GROUP.GROUP_1,
  [CA_DEP_REMOVAL]: CASE_ACTION_GROUP.GROUP_1,
  [CA_REFUND_BANKRUPTCY_REQ]: CASE_ACTION_GROUP.GROUP_1,
  [CA_REFUND_REFUNT_REQ]: CASE_ACTION_GROUP.GROUP_1,
  [CA_REFUND_NO_CHECK]: CASE_ACTION_GROUP.GROUP_1,
  [CA_REFUND_STATUS_OR_STOP]: CASE_ACTION_GROUP.GROUP_1,

  [CA_DEPS_TRANSFER]: CASE_ACTION_GROUP.GROUP_2,
  [CA_DEPS_WRNG_DEPOSIT]: CASE_ACTION_GROUP.GROUP_2,
  [CA_PAYMT_PAYMT_BLK_REMOVE]: CASE_ACTION_GROUP.GROUP_2,
  [CA_TRNSFR_PAYMENT_OR_FUNDS]: CASE_ACTION_GROUP.GROUP_2,
  [CA_SBP_TRANSACTION_ISSUE]: CASE_ACTION_GROUP.GROUP_2,
  
  [CA_NSF_DISPUTE]: CASE_ACTION_GROUP.GROUP_3,
  [CA_NSF_NSF_REFUND]: CASE_ACTION_GROUP.GROUP_3,
  
});