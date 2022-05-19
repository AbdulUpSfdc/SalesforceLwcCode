import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import FullRejectUnauthorizedMessage from '@salesforce/label/c.FullRejectUnauthorizedMessage';
import checkAccessibility from '@salesforce/apex/BWC_FullRejectAdjustmentApproval.checkAccessibility';
export default class BwcFullRejectAdustmentApproval extends LightningElement {
    @api message;
    @api recordId;
    @api title;
    @api variant;
    @api invoke() {
        checkAccessibility({workItemId: this.recordId}).then((result) => {
            this.message = result;
            if(this.message===FullRejectUnauthorizedMessage){
                this.title='Error';
                this.variant='error';
            } else {
                this.title='Success';
                this.variant='success';
            }
            this .error= undefined;           
            this.dispatchEvent(
                new ShowToastEvent({
                  title: this.title,
                  message: this.message,
                  variant: this.variant
                })
            );        
        }).catch((error) => {
            this.dispatchEvent(
                new ShowToastEvent({
                  title: "Error",
                  message: error,
                  variant: "error"
                })
            );        
        });
    }
}