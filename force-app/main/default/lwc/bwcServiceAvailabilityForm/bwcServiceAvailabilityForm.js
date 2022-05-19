import { LightningElement, api, track } from 'lwc';

import BwcPageElementBase from 'c/bwcPageElementBase';

// Custom labels 
import label_mulesoftErrorCode from '@salesforce/label/c.BWC_UnexpectedError_RefreshSection';

export default class BwcServiceAvailabilityForm extends BwcPageElementBase {


    isSubmitButtonDisabled = true;

    @api addressLine1;
    @api addressLine2;
    @api aptUnitNumber;
    @api city;
    @api state;
    @api zip;

    showenteredaddress = true;
    inputAddressLine1;
    inputAddressLine2;
    inputAptUnit;
    inputCity;
    inputState;
    inputZip;

    @api isnomatch;
    @api isexactmatch;
    isAlreadyLoaded;



    handleInputChange(event) {

        let fieldName = event.target.name;
        let value = event.detail.value;
        this[fieldName] = value;

        this.validateInputs();
    }

    submitForm() {
        let addressLine1 = this.inputAddressLine1;
        let aptUnitNumber = this.inputAddressLine2||'';
        let city = this.inputCity;
        let state = this.inputState;
        let zip = this.inputZip;

        const updatedAddressEvent = new CustomEvent('updatedaddress',
            {
                detail: {
                    addressLine1,
                    aptUnitNumber,
                    city,
                    state,
                    zip
                }
            }
        );

        this.dispatchEvent(updatedAddressEvent);
    }
    handleEditAddress() {
        try {
            this.inputAddressLine1 = this.addressLine1;
            this.inputAddressLine2 = this.addressLine2;
            this.inputAptUnit = '';
            this.inputCity = this.city;
            this.inputState = this.state;
            this.inputZip = this.zip;
            this.showenteredaddress = false;
        } catch (error) {
            super.handleError(error, label_mulesoftErrorCode, COMPONENT_UI_NAME, 'inline');
        }
    }
    handleSearchNewAddress() {
        try {
            this.inputAddressLine1 = '';
            this.inputAddressLine2 = '';
            this.inputAptUnit = '';
            this.inputCity = '';
            this.inputState = '';
            this.inputZip = '';
            this.showenteredaddress = false;
        } catch (error) {
            super.handleError(error, label_mulesoftErrorCode, COMPONENT_UI_NAME, 'inline');
        }
    }

    validateInputs() {

        let inputs = Array.from(this.template.querySelectorAll('lightning-input'));
        inputs.push(this.template.querySelector('lightning-combobox'));
        let inputValidations = inputs.map(input => {
            const trimmedValue = input.value?.trim();
            if (!trimmedValue && input.required) {
                return false;

            }
            return input.checkValidity();

        });

        let invalidInputs = inputValidations.some(validation => validation !== true);
        this.isSubmitButtonDisabled = invalidInputs;

    }
    // added to display Search New Address 
    get showNewAddress() {
        return this.isexactmatch && this.showenteredaddress;
    }
    // added to display you entered 
    get searchTerm() {

        const streetAddress = this.addressLine1 ? `${this.addressLine1}` : '';
        const streetAddress2 = this.addressLine2 ? ` ${this.addressLine2}\n` : '\n';
        const city = this.city ? `${this.city},` : '';
        const state = this.state ? ` ${this.state}` : '';
        const zipCode = this.zip ? `  ${this.zip}` : '';
        return `${streetAddress}${streetAddress2}${city}${state}${zipCode}`;
    }
    get stateValues() {
        return [
            { label: 'Alabama', value: 'AL' },
            { label: 'Alaska', value: 'AK' },
            { label: 'American Samoa', value: 'AS' },
            { label: 'Arizona', value: 'AZ' },
            { label: 'Arkansas', value: 'AR' },
            { label: 'California', value: 'CA' },
            { label: 'Colorado', value: 'CO' },
            { label: 'Connecticut', value: 'CT' },
            { label: 'Delaware', value: 'DE' },
            { label: 'District of Columbia', value: 'DC' },
            { label: 'Federated States of Micronesia', value: 'FM' },
            { label: 'Florida', value: 'FL' },
            { label: 'Georgia', value: 'GA' },
            { label: 'Guam', value: 'GU' },
            { label: 'Hawaii', value: 'HI' },
            { label: 'Idaho', value: 'ID' },
            { label: 'Illinois', value: 'IL' },
            { label: 'Indiana', value: 'IN' },
            { label: 'Iowa', value: 'IA' },
            { label: 'Kansas', value: 'KS' },
            { label: 'Kentucky', value: 'KY' },
            { label: 'Louisiana', value: 'LA' },
            { label: 'Maine', value: 'ME' },
            { label: 'Marshall Islands', value: 'MH' },
            { label: 'Maryland', value: 'MD' },
            { label: 'Massachusetts', value: 'MA' },
            { label: 'Michigan', value: 'MI' },
            { label: 'Minnesota', value: 'MN' },
            { label: 'Mississippi', value: 'MS' },
            { label: 'Missouri', value: 'MO' },
            { label: 'Montana', value: 'MT' },
            { label: 'Nebraska', value: 'NE' },
            { label: 'Nevada', value: 'NV' },
            { label: 'New Hampshire', value: 'NH' },
            { label: 'New Jersey', value: 'NJ' },
            { label: 'New Mexico', value: 'NM' },
            { label: 'New York', value: 'NY' },
            { label: 'North Carolina', value: 'NC' },
            { label: 'North Dakota', value: 'ND' },
            { label: 'Northern Mariana Islands', value: 'MP' },
            { label: 'Ohio', value: 'OH' },
            { label: 'Oklahoma', value: 'OK' },
            { label: 'Oregon', value: 'OR' },
            { label: 'Palau', value: 'PW' },
            { label: 'Pennsylvania', value: 'PA' },
            { label: 'Puerto Rico', value: 'PR' },
            { label: 'Rhode Island', value: 'RI' },
            { label: 'South Carolina', value: 'SC' },
            { label: 'South Dakota', value: 'SD' },
            { label: 'Tennessee', value: 'TN' },
            { label: 'Texas', value: 'TX' },
            { label: 'Utah', value: 'UT' },
            { label: 'Vermont', value: 'VT' },
            { label: 'Virgin Islands', value: 'VI' },
            { label: 'Virginia', value: 'VA' },
            { label: 'Washington', value: 'WA' },
            { label: 'West Virginia', value: 'WV' },
            { label: 'Wisconsin', value: 'WI' },
            { label: 'Wyoming', value: 'WY' },

        ];
    }
}