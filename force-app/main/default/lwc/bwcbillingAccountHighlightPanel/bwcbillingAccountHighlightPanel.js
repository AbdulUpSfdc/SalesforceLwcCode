import { LightningElement, wire, api,track } from 'lwc';
import BILLINGACCOUNT_OBJECT from '@salesforce/schema/Billing_Account__c';
import {CurrentPageReference} from "lightning/navigation";
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import { bwcPubSubRegisterListener, bwcPubSubUnregisterAllListeners} from 'c/bwcPubSub';

import * as BwcConstants from 'c/bwcConstants';
import * as bwcDispatchEscalationCase from 'c/bwcDispatchEscalationCase';

import BAN_FIELD from '@salesforce/schema/Billing_Account__c.Billing_Account_Number__c';
import ACCOUNT_TYPE_FIELD from '@salesforce/schema/Billing_Account__c.Account_Type__c';

import hasPermission from '@salesforce/customPermission/Order_Fallout'

const BILLING_ACCOUNT_F = [BAN_FIELD, ACCOUNT_TYPE_FIELD];

import {
    subscribe,
    unsubscribe,
    MessageContext
} from 'lightning/messageService';
import COMPLETIONMC from '@salesforce/messageChannel/BWC_Completion__c';


const BILLING_ACCOUNT_FIELDS = [
    'Billing_Account_Number__c',
    'First_Name__c',
    'Last_Name__c',
    'Formatted_Contact_Number__c',
    'Email_No_URL__c'
];

export default class bwcBillingAccountHighlightPanel extends LightningElement {

    noAccess =  !hasPermission

    billingAccountObject = BILLINGACCOUNT_OBJECT;
    banFields = BILLING_ACCOUNT_FIELDS;
    orderNumber;
    isLoading = false;
    clientStatus='';
    clientSubStatus='';

    //fields for escalation
    completionSubscription;
    interactionId;

    @api recordId;
    @track recordFound = true;
    @track isOpen = true;
    
    @wire(CurrentPageReference)
    pageRef;

    connectedCallback(){

        this.recordId = this.pageRef.state.c__ban;
        this.orderNumber = this.pageRef.state.c__orderId;

        this.getStatusSubStatus();
    }
    getStatusSubStatus(){
        //subscribing to the event
          bwcPubSubRegisterListener('pubsubproductdetails', this.handleProductDetails, this);
     }
     handleProductDetails(products){
         
        for(let i=0; i<products.length; i++){
           if( products[i].lines[i].lineStatus.clientStatus == 'In Queue' ){
            this.clientStatus = products[i].lines[i].lineStatus.clientStatus; 
            this.clientSubStatus = products[i].lines[i].lineStatus.clientSubStatus; 
            break;
           }   
        }

        console.log('clientStatus:'+this.clientStatus);
        console.log('clientSubStatus:'+this.clientSubStatus);

        }

    get orderTitle(){
        return `ORD - ${this.orderNumber}`
    }

    //Escalation case changes 

    @wire(getRecord, {recordId: '$recordId', fields: BILLING_ACCOUNT_F})
    billingAccount;

    @wire(MessageContext)
    messageContext;

    onEscalate(event){
        //const actionName = event.detail.action.name;
        //const row = event.detail.row;
        //this.isLoading = true;
        this.isLoading = true;

        this.completionSubscription = subscribe(
            this.messageContext,
            COMPLETIONMC, (message) => {
                this.escalationComplete(message);
            }
        );

       // let ecType = BwcConstants.HighLevelCaseType.Account_Services_Promotions.type;
       // let ecFeature = BwcConstants.HighLevelCaseType.Account_Services_Promotions.feature;
    //    let ecType = "Order Action"
    //    let ecFeature = "Online fallout Wireless"

        let hlCaseType = BwcConstants.HighLevelCaseType.Order_Fallout.type;
        let hlCaseFeature = BwcConstants.HighLevelCaseType.Order_Fallout.feature;
        //console.log("Case Type is :" +event.detail.value)
        
        if(hlCaseType!=undefined && hlCaseFeature!=undefined){

            let ecType = hlCaseType;
            let ecFeature = hlCaseFeature;

            bwcDispatchEscalationCase.publishEscalationCaseMessage(
                this.interactionId,
                ecType,
                ecFeature,
                JSON.stringify(
                    {
                        ban: this.billingAccount.data.fields.Billing_Account_Number__c.value,
                        orderNumber : this.orderNumber,
                        status: this.clientStatus,
                        subStatus: this.clientSubStatus
                       
                        // caseAction: CASE_ACTION_PROMOTIONS,
                    }
                )
            );
       // this.template.querySelector('div').click();
    }
}

    escalationComplete(){
        console.log("Inside Escalation Complete")
        unsubscribe(this.completionSubscription);
        this.completionSubscription=null;
        this.isLoading = false;
    }
    renderedCallback() { 
        this.getInteractionId();
        console.log("In Render CallBack")
    }

    getInteractionId(){
        console.log("getIntercation id method")
        if(this.pageRef.state.ws){
           let interactionIdData = this.pageRef.state.ws.split('/');
            for(let i = 0; i < interactionIdData.length; i++){
                if(interactionIdData[i] === 'Interaction__c'){
                    this.interactionId = interactionIdData[i+1];
                }
            }
        }
    }
    disconnectedCallback() {
        // unsubscribe from pubsubproductdetails event
        bwcPubSubUnregisterAllListeners(this);
    }
    
}