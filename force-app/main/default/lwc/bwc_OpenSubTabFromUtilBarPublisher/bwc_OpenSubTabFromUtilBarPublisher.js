import { LightningElement } from 'lwc';
import {publish, MessageContext, createMessageContext } from 'lightning/messageService';
import OPENSUBTAB from '@salesforce/messageChannel/BWC_OpenSubTabFromUtilBar__c';
export const publishMessage = (recordIdParam)=>{

const message = {
    recordId: recordIdParam
};

publish(createMessageContext(), OPENSUBTAB , message);


};
export default class Bwc_OpenSubTabFromUtilBarPublisher extends LightningElement {}