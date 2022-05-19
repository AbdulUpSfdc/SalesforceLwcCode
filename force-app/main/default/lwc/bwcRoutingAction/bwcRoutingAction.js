import { LightningElement, track, api, wire } from 'lwc';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

//Apex
import getRoutingActionValues from '@salesforce/apex/BWC_RoutingActionController.getRoutingActionValues';
import getQueueId from '@salesforce/apex/BWC_RoutingActionController.getQueueId';
import getTierValues from '@salesforce/apex/BWC_RoutingActionController.getTierValues';
import getOutboundQueueName from '@salesforce/apex/BWC_RoutingActionController.getOutboundQueueName';
import getQueueIdByDevName from '@salesforce/apex/BWC_RoutingActionController.getQueueIdByDevName';

//Case fields
import CASE_TYPE_FIELD from '@salesforce/schema/Case.Type';
import CASE_STATUS_FIELD from '@salesforce/schema/Case.Status';
import CASE_OWNER_FIELD from '@salesforce/schema/Case.OwnerId';
import CASE_ACTION_FIELD from '@salesforce/schema/Case.CaseAction__c';
import ROUTING_ACTION_FIELD from '@salesforce/schema/Case.RoutingAction__c';
import TIER_2_FIELD from '@salesforce/schema/Case.Tier2__c';
import TIER_3_FIELD from '@salesforce/schema/Case.Tier3__c';
import CASE_COMMENTS_FIELD from '@salesforce/schema/Case.Comments';
import RESOLUTION_FIELD from '@salesforce/schema/Case.Resolution__c';
import RESOLUTION_2_FIELD	from '@salesforce/schema/Case.Resolution2__c';
import IS_RESPONSE_REQUIRED_FIELD from '@salesforce/schema/Case.Is_Response_Required__c';
//Custom label
// import no_routing_action from '@salesforce/label/c.BWC_No_Routing_Action';

//Other components
import * as BwcUtils from 'c/bwcUtils';

const CASE_FIELDS = [
    CASE_TYPE_FIELD,
    CASE_ACTION_FIELD,
    ROUTING_ACTION_FIELD,
    TIER_2_FIELD,
    TIER_3_FIELD,
    CASE_COMMENTS_FIELD,
    RESOLUTION_FIELD,
    RESOLUTION_2_FIELD,
    CASE_OWNER_FIELD,
    CASE_STATUS_FIELD,
    IS_RESPONSE_REQUIRED_FIELD
];

// Routing action values
const TIER_1_OPTION = 'Tier 1';
const DONE_OPTION = 'Done';
const TIER_2_PRE = 'Tier 2: Pre-Dispatch';
const TIER_2_POST = 'Tier 2: Post-Dispatch';
const TIER_3_PRE = 'Tier 3: Pre-Dispatch';
const TIER_3_POST = 'Tier 3: Post-Dispatch';
const OUTBOUND = 'Outbound';
const BILLING_ADJUSTMENT = 'Billing | Adjustment';

const CANCELLED_STATUS = 'Cancelled';
const CLOSED_STATUS = 'Closed';
const MERGED_STATUS = 'Merged';
const PENDING_CLOSE_STATUS='Pending Close';

const LNP_PREFIX = 'LNP';
const IT_TLG_PREFIX = 'IT-TLG';
const DIGITAL_PREFIX = 'Digital';
const DIGITAL_QUEUE_PREFIX = 'DIGITAL';


// const LNP_QUEUES = [
//     {label:'IT-TLG-AR PS',value:'IT-TLG-AR PS'},
//     {label:'IT-TLG-MKTSERVICES-NUMBERS',value:'IT-TLG-MKTSERVICES-NUMBERS'},
//     {label:'IT-TLG-NUMBERS MGMT -T1 PS',value:'IT-TLG-NUMBERS MGMT -T1 PS'},
//     {label:'IT-TLG-TABLES PS',value:'IT-TLG-TABLES PS'},
// ];

