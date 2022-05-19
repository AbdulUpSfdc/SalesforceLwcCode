// Billing_Account.Account_Type__c: add values as needed
export const BillingAccountType = {
    WIRELESS: {value: 'wireless', label: 'Wireless'},
    WIRELINE: {value: 'wireline'},
    UVERSE: {value: 'uverse', label: 'Uverse'},
    DTVNOW: {value:'dtvnow', label: 'DIRECTV STREAM'},
    DTVS: {value: 'dtvs', label: 'DIRECTV LEGACY'},
    WATCHTV: {value: 'watchtv', label: 'WatchTV'},
    DTV: {value: 'dtv', label: 'DIRECTV'},
    POTS: {value: 'pots', label: 'POTS'},

    getLabelForValue: value => {
        const billingAccountType = Object.values(BillingAccountType).find(item => item.value === value);
        return billingAccountType ? billingAccountType.label : value;
    }

};

// Billing account type values that are valid for payment operations.
export const PaymentBillingAccountTypes = [
    BillingAccountType.WIRELESS.value,
    BillingAccountType.UVERSE.value
];

// Billing_Account.Account_Status__c: add values as needed
export const BillingAccountStatus = {
    ACTIVE: {value: 'Active'},
    SUSPENDED: {value: 'Suspended'},
    CANCELED: {value: 'Canceled'}
}

// Topics to pass to payment details API
export const PaymentDetailTopic = {
    PAYMENT_HISTORY: {value: 'paymentHistory'},
    FUTURE_PAYMENTS: {value: 'futurePayments'},
    PAYMENT_PROFILES: {value: 'paymentProfiles'},
    CONVENIENCE_FEE_ELIGIBILITY: {value: 'convenienceFeeEligibility'},
    LAST_PAYMENT_METHOD: {value: 'lastPaymentMethod'},
    ACCOUNT_BALANCE_SUMMARY: {value: 'accountBalanceSummary'},
    BAN_BILLING_IDS: {value: 'banBillingIds'},
    PAYMENT_RECOMMENDATIONS: {value: 'paymentRecommendations'},
    AUTOPAY: {value: 'autopay'},
    TEMPORARY_PAYMENT_PROFILES : {value: 'temporaryPaymentProfiles'},
    EXTENDED_PA : {value: 'extendedPA'}
};

// Payment methods
export const PaymentMethodType = {
    CARD: {value: 'CARD', label: 'Debit/Credit Card', addLabel: 'Use New Debit/Credit Card'},
    BANKACCOUNT: {value: 'BANKACCOUNT', label: 'Bank Account', addLabel: 'Use New Checking/Savings Account'},
    PAYMENT_PROFILE: {value: 'PAYMENT_PROFILE'},
    PROMISE_TO_PAY: {value: 'PROMISETOPAY', label: 'Promise-to-Pay'},

    // Tells if value is a secured (not a promise) payment type.
    isSecured: value => {return value === PaymentMethodType.CARD.value || value === PaymentMethodType.BANKACCOUNT.value || value === PaymentMethodType.PAYMENT_PROFILE.value;},

    // Tells if value is a secured (not a promise) payment type that is not a stored profile.
    isNewSecured: value => {return value === PaymentMethodType.CARD.value || value === PaymentMethodType.BANKACCOUNT.value;}

};

// Translate from type used in payment details to type used in payment method
export const PaymentDetailToPaymentMethodType = {
    CREDITCARD: PaymentMethodType.CARD,
    ACH: PaymentMethodType.BANKACCOUNT,
    PROMISETOPAY: PaymentMethodType.PROMISE_TO_PAY
};

// Credit card types
export const CardType = {

    VISA: {value: 'VISA', label: 'VISA'},
    MASTERCARD: {value: 'MASTERCARD', label: 'MasterCard'},
    AMEX: {value: 'AMEX', label: 'American Express'},
    DINERS: {value: 'DINERS', label: 'Diners Club'},
    DISCOVER: {value: 'DISCOVER', label: 'Discover'},

    getLabel: value => {return CardType[value] ? CardType[value].label : value;}

}

// Card Types to use as options
export const CardTypeOptions = [
    CardType.VISA, CardType.MASTERCARD, CardType.AMEX, CardType.DINERS, CardType.DISCOVER
];

// Bank account types
export const BankAccountType = {
    CHECKING: {value: 'CHECKING', label: 'Checking', longLabel: 'Checking Account'},
    SAVINGS: {value: 'SAVINGS', label: 'Savings', longLabel: 'Savings Account'},

    getLabel: value => {return BankAccountType[value] ? BankAccountType[value].label : value;}

}

// Bank account types to use as options
export const BankAccountTypeOptions = [
    BankAccountType.CHECKING, BankAccountType.SAVINGS
];

