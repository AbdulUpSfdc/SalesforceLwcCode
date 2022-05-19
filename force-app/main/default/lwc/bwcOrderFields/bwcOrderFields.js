import { LightningElement, api} from 'lwc';

/**
 *Component used to display data from an Order API Response.
*/
export default class BwcOrderFields extends LightningElement {

    /* List of read only data we want to display.
    Objects should have an is+datatype+Type attribute
    i.e. isTextType, isCurrencyType, IsDateType */
    @api fields;
    @api columns=1;

    /*
    example:
    [
        {
            label: 'Promo ID',
            fieldName: 'promotionId',
            innerFieldName: 'code',
            value: '',
            isTextType: true,
        },
        {
            label: 'Amount',
            fieldName: 'amount',
            value: '',
            isCurrencyType: true,
        },
        {
            label: 'Promo Type',
            fieldName: 'promotionType',
            innerFieldName: 'friendlyCode',
            value: '',
            isTextType: true,
        },
        {
            label: 'Promo Cycle',
            fieldName: 'promotionCycle',
            value: '',
            isTextType: true,
        },
        {
            label: 'Start Date',
            fieldName: 'effectiveDate',
            value: '',
            isDateType: true,
        },
        {
            label: 'Description',
            fieldName: 'description',
            value: '',
            isTextType: true,
        },
    ]
    */

    get columnClass(){

        let columns = this.columns;
        if(columns>12 || columns<1){
            columns = 1;
        }

        let sldsClass = `slds-col slds-size_1-of-${columns} slds-form-element`;

        return sldsClass;
    }
}