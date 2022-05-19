import { LightningElement, api, track } from 'lwc';
import * as BwcUtils from 'c/bwcUtils';

const ITEMS_ORDERED_FIELDS = [
    {
        label: 'Quantity',
        fieldPath: 'quantityOrdered',
        value: '',
        isTextType:true,
    },
    //show two dates on the same field, fromDate - toDate
    {
        label: 'Estimated Shipping',
        fieldPath: 'estimatedShipDateRange.fromDate',
        value: '',
        isTextType:true,
    },
    //show two dates on the same field, fromDate - toDate
    {
        label: 'Estimated Delivery',
        fieldPath: 'estimatedDeliveryDateRange.fromDate',
        value: '',
        isTextType:true,
    },
    {
        label: 'Price Type',
        fieldPath: 'price.priceType',
        value: '',
        isTextType:true,
    },
    {
        label: 'Amount',
        fieldPath: 'price.unitPrice',
        wirelessFieldPath: 'price.salePrice',
        value: '',
        isCurrencyType:true,
    },
    {
        label: 'Sales Tax',
        fieldPath: 'price.totalTax',
        value: '',
        isCurrencyType:true,
    },
]

const TRADE_IN_ITEMS_FIELDS = [
    {
        label: 'Description',
        fieldName: 'itemDescription',
        value: '',
        isTextType:true,
    },
    {
        label: 'Trade In Type',
        fieldName: 'tradeInType',
        value: '',
        isTextType:true,
    },
    {
        label: 'Trade Status',
        fieldName: 'tradeInDetails',
        innerFieldName: 'tradeStatus',
        value: '',
        isTextType:true,
    },
    {
        label: 'Trade Date',
        fieldName: 'tradeInDetails',
        innerFieldName: 'tradeDate',
        value: '',
        isDateType:true,
    },
    {
        label: 'Inspected Date',
        fieldName: 'tradeInDetails',
        innerFieldName: 'inspectedDate',
        value: '',
        isDateType:true,
    },
    {
        label: 'Post Inspection Value',
        fieldName: 'tradeInDetails',
        innerFieldName: 'postInspectionValue',
        value: '',
        isCurrencyType:true,
    },
]

//Info located in fulfillments object.
const SHIPMENT_FIELDS_C2S = [
    {
        label: 'Type',
        fieldName: 'type',
        value: '',
        isTextType:true,
    },
    {
        label: 'Fulfillment Type',
        fieldName: 'fulfillmentType',
        value: '',
        isTextType:true,
    },
    //Is this a list or just a property?
    {
        label: 'Status',
        fieldName: 'shipments',
        innerFieldName: 'shipmentStatus',
        fallbackFieldName: 'fulfillmentStatus',
        fallbackInnerFieldName: 'code',
        value: '',
        isTextType:true,
    },
    {
        label: 'Status Detail',
        fieldName: 'fulfillmentStatus',
        innerFieldName: 'friendlyCode',
        value: '',
        isTextType:true,
    },
    {
        label: 'Store Name',
        fieldName: 'storeDetails',
        innerFieldName: 'name',
        value: '',
        isTextType:true,
    },
    {
        label: 'Address',
        fieldName: 'storeDetails',
        innerFieldName: 'address',
        value: '',
        isTextType:true,
    },
    {
        label: 'Item Quantity',
        fieldName: 'pickupVisits',
        value: '',
        isTextType:true,
    },
];

