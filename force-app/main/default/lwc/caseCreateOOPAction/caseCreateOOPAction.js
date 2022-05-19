import { LightningElement, track, wire,api} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import createOOPCase from '@salesforce/apex/OOP_CreateCase.createOOPCase';

export default class CaseCreateOOPAction extends NavigationMixin(LightningElement){
    @api recordId;
    @track showLoadingSpinner = true;
     // Imperative Call
    executeDetails() {
     
          createOOPCase({billingAccountId: this.recordId}).then(result => {
              console.log("##result",result);	
              this.showLoadingSpinner = true;
              
              // showing success message
               this.dispatchEvent(new ShowToastEvent({
                  title: 'Success!!',
                  message: 'Successfully Created Case',
                  variant: 'success'
              }));

            var value =result.Id;
            const valueChangeEvent = new CustomEvent("valuechange", {
            detail:{value}
            });
            // Fire the custom event
            this.dispatchEvent(valueChangeEvent);
             
            this.dispatchEvent(new CustomEvent('close'));
 
          }).catch(errorPhase => {      
             console.log('###Errp'+errorPhase.body.message);

              this.showLoadingSpinner = false;
              this.dispatchEvent(new ShowToastEvent({
                title: 'Error!!',
                message: errorPhase.body.message,
                variant: 'error'
              }));

              this.dispatchEvent(new CustomEvent('close'));
 
          });
        

    }

    connectedCallback() {
          this.executeDetails();
    }
  
   
}