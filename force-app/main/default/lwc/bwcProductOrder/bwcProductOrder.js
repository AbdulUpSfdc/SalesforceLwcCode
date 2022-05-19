import { LightningElement, track, api } from 'lwc';

// Other components
import * as BwcUtils from 'c/bwcUtils';

const FIELDS = [
    {
        label: 'Plan Type',
        fieldPath: 'type',
        value: '',
        isTextType:true,
    },
    {
        label: 'Price Type',
        fieldPath: 'price.priceType',
        value: '',
        isTextType: true,
    },
    {
        label: 'Product Type',
        fieldPath: 'serviceProductType',
        value: '',
        isTextType:true,
    },
    {
        label: 'Unit/Sale Price',
        fieldPath: 'price.unitPrice',
        wirelessFieldPath: 'price.salePrice',
        value: '',
        isCurrencyType:true,
    },
]

const FALLOUT_FIELDS = [
    {
        label: 'Status',
        fieldPath: 'clientStatus',
        value: '',
        isTextType:true,
    },
    {
        label: 'Sub-Status',
        fieldPath: 'clientSubStatus',
        value: '',
        isTextType:true,
    },
    {
        label: 'Status Detail',
        fieldPath: 'friendlyCode',
        value: '',
        isTextType:true,
    },
]

const PROMOTION_ADJUSTMENT_TYPE = 'promotion';

const planTypes = {
    subscriptionPlan: {value: 'subscriptionPlan', label: 'Subscripition Plan'},
    feePlan: {value: 'fee', label: 'Fee'},

    getLabelForValue: value => {
        const planType = Object.values(planTypes).find(item => item.value === value);
        return planType ? planType.label : value;
    }
}

const serviceProductTypes = {
    protectionPlan: {value: 'protection-plan', label: 'Protection Plan'},
    fee: {value: 'fee', label: 'Fee'},
    addOn: {value: 'add-on', label: 'Add On'},

    getLabelForValue: value => {
        const serviceProductType = Object.values(serviceProductTypes).find(item => item.value === value);
        return serviceProductType ? serviceProductType.label : value;
    }
}

//TODO: move this to bwcUtils and use it from there
const priceTypes = {
    recurring: {value: 'recurring', label: 'Recurring'},
    oneTime: {value: 'one-time', label: 'One Time'},

    getLabelForValue: value => {
        const priceType = Object.values(priceTypes).find(item => item.value === value);
        return priceType ? priceType.label : value;
    }
}

const lineTypes = {
    NEWACT: {value: 'NEWACT', label: 'New Service Activation'},
    UP: {value: 'UP', label: 'Upgrade'},
    AAL: {value: 'AAL', label: 'Add a Line'},
    AL: {value: 'AL', label: 'Add a Line'},

    getLabelForValue: value => {
        const lineType = Object.values(lineTypes).find(item => item.value === value);
        return lineType ? lineType.label : value;
    }
}

const WIRELESS_PRODUCT = 'wireless';
const UVERSE_PRODUCT = 'uverse';

export default class BwcProductOrder extends LightningElement {

    _promotions=[];
    _lineType = '';
    isRendered=false;

    @track isExpanded=true;
    @track planFields = [];
    @track falloutFields=[];
    @track _services = []

    @api addresses=[];
    @api fulfillments=[];
    @api productSequenceNumber;
    _items;
    @api get items(){
        return this._items;
    }
    set items(values){
        if(!values){
            return;
        }
        const tempItems = JSON.parse(JSON.stringify(values));
        const itemSequenceSet = new Set(this.line.itemSequences);
        this._items = tempItems.filter(item=>itemSequenceSet.has(item.itemSequence));      
    }

    @api ctn;
    @api lineType;
    @api line;
    @api isFallout;
    @api productName;
    @api lineOfBusiness;

    get isUverse(){
        return this.lineOfBusiness?.toLowerCase() === UVERSE_PRODUCT;
    }
    @api get isWireless(){
        return this.lineOfBusiness?.toLowerCase() ===  WIRELESS_PRODUCT;
    }