const SHIPMENT_FIELDS_DF = [
    {
        label: 'Type',
        fieldName: 'type',
        value: '',
        isTextType:true,
    },
    {
        label: 'Fulfillment Type',
        fieldName: 'fulfillmentType',
        value: '',
        isTextType:true,
    },
    //Is this a list or just a property?
    {
        label: 'Status',
        fieldName: 'shipments',
        innerFieldName: 'shipmentStatus',
        fallbackFieldName: 'fulfillmentStatus',
        fallbackInnerFieldName: 'code',
        value: '',
        isTextType:true,
    },
    {
        label: 'Status Detail',
        fieldName: 'fulfillmentStatus',
        innerFieldName: 'friendlyCode',
        value: '',
        isTextType:true,
    },
    {
        label: 'Item Quantity',
        fieldName: 'itemQuantity',
        value: '',
        isTextType:true,
    },
    {
        label: 'Address',
        fieldName: 'address',
        value: '',
        isTextType:true,
    },
    {
        label: 'Carrier',
        fieldName: 'shipment',
        innerFieldName: 'carrierName',
        value: '',
        isTextType:true,
    },
    {
        label: 'Ship Date',
        fieldName: 'shipment',
        innerFieldName: 'shippedDate',
        value: '',
        isDateType:true,
    },
    {
        label: 'Tracking ID',
        fieldName: 'shipment',
        innerFieldName: 'trackingId',
        value: '',
        isTextType:true,
    },
    {
        label: 'Tracking URL',
        fieldName: 'shipment',
        innerFieldName: 'trackingURL',
        value: '',
        urlLabel: '',
        isURLType:true,
    },
];

const SHIPMENT_FIELDS_PDO_DOO = [
    {
        label: 'Type',
        fieldName: 'deliveryOption',
        value: '',
        isTextType:true,
    },
    {
        label: 'Item Quantity',
        fieldName: 'pickupVisits',
        value: '',
        isTextType:true,
    },
    {
        label: 'Fulfillment Type',
        fieldName: 'fulfillmentType',
        value: '',
        isTextType:true,
    },
    {
        label: 'Fulfillment Status',
        fieldName: 'fulfillmentStatus',
        innerFieldName: 'friendlyCode',
        value: '',
        isTextType:true,
    },
    {
        label: 'Scheduled Date',
        fieldName: 'appoinments',
        innerFieldName:'scheduledDate',
        value: '',
        isDateType:true,
    },
    {
        label: 'Delivered Date',
        fieldName: 'appointments',
        innerFieldName:'deliveredDate',
        value: '',
        isDateType:true,
    },

    {
        label: 'Address',
        fieldName: 'shippingAddress',
        value: '',
        isTextType:true,
    },
];

//TODO: move this to bwcUtils and use it from there
const priceTypes = {
    recurring: {value: 'recurring', label: 'Recurring'},
    oneTime: {value: 'one-time', label: 'One Time'},

    getLabelForValue: value => {
        const priceType = Object.values(priceTypes).find(item => item.value === value);
        return priceType ? priceType.label : value;
    }
}

const shipmentTypes = {
    storePickup: {value: 'store-pickup', label: 'Store Pickup'},
    ship: {value: 'ship', label: 'Ship'},
    delivery: {value: 'delivery', label: 'Drop Off Option'},

    getLabelForValue: value => {
        const shipmentType = Object.values(shipmentTypes).find(item => item.value === value);
        return shipmentType ? shipmentType.label : value;
    }
}

const fulfillmentTypes = {
    DF: {value: 'DF', label: 'Direct Fulfillment'},
    C2S: {value: 'C2S', label: 'Click to Store'},
    PDO: {value: 'PDO', label: 'Premium Delivery Option'},
    DOO: {value: 'DOO', label: 'Drop off Option'},
    CC: {value: 'CC', label: 'Cash and Carry'},

    getLabelForValue: value => {
        const fulfillmentType = Object.values(fulfillmentTypes).find(item => item.value === value);
        return fulfillmentType ? fulfillmentType.label : value;
    }
}

const deliveryOptions = {
    doorDelivery: {value: 'door-delivery', label: 'Door Delivery'},

    getLabelForValue: value => {
        const fulfillmentType = Object.values(deliveryOptions).find(item => item.value === value);
        return fulfillmentType ? fulfillmentType.label : value;
    }
}

const FULFILLMENT_TYPE_C2S ='Click to Store';
const FULFILLMENT_TYPE_DF ='Direct Fulfillment';
const FULFILLMENT_TYPE_PDO ='Premium Delivery Option';
const FULFILLMENT_TYPE_DOO ='Drop off Option';

const SHIPPING_ADDRESS = 'shipping';

const PROMOTION_ADJUSTMENT_TYPE = 'promotion';
const WIRELESS_PRODUCT = 'wireless';

export default class BwcOrderDetailItems extends LightningElement {

