import { LightningElement } from 'lwc';
import {publish, MessageContext, createMessageContext } from 'lightning/messageService';
import MessageChannel from '@salesforce/messageChannel/BWC_DisableCloseTab__c';
export const publishMessage = (enabled)=>{
    
        const message = { Enabled : enabled
    };
    publish(createMessageContext(), MessageChannel, message);


};
export default class BwcDisableCloseTabPublisher extends LightningElement {}