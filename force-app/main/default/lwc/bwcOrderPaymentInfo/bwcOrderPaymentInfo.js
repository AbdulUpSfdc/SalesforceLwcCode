import { LightningElement, track, api } from 'lwc';

//Other components
import * as BwcUtils from 'c/bwcUtils';

const CREDIT_CARD_FIELDS = [
    {
        label: 'Amount',
        fieldName: 'tenderAmount',
        value: '',
        isCurrencyType:true,
    },
    {
        label: 'Card Type',
        fieldName: 'creditCardType',
        value: '',
        isTextType: true,
    },
    {
        label: 'Credit Card Last 4-digits',
        fieldName: 'creditCardLastFourDigits',
        value: '',
        isTextType:true,
    },
]

const INSTALLMENT_PLAN_FIELDS = [
    {
        label: 'Amount',
        fieldName: 'tenderAmount',
        value: '',
        isCurrencyType:true,
    },
    {
        label: 'Installment Terms',
        fieldName: 'installmentTerms',
        value: '',
        isTextType: true,
    },
    {
        label: 'Monthly Installment Amount',
        fieldName: 'monthlyInstallmentAmount',
        value: '',
        isCurrencyType:true,
    },
    {
        label: 'Down Payment',
        fieldName: 'downPaymentAmount',
        value: '',
        isCurrencyType:true,
    },
    {
        label: 'Device',
        fieldName: 'device',
        value: '',
        isTextType: true,
    },
]

const GIFT_CARD_FIELDS = [
    {
        label: 'Amount',
        fieldName: 'type',
        value: '',
        isCurrencyType:true,
    },
]

const BILL_TO_MOBILE_CARD_FIELDS = [
    {
        label: 'Tender Amount',
        fieldName: 'tenderAmount',
        value: '',
        isCurrencyType:true,
    },
]


const PAYMENT_TYPE_FIELDS_MAP = new Map([
    ['Credit Card', CREDIT_CARD_FIELDS],
    ['Installment Plan', INSTALLMENT_PLAN_FIELDS],
    ['Giftcard', GIFT_CARD_FIELDS],
    ['billToMobile', BILL_TO_MOBILE_CARD_FIELDS],
])

const paymentTypes = {
    creditCard: {value: 'Credit Card', label: 'Credit Card'},
    installmentPlan: {value: 'Installment Plan', label: 'Installment Plan'},
    giftCard: {value: 'giftCard', label: 'Gift Card'},
    
    getLabelForValue: value => {
        const paymentType = Object.values(paymentTypes).find(item => item.value === value);
        return paymentType ? paymentType.label : value;
    }
}

export default class BwcOrderPaymentInfo extends LightningElement {

    isExpanded=true;
    @track additionalPaymentInfo = [];
    @track paymentTenders =[];
    @api orderPrice;

    creditCardFields = CREDIT_CARD_FIELDS;
    installmentPlanFields = INSTALLMENT_PLAN_FIELDS;
    giftCardFields = GIFT_CARD_FIELDS;

    isRendered=false;

    @api set paymentInfo(paymentInfo){

        BwcUtils.log('Setting payment info', paymentInfo);

        if(paymentInfo===null || paymentInfo === undefined || !Array.isArray(paymentInfo)) return;

        let localValues = JSON.parse(JSON.stringify(paymentInfo));

        let tempPaymentInfo = [];

        localValues.forEach(paymentTender => {

            if(!PAYMENT_TYPE_FIELDS_MAP.has(paymentTender.type)){
                return;
            }

            

            if(paymentTender.type === paymentTypes.installmentPlan.value ){
                paymentTender.title = `${paymentTypes.getLabelForValue(paymentTender.type)} (${paymentTender.ctn})`;
            }else{
                paymentTender.title = paymentTypes.getLabelForValue(paymentTender.type);
            }
            

            let fields = PAYMENT_TYPE_FIELDS_MAP.get(paymentTender.type);
            paymentTender.fields = this.processPaymentFields(paymentTender, fields);
            BwcUtils.log({paymentTender});
            tempPaymentInfo.push(paymentTender);
        });

        this.additionalPaymentInfo.push(this.getTotalAmountField());
        this.paymentTenders = tempPaymentInfo;
    }

    get paymentInfo(){
        return this.paymentTenders;
    }

    renderedCallback(){
        if(!this.isRendered){
            this.handleExpandAll();
            this.isRendered = true;
        }
    }

    handleExpandAll(){

        this.isExpanded = !this.isExpanded;
        let expandableSections = this.template.querySelectorAll('c-bwc-expandable-section');

        expandableSections.forEach(section=>{
            section.expandCollapseSection(this.isExpanded);
        })

    }

    /*Method used to get the value from the payment record
    this method can be used when there's no an additional mapping
    involved.
    i.e. for cardType, depending on the value, we need to return someting different
    */
    processPaymentFields(paymentTender, fields){
        return fields.map((tempField)=>{
            let field = {...tempField};
            field.value = paymentTender[field.fieldName];
            return field;
        });
    }

    getTotalAmountField(){
        return{
            isCurrencyType: true,
            label: 'Total Order Amount',
            value: this.orderPrice
        }
    }

    get expandButtonText(){
        return this.isExpanded ? 'Collapse' : 'Expand';
    }

}