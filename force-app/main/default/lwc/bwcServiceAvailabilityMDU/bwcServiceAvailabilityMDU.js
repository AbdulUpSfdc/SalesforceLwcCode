import { LightningElement, track, api } from 'lwc';

import BwcPageElementBase from 'c/bwcPageElementBase';
import * as BwcUtils from 'c/bwcUtils';

// Custom labels 
import label_mulesoftErrorCode from '@salesforce/label/c.BWC_UnexpectedError_RefreshSection';
import label_mdu from '@salesforce/label/c.BWC_ServiceAvailabilityMDU';
import label_closematch from '@salesforce/label/c.BWC_ServiceAvailabilityCloseMatch';
import label_addressnotlisted from '@salesforce/label/c.BWC_ServiceAvailabilityAddressNotListed';

export default class BwcServiceAvailabilityMDU extends BwcPageElementBase {

    showTable = true;
    showRefineForm = true;
    isSubmitButtonDisabled = true;

    label = {
        mdu: label_mdu,
        closematch: label_closematch,
        addressnotlisted: label_addressnotlisted
    };

    aptUnitNumber;


    tableColumnsWithAddressline = [
        { type: 'text', fieldName: 'addressLine1', label: 'Address Line 1', hideDefaultActions: true, },
        {
            label: 'Address Line2', fieldName: 'addressLine2', type: 'actionLink',
            hideDefaultActions: true,
            typeAttributes: {
                label: {
                    fieldName: 'addressLine2'
                },
                onactionclick: this.handleSelectedMduAddress.bind(this)
            },
        },
        { type: 'text', fieldName: 'city', label: 'City', hideDefaultActions: true, },
        { type: 'text', fieldName: 'state', label: 'State', hideDefaultActions: true, },
        { type: 'text', fieldName: 'zip', label: 'Zip Code', hideDefaultActions: true, },
    ];
    tableColumnsWithoutAddressline = [
        {
            type: 'actionLink', fieldName: 'addressLine1', label: 'Address Line 1', hideDefaultActions: true,
            typeAttributes: {
                label: { fieldName: 'addressLine1' },
                title: { fieldName: 'addressLine1' },
                onactionclick: this.handleSelectedCloseMatchAddress.bind(this)
            }
        },
        { type: 'text', fieldName: 'addressLine2', label: 'Address Line 2', hideDefaultActions: true },
        { type: 'text', fieldName: 'city', label: 'City', hideDefaultActions: true, },
        { type: 'text', fieldName: 'state', label: 'State', hideDefaultActions: true, },
        { type: 'text', fieldName: 'zip', label: 'Zip Code', hideDefaultActions: true, },
    ];



    @api addresses = [];
    @api closematchaddress = [];

    get isclosematchAddress() {
        return this.closematchaddress?.length > 0;
    }
    get isMduAddress() {
        return this.addresses?.length > 0;
    }

    handlesShowAddressesList(event) {
        event.preventDefault();
        this.showTable = true;
        this.showRefineForm = false;
    }

    handleShowRefineForm(event) {
        event.preventDefault();
        this.showTable = false;
        this.showRefineForm = true;
    }

    handleSelectedMduAddress(event) {
        try {
            const selectedAddress = event.detail.value;
            //if using addressLine2, we could remove this by showing the addressId to the agent
            const selectedRow = this.addresses.find((address) => address.addressLine2 === selectedAddress);
            BwcUtils.log('Address Line   ', selectedRow);
            const selectedAddressEvent = new CustomEvent('selectedaddress',
                {
                    detail: JSON.stringify(selectedRow)
                }
            );

            this.dispatchEvent(selectedAddressEvent);

        } catch (e) {
            super.handleError(error, label_mulesoftErrorCode, COMPONENT_UI_NAME, 'inline');
        }
    }
    handleSelectedCloseMatchAddress(event) {
        try {
            const selectedAddress = event.detail.value;
            //if using addressLine2, we could remove this by showing the addressId to the agent
            const selectedRow = this.closematchaddress.find((address) => address.addressLine1 === selectedAddress);
            BwcUtils.log('Address Line   ', selectedRow);
            const selectedAddressEvent = new CustomEvent('selectedaddress',
                {
                    detail: JSON.stringify(selectedRow)
                }
            );

            this.dispatchEvent(selectedAddressEvent);

        } catch (e) {
            super.handleError(error, label_mulesoftErrorCode, COMPONENT_UI_NAME, 'inline');
        }
    }

}