import { LightningElement, wire,track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getCustomer from '@salesforce/apex/DCIController.getBusyCustomer';
export default class DciHelpNextCustomerShortcut extends NavigationMixin(LightningElement) {
@track showCustInfo = false;
@track custmerName;
@track CustId;


connectedCallback(){
        getCustomer()
        .then(result => {
           
            this.custmerName=result.Lead__r.Name;
            this.CustId=result.Id;
            this.showCustInfo=true;
        })
        .catch(error => {
           
        });
  }

viewRecord(event) {
        // Navigate to Account record page
// alert(this.contacts.ID);
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                "recordId": this.CustId,
                "objectApiName": "RetailCheckinQueue__c",
                "actionName": "view"
            },
        });
    }
}