// Promise to pay methods
export const PromiseToPayMethod = {
    MAIL: {value: 'MAIL', label: 'Mail', longLabel: 'Pay by Mail'},
    AGENCY: {value: 'AGENCY', label: 'In Person', longLabel: 'Pay in Person'},
    OTHER: {value: 'OTHER', label: 'Online', longLabel: 'Pay Online'},

    getLabel: value => {return PromiseToPayMethod[value] ? PromiseToPayMethod[value].label : value;},

    getLongLabel: value => {return PromiseToPayMethod[value] ? PromiseToPayMethod[value].longLabel : value;}

}

// Promise to pay
export const PromiseToPayMethodOptions = [

    PromiseToPayMethod.MAIL,
    PromiseToPayMethod.AGENCY,
    PromiseToPayMethod.OTHER

]

// Future or historical payment status
export const PaymentStatus = {
    PENDING: {value: 'PENDING', label: 'Pending'},
    POSTED: {value: 'POSTED', label: 'Posted'},
    CANCELED: {value: 'CANCELED', label: 'Canceled'},

    getLabel: value => {return PaymentStatus[value] ? PaymentStatus[value].label : value;}
}

// Terms and Conditions key values
export const PaymentEventType  = {

    OF: {value: 'OF', label: 'One-Time Payment / Future Dated Payment'},
    PP: {value: 'PP', label: 'Payment Profile'},
    AE: {value: 'AE', label: 'AutoPay Enrollment'},
    OP: {value: 'OP', label: 'One-Time Payment & Payment Profile'},
    OA: {value: 'OA', label: 'One-Time Payment & AutoPay Enrollment'},
    AP: {value: 'AP', label: 'AutoPay Enrollment & Payment Profile'},
    CF: {value: 'CF', label: 'Card On File (COF; Security Profile)'},
    SB: {value: 'SB', label: 'Session Based Pricing (special case)'},
    CC: {value: 'CC', label: 'Crypto Currency (special case)'},
    CA: {value: 'CA', label: 'Cricket AutoPay (special case)'},
    FO: {value: 'FO', label: 'FirstNet One-Time Payment'},
    FA: {value: 'FA', label: 'FirstNet AutoPay Enrollment'},
    TP: {value: 'TP', label: 'Text2Pay (special case)'},
    ME: {value: 'ME', label: 'One-Time Payment / AutoPay Enrollment / Payment Profile'}

}

//used to pass action values that map to BWC_Interaction_Metadata__mdt for interaction / one and done solution
export const InteractionActivityValueMapping  = {

    Payment: {action: 'Onetime Payment'},
    BanInquiry: {action: 'Inquiry | Service'},
    BillingChangeCycleDate: {action: 'Change bill cycle date'},
    ViewPaymentHistory: {action:'View payment history'},
    ViewBillPDF: {action:'Bill PDF'},
    ViewBill:{action: 'Viewed Billing detail'},
    AddPaymentMethod:{action: 'Add payment method'},
    ChangeBillOwnership:{action:'Change billing ownership'},
    ViewChangeInstallments:{action: 'Installments'},
    MakeCollectionPayment:{action:'Collections'},
    PaymentAdjustmentAddCharges:{action:'Payment or adjustment | Add charges'},
    PaymentAdjustmentAddGoodwillAdj:{action:'Payment or adjustment | Add goodwill adjustment'},
    PaymentAdjustmentAddBillAdj:{action:'Payment or adjustment | Add billing adjustment'},
    PaymentAdjustmentAddPendingChargeAdj:{action:'Payment or adjustment | Add pending charge adjustment'},
    PaymentAdjustmentSuspendedAccount:{action:'Payment or Adjustment | Suspended Account'},
    PaymentAdjustmentCancelledAccount:{action:'Payment or Adjustment | Cancelled Account'},
    ViewPromo:{action:'View promotions'},
    ProfileManagementAuthorizedusersAdd: {action: 'Authorized users | Add'},
    ProfileManagementAuthorizedusersDelete: {action: 'Authorized users | Delete'},
    ProfileManagementChangecontactinfoCBR: {action: 'Change contact info | CBR'},
    ProfileManagementChangecontactinfoEmail	: {action: 'Change contact info | Email'},
    ProfileManagementMyATTResetPwdQA: {action: 'MyAT&T Users | Reset Password & Security Q&A'},
    ProfileManagementMyATTResetPwd: {action: 'MyAT&T Users | Reset Password'},
    ProfileManagementMyATTUnlock: {action: 'MyAT&T Users | Unlock'},
    ProductServiceDeviceUpgrade: {action: 'Device | Upgrade'},
    ProductServiceChangeServices: {action: 'Change Services'},
    ProductServiceChangePlan: {action: 'Change Plan'},
    ProductServiceAddaline: {action: 'Add a line'},
    TroubleshootResolveDeviceSupport: {action:'Device | Support'},
    TroubleshootResolveDeviceIssues: {action:'Device | Issues'},
    TroubleshootResolveServiceIssues: {action:'Service | Issues'},
    InquiryAuthentication: {action:'Authentication'},
    InquiryNoAuthentication: {action:'No Authentication'},
    InquiryBypassAuthentication: {action:'Authentication Bypassed'},
    BillingPaymentImmediateOrFuture: {action: 'Immediate or Future dated'},
    BillingPaymentPromiseToPay: {action: 'Promise to pay'},
    BillingPaymentSplit: {action: 'Split payment'},
    BillingPaymentSecuredAdd: {action: 'Secured Payment - Add'},
    BillingPaymentSecuredEdit: {action: 'Secured Payment - Edit'},
    BillingPaymentSecuredCancel: {action: 'Secured Payment - Cancel'},
    BillingPaymentPromiseAdd: {action: 'Promise to Pay - Add'},
    BillingPaymentPromiseEdit: {action: 'Promise to Pay - Edit'},
    BillingPaymentPromiseCancel: {action: 'Promise to Pay - Cancel'},
    BillingPaymentEpaEnroll: {action: 'Epa Enroll'},
    BillingPaymentEpaView: {action: 'Epa View'},
    OrderDetailsReturns: {action: 'Order Details | Returns'},
    BillingAdjustmentsAdjustmentsReverseAdju: {action: 'Adjustments | Reverse Adjustment'},
    BillingAdjustmentsAdjustmentsAddCharge: {action: 'Adjustments | Add Charge'},
    CustomerCommunicationsResendEmail: { action: 'Customer Communications | Resend Email' },
    CustomerCommunicationsResendSMS: { action: 'Customer Communications | Resend SMS' },
    ViewBANUsageSummary: { action: 'Mobility Usage | View Summary' },
    CustomerSearch: { action: 'Inquiry | Customer Search' },
    CompleteInteraction: { action: 'Inquiry | Complete Interaction' },
}

