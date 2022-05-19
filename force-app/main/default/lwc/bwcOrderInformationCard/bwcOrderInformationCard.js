import { LightningElement, api, track } from 'lwc';

// Other components
import * as BwcUtils from 'c/bwcUtils';

const FIELDS = [
    {
        label: 'Order Id',
        fieldPath: 'orderId',
        value: '',
        isTextType:true,
    },
    {
        label: 'Order Status',
        fieldPath: 'orderStatus.code',
        value: '',
        isTextType:true,
    },
    {
        label: 'Status Detail',
        fieldPath: 'orderStatus.friendlyCode',
        value: '',
        isTextType:true,
    },
    {
        label: 'Additional Details',
        fieldPath: 'orderStatus.friendlyDescription',
        value: '',
        isTextType:true,
    },
    {
        label: 'Order Date',
        fieldPath: 'orderDate',
        value: '',
        isDateType: true,
    },
    {
        label: 'Store Id',
        fieldPath: 'orderingStoreId',
        value: '',
        isTextType:true,
    },
    {
        label: 'Sales Representative ID',
        fieldPath: 'salesRepresentativeId',
        value: '',
        isTextType:true,
    },
    {
        label: 'Originating System',
        fieldPath: 'originatingSystem',
        value: '',
        isTextType:true,
    },
]

const BILLING = 'billing';
const SERVICE = 'service';
const WIRELESS_PRODUCT = 'Wireless';
const UVERSE_PRODUCT = 'Uverse';
const BILLING_ADDRESS = 'Billing Address';
const SERVICE_ADDRESS = 'Service Address';

export default class BwcOrderInformationCard extends LightningElement {

    @track orderInfoFields = [];
    @api addresses;

    @api columns=2;
    set order(values){

        if(!values){
            return;
        }

        const tempFields = FIELDS.map(tempField=>{
            let field = {...tempField};
            field.value = BwcUtils.getValueFromField(values, field.fieldPath) || '';

            return field;
        });

        let hasWireless = false;
        let hasWireline = false;

        values.products.forEach(product =>{
            const productName = product.lineOfBusiness;
            if(productName === WIRELESS_PRODUCT){
                hasWireless = true;
            }
            if(productName === UVERSE_PRODUCT){
                hasWireline = true;
            }
        });

        if(hasWireless){
            const wirelessAddress = this.getAddress(BILLING);
            const tempAddressField = this.getFormattedAddress(wirelessAddress, BILLING_ADDRESS);
            tempFields.push(tempAddressField);
        }

        if(hasWireline){
            const wireAddress = this.getAddress(SERVICE);
            const tempAddressField = this.getFormattedAddress(wireAddress, SERVICE_ADDRESS);
            tempFields.push(tempAddressField);
        }

        this.orderInfoFields = tempFields;
    }

    @api get order(){
        return this.orderInfoFields;
    }

    getFormattedAddress(address, label){
        if( address === null || address === undefined){
            return '';
        } 
        let str = `${address.address1 || ''} \n ${address.address2 || ''} \n ${address.city || ''}, ${address.state || ''} ${address.zipcode || address.zip || ''}`;
        
        return {
            label: label,
            value: str,
            isTextType:true,
        };
    }

    getAddress(addressClassification){
        return this.addresses.find((address)=> address.addressClassification === addressClassification);
    }
}