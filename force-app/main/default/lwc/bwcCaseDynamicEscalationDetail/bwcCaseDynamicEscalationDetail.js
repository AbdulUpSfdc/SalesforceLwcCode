import { LightningElement, api, wire, track } from 'lwc';
import {
    subscribe,
    unsubscribe,
    APPLICATION_SCOPE,
    MessageContext,
} from 'lightning/messageService';
import { getFieldValue, getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import REFRESHMC from '@salesforce/messageChannel/BWC_Refresh__c';

//Other components
import * as BwcUtils from 'c/bwcUtils';

//Apex methods
import getCaseActionFieldSet from '@salesforce/apex/BWC_CaseEscalationDetailController.getCaseActionFieldSet';
import getUserAccessToCase from '@salesforce/apex/BWC_CaseEscalationDetailController.getUserAccessToCase';

//Case Fields for getRecord method
import CASE_TYPE_FIELD from '@salesforce/schema/Case.Type';
import CASE_ACTION_FIELD from '@salesforce/schema/Case.CaseAction__c';


const CASE_FIELDS = [
    CASE_TYPE_FIELD,
    CASE_ACTION_FIELD,
];

//SPTSFDCSPT-8366
const CASE_TYPE_ORDER_ACTION_ONLINE_FALLOUT_WIRELESS = 'Order Action | Online fallout Wireless'; 		//SPTSFDCSPT-8366

const CASE_ACTION_WIRELESS_ORDER_FALLOUT_DF = 'Wireless order fallout | DF';						
const CASE_ACTION_WIRELESS_ORDER_FALLOUT_IN_STORE = 'Wireless order fallout | In Store';
const CASE_ACTION_WIRELESS_ORDER_FALLOUT_READY_TO_GO = 'Wireless order fallout | Ready to Go';


//Stores the apiName of the fields that need to take the whole width of the screen
const WIDER_FIELDS = new Set([
    'Description',
    'Missing_Information__c'
]);

const HALF_COLUMN='slds-p-horizontal--small slds-size--1-of-1 slds-medium-size--6-of-12 slds-large-size--6-of-12';
const WHOLE_COLUMN='slds-p-horizontal--small slds-size--1-of-1 slds-medium-size--12-of-12 slds-large-size--12-of-12';

const READ_ONLY_CASE_ACTION_FIELDS = ['Amount_in_Dispute__c', 'Amount_Charged__c'];
const BILLING_ADJUSTMENT = 'Billing | Adjustment';
export default class BwcCaseDynamicEscalationDetail extends LightningElement {

    @api recordId;
    subscription;

    @wire(MessageContext)
    messageContext;

    @wire(getRecord, {recordId:'$recordId', fields: CASE_FIELDS})
    wiredCase({error, data}){

        if(data){
            this.currentCase = data;
            this.callGetCaseActionFieldSet();
        }
    }

    @wire(getUserAccessToCase, {recordId:'$recordId'})
    userHasEditAccess

    @track caseActionfieldSet = [];
    @track ctnFieldset = [];
    @track isEditFormLoading = true;
    @track isViewFormLoading = true;
    @track isReadOnly = true;

    objectApiName = 'Case';
    recordFormMode = 'view';
    numberColumns = 2;
    currentCase;

    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                REFRESHMC,
                (message) => this.handleMessage(message),
                { scope: APPLICATION_SCOPE }
            );
        }
    }

    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    handleMessage(message) {
        if (message.scope === 'refreshCaseDynamicEscalationDetail') {
            refreshApex(this.userHasEditAccess);
        }
    }

    connectedCallback() {
        this.subscribeToMessageChannel();
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    async callGetCaseActionFieldSet(){
        try{
            let caseAction = getFieldValue(this.currentCase, CASE_ACTION_FIELD);
            let caseId = this.recordId;

            let result = await getCaseActionFieldSet({caseId, caseAction});

            this.processCaseActionFieldSetResult(result);
        }catch(error){
            BwcUtils.error('callGetCaseActionFieldSet: ', error);
        }finally{

        }
    }

    processCaseActionFieldSetResult(result){
        const parsedResult = JSON.parse(result);

        BwcUtils.log('%cprocessCaseActionFieldSetResult','color:cyan');
        BwcUtils.log({parsedResult});

        this.caseActionfieldSet = this.AddCssClass(parsedResult.caseActionfieldSet);
        //SPTSFDCSPT-8366_START
        this.caseActionfieldSet.forEach(element => {
            if (element.apiName == 'Order_ID__c') {element.showHyperlink = true} else {element.showHyperlink = false}
            // CDEX-87294 START
            if (READ_ONLY_CASE_ACTION_FIELDS.includes(element.apiName) && getFieldValue(this.currentCase, CASE_TYPE_FIELD) === BILLING_ADJUSTMENT) {
                element.readOnly = true;
            } else {
                element.readOnly = false; 
            }
            // CDEX-87294 END
        });
        //SPTSFDCSPT-8366_END
        this.ctnFieldset = this.AddCssClass(parsedResult.ctnFieldset);
        this.ctnDynamicFields = parsedResult.ctnDynamicFields;
    }

    showEditForm(){
        this.isReadOnly = false;
        this.isEditFormLoading = true;
    }

    hideEditForm(){
        this.isReadOnly = true;
        this.isViewFormLoading = true;
    }

    handleSubmit(event){
        const inputFields = event.detail.fields;
        //TODO: logic post submit

        this.isEditFormLoading = true;
        this.template.querySelector('lightning-record-edit-form').submit(inputFields);
    }

    handleSuccess(event){

        this.isEditFormLoading = false;
        const toastArgs = {
            title: 'Success!',
            message: 'Case successfully updated!',
            variant: 'success',
        }

        BwcUtils.showToast(this, toastArgs);

        this.hideEditForm();
    }

    handleError(event){

        this.isEditFormLoading = false;

        let errDetails='';
        if(event.detail!=undefined && event.detail.detail!=undefined  ){
            errDetails+=event.detail.detail;
        }else if(event.message!=undefined){
            errDetails+=event.message;
        }

        const toastArgs = {
            title: 'Error',
            message: errDetails,
            variant: 'error',
        }

        BwcUtils.showToast(this, toastArgs);
    }

    handleEditLoad(event){
        this.isEditFormLoading = false;
    }

    handleViewLoad(event){
        this.isViewFormLoading = false;
    }

    AddCssClass(caseFields){

        caseFields.forEach((field)=>{

            if(WIDER_FIELDS.has(field.apiName)){
                field.cssClass = WHOLE_COLUMN;
            }else{
                field.cssClass = HALF_COLUMN;
            }
        });

        return caseFields
    }

    get title(){
        const caseType = getFieldValue(this.currentCase, CASE_TYPE_FIELD);
        const caseAction = getFieldValue(this.currentCase, CASE_ACTION_FIELD);
        return `${caseType} > ${caseAction}`;
    }

    get readOnlyFields(){

        BwcUtils.log([...this.caseActionfieldSet, ...this.ctnFieldset]);
        return [...this.caseActionfieldSet, ...this.ctnFieldset];
    }
    
    //SPTSFDCSPT-8366
	get isOrderHyperlinkVisible() {
        const caseType = getFieldValue(this.currentCase, CASE_TYPE_FIELD);
        const caseAction = getFieldValue(this.currentCase, CASE_ACTION_FIELD);
		return (
			caseType === CASE_TYPE_ORDER_ACTION_ONLINE_FALLOUT_WIRELESS 
			&& 
			( 
				caseAction === CASE_ACTION_WIRELESS_ORDER_FALLOUT_DF||
				caseAction === CASE_ACTION_WIRELESS_ORDER_FALLOUT_IN_STORE ||
				caseAction	=== CASE_ACTION_WIRELESS_ORDER_FALLOUT_READY_TO_GO
			)
		)
	}
}