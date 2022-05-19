import { LightningElement, api, wire } from 'lwc';
import updateLeads from '@salesforce/apex/LeadForm.updateLeads';
import changeLeadOwner from './changeLeadOwnerLwc.html';
import changeLeadOwnerListView from './changeLeadOwnerLwcListView.html';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import OWNER_FIELD from '@salesforce/schema/Lead.Owner__c';
import ID_FIELD from '@salesforce/schema/Lead.Id';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import USER_NAME_FIELD from '@salesforce/schema/User.Name';
import USER_CHANNEL_FIELD from '@salesforce/schema/User.Channel__c';

export default class ChangeLeadOwnerLwc extends LightningElement {
    @api recordId;
    @api leadsList;
    @api calledFrom;
    isToastVisible = false;
    isSuccess = true;
    toastMessage = 'This is toast message';
    selectedLeadsCount = 0;
    leadIds;
    userFullName;  
    userRecordId;
    lookupInfo;
    hasProspect = false;
 
    render() {
        if (this.isListView()) {
            this.selectedLeadsCount = this.leadsList.split(',').length;
            this.leadIds = this.leadsList.split(',').map(id => id.trim()).join();
            return changeLeadOwnerListView;
        } else {
            if (this.recordId) this.leadIds = this.recordId;
            return changeLeadOwner;
        }
    }
    
    
    
    
    @wire(getRecord, {recordId: USER_ID, fields: [USER_NAME_FIELD, USER_CHANNEL_FIELD]}) 
        wireuser({error, data}) {
            if (error) {
                console.log(`wireuser:Error: ${JSON.stringify(error, null, 4)}`);
            } else if (data) {
                console.log(`wireuser:Data: ${JSON.stringify(data, null, 4)}`);
                console.log(data.fields.Channel__c.value);
                this.lookupInfo = data.fields.Channel__c.value;
            }
    }

   

    onUserSelected(event){
        this.userFullName = event.detail.selectedValue;  
        this.userRecordId = event.detail.selectedRecordId;
    }

    handleClose() {
        //window.history.go(-1);

        if(FORM_FACTOR === 'Small' || FORM_FACTOR === 'Medium') {
            const cancelClickedEvent = new CustomEvent('cancelclicked');    
            this.dispatchEvent(cancelClickedEvent);
          }
          else
            window.history.back();
        }
    

    onClose(event) {
        this.handleClose();
    }

    onSave(event) {
        if (this.isListView()) {
            if (!this.userRecordId) {
                this.handleToast({shouldClose: false, status: 'error', message: 'Please select a value'});
            } else {
                updateLeads({ids: this.leadIds.split(','), owner: this.userRecordId})
                .then(() => {
                    if(this.hasProspect) {
                        this.handleToast({shouldClose: true, status: 'success', message: 'Success: Lead/s owner has been changed. Lead/s of type Prospect cannot be updated'});  
                    } else {
                        this.handleToast({shouldClose: true, status: 'success', message: 'Success: Lead/s owner has been changed'});
                    }
                })
                .catch(error => {
                    let errMsg = 'An error occurred while trying to update the record. Please contact system administrator.';
                    if(error.body.message) errMsg = error.body.message;
                    if(error.body.pageErrors.length > 0) errMsg = error.body.pageErrors[0].message;
                    this.handleToast({shouldClose: false, status: 'error', message: errMsg});
                });
            }
        } else {
            const fields = {};
            fields[ID_FIELD.fieldApiName] = this.recordId;
            fields[OWNER_FIELD.fieldApiName] = this.userRecordId;
            if (this.userRecordId) {
                updateRecord({ fields })
                    .then(() => {
                        this.handleToast({status: 'success', message: 'Lead updated'});
                        this.handleClose();
                    })
                    .catch(error => {
                        this.handleToast({status: 'error', message: error.body.message});
                    });
            } else {
                this.handleToast({status: 'error', message: 'Select a owner to change ownership'});
            }
        }
    }

    isListView() {
        return (this.calledFrom && this.calledFrom === 'LeadListView');
    }

    handleToast(args) {
        if (this.isListView()) {
            let delay = 2000;
            this.toastMessage = args.message;
            this.isSuccess = args.status && args.status === 'success' ? true : false;
            this.isToastVisible = true;
            setTimeout(() => {
                this.isToastVisible = false;
                if (args.shouldClose) this.handleClose();
            }, delay );
        } else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: args.status && args.status === 'success' ? 'Success' : 'Error',
                    message: args.message,
                    variant: args.status
                })
            );
        }
    }


}