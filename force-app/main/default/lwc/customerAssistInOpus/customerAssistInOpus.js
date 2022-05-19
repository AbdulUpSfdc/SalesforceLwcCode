import { LightningElement, api,wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import isRecordEngaged from '@salesforce/apex/OPUSLaunchHelper.isRecordEngaged';
import getRetailCustomSettings from '@salesforce/apex/OPUSLaunchHelper.getRetailCustomSettings';


export default class CustomerAssistInOpus extends NavigationMixin(LightningElement) {
    @api recordId;
    redirectURL = null;
    launchIntent;
    showAssistInOpusCmp = true;

    handleClick(event) {
        this.redirectURL = event.detail.redirectURL;
        this.verifyCheckinRecord();
    }
    connectedCallback()
    {
        getRetailCustomSettings({key: 'DCIEnableLICOpusButton'})
                        .then(output => {    
                            if(output === 'OFF'){
                                this.showAssistInOpusCmp = false;
                            }
                        });
    }

    verifyCheckinRecord(){
        isRecordEngaged({recordId: this.recordId})
        .then(result => {   
                if(result){
                    this.navigateToOPUS();
            }
            else{
                    this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Ensure the check-in is engaged before attempting to assist the customer in OPUS',
                        variant: 'error'
                    })
                )
            }
        });
    }

    navigateToOPUS() {
        this[NavigationMixin.Navigate]({
            "type": "standard__webPage",
            "attributes": {
                "url": encodeURI(this.redirectURL)
            }
        });
    } 
}