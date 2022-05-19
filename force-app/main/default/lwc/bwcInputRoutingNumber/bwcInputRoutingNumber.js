import { api } from 'lwc';
import BwcInputMasked from 'c/bwcInputMasked';

const ROUTING_NUMBER_REGEX = /^((0[0-9])|(1[0-2])|(2[1-9])|(3[0-2])|(6[1-9])|(7[0-2])|80)([0-9]{7})$/;

export default class BwcInputBankAccountNumber extends BwcInputMasked {

    @api label = "Routing Number";
    @api placeholder;
    @api messageWhenValueMissing = 'Routing number is required';
    @api messageWhenRoutingNumberInvalid = 'Invalid routing number';
    @api reenterMessage = 'Please re-enter the complete routing number';

    /*
        Custom validation for card number.
    */
    validateCustom(routingNumber) {

        const routingNumberInput = super.inputComponent;
        routingNumberInput.setCustomValidity('');
        if (!ROUTING_NUMBER_REGEX.test(routingNumber)) {
            routingNumberInput.setCustomValidity(this.messageWhenRoutingNumberInvalid);
            return false;
        }
        return true;

    }

}