// const DIGITAL_QUEUES = [
//     {label:'DIGITAL_ENG_SVCS_MYATT',value:'DIGITAL_ENG_SVCS_MYATT'},
//     {label:'DIGITAL_ENG_SVCS_DSS',value:'DIGITAL_ENG_SVCS_DSS'},
//     {label:'DIGITAL_ENG_SVCS_OPSS',value:'DIGITAL_ENG_SVCS_OPSS'},
//     {label:'TECH-TLG-FBF/EMI/NonPaper',value:'TECH-TLG-FBF/EMI/NonPaper'},
//     {label:'TECH-TLG-BILLING-T1',value:'TECH-TLG-BILLING-T1'},
//     {label:'TECH-TLG-CSM-T2',value:'TECH-TLG-CSM-T2'},
// ];

const CLOSED_STATUSES = [
    CANCELLED_STATUS,
    CLOSED_STATUS,
    MERGED_STATUS,
]

export default class BwcRoutingAction extends LightningElement {

    @api recordId

    queueId;
    _caseOwner;
    _initialRouteAction;
    _tier2;
    _tier3;
    _caseAction;
    _outboundQueueName='';
    _outboundQueueId='';

    // label={
    //     no_routing_action
    // }
    @track requiredTier2=false;
    @track requiredTier3=false;
    @track disabledTier2=false;
    @track disabledTier3=false;
    @track tier2;
    @track tier3;
    @track routeAction;
    @track currentCase;
    @track resolutionRequired=false;
    @track routeActionOptions=[];
    @track _routingOptions = {}
    @track isCaseClosed = false;
    @track showTier2=true;
    @track showTier3=true;
    @track tier2Options =[];
    @track tier3Options =[];
    @track isLoading=true;

    callGetRoutingActionValues(){
        getRoutingActionValues({caseAction: this.caseActionValue})
        .then(result=>{
            BwcUtils.log({result})
            this._routingOptions = JSON.parse(result);
            this.routeActionOptions = this._routingOptions?.[this.routeAction] || this._routingOptions['Tier 1'];
        })
        .catch(error=>{
            BwcUtils.error(error);
        });
    }

    async callGetOutboundQueueName(){
        try{
            this._outboundQueueName = await getOutboundQueueName({caseAction: this.caseActionValue});

            if(this._outboundQueueName!==null){
                let queueId = await getQueueIdByDevName({queueName: this._outboundQueueName});
                this._outboundQueueId =queueId;
            }
        }catch(error){
            BwcUtils.error(error);
        }
    }

    @wire(getRecord, {recordId: '$recordId', fields: CASE_FIELDS })
    wiredCase({error, data}){

        if(data){
            this.currentCase = data;
            let caseStatus = getFieldValue(this.currentCase, CASE_STATUS_FIELD);

            if(CLOSED_STATUSES.some((status)=>status===caseStatus)){
                this.isCaseClosed = true;
                this.isLoading=false;
                return;
            }

            this._caseAction = getFieldValue(this.currentCase, CASE_ACTION_FIELD);
            this._tier2 = getFieldValue(this.currentCase, TIER_2_FIELD);
            this._tier3 = getFieldValue(this.currentCase, TIER_3_FIELD);
            this._caseOwner = getFieldValue(this.currentCase, CASE_OWNER_FIELD);
            // this.routeActionOptions = this._routingOptions?.[this.routeAction] || this._routingOptions['Tier 1'];

            if(getFieldValue(this.currentCase, ROUTING_ACTION_FIELD) === OUTBOUND){
                this._initialRouteAction = TIER_1_OPTION;
                this.routeAction = TIER_1_OPTION;
            }
            if(getFieldValue(this.currentCase, CASE_TYPE_FIELD) === BILLING_ADJUSTMENT){
                this._initialRouteAction = DONE_OPTION;
                this.routeAction = DONE_OPTION;
            }else{
                this._initialRouteAction = getFieldValue(this.currentCase, ROUTING_ACTION_FIELD);
                this.routeAction = getFieldValue(this.currentCase, ROUTING_ACTION_FIELD);
            }


            this.callGetRoutingActionValues();
            this.enableTiers(this.routeAction);

            if(this._tier2!=null) this.callGetQueueId(this._tier2);
            if(this._tier3!=null) this.callGetQueueId(this._tier3);
            if(this.routeAction===DONE_OPTION) this.resolutionRequired = true;

            if(this.routeAction.startsWith('Tier 2')){
                this.tier2 = getFieldValue(this.currentCase, TIER_2_FIELD);
            }
            if(this.routeAction.startsWith('Tier 3')){
                this.tier3 = getFieldValue(this.currentCase, TIER_3_FIELD);
            }

            this.tierVisibility();

            this.callGetOutboundQueueName();
        }
    }

