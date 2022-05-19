import { LightningElement } from 'lwc';
import {publish, createMessageContext } from 'lightning/messageService';
import OpenNewBrowserTab from'@salesforce/messageChannel/BWC_OpenNewBrowserTab__c'
export const publishMessage = (urlParams)=>{

    const message = {
        URL: urlParams
    }; 
        const messagContext = createMessageContext();
    publish(messagContext, OpenNewBrowserTab, message);

};
export default class BwcOpenNewBrowserTabPublisher extends LightningElement {}