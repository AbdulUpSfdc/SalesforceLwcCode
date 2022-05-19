import { api } from 'lwc';
import BwcInputMasked from 'c/bwcInputMasked';

export default class BwcInputBankAccountNumber extends BwcInputMasked {

    @api label = "Account Number";
    @api placeholder;
    @api messageWhenValueMissing = 'Account number is required';
    @api reenterMessage = 'Please re-enter the complete account number';

    /*
        Custom validation for account number.
    */
    validateCustom(accountNumber) {

        const accountNumberInput = super.inputComponent;

        let isValid = false;
        accountNumberInput.setCustomValidity('');

        if (accountNumber && accountNumber.startsWith('XXX')) {
            // Account numbers come back from API masked with X character.
            // So the account number has been retrieved and we only have the masked value -- the user has to re-enter the full account number.
            accountNumberInput.setCustomValidity(this.reenterMessage);
        }
        else if (accountNumber) {

            isValid = true;

        }

        return isValid;

    }

}