    handleRouteAction(event){
        BwcUtils.log(event.detail.value);
        this.routeAction = event.detail.value;
        if(this.routeAction===DONE_OPTION){
            this.resolutionRequired = true;
            this.clearTierValues();
        }else{
            this.resolutionRequired = false;
        }

        if(this.routeAction === TIER_1_OPTION){
            this.clearTierValues();
        }

        if(this.routeAction === TIER_2_POST || this.routeAction === TIER_2_PRE){
            this.tier3 = null;
        }

        if(this.routeAction === TIER_3_POST || this.routeAction === TIER_3_PRE){
            this.tier2 = null;
        }

        this.enableTiers(this.routeAction);
    }

    clearTierValues(){
        this.tier2 = null;
        this.tier3 = null;
    }

    enableTiers(routeAction){

        if(this._initialRouteAction == DONE_OPTION && routeAction === DONE_OPTION) this.updateTierState(false, true, false, true);

        if(this._initialRouteAction == TIER_1_OPTION && (routeAction ==  TIER_1_OPTION || routeAction == DONE_OPTION)  ) this.updateTierState(false, true, false, true);
        if(this._initialRouteAction == TIER_1_OPTION && (routeAction == TIER_2_PRE || routeAction == TIER_2_POST)) this.updateTierState(true,false, false, true);

        if(this._initialRouteAction ==TIER_2_PRE && (routeAction ==  TIER_1_OPTION || routeAction == DONE_OPTION)) this.updateTierState(false, true, false, true);
        if(this._initialRouteAction ==TIER_2_PRE && routeAction == TIER_2_PRE) this.updateTierState(true,false, false, true);
        if(this._initialRouteAction ==TIER_2_PRE && routeAction == TIER_3_PRE ) this.updateTierState(false, true, true,false );

        if(this._initialRouteAction == TIER_2_POST && (routeAction ==  TIER_1_OPTION || routeAction == DONE_OPTION)) this.updateTierState(false, true, false, true);
        if(this._initialRouteAction == TIER_2_POST && routeAction == TIER_2_POST) this.updateTierState(true,false, false, true);
        if(this._initialRouteAction == TIER_2_POST && routeAction == TIER_3_POST ) this.updateTierState(false, true, true,false);

        if(this._initialRouteAction ==TIER_3_PRE && (routeAction ==  TIER_1_OPTION || routeAction == DONE_OPTION)) this.updateTierState(false, true, false, true);
        if(this._initialRouteAction ==TIER_3_PRE && routeAction == TIER_2_PRE) this.updateTierState(true,false, false, true);
        if(this._initialRouteAction ==TIER_3_PRE && routeAction == TIER_3_PRE ) this.updateTierState(false, true, true,false );

        if(this._initialRouteAction ==TIER_3_POST && routeAction == TIER_2_POST) this.updateTierState(true,false, false, true);
        if(this._initialRouteAction ==TIER_3_POST && routeAction == TIER_3_POST ) this.updateTierState(false, true, true,false );
        if(this._initialRouteAction ==TIER_3_POST && routeAction == DONE_OPTION) this.updateTierState(false, true, false, true);

        this.clearTierErrorMessages()

    }

    /**
     * Method used to switch required and disable attribute for Tier 2 and Tier 3 fields
     * @param  t2Required boolean value that will set Tier 2 field as required
     * @param  t2Disabled boolean value that will set Tier 2 field as disabled/enabled
     * @param  t3Required boolean value that will set Tier 2 field as required
     * @param  t3Disabled boolean value that will set Tier 2 field as disabled/enabled
    */
    updateTierState(t2Required, t2Disabled, t3Required, t3Disabled){
        this.requiredTier2 = t2Required;
        this.disabledTier2 = t2Disabled;
        this.requiredTier3 = t3Required;
        this.disabledTier3 = t3Disabled;
    }

    clearTierErrorMessages(){

        let tier2 = this.template.querySelector('[name="Tier2"]');
        let tier3 = this.template.querySelector('[name="Tier2"]');

        if(tier2){
            tier2.reportValidity();
        }

        if(tier3){
            tier3.reportValidity();
        }

    }

