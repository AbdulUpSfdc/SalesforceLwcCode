import { LightningElement, api, track } from 'lwc';
import formFactor from '@salesforce/client/formFactor';
import { NavigationMixin } from 'lightning/navigation';
import postToOPUS from '@salesforce/apex/OPUSLaunchHelper.postToOPUS';

export default class DciCustomerSearchLwc extends NavigationMixin(LightningElement) {
    @api recordId;
    redirectURL = null;
    connectedCallback() {
        if(formFactor != 'Large'){
            postToOPUS({
              recordId: this.recordId, launchIntent: 'Customer Search'
            })
            .then(result => {
              this.redirectURL = result;
              const SubmitHandleMobile = new CustomEvent("HandleMobile", {
                detail: { result }
              });
              this.dispatchEvent(SubmitHandleMobile);     
            });
        }else {
            const SubmitHandleDesktop = new CustomEvent("HandleDesktop");
            this.dispatchEvent(SubmitHandleDesktop);  
        }  
    } 
}