    // Stores the shipments related to the productSequenceNumber
    fulfillment;

    @track _fulfillmentType;
    @track _items;
    @track areThereDevices=false;

    @api addresses;
    @api fulfillments;
    @api promotions;
    @api productSequenceNumber;

    @api productName;
    @api lineOfBusiness;
    

    @api get isWireless(){
        return this.lineOfBusiness?.toLowerCase() ===  WIRELESS_PRODUCT;
    }

    @api expandCollapseSections(expand){

        let expandableSections = this.template.querySelectorAll('c-bwc-expandable-section');

        expandableSections.forEach(section=>{
            section.expandCollapseSection(expand);
        });
    }

    /**
     * process items, check what kind of fields we need to display
     * items have shipment information presented in collapsable section, from fulfillments array
     *  we need to check what fields we need to display for shipment information
     * items have promo information presented in collapsable section, from promotions array
     *
    */
    @api set items(values){

        if(values===null || values === undefined || !Array.isArray(values)) return;

        this.setShipments();

        //Stringify and Parse to remove the readonly restriction
        let localValues = JSON.parse(JSON.stringify(values));

        let tempItems = [];
        for(let item of localValues){
            let tempItem = {};

            //Non TradeInDevice and non hardgood should not be shown
            if(!item.isTradeInDevice && !item.isHardGood) continue;

            let itemPrice = this.isWireless ? item.price?.salePrice : item.price?.unitPrice;
            itemPrice = Number(itemPrice);

            tempItem.itemDescription = item.itemDescription;
            tempItem.Type = item.itemTypeDescription;
            tempItem.itemPrice = itemPrice || false;
            tempItem.itemSequence = item.itemSequence;
            tempItem.itemStatus = item.itemStatus;
            tempItem.salePrice = item.price?.salePrice;
            tempItem.promotionTitle = `${tempItem.itemDescription} (Promotion)`;
            
            if(tempItem.Type != null){
                tempItem.title = `${item.itemDescription} (${item.itemTypeDescription})`;
            } else {
                tempItem.title = item.itemDescription;
            }
             
            if(item.isTradeInDevice){
                tempItem.fields = this.processTradeInFields(item);
            }else{
                tempItem.fields = this.processItemFields(item);
            }

            let shipmentFields = this.getShipmentFields(item.itemSequence);
            if(shipmentFields.length>0){
                tempItem.shipmentFields = shipmentFields;
            }

            let promotion = this.getPromotion(item);
            if(promotion){
                tempItem.promotion = promotion;
            }

            tempItems.push(tempItem);
        }

        if(tempItems.length > 0){
            this._items = tempItems;
            this.areThereDevices = true;
        }

    }
    get items(){
        return this._items;
    }

    processItemFields(itemInfo){
        return ITEMS_ORDERED_FIELDS.map((tempField)=>{
            let field = { ...tempField };
            if(field.hasOwnProperty('wirelessFieldPath') && this.isWireless){
                field.value = BwcUtils.getValueFromField(itemInfo,tempField.wirelessFieldPath);
            } else{
                field.value = BwcUtils.getValueFromField(itemInfo,tempField.fieldPath);
            }
            return field;
        });
    }

    processTradeInFields(itemInfo){
        return TRADE_IN_ITEMS_FIELDS.map((tempField)=>{
            let field = {...tempField};

            if(field.innerFieldName){
                field.value = itemInfo[field.fieldName]?.[field.innerFieldName];
            }else{
                field.value = itemInfo[field.fieldName];
            }

            return field;
        });
    }

    getMakeAndModel(item){
        return `${item.make} + ${item.model}`;
    }

    getDateRange(dateRange){

        if(dateRange == null || dateRange==undefined) return;

        let fromDate = dateRange.fromDate ? this.getFormattedDate(dateRange.fromDate) : '';
        let toDate = dateRange.toDate ? this.getFormattedDate(dateRange.toDate) : '';

        return `${fromDate} - ${toDate}`;
    }

    getFormattedDate(date){

        if(date==null || date==undefined) return '';

        let d = new Date(date);
        let ye = new Intl.DateTimeFormat('en', { year: 'numeric' }).format(d);
        let mo = new Intl.DateTimeFormat('en', { month: '2-digit' }).format(d);
        let da = new Intl.DateTimeFormat('en', { day: '2-digit' }).format(d);
        return `${mo}/${da}/${ye}`;
    }

