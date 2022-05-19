import { LightningElement, api } from 'lwc';
import * as BwcUtils from 'c/bwcUtils';
import { StateOptions } from 'c/bwcConstants';
import label_zipAStMand from '@salesforce/label/c.BWC_CustomerSearchError_ZipAStMand';
import { labels } from 'c/bwcUnifiedSearchServices';
export default class BwcAddressSelection extends LightningElement {

    label = labels;
    columns = [
        { label: 'STREET ADDRESS', fieldName: 'id', type:'actionLink',
            sortable: true,
            hideDefaultActions: true,
            typeAttributes: {
                label: {
                    fieldName: 'streetAddress'
                },
                onactionclick: this.handleAddressSelection.bind(this)
            },
        },
        { label: 'ADDRESS 2', fieldName: 'address2',  hideDefaultActions: true},
        { label: 'CITY', fieldName: 'city',  hideDefaultActions: true},
        { label: 'STATE', fieldName: 'stateOrProvince',  hideDefaultActions: true},
        { label: 'ZIP', fieldName: 'postcode',  hideDefaultActions: true},
        { label: 'COUNTRY', fieldName: 'country',  hideDefaultActions: true},
    ];
    _addresses;
    showForm = false;
    states=StateOptions;

    streetAddress;
    aptUnitNo;
    city;
    state;
    zipCode;

    set enteredStreetAddress(value){
        this.streetAddress = value;
    }
    set enteredAptUnitNo(value){
        this.aptUnitNo = value;
    }
    set enteredCity(value){
        this.city = value;
    }
    set enteredState(value){
        this.state = value;
    }
    set enteredZipCode(value){
        this.zipCode = value;
    }

    @api get enteredStreetAddress(){
        return this.streetAddress;
    }

    @api get enteredAptUnitNo(){
        return this.aptUnitNo;
    }

    @api get enteredCity(){
        return this.city;
    }

    @api get enteredState(){
        return this.state;
    }

    @api get enteredZipCode(){
        return this.zipCode;
    }


    get searchTerm(){
        const stateName = this.states.find(state => state.value === this.state)?.label;

        const streetAddress = this.streetAddress ? `${this.streetAddress}\n` : '';
        const aptUnitNo = this.aptUnitNo ? `${this.aptUnitNo}\n` : '';
        const city = this.city ? `${this.city}\n` : '';
        const state = stateName ? `${stateName}` : '';
        const zipCode = this.zipCode ? ` - ${this.zipCode}` :'';

        return `${streetAddress}${aptUnitNo }${city }${state}${zipCode }`;
    }

    set addresses(value){

        if(!value || (Array.isArray(value) && value.length === 0)){
            this._addresses = [];
            return;
        }

        const tempData = BwcUtils.cloneObject(value);

        tempData.forEach( address => {

            const addressLine1 = address.addressCharacteristic?.[0];
            const addressLine2 = address.addressCharacteristic?.[1];
            const stateLabel= this.states.find(state => state.value === address.stateOrProvince)?.label;


            address.streetAddress = addressLine1?.value;
            address.address2 = addressLine2?.value;
            address.stateOrProvince = stateLabel ? stateLabel.toUpperCase() : '';
        });
        this._addresses = tempData;
    }

    @api get addresses(){
        return this._addresses;
    }

    handleNewSearch(){
        this.dispatchEvent(new CustomEvent('newsearch', {
            detail:{
                clear: false
            }
        }));
    }

    handleAddressSelection(event){

        const addressId = event.detail.value;

        this.dispatchEvent(new CustomEvent('addressselection', {
            detail:addressId
        }));

    }

    handleInputChange(event){

        this[event.target.dataset.id] = event.target.value.trim();

        event.target.setCustomValidity('');
    }

    handleSearchAgain(){
        this.showForm = !this.showForm;
    }

    handleNewAddress(){

        let isValidated = this.validate();
        if(isValidated){
            // If empty, take entered address
            const newAddress = new CustomEvent('newaddress', {
                detail:{
                    streetAddress: this.streetAddress,
                    aptUnitNo: this.aptUnitNo,
                    city: this.city,
                    state: this.state,
                    zipCode: this.zipCode
                }
            });

            this.dispatchEvent(newAddress);
            this.showForm = false;
        }

    }

    validate(){

        let isValid = true;

        // Run built-in validation on all enabled inputs
        this.template.querySelectorAll('lightning-input, lightning-combobox').forEach(component => {

            if(component.dataset.id === 'streetAddress'){
                const value = component.value;
                if(!value){
                    this.setCustomValidity('streetAddress', label_zipAStMand);
                }
            }

            if(component.dataset.id === 'zipCode'){
                const value = component.value;
                if(!value){
                    this.setCustomValidity('zipCode', label_zipAStMand);
                }
            }

            if(component.dataset.id === 'state'){
                const value = component.value;
                if(!value){
                    this.setCustomValidity('state', this.label.selectValidState);
                }
            }

            const i = component.reportValidity();

            isValid = isValid && i;

        });

        return isValid;

    }

    setCustomValidity(componentId, message) {

        const component = this.template.querySelector(`[data-id="${componentId}"]`);
        if (component) {
            component.setCustomValidity(message);
            component.reportValidity();
        }
        else {
            throw new Error('Component not found: ' + componentId);
        }

    }


}