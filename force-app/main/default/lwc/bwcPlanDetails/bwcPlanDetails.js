import { LightningElement,api } from 'lwc';
import getBillingAccount from '@salesforce/apex/BWC_PlanDetailController.getBillingAccount';

export default class BwcPlanDetails extends LightningElement {
    recordDetails
    @api recordId
    myrecordId
    col = []

    connectedCallback(){ 
        getBillingAccount({recordId:this.recordId})
            .then(result => {    
                this.recordDetails = JSON.parse(result);
                this.myrecordId=this.recordDetails.recordId;
                this.col = this.recordDetails.fields;
                this.data = this.recordDetails;
            })
            .catch(error => {
                this.error = error;
                //this.data = mydata;
            });

    }
}