// Escalation Cases: High Level Case types
export const HighLevelCaseType = {
    Billing_Payment: {value: 'Billing | Payment', type: 'Billing', feature: 'Payment'},
    Billing_Inquiry: {value: 'Billing | Inquiry', type: 'Billing', feature: 'Inquiry'},
    Device_Return_Inquiry: {value: 'Device Return | Inquiry', type: 'Device Return', feature: 'Inquiry'},
    Device_Inquiry: {value: 'Device | Inquiry', type: 'Device', feature: 'Inquiry'},
    Services_Inquiry: {value: 'Services | Inquiry', type: 'Services', feature: 'Inquiry'},
    Account_Services_Promotions: {value: 'Account Services | Promotions', type: 'Account Services', feature: 'Promotions'},
    Feature_Inquiry: {value: 'Feature | Inquiry', type: 'Feature', feature: 'Inquiry'},
    Order_Fallout: {value: 'Order Action | Online fallout Wireless', type: 'Order Action', feature: 'Online fallout Wireless'},
    Product_Service_Device_Upgrade: {value: 'Product Service | Device | Upgrade', type: 'Product Service', feature: 'Device | Upgrade'},
    Product_Service_Rate_Plan: {value: 'Product Service | Rate Plan | Add Change Remove', type: 'Product Service', feature: 'Rate Plan | Add Change Remove'}
}

// Authentication types for auth services
export const AuthenticationMethod = {

    NONE: {value: 'NONE', label: 'None'},
    PASSCODE: {value: 'PASSCODE', label: 'Passcode'},
    OTP: {value: 'OTP', label: 'One-Time Pin (OTP)'},
    BYPASS: {value: 'BYPASS'},

    getLabel: value => {return AuthenticationMethod[value] ? AuthenticationMethod[value].label : value;},

    isOtpPrivileged: value => {return value === AuthenticationMethod.OTP.value || value === AuthenticationMethod.BYPASS.value;}

}

// Authentication Levels
export const AuthenticationLevel = {

    L0: {value: 'L0'},
    L1: {value : 'L1'},
    BYPASS: {value: 'BYPASS'},

    isL1Privileged: value => {return value === AuthenticationLevel.L1.value || value === AuthenticationLevel.BYPASS.value;}

}

// Case caseAction pickValues
export const AdjustmentCaseAction = {
    GOODWILL: 'Goodwill',
    LINEITEM: 'LineItem'
}

export const CDEStatus = {
    APPROVED: {value: 'Approved', label: 'Approved'},
    APPROVED_WITH_CONDITIONS: {value: 'Approved With Conditions', label: 'Approved With Conditions'},
    REJECTED: {value: 'Rejected', label: 'Rejected'}
}

