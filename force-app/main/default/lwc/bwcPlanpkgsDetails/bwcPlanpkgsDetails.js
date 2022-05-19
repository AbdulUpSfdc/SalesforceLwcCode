import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import {CurrentPageReference} from "lightning/navigation";

//Custom Permission
import HAS_URGENT_PERMISSION from '@salesforce/customPermission/Urgent_Billing_Inquiries';

//Other components
import * as BwcConstants from 'c/bwcConstants';
import * as bwcDispatchEscalationCase from 'c/bwcDispatchEscalationCase';

//Apex
import getPlanPkgsDetail from '@salesforce/apex/BWC_PlanPkgsDetailController.getPlanPkgsDetail';

//Lightning Message Service
import {
    subscribe,
    unsubscribe,
    MessageContext
} from 'lightning/messageService';
import COMPLETIONMC from '@salesforce/messageChannel/BWC_Completion__c';

//Billing account fields
import BAN_FIELD from '@salesforce/schema/Billing_Account__c.Billing_Account_Number__c';
import ACCOUNT_TYPE_FIELD from '@salesforce/schema/Billing_Account__c.Account_Type__c';

const BILLING_ACCOUNT_FIELDS = [BAN_FIELD, ACCOUNT_TYPE_FIELD];
const ESCALATION_BUTTONS_MAP = {
    escalateService: 'Services_Inquiry',
}
const CASE_ACTION_PLAN = 'Urgent Service Plan Issues'
const WIRELESS_TYPE = 'Wireless';

export default class BwcPlanpkgsDetails extends LightningElement {
    @api recordId
    recordDetails
    showLoading
    error;
    showNoRows
    interactionId;
    completionSubscription

    @wire(CurrentPageReference)
    pageRef;

    @wire(getRecord, {recordId: '$recordId', fields: BILLING_ACCOUNT_FIELDS})
    billingAccount;

    @wire(MessageContext)
    messageContext;

    connectedCallback(){
        this.showLoading = true;
        getPlanPkgsDetail({recordId:this.recordId})
            .then(resultJson => {

                const result = JSON.parse(resultJson);

                if (result.success) {
                    this.recordDetails = result.recordDetails.map(record=>{
                        record.isLoading = false;
                        return record;
                    });
                    this.data = this.recordDetails;
                    this.showLoading = false;
                    this.showNoRows = false;
                }
                else {
                    this.error = result.message;
                    this.showLoading = false;
                    this.showNoRows = true;
                }

            })
            .catch(error => {
                this.error = error.message;
                //this.data = mydata;
                this.showLoading = false;
                his.showNoRows = true;
            });
        this.getInteractionId();
    }

    handleActionMenuSelect(event) {
        const recordId = event.target.dataset.item;
        const recordDetail = this.recordDetails.find(rd => rd.recordId === recordId);

        switch(event.detail.value) {

            case 'escalateService':

                let hlCaseTypeIndex = ESCALATION_BUTTONS_MAP[event.detail.value];
                let hlCaseType = BwcConstants.HighLevelCaseType[hlCaseTypeIndex];

                if(hlCaseType!=undefined && hlCaseType!=undefined){

                    let ecType = hlCaseType.type;
                    let ecFeature = hlCaseType.feature;

                    this.createEscalationCase(ecType, ecFeature, recordDetail);
                }
                break;
            default:
                break;
        }

    }

    createEscalationCase(ecType, ecFeature, recordDetail){

        let recordId = recordDetail.recordId;

        this.showSpecificSpinner(recordId);

        this.completionSubscription = subscribe(
            this.messageContext,
            COMPLETIONMC, (message) => {
                this.escalationComplete(message);
            }
        );

        bwcDispatchEscalationCase.publishEscalationCaseMessage(
            this.interactionId,
            ecType,
            ecFeature,
            JSON.stringify(
                {
                    ban: this.billingAccount.data.fields.Billing_Account_Number__c.value,
                    // caseAction: CASE_ACTION_PLAN,
                }
            )
        );
        this.template.querySelector('div').click();
    }

    showSpecificSpinner(recordId){
        this.recordDetails = this.recordDetails.map((record) =>{
                if(record.recordId === recordId){
                    record.isLoading = true;
                }
                return record;
        });
    }

    hideAllEquipmentSpinners(){
        this.recordDetails = this.recordDetails.map((record) =>{
            record.isLoading = false;
            return record;
        });
    }

    escalationComplete(){
        unsubscribe(this.completionSubscription);
        this.completionSubscription=null;
        this.hideAllEquipmentSpinners();
    }

    getInteractionId(){
        if(this.pageRef.state.ws){
           let interactionIdData = this.pageRef.state.ws.split('/');
            for(let i = 0; i < interactionIdData.length; i++){
                if(interactionIdData[i] === 'Interaction__c'){
                    this.interactionId = interactionIdData[i+1];
                }
            }
        }
    }

    get hasData(){
        if(this.recordDetails && this.recordDetails.length > 0){
            return true;
        } else {
            return false;
        }
    }

    get isWirelessType(){
        return getFieldValue(this.billingAccount.data, ACCOUNT_TYPE_FIELD) === BwcConstants.BillingAccountType.WIRELESS.value;
    }

    get hasUrgentBillingPermission(){
        return HAS_URGENT_PERMISSION;
    }

    get showEscalateButton(){
        return this.isWirelessType;
    }
}