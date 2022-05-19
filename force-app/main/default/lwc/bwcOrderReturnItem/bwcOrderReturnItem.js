import { LightningElement, track, api } from 'lwc';

const RETURN_ITEM_FIELDS = [
    {
        label: 'Device Type',
        fieldPath: 'itemTypeDescription',
        value: '',
        isTextType:true,
    },
    {
        label: 'Return ID',
        fieldPath: 'tradeInDetails.itemId',
        value: '',
        isTextType: true,
    },
    {
        label: 'Return Type',
        fieldPath: 'tradeInType',
        value: '',
        isTextType:true,
    },
    {
        label: 'Status',
        fieldPath: 'itemStatus.friendlyCode',
        value: '',
        isTextType:true,
    },
    {
        label: 'Status Detail',
        fieldPath: 'itemStatus.friendlyDescription',
        value: '',
        isTextType:true,
    },
    {
        label: 'Trade-in Date',
        fieldPath: 'tradeInDetails.tradeDate',
        value: '',
        isTextType:true,
    },
    {
        label: 'Invoice #',
        fieldPath: 'tradeInDetails.invoiceNumber',
        value: '',
        isTextType:true,
    },
    {
        label: 'Trade-In Value (Quoted)',
        fieldPath: 'tradeInDetails.tradeValue',
        value: '',
        isTextType:true,
    },
    {
        label: 'Trade-In Value (Actual)',
        fieldPath: 'tradeInDetails.postInspectionValue',
        value: '',
        isTextType:true,
    },
    {
        label: 'Manufacturer',
        fieldPath: 'tradeInDetails.expectedDetails.manufacturer',
        value: '',
        isTextType:true,
    },
    {
        label: 'Carrier',
        fieldPath: 'tradeInDetails.expectedDetails.carrier',
        value: '',
        isTextType:true,
    },
    {
        label: 'Model #',
        fieldPath: 'tradeInDetails.expectedDetails.modelNumber',
        value: '',
        isTextType:true,
    },
    {
        label: 'Promotion Code',
        fieldPath: 'tradeInDetails.expectedDetails.promotionCode',
        value: '',
        isTextType:true,
    },
    {
        label: 'Model Name',
        fieldPath: 'tradeInDetails.expectedDetails.modelName',
        value: '',
        isTextType:true,
    },
    {
        label: 'Promotion Value',
        fieldPath: 'tradeInDetails.expectedDetails.promotionValue',
        value: '',
        isCurrencyType:true,
    },
    {
        label: 'Device Capacity',
        fieldPath: 'tradeInDetails.expectedDetails.capacity',
        value: '',
        isTextType:true,
    },
]

const RETURN_DETAILS_FIELDS = [
    // from fulfillment
    {
        label: 'Type',
        fieldPath: 'fulfillmentType',
        value: '',
        isTextType:true,
    },
    {
        label: 'Status Code',
        fieldPath: 'fulfillmentStatus.code',
        value: '',
        isTextType: true,
    },
    // From shipment
    {
        label: 'Carrier Name',
        fieldPath: 'carrierName',
        value: '',
        isTextType:true,
    },
    {
        label: 'Status',
        fieldPath: 'fulfillmentStatus.friendlyCode',
        value: '',
        isTextType:true,
    },
    // From shipment
    {
        label: 'Shipped Date',
        fieldPath: 'shippedDate',
        value: '',
        isTextType:true,
    },
    {
        label: 'Status Detail',
        fieldPath: 'fulfillmentStatus.friendlyDescription',
        value: '',
        isTextType:true,
    },
    // from shipments
    {
        label: 'Tracking #',
        fieldPath: 'trackingURL',
        value: '', // trackingURL
        urlLabel:'', // trackingURL
        isURLType:true, //this is URL
    },
]

export default class BwcOrderReturnItem extends LightningElement {

    isRendered=false
    isExpanded=true
    productSequenceNumber;
    itemSequence;
    _returnItem={};
    currentStage;

    @track fields = RETURN_ITEM_FIELDS;
    @track returnFields = RETURN_DETAILS_FIELDS;
    @track fulfillment;

