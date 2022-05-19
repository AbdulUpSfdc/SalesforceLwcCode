import { LightningElement,wire, api } from 'lwc';
import {publish, MessageContext, createMessageContext } from 'lightning/messageService';
import launchLICChannel from'@salesforce/messageChannel/BWC_MsgToLIC__c'
export const publishMessage = (msg,params,ban)=>{
    const message = {
        msg : msg,
        params: params,
        ban : ban
    }; 
        const messagContext = createMessageContext();
    publish(messagContext, launchLICChannel, message);

};
export default class BwcMsgToLICPublisher extends LightningElement {


    @wire(MessageContext)
    messageContext; 

    @api publish(msg,params,ban){

        const message = {
            msg : msg,
            params: params,
            ban : ban
        };       
       
        publish(this.messageContext, launchLICChannel, message);
        

    }
}