/*
    Shared components for payments functionality.
*/
import * as BwcUtils from 'c/bwcUtils';

export const PaymentMethodType = {
    CARD: {value: 'CARD', label: 'Debit/Credit Card', addLabel: 'Use New Debit/Credit Card'},
    BANKACCOUNT: {value: 'BANKACCOUNT', label: 'Bank Account', addLabel: 'Use New Checking/Savings Account'},
    PAYMENT_PROFILE: {value: 'PAYMENT_PROFILE'},
    PROMISE_TO_PAY: {value: 'PROMISETOPAY', label: 'Promise-to-Pay'}
};

// Convert from types used in a pending payment to standard types
const PaymentDetailToPaymentMethodType = {
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

// Status for extendedPA.status or extendedPa.installmentList[n].status
export const PaymentSmartFields = {
    BANK_ACCOUNT_NUMBER: 'bankAccountNumber',
    ROUTING_NUMBER: 'routingNumber',
    CARD_NUMBER: 'cardNumber',
    EXPIRATION_DATE: 'expirationDate',
    SECURITY_CODE: 'securityCode',
    ZIP_CODE: 'zipCode',
    PROFILE_SECURITY_CODE: 'profileSecurityCode'
};

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
    TEMPORARY_PAYMENT_PROFILES: {value: 'temporaryPaymentProfiles'},
    EXTENDED_PA: {value: 'extendedPA'}
};

// Topics to pass to payment details API
export const RaisrContext = {
    MAKE_PAYMENT: {value: 'Make Payment'},
    UPDATE_PAYMENT: {value: 'Update Payment'},
    AUTOPAY_ENROLL: {value: 'Autopay Enroll'},
    AUTOPAY_UPDATE: {value: 'Autopay Update'},
    EPA_ENROLL: {value: 'EPA Enroll'},
    EPA_UPDATE: {value: 'EPA Update'},
    ADD_PAYMENT_PROFILE: {value: 'Add Payment Profile'},
    UPDATE_PAYMENT_PROFILE: {value: 'Update Payment Profile'}
};

// Pay Source for Adding, Updating and Deleting Payment Profiles 
export const PaymentProfilePaySource = {
    BSSE_CUSTOMERS: {
        SOURCE_SYSTEM: "RTB",
        SOURCE_LOCATION: "XX"
    }
};

// Status for extendedPA.status or extendedPa.installmentList[n].status
export const EpaStatus = {
    ENROLLED: 'Enrolled',
    ACTIVE: 'Due',
    BROKEN: 'Broken',
    COMPLETED: 'Completed',
    FUTURE: 'Future'
};

/*
    Open payment wizrd for new payment or edit.
*/
export const openPaymentWizard = (pageComponent, interactionId, defaultBan, isEdit, confirmationNumber) => {

    const pageReference = {
        type: 'standard__component',
        attributes: {
            componentName: 'c__BWCPaymentWizardPage'
        },
        state: {
            c__recordId: interactionId,
            c__defaultBan: defaultBan,
            c__isEdit: isEdit,
            c__confirmationNumber: confirmationNumber
        }
    };
    pageComponent.openSubtab(pageReference, isEdit ? 'Edit Payment' : 'Make a Payment', 'custom:custom41');

}

/*
    Send message to open sub tab for cancelling payment
*/
export const openCancelPayment = (pageComponent, interactionId, ban, confirmationNumber) => {

    const pageReference = {
        type: 'standard__component',
        attributes: {
            componentName: 'c__BWCCancelPaymentPage'
        },
        state: {
            c__recordId: interactionId,
            c__ban: ban,
            c__confirmationNumber: confirmationNumber
        }
    };
    pageComponent.openSubtab(pageReference, 'Cancel Payment', 'custom:custom41');

}

/*
    View EPA details for the specified interaction and billing account.
*/
export const epaOpenViewer = (pageComponent, interactionId, billingAccountId) => {
    const pageReference = {
        type: 'standard__component',
        attributes: {
            componentName: 'c__BWCEpaViewerPage'
        },
        state: {
            c__interactionId: interactionId,
            c__billingAccountId: billingAccountId
        }
    };
    pageComponent.openSubtab(pageReference, 'Extended Payment Arrangements', 'utility:money');
}

/*
    View Enroll to EPA details for the specified interaction and billing account.
*/
export const epaOpenWizard = (pageComponent, interactionId, ban) => {
    const pageReference = {
        type: 'standard__component',
        attributes: {
            componentName: 'c__BWCEpaWizardPage'
        },
        state: {
            c__selectedBan: ban,
            c__recordId: interactionId
        }
    };
    pageComponent.openSubtab(pageReference, 'Extended Payment Arrangements', 'utility:money');
}

