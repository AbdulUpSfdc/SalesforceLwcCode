import { LightningElement, api, track } from 'lwc';
import { getValueFromField } from 'c/bwcUtils';
const FIELDS = [
    {
        label: 'Promo ID',
        fieldPath: 'promotionId',
        value: '',
        isTextType: true,
    },
    // Amount already includes $ sign
    {
        label: 'Discount',
        fieldPath: 'amount',
        value: '',
        isCurrencyType:true,
    },
    {
        label: 'Promo Type',
        fieldPath: 'promotionType',
        value: '',
        isTextType: true,
    },
    {
        label: 'Start Date',
        fieldPath: 'effectiveDate',
        value: '',
        isTextType: true,
    },
    {
        label: 'Promo Cycle',
        fieldPath: 'promotionCycle',
        value: '',
        isTextType: true,
    },
    {
        label: 'Description',
        fieldPath: 'description',
        value: '',
        isTextType: true,
    },
]

const promotionTypes = {
    billCreditWithQualifier: {value: 'BILLCREDITWITHQUALIFIER', label: 'Bill Credits'},

    getLabelForValue: value => {
        const promoType = Object.values(promotionTypes).find(item => item.value === value);
        return promoType ? promoType.label : value;
    }
}

const promoCycles = {
    oneTime: {value: 'ONETIME', label: 'One Time'},
    monthly: {value: 'MONTHLY', label: 'monthly'},

    getLabelForValue: value => {
        const promoCycle = Object.values(promoCycles).find(item => item.value === value);
        return promoCycle ? promoCycle.label : value;
    }
}


export default class BwcOrderPromoApplied extends LightningElement {

    @track promoFields = [];
    promotionData;
    
    @api set promoInformation(values){
        let localValues = JSON.parse(JSON.stringify(values));
        this.promotionData = localValues;
        let fields = [...FIELDS];

        for(let field of fields){

            field.value = getValueFromField(localValues, field.fieldPath);
        }

        this.promoFields = fields;
    }

    get promoInformation(){
        this.promoFields;
    }

}