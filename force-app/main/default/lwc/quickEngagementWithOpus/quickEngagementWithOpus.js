import { LightningElement, api,track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import DCIcheckIfBusywithCustomer from '@salesforce/apex/DCIController.DCIcheckIfBusywithCustomer';
import getRetailCustomSettings from '@salesforce/apex/OPUSLaunchHelper.getRetailCustomSettings';

export default class QuickEngagementWithOpus extends NavigationMixin(LightningElement) {
    @api recordId;
    redirectURL = null;
    launchIntent;
    showAssistInOpusCmp = true;
    @track isDisable;

    handleClick(event) {
        this.redirectURL = event.detail.redirectURL;
        this.navigateToOPUS(); 
    }

    connectedCallback()
    {
        getRetailCustomSettings({key: 'DCIEnableLICOpusButton'})
                        .then(output => {    
                            if(output === 'OFF'){
                                this.showAssistInOpusCmp = false;
                            }
                            else
                            {
                                DCIcheckIfBusywithCustomer()
                                    .then(result => {   
                                            this.isDisable = result;
                                            console.log('Reload :' + this.isDisable);
                                    }); 
                            }
                        });
    }

    navigateToOPUS() {
        this.isDisable = true;
        this[NavigationMixin.Navigate]({
            "type": "standard__webPage",
            "attributes": {
                
                "url": encodeURI(this.redirectURL)
            }
        });
    } 
}