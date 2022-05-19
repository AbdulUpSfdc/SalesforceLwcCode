import { LightningElement ,api, wire} from 'lwc';

// Message channel way
import { publish, MessageContext } from 'lightning/messageService';
import OpenCloseTabMC from '@salesforce/messageChannel/BWC_OpenCloseTabMC__c';


export default class BwcModal extends LightningElement {

    @api bShowModal
    @api modalHeader
    @api modalMessage

    @wire(MessageContext)
    messageContext;

    
    closeModal() {    
        // to close modal window set 'bShowModal' tarck value as false
        this.bShowModal = false;
        console.log('Calling close tab');
        const message = {
            operation: 'CloseTab',
            recordID: 'noRec'
        };
        publish(this.messageContext, OpenCloseTabMC, message);
    }
}