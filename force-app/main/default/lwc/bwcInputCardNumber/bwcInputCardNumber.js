import { api } from 'lwc';
import BwcInputMasked from 'c/bwcInputMasked';

// Card Info.
const CARD_SPECS = [
    {
        cardType: 'VISA',
        label: 'Visa',
        regex: /^4[0-9]{12}(?:[0-9]{3})?$/
    },
    {
        cardType: 'MASTERCARD',
        label: 'MasterCard',
        regex: /^(?:5[1-5][0-9]{2}|222[1-9]|22[3-9][0-9]|2[3-6][0-9]{2}|27[01][0-9]|2720)[0-9]{12}$/
    },
    {
        cardType: 'AMEX',
        label: 'American Express',
        regex: /^3[47][0-9]{13}$/
    },
    {
        cardType: 'DINERS',
        label: 'Diners Club',
        regex: /^3(?:0[0-5]|[68][0-9])[0-9]{11}$/
    },
    {
        cardType: 'DISCOVER',
        label: 'Discover',
        regex: /^65[4-9][0-9]{13}|64[4-9][0-9]{13}|6011[0-9]{12}|(622(?:12[6-9]|1[3-9][0-9]|[2-8][0-9][0-9]|9[01][0-9]|92[0-5])[0-9]{10})$/
    },
];

const CARD_TYPE_CHANGE_EVENT = 'cardtypechange';

export default class BwcInputCardNumber extends BwcInputMasked {

    // Read-only card type, detected by card number
    _cardType;
    @api get cardType() {return this._cardType;}

    @api label = "Card Number";
    @api placeholder;
    @api messageWhenValueMissing = 'Card number is required';
    @api messageWhenCardNumberInvalid = 'Invalid card number';
    @api reenterMessage = 'Please re-enter the complete card number';

    /*
        Runs on every change to input.
    */
    handleChange(event) {

        super.handleChange(event);

        // Attempt to determine card type from number.
        const cardNumber = event.target.value;
        let newCardType;
        for (let i = 0; i < CARD_SPECS.length; i++) {
            if (CARD_SPECS[i].regex.test(cardNumber)) {

                newCardType = CARD_SPECS[i].cardType;
                break;

            }
        }

        if (newCardType !== this._cardType) {

            // Change card type
            this._cardType = newCardType;
            this.dispatchEvent(new CustomEvent(CARD_TYPE_CHANGE_EVENT, {detail: {cardType: this._cardType}}));

        }

    }

    /*
        Custom validation for card number.
    */
    validateCustom(cardNumber) {

        const cardNumberInput = super.inputComponent;

        let isValid = false;
        cardNumberInput.setCustomValidity('');

        if (cardNumber && cardNumber.startsWith('XXX')) {
            // Card numbers come back from API masked with X character.
            // So the card number has been retrieved and we only have the masked value -- the user has to re-enter the full card number.
            cardNumberInput.setCustomValidity(this.reenterMessage);
        }
        else if (cardNumber) {

            // Try all patterns
            for (let i = 0; i < CARD_SPECS.length; i++) {
                if (CARD_SPECS[i].regex.test(cardNumber)) {
                    // It matches a valid card number
                    isValid = true;
                    break;
                }
            }
    
            if (!isValid) {
                cardNumberInput.setCustomValidity(this.messageWhenCardNumberInvalid);
            }

        }

        return isValid;

    }

}