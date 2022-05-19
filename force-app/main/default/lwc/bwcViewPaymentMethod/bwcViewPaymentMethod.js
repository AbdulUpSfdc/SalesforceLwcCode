import { LightningElement, api } from 'lwc';
import * as BwcConstants from 'c/bwcConstants';
import * as BwcPayments from 'c/bwcPayments';
export default class BwcViewPaymentMethod extends LightningElement {

    // Payment details value.
    @api paymentMethod = {
    };

    // Raisr values
    @api spiData = {
        spiDataList: []
    }

    get isTypeCard() {
        return this.paymentMethod.type === BwcConstants.PaymentMethodType.CARD.value ||
                (this.paymentMethod.type === BwcConstants.PaymentMethodType.PAYMENT_PROFILE.value && this.paymentMethod.card);
    }
    get isTypeBankAccount() {
        return this.paymentMethod.type === BwcConstants.PaymentMethodType.BANKACCOUNT.value ||
        (this.paymentMethod.type === BwcConstants.PaymentMethodType.PAYMENT_PROFILE.value && this.paymentMethod.bankAccount);
    }
    get isTypePromiseToPay() {return this.paymentMethod.type === BwcConstants.PaymentMethodType.PROMISE_TO_PAY.value;}

    get paymentMethodName() {
        
        if (this.isTypeCard) {
            return BwcConstants.PaymentMethodType.CARD.label;
        }
        else if (this.isTypeBankAccount) {
            const accountType = BwcConstants.BankAccountType[this.paymentMethod.bankAccount.accountType];
            return accountType ? accountType.longLabel : '';
        }
        else if (this.isTypePromiseToPay) {
            return BwcConstants.PaymentMethodType.PROMISE_TO_PAY.label;
        }
        return '';

    }

    get cardTypeLabel() {
        const cardType = this.paymentMethod.card.cardType;
        return cardType ? `${BwcConstants.CardType[cardType].label} Ending in` : undefined;
    }

    get cardLast4() {
        if (this.spiData.spiDataList && this.spiData.spiDataList.length > 0) {
            const cardNumber = this.spiData.spiDataList.find(data => data.name === BwcPayments.PaymentSmartFields.CARD_NUMBER);
            return cardNumber.value ? cardNumber.value.substring(cardNumber.value.length - 4) : undefined;
        } else {
            const cardNumber = this.paymentMethod.card.cardNumber;
            return cardNumber ? cardNumber.substring(cardNumber.length - 4) : undefined;
        }
    }

    get cardExpirationDate() {
        const expireMonth = this.paymentMethod.card.expireMonth;
        const expireYear = this.paymentMethod.card.expireYear;
        if (expireMonth && expireYear) {
            return `${this.paymentMethod.card.expireMonth}/${this.paymentMethod.card.expireYear.substring(0, 4)}`;
        }
        return undefined;

    }

    get cardBillingZipCode() {
        return this.paymentMethod.card.zipCode;
    }

    get bankAccountLast4() {
        if (this.spiData.spiDataList && this.spiData.spiDataList.length > 0) {
            const accountNumber = this.spiData.spiDataList.find(data => data.name === BwcPayments.PaymentSmartFields.BANK_ACCOUNT_NUMBER);
            return accountNumber.value ? accountNumber.value.substring(accountNumber.value.length - 4) : undefined;
        } else {
            const accountNumber = this.paymentMethod.bankAccount.bankAccountNumber;
            return accountNumber ? accountNumber.substring(accountNumber.length - 4) : undefined;
        }
    }

    get promiseToPayMethodLabel() {
        return BwcConstants.PromiseToPayMethod.getLongLabel(this.paymentMethod.promiseToPay.method);
    }

}