    handleTier2(event){
        this.tier2 = event.detail.value;
        this.callGetQueueId(this.tier2);
    }

    handleTier3(event){
        this.tier3 = event.detail.value;
        this.callGetQueueId(this.tier3);
    }

    callGetQueueId(queueName){
        queueName = queueName.substring(0, 40);
        getQueueId({queueName})
        .then((result)=>{
            this.queueId = result
            BwcUtils.log(`queueId: ${result}`);
        })
        .catch((error)=>{
            BwcUtils.error('error retrieving the queueId');
            BwcUtils.error(error);
        });
    }

    async handleSubmit(event){

        //show spinner
        this.isLoading = true;

        event.preventDefault();

        const additionalFields = [...this.template.querySelectorAll('lightning-combobox')]
        let validFields = true;
        additionalFields.forEach(field=>{

            validFields = validFields && field.checkValidity();
            field.reportValidity();
        });

        if(!validFields){
            this.isLoading = false;
            return;
        }
        const formFields = event.detail.fields;
        BwcUtils.log({formFields})
        BwcUtils.log(this.routeAction);
        const fields = {}
        fields['Id'] = this.recordId;
        fields[CASE_STATUS_FIELD.fieldApiName] = 'New';
        for (const field in formFields) {
            BwcUtils.log(field)
            fields[field] = formFields[field];
        }

        //Adding additional values as inputs is not inputfield type
        fields[ROUTING_ACTION_FIELD.fieldApiName] = this.routeAction;
        if(this.showTier2 && this.tier2!=null) fields[TIER_2_FIELD.fieldApiName] = this.tier2;
        if(this.showTier3 && this.tier3!=null) fields[TIER_3_FIELD.fieldApiName] = this.tier3;

        BwcUtils.log('this.routeAction', this.routeAction);
        BwcUtils.log(this.queueId)
        BwcUtils.log(this._caseOwner)

        if(
            this.routeAction !== TIER_1_OPTION
            && this.routeAction !== DONE_OPTION
            && this.queueId
            && this.queueId != this._caseOwner
            ){
            //Assigning new case owner if the case was moved to another tier
            BwcUtils.log('Assigning tier x as owner');
            fields[CASE_OWNER_FIELD.fieldApiName] = this.queueId;
        }

        //If previous value contains pre-dispatch, and selected routing action is Done, change to Tier 1.
        if(this._initialRouteAction.includes('Pre-Dispatch') && this.routeAction === DONE_OPTION ){
            this.routeAction = TIER_1_OPTION;
            fields[ROUTING_ACTION_FIELD.fieldApiName] = this.routeAction;
        }

        //if routing action = tier1, clear tier 2 and tier 3 values. Execute assignment rules
        if(this.routeAction == TIER_1_OPTION){
            BwcUtils.log('Clearing tier 2 and tier 3');
            fields[TIER_2_FIELD.fieldApiName] = null;
            fields[TIER_3_FIELD.fieldApiName] = null;
        }

        if(this.routeAction === DONE_OPTION
            && this.isResponseRequired
            && this._outboundQueueId!==''
            && this.caseStatus !==  PENDING_CLOSE_STATUS){

            this.routeAction = OUTBOUND;

            fields[CASE_STATUS_FIELD.fieldApiName] = PENDING_CLOSE_STATUS;
            fields[ROUTING_ACTION_FIELD.fieldApiName] = this.routeAction;
            fields[CASE_OWNER_FIELD.fieldApiName] = this._outboundQueueId;
        }

        if(this.routeAction === DONE_OPTION && (this.caseStatus ===  PENDING_CLOSE_STATUS || this._outboundQueueId === '')){
            fields[CASE_STATUS_FIELD.fieldApiName]  = CLOSED_STATUS;
        }

        const recordInput = {fields};
        BwcUtils.log({recordInput})
        try{
            await updateRecord(recordInput);

            //Notify Aura wrapper, so quickAction is closed
            this.dispatchEvent(new CustomEvent('caseupdated'));

            const event = new ShowToastEvent({
                "variant": "success",
                "title": "Success",
                "message": "The case was updated!",
            });
            this.dispatchEvent(event);

        }catch(error){
            BwcUtils.error('Error updating case Routing Action component');
            BwcUtils.error(error);
            let errorMessage = '';

            //Errors related to validation rules
            if(error?.body?.output?.fieldErrors){
                for(let field in error.body.output.fieldErrors){
                    BwcUtils.log({field});
                    for(let e of error.body.output.fieldErrors[field]){
                        BwcUtils.log({e});
                        errorMessage+=' \n'+e.message;
                    }
                }
            }

            //Errors related to the record
            if(error?.body?.output?.errors){
                for(let outputError of error.body.output.errors){
                    BwcUtils.log({outputError});
                    //IF user doesn't have access to the record (User not in QUEUE) show a more friendly error message
                    if(outputError.errorCode === 'INSUFFICIENT_ACCESS_OR_READONLY'){
                        errorMessage+=' \n User does not have access to the Case Record';
                    }else{
                        errorMessage+=' \n'+outputError.message;
                    }
                }
            }


            this.showErrorMessage(errorMessage);
            //hide spinner
            this.isLoading = false;
        }
    }

