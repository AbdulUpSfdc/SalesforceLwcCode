import { LightningElement, wire, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import postToOPUS from '@salesforce/apex/OPUSLaunchHelper.postToOPUS';
import { getRecord } from 'lightning/uiRecordApi';

const FIELDS = [
    'RetailCheckinQueue__c.DCIBOPISOrder__c',
];
export default class ContextInLaunchBOPIS extends NavigationMixin(LightningElement) {
    orderId = null;
    RetailCheckinQueue__c;
    @api recordId;
    redirectURL = null;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (error) {
            let message = 'Unknown error';
        } else if (data) {
            this.RetailCheckinQueue__c = data;
            if(this.RetailCheckinQueue__c.fields.DCIBOPISOrder__c.value)
            this.orderId = 'Pick up Order #'+this.RetailCheckinQueue__c.fields.DCIBOPISOrder__c.value;
            else
            this.orderId = 'Pick up Order #';
        }
    }

    viewOrder(event) {
        postToOPUS({
            recordId: this.recordId,
            launchIntent: 'BOPIS'
        })
        .then(result => {
            this.redirectURL = result;
            console.log('result : '+ result);
            this.navigateToOPUS();      
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