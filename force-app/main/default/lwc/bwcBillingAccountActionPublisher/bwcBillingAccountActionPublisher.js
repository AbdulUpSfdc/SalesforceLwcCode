import { LightningElement } from 'lwc';
import {publish, createMessageContext } from 'lightning/messageService';
import BAActionMSG from '@salesforce/messageChannel/BWC_BillingAction__c';

export const publishMessage = (LICAction,primaryKey,interactionType)=>{
       
        const message = {
        action: LICAction,
        PrimaryKey: primaryKey,
        Type:interactionType
    };

    publish(createMessageContext(), BAActionMSG, message);
    
};
export default class BwcBillingAccountActionPublisher extends LightningElement {

}