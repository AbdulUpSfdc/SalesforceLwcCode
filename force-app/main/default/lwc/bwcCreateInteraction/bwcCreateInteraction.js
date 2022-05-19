/*
Hitesh Reddy    03/01/2021      Initial version created.
Hitesh reddy    03/10/2021      Updated handleProceedtoSearch method to handle spinner.
 */
import { LightningElement, api, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { createRecord } from 'lightning/uiRecordApi';
import INTERACTION_OBJECT from '@salesforce/schema/Interaction__c';
import IS_MANUAL_SEARCH from '@salesforce/schema/Interaction__c.Is_Manual_Search__c';
import CTI_CALL_IDENTIFIER from '@salesforce/schema/Interaction__c.CTI_Call_Identifier__c';

import * as BwcUtils from 'c/bwcUtils';

export default class BwcCreateInteraction extends LightningElement {

    showLoadingSpinner = false;

    interactionTypeOptions = [
        {label: 'Inbound', value: 'Inbound'},
        {label: 'Offline', value: 'Offline'},
        {label: 'Outbound', value: 'Outbound'},
    ];

    @wire(getObjectInfo, { objectApiName: INTERACTION_OBJECT })
    interactionObjectInfo;

    recordTypeId;

    handleSearchCustomer(){
        
        // Validate
        const comboBox = this.template.querySelector('lightning-combobox');
        if (comboBox.reportValidity()) {

            // Get record type ID
            const recordTypeName = comboBox.value;
            const recordTypeInfos = this.interactionObjectInfo.data.recordTypeInfos;
            const recordTypeIds = Object.keys(recordTypeInfos);
            this.recordTypeId = recordTypeIds.find(recordTypeId => recordTypeInfos[recordTypeId].name === recordTypeName);

            // Tell aura wrapper to start
            this.dispatchEvent(new CustomEvent('valuechange'));

        }
    }

    @api async createInteraction(){

        this.showLoadingSpinner = true;

        // Get record type

        const randomNumber = Math.random().toString(36).substring(5);
        const dateTimeString = this.getDateTimeString();
        const recordInput = {
            apiName: INTERACTION_OBJECT.objectApiName,
            fields: {
                RecordTypeId: this.recordTypeId,
                [IS_MANUAL_SEARCH.fieldApiName] : true,
                [CTI_CALL_IDENTIFIER.fieldApiName]: 'Manual_'+ dateTimeString +'_'+ randomNumber
            }
        };

        try {

            const result = await  createRecord(recordInput);

            // Fire the custom event
            this.dispatchEvent(new CustomEvent('navtointeraction', {detail: {value: result }}));

        }
        catch(error) {
            BwcUtils.error(error);
            let errorMessage = BwcUtils.processError(error);
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: errorMessage, variant: 'error'}));
        }
        finally {
            this.showLoadingSpinner = false;
        }
        
    }

    getDateTimeString(){
        const x = new Date();
        const y = x.getFullYear().toString();
        const m = (x.getMonth() + 1).toString();
        const d = x.getDate().toString();
        const h = x.getHours();
        const mm = x.getMinutes();
        const yymmdd = y + m + d+h+mm;
        return yymmdd;
    }
}