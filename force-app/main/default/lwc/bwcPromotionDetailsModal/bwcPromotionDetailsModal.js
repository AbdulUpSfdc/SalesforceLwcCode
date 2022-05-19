import { api, LightningElement, wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import OpenCloseTabMC from '@salesforce/messageChannel/BWC_OpenCloseTabMC__c';

export default class BwcModal extends LightningElement 
{
        @api title;
   
        @api isModalOpen = false;
        
        @wire(MessageContext)
        messageContext
        
        @api
        openModal() {
        
            this.isModalOpen = true;
        }
        
        closeModal() {
    
            this.isModalOpen = false;
            this.publishCloseMessage();
        }
        submitDetails() {

            this.isModalOpen = false;
            this.publishCloseMessage();
        }

        publishClosemessage()
        {
            const message = {
                operation: 'CloseTab',
                recordID: 'noRec'
            };
            publish(this.messageContext, OpenCloseTabMC, message);
        }
}