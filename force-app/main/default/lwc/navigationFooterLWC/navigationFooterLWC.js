import { LightningElement, api, wire } from 'lwc';
import { publish, subscribe, MessageContext, APPLICATION_SCOPE } from 'lightning/messageService';
import buyFlowChannel from '@salesforce/messageChannel/buyFlow__c';

export default class NavigationFooterLWC extends LightningElement {
    //Booleans
    @api hideBack = false;
    @api disableBack = false;
    //Must choose only one, Continue or Submit
    @api hideContinue = false;
    @api disableContinue = false;
    @api hideSubmit = false;
    @api disableSubmit = false;
    //strings
    @api backLabel = 'Back';
    @api continueLabel = 'Continue';
    @api submitLabel = 'Submit';

    subscription

    @wire(MessageContext)
    messageContext;

    connectedCallback(){
        this.subscribeToMessageChannel();
    }

    handleClick(event){
        let payload = {};
        switch(event.target.label){
            case this.backLabel: 
                payload.buttonClicked = 'back';
                break;
            case this.continueLabel: 
                payload.buttonClicked = 'continue';
                break;
            case this.submitLabel: 
                payload.buttonClicked = 'submit';
                break;
            default:
                break;
        }
        publish(this.messageContext, buyFlowChannel, payload);
    }

    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                buyFlowChannel,
                (message) => this.handleMessage(message),
                { scope: APPLICATION_SCOPE }
            ); 
        }
    }

    handleMessage(message){

        if (message.hasSelected === true) {
            this.disableContinue = false;
        } else if (message.hasSelected === false) {
            this.disableContinue = true;
        }

        switch (message.enable){
            case 'enableContinue':
                this.disableContinue = false;
                break;
            case 'disableContinue':
                this.disableContinue = true;
                break;
            case 'enableBack':
                this.disableBack = false;
                break;
            case 'disableBack':
                this.disableBack = true;
                break;
            case 'enableSubmit':
                this.disableSubmit = false;
                break;
            case 'disableSubmit':
                this.disableSubmit = true;
                break;
            default:
                break;
        }
    }
}