    showErrorMessage(errorMessage){
        const event = new ShowToastEvent({
            "variant": "error",
            "title": "Error on Routing Action!",
            "message": errorMessage,
        });
        this.dispatchEvent(event);
    }

    async tierVisibility(){

        await this.callGetTierValues(TIER_2_FIELD.fieldApiName, this.caseActionValue);
        await this.callGetTierValues(TIER_3_FIELD.fieldApiName, this.caseActionValue);
        this.isLoading = false;
    }

    async callGetTierValues(dependentField, selectedValue){
        try{
            let result = await getTierValues({dependentField, selectedValue});
            let parsedResult = JSON.parse(result);

            if(dependentField === TIER_3_FIELD.fieldApiName){
                if(parsedResult.length>0){

                    // if(!(this._caseAction?.includes(LNP_PREFIX))){
                    //     parsedResult = parsedResult.filter((tier3Val)=>{
                    //         return !(tier3Val.label?.startsWith(IT_TLG_PREFIX));
                    //     });
                    // }

                    // if(!(this._caseAction?.includes(DIGITAL_PREFIX))){
                    //     parsedResult = parsedResult.filter((tier3Val)=>{
                    //         return !(tier3Val.label?.startsWith(DIGITAL_QUEUE_PREFIX));
                    //     });
                    // }

                    this.tier3Options = parsedResult;
                    BwcUtils.log('this.showTier2', this.showTier2);
                    this.showTier3 = this.showTier2;

                    // if(this.tier3Options.length===0){
                    //     this.showTier3=false;
                    // }
                }else{
                    this.showTier3 = false;
                }
            }

            if(dependentField === TIER_2_FIELD.fieldApiName){
                this.tier2Options = parsedResult;
                if(parsedResult.length>0){
                    this.tier2Options = parsedResult;
                }else{
                    this.showTier2 = false;
                }
            }
        }catch(error){
            BwcUtils.error('ERROR getTierValues',error);
        }
    }

    handleCaseAction(event){
        this. _caseAction = event.detail.value;
    }

    setDefaultTier3Queues(queues){
        this.tier3Options = queues;
    }


    get caseStatus(){
        return getFieldValue(this.currentCase, CASE_STATUS_FIELD)
    }

    get isResponseRequired(){
        return getFieldValue(this.currentCase, IS_RESPONSE_REQUIRED_FIELD);
    }

    get caseTypeValue(){
        return getFieldValue(this.currentCase, CASE_TYPE_FIELD);
    }

    get caseActionValue(){
        return getFieldValue(this.currentCase, CASE_ACTION_FIELD);
    }

    get caseRoutingActionValue(){
        return getFieldValue(this.currentCase, ROUTING_ACTION_FIELD);
    }

    get caseTier2Value(){
        return getFieldValue(this.currentCase, TIER_2_FIELD);
    }

    get caseTier3Value(){
        return getFieldValue(this.currentCase, TIER_3_FIELD);
    }

    get caseCommentsValue(){
        return getFieldValue(this.currentCase, CASE_COMMENTS_FIELD);
    }

    get caseResolutionValue(){
        return getFieldValue(this.currentCase, RESOLUTION_FIELD);
    }

    get caseResolution2Value(){
        return getFieldValue(this.currentCase, RESOLUTION_2_FIELD);
    }
}