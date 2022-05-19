import { LightningElement, api, track } from 'lwc';

// Other components
import * as BwcUtils from 'c/bwcUtils';

const FIELDS = [
    {
        label: 'Channel Rep Id',
        fieldPath: 'compensation.channelRepId',
        value: '',
        isTextType:true,
    },
    {
        label: 'Rep Dealer Code 1',
        fieldPath: 'compensation.repDealer1Code',
        value: '',
        isTextType:true,
    },
    {
        label: 'Rep Dealer Code 2',
        fieldPath: 'compensation.repDealer2Code',
        value: '',
        isTextType:true,
    },
    {
        label: 'Channel Type',
        fieldPath: 'compensation.channelType',
        value: '',
        isTextType:true,
    }
]

export default class BwcOrderSalesRepInfo extends LightningElement {

    @track salesRepInfoFields = [];

    set order(values){

        if(!values){
            return;
        }

        const product = values.products?.[0];

        if(!product){
            return;
        }

        this.salesRepInfoFields = FIELDS.map(tempField=>{
            let field = {...tempField};
            field.value = BwcUtils.getValueFromField(product, field.fieldPath) || '';

            return field;
        })
    }

    @api get order(){
        return this.salesRepInfoFields;
    }

}