// Suffixes for authorized user name
export const NameSuffixes = [
    'SR', 'JR', 'II', 'III', 'IV', 'V', 'ESQ'
];

// CPNI Consent preference options
export const CpniConsent = {
    PermanentGranted: 'Permanent Granted',
    PermanentDenied: 'Permanent Granted',
    DocDovGranted: 'DOC/DOV Granted',
    DocDovDenied: 'DOC/DOV Denied',
    GrantedByPreference: 'Granted by Preference',
    Implied: 'Implied',
    PermanentYes: 'Permanent/Yes',
    DeniedNo: 'Denied/No',
    Pending: 'Pending',
    DoNotKnow: 'Do not know',
    FailedDelivery: 'Failed Delivery',
    NoVoiceOnAccount: 'No voice on account'
};

// Standard list of states used in address search.
export const StateOptions = [
    { label:'Select a State', value: '' },
    { label:'Alabama', value:'AL'},
    { label:'Alaska', value:'AK'},
    { label:'American Samoa', value:'AS'},
    { label:'Arizona', value:'AZ'},
    { label:'Arkansas', value:'AR'},
    { label:'California', value: 'CA' },
    { label:'Colorado', value:'CO'},
    { label:'Connecticut', value:'CT'},
    { label:'Delaware', value:'DE'},
    { label:'District of Columbia', value:'DC'},
    { label:'Federated States of Micronesia', value:'FM'},
    { label:'Florida', value:'FL'},
    { label:'Georgia', value:'GA'},
    { label:'Guam', value:'GU'},
    { label:'Hawaii', value:'HI'},
    { label:'Idaho', value:'ID'},
    { label:'Illinois', value:'IL'},
    { label:'Indiana', value:'IN'},
    { label:'Iowa', value:'IA'},
    { label:'Kansas', value:'KS'},
    { label:'Kentucky', value:'KY'},
    { label:'Louisiana', value:'LA'},
    { label:'Maine', value:'ME'},
    { label:'Marshall Islands', value:'MH'},
    { label:'Maryland', value:'MD'},
    { label:'Massachusetts', value:'MA'},
    { label:'Michigan', value:'MI'},
    { label:'Minnesota', value:'MN'},
    { label:'Mississippi', value:'MS'},
    { label:'Missouri', value:'MO'},
    { label:'Montana', value:'MT'},
    { label:'Nebraska', value:'NE'},
    { label:'Nevada', value:'NV'},
    { label:'New Hampshire', value:'NH'},
    { label:'New Jersey', value:'NJ'},
    { label:'New Mexico', value:'NM'},
    { label:'New York', value:'NY'},
    { label:'North Carolina', value:'NC'},
    { label:'North Dakota', value:'ND'},
    { label:'Northern Mariana Islands', value:'MP'},
    { label:'Ohio', value:'OH'},
    { label:'Oklahoma', value:'OK'},
    { label:'Oregon', value:'OR'},
    { label:'Palau', value:'PW'},
    { label:'Pennsylvania', value:'PA'},
    { label:'Puerto Rico', value:'PR'},
    { label:'Rhode Island', value:'RI'},
    { label:'South Carolina', value:'SC'},
    { label:'South Dakota', value:'SD'},
    { label:'Tennessee', value:'TN'},
    { label:'Texas', value: 'TX' },
    { label:'Utah', value:'UT'},
    { label:'Vermont', value:'VT'},
    { label:'Virgin Islands', value:'VI'},
    { label:'Virginia', value:'VA'},
    { label:'Washington', value:'WA'},
    { label:'West Virginia', value:'WV'},
    { label:'Wisconsin', value: 'WI' },
    { label:'Wyoming', value:'WY'},

    ];
    
//Value returned when there are no Intents for a given account
export const NO_INTENT_FOUND = 'No Intent Found';

// Picklist values for Call_status__c field on Interaction__c
export const callStatus = {
    CALL_ENDED: {label: 'Call Ended', value:'Call Ended'},
    IN_CALL:{label: 'In Call', value:'In Call'},
};

export const ERROR_CODE_404 = 404;

// Billing
export const CHARGES = {
    TYPES: {
        TAXES: 'TAXES', 
        SURCHARGES: 'SURCHARGES', 
        PLAN_CHANGES: 'PLAN_CHANGES', 
        MONTHLY_CHARGES_DETAILS: 'MONTHLY_CHARGES_DETAILS'
    },
    AMTIND: {
        CR: 'CR'
    }
}

// Milliseconds wait for secondary Interaction components to wait before loading to prevent boxcar of all api calls.
export const BOXCAR_WAIT = 2000;

//Value returned when there are no articles associated to an Intent for a given account
export const NO_ARTICLE_NEEDED = 'no_article_needed';