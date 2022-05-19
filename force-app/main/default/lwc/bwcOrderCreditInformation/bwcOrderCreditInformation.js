import { api, LightningElement, track } from 'lwc';

import * as BwcUtils from 'c/bwcUtils';

const FIELDS = [
    {
        label: 'Credit Reference ID',
        fieldPath: 'creditReferenceId',
        value: '',
        isTextType:true,
    },
    {
        label: 'Credit Reference Date',
        fieldPath: 'creditReferenceDate',
        value: '',
        isDateType: true,
    },
    {
        label: 'Credit Check Status',
        fieldPath: 'creditCheckStatus',
        value: '',
        isTextType:true,
    },
    {
        label: 'Credit Class',
        fieldPath: 'creditClass',
        value: '',
        isTextType:true,
    },
    {
        label: 'No. of Lines Approved',
        fieldPath: 'noOfLinesApproved',
        value: '',
        isTextType:true,
    },
]

export default class BwcOrderCreditInformation extends LightningElement {

    @track creditInformationFields = FIELDS;

    set order(values){

        if(!values){
            return;
        }

        //TODO: Is it the first one?
        let creditCheck = values.customer?.creditChecks?.[0];

        if(!creditCheck){
            return;
        }

        this.creditInformationFields = FIELDS.map(tempField=>{
            let field = {...tempField};
            field.value = BwcUtils.getValueFromField(creditCheck, field.fieldPath);

            return field;
        });

    }

    @api get order(){
        return this._order;
    }

}