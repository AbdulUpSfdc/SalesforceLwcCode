import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import msg from '@salesforce/label/c.BWC_MainToast_Message';

export default class BwcMainToast extends LightningElement {
    message = msg;
    variant = 'info';

    connectedCallback(){
        const evt = new ShowToastEvent({
            message: this.message,
            variant: this.variant,
            mode: 'sticky',
        });
        this.dispatchEvent(evt);
    }

}