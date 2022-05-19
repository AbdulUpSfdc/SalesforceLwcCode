import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import formFactorPropertyName from "@salesforce/client/formFactor";


export default class createFeedback extends LightningElement {
    @api recordId;
    @api desc;
    @api Description;
    @api Reason;
    IS_DESKTOP;
    erroMessage;
    IS_Reason;
    IS_Desc;
  

    connectedCallback() {
        if (formFactorPropertyName == 'Large') {
            this.IS_DESKTOP = true;
        }
    }

    handleSubmit(event) {
        event.preventDefault();   // stop the form from submitting
          
        this.IS_Desc = false;
        this.IS_Reason = false;
        this.erroMessage = '';

        const inputFields = this.template.querySelectorAll('lightning-input-field');
        if (inputFields) {
            inputFields.forEach(field => {
                if (field.fieldName === 'Reason__c') {
                    const checkVal = field.value;
                    if (checkVal == null || checkVal == '') {
                        this.erroMessage = 'Reason is required to submit the Feedback.';
                    } else {
                        this.IS_Reason = true;
                    }
                }
                if (field.fieldName === 'Description__c') {
                    const checkVal = field.value;
                    if (checkVal == null || checkVal == '') {
                        if(this.erroMessage != ''){
                        this.erroMessage += '\n\n Description is required to submit the Feedback.';
                        }else{
                            this.erroMessage = 'Description is required to submit the Feedback.';
                        }

                    } else {
                        this.IS_Desc = true;
                    }
                }
            });
            
            if (this.IS_Desc && this.IS_Reason) {
                const fields = event.detail.fields;
                fields.Knowledge__c = this.recordId;
                this.template.querySelector('lightning-record-edit-form').submit(fields);
               inputFields.forEach(field => {
                    field.reset();
                });
               
                const evt = new ShowToastEvent({
                    title: ' ',
                    message: 'Feedback Submitted Successfully',
                    variant: 'success',
                    mode: 'dismissable'
                });
                this.dispatchEvent(evt);

            
            }
            else {
                const evt = new ShowToastEvent({
                    title: ' ',
                    message: this.erroMessage,
                    variant: 'error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(evt);

            }

        }

    }

}