    @api get lineStatus(){
        return this.falloutFields;
    }

    set lineStatus(values){

        if(!values){
            return;
        }

        if(!this.isFallout){
            return;
        }

        this.falloutFields = FALLOUT_FIELDS.map(tempField=>{
            const field = {...tempField};
            field.value = BwcUtils.getValueFromField(values,field.fieldPath);

            // Append friendly Description
            if(field.fieldPath === 'friendlyCode'){
                field.value += ' '+BwcUtils.getValueFromField(values,'friendlyDescription');
            }

            return field;
        })
    }

    set promotions(values){

        if(values===null || values=== undefined) return;
        this._promotions = JSON.parse(JSON.stringify(values));
    }

    @api get promotions(){
        return this._promotions;
    }

    set services(values){

        if(values===null || values === undefined || !Array.isArray(values)) return;

        //Stringify and Parse to remove the readonly restriction
        let localValues = JSON.parse(JSON.stringify(values));
        let tempServices = [];

        for(let service of localValues){

            let tempService={}

            tempService.fields = FIELDS.map((tempField)=>{
                let field = { ...tempField };
                if(field.hasOwnProperty('wirelessFieldPath') && this.isWireless){
                    field.value = BwcUtils.getValueFromField(service,field.wirelessFieldPath);
                } else{
                    field.value = BwcUtils.getValueFromField(service,field.fieldPath);
                }
                return field;

            });
            let servicePrice = this.isWireless ? service.price?.salePrice : service.price?.unitPrice;
            servicePrice = Number(servicePrice);
            tempService.serviceType = this.capitalize(service.serviceType);
            tempService.salePrice = service.price?.salePrice;
            tempService.servicePrice = servicePrice || false;
            tempService.title= service.name;
            tempService.promotions = this.getPromotions(service);
            tempService.serviceSequence = service.serviceSequence;
            tempService.promotionTitle = `${tempService.title} (Promotion)`;
            

            tempServices.push(tempService);

        }

        this._services = tempServices;
    }

    @api get services(){
        return this._services;
    }

    renderedCallback(){
        if(!this.isRendered){
            this.isRendered = true;
            this.handleExpandAll();
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

        const expandableComponents = [...this.template.querySelectorAll('c-bwc-order-detail-items, c-bwc-order-line-details')];
        expandableComponents.forEach(component=>{
            const sections = component.expandedSections;

            if(!sections){
                return;
            }

            sectionsCounter.closed += sections.closed;
            sectionsCounter.expanded += sections.expanded;
        });

        this.isExpanded = sectionsCounter.expanded>=1;
    }

    handleExpandAll(){

        this.isExpanded = !this.isExpanded;
        let expandableSections = this.template.querySelectorAll('c-bwc-expandable-section');

        expandableSections.forEach(section=>{
            section.expandCollapseSection(this.isExpanded);
        });

        const expandableComponents = [...this.template.querySelectorAll('c-bwc-order-detail-items, c-bwc-order-line-details')];
        expandableComponents.forEach(section=>{
            section.expandCollapseSections(this.isExpanded);
        });
    }

    /**
     * Method used to extract the promotions that belong to the current service
    */
    getPromotions(service){
        let {price} = service;

        if(!price.hasOwnProperty('adjustments')) return [];

        // Array that stores the promotionSequence of the price adjusment. there can be more than one
        //this value is used to extract the right promotion from the promotions array
        let servicePromotions = price.adjustments.filter((adjustment)=> adjustment.adjustmentType === PROMOTION_ADJUSTMENT_TYPE);

        let promotionSequences = servicePromotions.map(promotion => promotion.promotionSequence);

        let promotions = this.promotions.filter((promotion)=> promotionSequences.includes(promotion.promotionSequence) );

        return promotions;
    }

    capitalize(s){
        return s.charAt(0).toUpperCase() + s.slice(1);
    }

    get expandButtonText(){
        return this.isExpanded ? 'Collapse' : 'Expand';
    }

    get showServices(){
        return this.services && Array.isArray(this.services) && this.services.length>0;
    }

}