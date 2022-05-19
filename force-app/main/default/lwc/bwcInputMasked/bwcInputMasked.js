import { LightningElement, api } from 'lwc';

const MASK_CHAR = '•';
const UNMASKED_LENGTH = 4;
const CHANGE_EVENT = 'change';
const COMMIT_EVENT = 'commit';

export default class BwcInputMasked extends LightningElement {

    @api name;

    // The value shown in the input, masked except last 4.
    maskedValue;

    // Value
    _value;
    @api get value() {return this._value;}
    set value(val){
        this._value = val;
        this.maskedValue = this.getMaskedNumber(val);
    }

    @api required;
    @api disabled;
    @api autocomplete = 'off';

    // Retrieves the embedded input control
    get inputComponent() {return this.template.querySelector('lightning-input');}

    @api checkValidity() {
        this.validateCustom(this._value);
        return this.inputComponent.checkValidity();
    }

    @api reportValidity() {
        this.validateCustom(this._value);
        return this.inputComponent.reportValidity();
    }

    handleFocus(event) {

        // While we're focused, mask card number as typed
        event.target.type="password";
        if (event.target.value && event.target.value.startsWith('•')) {
            event.target.value = event.target.dataset.value;
        }

    }

    handleBlur(event) {

        // Stash card number in data property, then mask with last 4.
        const newValue = event.target.value;
        event.target.dataset.value = newValue;
        event.target.value = this.getMaskedNumber(newValue);
        event.target.type="text";

    }

    /*
        Runs on every change to input.
    */
    handleChange(event) {

        // Card number changing, valid or not
        this._value = event.target.value;
        this.dispatchEvent(new CustomEvent(CHANGE_EVENT, {detail: {value: this._value}}));

    }

    /*
        Validate on commit.
    */
    handleCommit(event) {

        this.validateCustom(event.target.value);
        this.dispatchEvent(new CustomEvent(COMMIT_EVENT));

    }

    /*
        E.g. •••••••••••1234
    */
    getMaskedNumber(number) {

        if (!number) {
            return '';
        }
        return MASK_CHAR.repeat(Math.max(0, number.length - UNMASKED_LENGTH)) + number.substring(number.length - UNMASKED_LENGTH);

    }

}