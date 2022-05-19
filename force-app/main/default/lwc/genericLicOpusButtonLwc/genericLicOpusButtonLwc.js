import { LightningElement,api } from 'lwc';
import postToOPUS from '@salesforce/apex/OPUSLaunchHelper.postToOPUS';

export default class GenericLicOpusButtonLwc extends LightningElement {
    @api recordId;
    @api label;
    @api variant;
    @api lauchIntent;
    @api quickSell;
    @api disabled;
    @api customCss;

    handleClick(event) {
            postToOPUS({
                recordId: this.recordId,
                launchIntent: this.lauchIntent
            })
            .then(result => {
                this.redirectURL = result;
                console.log('result : '+ result);  
                const selectEvent = new CustomEvent('recordclick', {
                    detail : {redirectURL: this.redirectURL}
                });
               this.dispatchEvent(selectEvent);
            });    
    }  
}