import { LightningElement } from 'lwc';
import {publish, MessageContext, createMessageContext } from 'lightning/messageService';
import CLOSTFOCUSTABLMS from '@salesforce/messageChannel/BWC_CloseFocusedTab__c';
export const publishMessage = ()=>{

const message = {

};

publish(createMessageContext(), CLOSTFOCUSTABLMS , message);


};
export default class Bwc_CloseFocusedTabPublisher extends LightningElement {}