    getPromotion(item){

        let {price} = item;

        if(!price.hasOwnProperty('adjustments')) return null;

        // Array that stores the promotionSequence of the price adjusment. there can be more than one
        //this value is used to extract the right promotion from the promotions array
        let servicePromotions = price.adjustments.filter((adjustment)=> adjustment.adjustmentType === PROMOTION_ADJUSTMENT_TYPE);

            let promotionSequences = servicePromotions.map(promotion => promotion.promotionSequence);

        let promotions = this.promotions.filter((promotion)=> promotionSequences.includes(promotion.promotionSequence) );

        // TODO: can an item have more than 1 promotion?
        return promotions[0];

    }

    /**
     * Filters fulfillments related to the current product
    */
    setShipments(){
        if(!Array.isArray(this.fulfillments)) return;

        this.fulfillment = this.fulfillments.find((fulfillment)=>fulfillment.productSequenceNumber?.[0] == this.productSequenceNumber);
        this._fulfillmentType = this.fulfillment?.fulfillmentType;
    }

    /**
     * Returns the shipment information related to the specified item
     */
    getShipmentFields(itemSequence){
        let shipmentFields=[];

        if(this.fulfillment==null || this.fulfillment==undefined) return [];

        let {fulfillmentType} = this.fulfillment;

        let fulfillmentInfo = this.fulfillment;

        switch (fulfillmentType) {
            case FULFILLMENT_TYPE_C2S:
                shipmentFields = this.processC2S_Fulfillment(fulfillmentInfo, itemSequence);
                break;
            case FULFILLMENT_TYPE_DF:
                shipmentFields = this.processDF_Fulfillment(fulfillmentInfo, itemSequence);
                break;
            case FULFILLMENT_TYPE_PDO:
            case FULFILLMENT_TYPE_DOO:
                shipmentFields = this.processPDO_DOO_Fulfillment(fulfillmentInfo, itemSequence);
                break;
        }

        return shipmentFields;
    }

    processC2S_Fulfillment(fulfillmentInfo, itemSequence){
        return SHIPMENT_FIELDS_C2S.map((tempField)=>{

            let field = {...tempField};

            if(field.fieldName == 'type'){
                field.value = shipmentTypes.getLabelForValue(fulfillmentInfo[field.fieldName]);
                return field;
            }

            if(field.fieldName == 'fulfillmentType'){
                field.value = fulfillmentTypes.getLabelForValue(fulfillmentInfo[field.fieldName]);
                return field;
            }

            if(field.fieldName == 'storeDetails' && field.innerFieldName == 'address'){
                let {fieldName, innerFieldName} = field;
                field.value = this.getFormattedAddress(fulfillmentInfo[fieldName]?.[innerFieldName], true);
                return field;
            }

            if(field.fieldName == 'pickupVisits'){
                let item = this.getItemQuantity(fulfillmentInfo, itemSequence);
                field.value = item ? item.quantity : '';
                return field;
            }

            if(field.innerFieldName == 'shipmentStatus'){

                let value = fulfillmentInfo[field.fieldName]?.[field.innerFieldName];

                if(!value){
                    value = fulfillmentInfo[field.fallbackFieldName]?.[field.fallbackInnerFieldName];
                }

                field.value = value;
                return field
            }


            if(field.innerFieldName){
                field.value = fulfillmentInfo[field.fieldName]?.[field.innerFieldName];
            }else{
                field.value = fulfillmentInfo[field.fieldName];
            }

            return field;

        });
    }