/*
    Encapsulates payment method details -- card, bank account, promise-to-pay
*/
export class PaymentMethod {

    // Properties
    type;
    card;
    bankAccount;
    promiseToPay;

    constructor(fromObject) {
        Object.assign(this, fromObject);
    }

    get isSecured() {return this.type === PaymentMethodType.CARD.value || this.type === PaymentMethodType.BANKACCOUNT.value || this.type === PaymentMethodType.PAYMENT_PROFILE.value;}

    get interactionActivityType() {
        const baseMethod = this.getBasePaymentMethod();
        if (baseMethod.type === PaymentMethodType.PROMISE_TO_PAY.value) {
            return baseMethod.promiseToPay.method.toLowerCase();
        }
        return baseMethod.type.toLowerCase();
    }

    /*
        Construct from a pending payment as returned from payment details.
    */
    static fromPendingPayment(pendingPayment) {

        const newObject = new PaymentMethod();

        // Convert type
        newObject.type = PaymentDetailToPaymentMethodType[pendingPayment.paymentMethod].value;

        if (!newObject.type) {
            throw new Error('Unknown pending payment method: ' + pendingPayment.paymentMethod);
        }

        switch (newObject.type) {

            case PaymentMethodType.BANKACCOUNT.value:
                newObject.bankAccount = {
                    accountType: pendingPayment.paymentDetailMethodType,
                    bankAccountNumber: 'XXXXX' + pendingPayment.paymentDetailMethodLastFour
                }
                break;

            case PaymentMethodType.CARD.value:
                newObject.card = {
                    cardType: pendingPayment.paymentDetailMethodType,
                    cardNumber: 'XXXXXXXXXXXX' + pendingPayment.paymentDetailMethodLastFour
                }
            break;

            case PaymentMethodType.PROMISE_TO_PAY.value:
                newObject.promiseToPay = {
                    method: pendingPayment.paymentDetailMethodType
                };
                break;

            default:
                break;

        }

        return newObject;

    }

    /*
        Return a payment method that is a card, bank account, or promise to pay -- even if payment method is reference to stored procedure.
    */
    getBasePaymentMethod() {

        if (this.type !== PaymentMethodType.PAYMENT_PROFILE.value) {
            return this;
        }

        const baseMethod = new PaymentMethod();
        if (this.bankAccount) {
            baseMethod.type = PaymentMethodType.BANKACCOUNT.value;
            baseMethod.bankAccount = this.bankAccount;
        }
        else if (this.card) {
            baseMethod.type = PaymentMethodType.CARD.value;
            baseMethod.card = this.card;
        }
        else {
            throw new Error('No bankAccount or card for stored profile payment method.');
        }
        return baseMethod;

    }

    /*
        Construct standard name for saved profile. Checking RAISR SPI Data
    */
    getProfileName(spiData) {
    
        const basePaymentMethod = this.getBasePaymentMethod();
    
        // Build Profile Name
        switch(basePaymentMethod.type) {
    
            case PaymentMethodType.CARD.value:
                {
                    const cardType = basePaymentMethod.card.cardType;
                    const cardLabel = cardType ? `${CardType[cardType].label} ...` : 'Card ...';

                    if (spiData && spiData.spiDataList && spiData.spiDataList.length > 0) {
                        const cardNumber = spiData.spiDataList.find(data => data.name === PaymentSmartFields.CARD_NUMBER);
                        return cardLabel + BwcUtils.rightstring(cardNumber.value, 4);
                    } else {
                        const cardNumber = basePaymentMethod.card.cardNumber;
                        return cardLabel + BwcUtils.rightstring(cardNumber, 4);
                    }

                }
    
            case PaymentMethodType.BANKACCOUNT.value:
                {

                    const accountType = basePaymentMethod.bankAccount.accountType;
                    const accountLabel = accountType ? `${BankAccountType[accountType].label} ...` : 'Account ...';

                    if (spiData && spiData.spiDataList && spiData.spiDataList.length > 0) {
                        const accountNumber = spiData.spiDataList.find(data => data.name === PaymentSmartFields.BANK_ACCOUNT_NUMBER);
                        return accountLabel + BwcUtils.rightstring(accountNumber.value, 4);
                    } else {
                        const accountNumber = basePaymentMethod.bankAccount.bankAccountNumber;
                        return accountLabel + BwcUtils.rightstring(accountNumber, 4);
                    }
                }
    
            default:
                return '';
    
        }
    
    }

}