    @api set returnItem(item){

        this.productSequenceNumber = item.productSequenceNumber;
        this.itemSequence = item.itemSequence;
        this._returnItem.data = item;

        let tempFields = RETURN_ITEM_FIELDS.map(tempField=>{
            let field = {...tempField};
            field.value = this.getValueFromField(item, tempField.fieldPath);

            // Set trackingId as the label for the trackingURL
            if(field.hasOwnProperty('urlLabel')){
                field.urlLabel = this.getValueFromField(item, 'trackingId');
            }

            return field;
        });

        this.fields = tempFields;

        this._returnItem.fields = tempFields;
        this.currentStage = this.milestone;
    }

    get returnItem(){
        return this._returnItem;
    }

    @api set fulfillments(values){
        this.fulfillment = this.getFulfillment(values);

        if(!this.fulfillment){
            return;
        }

        let tempReturnFields = RETURN_DETAILS_FIELDS.map(tempField=>{
            let field = {...tempField};
            field.value = this.getValueFromField(this.fulfillment, tempField.fieldPath);

            // Set trackingId as the label for the trackingURL
            if(field.hasOwnProperty('urlLabel')){
                field.urlLabel = this.getValueFromField(this.fulfillment, 'trackingId');
            }

            return field;
        });

        this.returnFields = tempReturnFields;
    }

    get fulfillments(){
        return this.fulfillment;
    }

    renderedCallback(){
        if(!this.isRendered){
            this.handleExpandAll();
            this.isRendered = true;
        }
    }

    handleExpand(event){
        event.stopPropagation();
        const expandableSections = [...this.template.querySelectorAll('c-bwc-expandable-section')];
        const sectionsCounter = {
            expanded: 0,
            closed:0
        };
        expandableSections.forEach((section)=>{
            const key = section.isExpanded ? 'expanded' : 'closed';
            sectionsCounter[key]++;
        });

        const detailItems = this.template.querySelector('c-bwc-order-detail-items')?.expandedSections;
        if(detailItems){
            const detailItemsParsed = JSON.parse(detailItems);
            sectionsCounter.closed += detailItemsParsed.closed;
            sectionsCounter.expanded += detailItemsParsed.expanded;
        }

        this.isExpanded = sectionsCounter.expanded>=1;
    }

    /**
     * Method that expands/collapse all the c-bwc-expandable-section included in this component
     */
    handleExpandAll(){

        this.isExpanded = !this.isExpanded;
        let expandableSections = this.template.querySelectorAll('c-bwc-expandable-section');

        expandableSections.forEach(section=>{
            section.expandCollapseSection(this.isExpanded);
        });
    }

    /**
     * Method that extract nested values from an object. Returns null if no property was found
     * @param  {} object Object that contains the property we want the extract values from
     * @param  {} path the name of the property we want to extract value from. If it is a nested
     * property, use dot notation
     * @example
     * //extract top level property from an object. Returns the value of name
     * getValueFromField(myObject,'name');
     *
     * //extract nested property from an object. Returns the value of modelNumber
     * getValueFromField(myObject,'tradeInDetails.expectedDetails.modelNumber');
     */
    getValueFromField(object, path){
        let localObject = {...object}
        let fields = path.split('.');
        let property
        for(let i=0; i<fields.length; i++){

            property = localObject[fields[i]];
            localObject = property;

            if(!localObject){
                return;
            }

        }

        return localObject;
    }

    /**
     * Method that extracts the fulfillment and shipment the return item is rel ed to
     * @param  {array} fulfillments - Array of fulfillments. Each fulfillment includes an array of shipments
     * @return {Object} fulfillment object including shipment information.
     */
    getFulfillment(fulfillments){

        fulfillments = JSON.parse(JSON.stringify(fulfillments));

        const fulfillment = fulfillments.find(fulfillment=>{

            return fulfillment.shipments?.find(shipment=>{

                return shipment.items?.find(item=>item.itemSequence===this.itemSequence)

            });

        });

        if(!fulfillment){
            return;
        }

        const shipmentfound = fulfillment?.shipments?.find(shipment=>{
            return shipment.items.find(item=>item.itemSequence===this.itemSequence);
        });

        // Add additional fields to fulfillment
        fulfillment.carrierName = shipmentfound?.carrierName;
        fulfillment.shippedDate = shipmentfound?.shippedDate;
        fulfillment.trackingId = shipmentfound?.trackingId;
        fulfillment.trackingURL = shipmentfound?.trackingURL;

        return fulfillment;
    }

    get expandButtonText(){
        return this.isExpanded ? 'Collapse' : 'Expand';
    }

    get milestone(){
        return this._returnItem.data.itemStatus?.milestone;
    }
}