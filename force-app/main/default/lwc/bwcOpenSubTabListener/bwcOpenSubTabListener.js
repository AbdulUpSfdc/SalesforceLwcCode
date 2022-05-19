import { LightningElement, wire } from 'lwc';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import OPENSUBTABMC from '@salesforce/messageChannel/BWC_OpenSubTab__c';

export default class BwcOpenSubTabListener extends LightningElement {

    @wire(MessageContext) messageContext;

    subscription;

    connectedCallback() {

        // Subscribe to channel
        this.subscription = subscribe(
            this.messageContext,
            OPENSUBTABMC,
            messageFields => {

                // Convert into a custom event which Aura component can handle.
                this.dispatchEvent(new CustomEvent('opensubtab', {detail: messageFields}));

            }
        );

    }
     
    disconnectedCallback() {

        // Unsubscribe from message channel
        if (this.subscription) {
            unsubscribe(this.subscription);
        }

        this.subscription = null;

    }

}