    processDF_Fulfillment(fulfillmentInfo, itemSequence){

        return SHIPMENT_FIELDS_DF.map((tempField)=>{

            let field = {...tempField};

            if(field.fieldName == 'type'){
                field.value = shipmentTypes.getLabelForValue(fulfillmentInfo[field.fieldName]);
                return field;
            }

            if(field.fieldName == 'fulfillmentType'){
                field.value = fulfillmentTypes.getLabelForValue(fulfillmentInfo[field.fieldName]);
                return field;
            }

            if(field.fieldName == 'address'){
                let address = this.getAddress(SHIPPING_ADDRESS);
                field.value = this.getFormattedAddress(address, false);
                return field;
            }

            if(field.fieldName == 'itemQuantity'){
                let item = this.getItemQuantity(fulfillmentInfo, itemSequence);
                field.value = item ? item.quantity : '';
                return field;
            }

            if(field.innerFieldName == 'shipmentStatus'){

                let value = fulfillmentInfo[field.fieldName]?.[field.innerFieldName];

                if(!value){
                    value = fulfillmentInfo[field.fallbackFieldName]?.[field.fallbackInnerFieldName];
                }

                field.value = this.capitalize(value);
                return field
            }

            if(field.hasOwnProperty('urlLabel')){
                field.urlLabel = fulfillmentInfo[field.fieldName]?.[field.innerFieldName];
            }

            if(field.innerFieldName){
                field.value = fulfillmentInfo[field.fieldName]?.[field.innerFieldName];
            }else{
                field.value = fulfillmentInfo[field.fieldName];
            }

            return field;

        });
    }

    processPDO_DOO_Fulfillment(fulfillmentInfo, itemSequence){
        return SHIPMENT_FIELDS_PDO_DOO.map((tempField)=>{

            let field = {...tempField};

            if(field.fieldName == 'type'){
                field.value = shipmentTypes.getLabelForValue(fulfillmentInfo[field.fieldName]);
                return field;
            }

            if(field.fieldName == 'fulfillmentType'){
                field.value = fulfillmentTypes.getLabelForValue(fulfillmentInfo[field.fieldName]);
                return field;
            }

            if(field.fieldName == 'address'){
                let address = this.getAddress(SHIPPING_ADDRESS);
                field.value = this.getFormattedAddress(address, false);
                return field;
            }

            //TODO: structure for shipments
            if(field.fieldName == 'itemQuantity'){
                let item = this.getItemQuantity(fulfillmentInfo, itemSequence);
                field.value = item ? item.quantity : '';
                return field;
            }

            if(field.innerFieldName == 'shipmentStatus'){

                let value = fulfillmentInfo[field.fieldName]?.[field.innerFieldName];

                if(!value){
                    value = fulfillmentInfo[field.fallbackFieldName]?.[field.fallbackInnerFieldName];
                }

                field.value = this.capitalize(value);
                return field
            }

            if(field.innerFieldName){
                field.value = fulfillmentInfo[field.fieldName]?.[field.innerFieldName];
            }else{
                field.value = fulfillmentInfo[field.fieldName];
            }

            return field;

        });
    }

    getAddress(addressClassification){
        return this.addresses.find((address)=> address.addressClassification === addressClassification);
    }

    getFormattedAddress(address, isStore){

        if(address==null || address == undefined) return '';

        let str='';
        if(isStore){
            str = `${address.address1} \n ${address.address2} \n ${address.city}, ${address.state} ${address.zipcode || address.zip}`;
        }else{
            //TODO: example does not have zipcode extension neither zipcode. it only has zip
            str = `${address.address1} \n ${address.city}, ${address.state} ${address.country} ${address.zipcode || address.zip}-${address.zipExtension}`;
        }

        return str;
    }

    getItemQuantity(shipmentInfo, itemSequence){
        return shipmentInfo.pickupVisits?.items?.find((item)=>item.itemSequence == itemSequence);
    }

    capitalize(s){
        return s.charAt(0).toUpperCase() + s.slice(1).toLowerCase();
    }

    handleExpand(event){
        event.stopPropagation();

        this.dispatchEvent(new CustomEvent('expand',{detail:event.detail, bubbles: true}))
    }

    @api get expandedSections(){
        const expandableSections = [...this.template.querySelectorAll("c-bwc-expandable-section[data-name='outterExpandSection']")];
        const sectionsCounter = {
            expanded: 0,
            closed:0
        };
        expandableSections.forEach((section)=>{
            const key = section.isExpanded ? 'expanded' : 'closed';
            sectionsCounter[key]++;
        });

        return sectionsCounter;
    }

}