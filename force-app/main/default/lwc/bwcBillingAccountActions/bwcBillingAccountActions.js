import { LightningElement,track,wire,api } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import BAN from '@salesforce/schema/Billing_Account__c.Billing_Account_Number__c';
import BA_STATUS from '@salesforce/schema/Billing_Account__c.Account_Status__c';
import COMPLETIONMC from '@salesforce/messageChannel/BWC_Completion__c';
import * as BwcConstants from 'c/bwcConstants';
import getAllowedActions from '@salesforce/apex/BWC_BillingAccountAction.getAllowedActions';
// Import message service features required for subscribing and the message channel
import {
    subscribe,
    unsubscribe,
    APPLICATION_SCOPE,
    MessageContext
} from 'lightning/messageService';
import BAActionMSG from '@salesforce/messageChannel/BWC_BillingAction__c';
import * as bwcDispatchEscalationCase from 'c/bwcDispatchEscalationCase';
import { CurrentPageReference } from "lightning/navigation";



export default class BwcBillingAccountActions extends LightningElement {
    @api recordId;

    @wire(getRecord, { recordId: '$recordId',  fields: [BAN , BA_STATUS] })
    billingAccount;

    @track showLoadingSpinner = false;
    @track lastLICActionMSG;

    @wire(getAllowedActions)
    getAllowedActions;
    @wire(CurrentPageReference)
    pageRef;

    interactionId;
    @wire(MessageContext)
    messageContext;
    suspended = 'Suspended';
    // Encapsulate logic for Lightning message service subscribe and unsubsubscribe
    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                BAActionMSG,
                (message) => this.handleBAActionLICMessage(message),
                { scope: APPLICATION_SCOPE }
            );
        }
    }
    get BillingAccountNumber() {
        return getFieldValue(this.billingAccount.data, BAN);
    }

    escalateLICAction(){
     //   let validOptions = JSON.parse(this.getAllowedActions);


    this.toggle();
    this.subscribToCompletion();

    bwcDispatchEscalationCase.publishEscalationCaseMessage(
            this.interactionId,
            this.lastLICActionMSG.Type,
            this.lastLICActionMSG.action,
            JSON.stringify({
                ban: this.billingAccount.data.fields.Billing_Account_Number__c.value,
                action: this.lastLICActionMSG.action,
                Type: this.lastLICActionMSG.Type}));
    this.template.querySelector('div').click();


    }
    handleBAActionLICMessage(message){
        let validActionList = JSON.parse(this.getAllowedActions.data);
        let enableButton = false;
        this.lastLICActionMSG = message;
        let button = this.template.querySelector('[data-id="EscalateButton"]');
        if(this.recordId === message.PrimaryKey){
        if(validActionList){
            for(let i = 0; i < validActionList.length; i++){

                if(validActionList[i] === message.action){
                    enableButton = true;
                }
            }
            if(enableButton){
                button.disabled = false;
                button.label = 'Escalate For '+ this.handleButtonLabel(message.action);
            }else{
                button.disabled = true;
                button.label = 'Escalate';
            }
            if( getFieldValue(this.billingAccount.data ,BA_STATUS) === this.suspended){
                button.disabled = true;
                button.label = 'Escalate';
            }
        }
    }

    }
    handleButtonLabel(labelValue){
        let buttonLabel = labelValue;
        let testVal = null;
        switch(buttonLabel){
            case BwcConstants.InteractionActivityValueMapping.ProductServiceAddaline.action:
                buttonLabel = BwcConstants.InteractionActivityValueMapping.ProductServiceDeviceUpgrade.action;
                this.overideLastActionMSG(buttonLabel);
            break;
        }
        return buttonLabel;
    }
    overideLastActionMSG(actionVal){
        this.lastLICActionMSG = {
            'action':actionVal,
            'PrimaryKey':this.lastLICActionMSG.PrimaryKey,
            'Type': this.lastLICActionMSG.Type
        }
    }
    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }
    connectedCallback() {
        this.subscribeToMessageChannel();
        this.getInteractionId();
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
    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }
    toggle() {
        this.showLoadingSpinner = !this.showLoadingSpinner;
    }

    toggleAndUnsubscribe() {
    this.toggle();
    this.unsubscribToCompletion();
    }
    subscribToCompletion(){
             // subscribe to completion LMC
             this.completionSubscription = subscribe(
                this.messageContext,
                COMPLETIONMC, (message) => {
                    this.toggleAndUnsubscribe();
                });
    }
    unsubscribToCompletion(){
        unsubscribe(this.completionSubscription);
        this.completionSubscription = null;
    }

}