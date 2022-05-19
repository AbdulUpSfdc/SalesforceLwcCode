import { LightningElement, track, api, wire} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import changeCustomerStatus from '@salesforce/apex/DCIChangeCustomerStatusController.changeCustomerStatus';
import swapPosition from '@salesforce/apex/DCIChangeCustomerStatusController.swapQueuePositions';
import FORM_FACTOR from '@salesforce/client/formFactor';
import getAvailableReps from '@salesforce/apex/DCIUtil.getAvailableReps';
import updateLeadWithRep from '@salesforce/apex/DCIChangeCustomerStatusController.updateLeadWithRep';
import { getRecord } from 'lightning/uiRecordApi';
let i=0;

const FIELDS = ['RetailCheckinQueue__c.Status__c'];

export default class MyComponent extends NavigationMixin(LightningElement){
    
	@api recordId;
	@api actionType;
	@track showSpinner = false;
	@track badgeStyle;
	@track items = []; //this holds the array for records with value & label
	@track error;
	RetailCheckinQueueRecord;
	recordStatus;
	selectedRepId;
	selectedRepName;
	isAssignVal = false;


	@wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
         if (data) {
            this.RetailCheckinQueueRecord = data;
            this.recordStatus = this.RetailCheckinQueueRecord.fields.Status__c.value;
			console.log('recordStatus : '+ this.recordStatus);
        }
    }
	   
	get userOptions() {
        return this.items;
    }
	
	@wire(getAvailableReps, { recordId: '$recordId', actionType: '$actionType'})
    getAvailableReps({ error, data }) {
        if (data) {
            for(i=0; i<data.length; i++) {
                this.items = [...this.items ,{value: data[i].User__c , label: data[i].Employee__r.Name}];                                
            }               
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.items = undefined;
        }
    }

	handleCustomEvent(event) {		
        this.selectedRepId = event.detail.value;
		this.selectedRepName = event.detail.label;
    }

    /*constants*/
    @api CONSTANTS = {
        MOVE_UP : 'Move customer up In queue?',
        MOVE_UP_ACTION_TYPE : 'MoveUp',
        MOVE_UP_LABEL : 'Move up'
    }

	/** Getters start here  */

	get MARK_PENDING() {
		return 'MarkPending';
	}
	get MARK_ARRIVED() {
		return 'MarkArrived';
	}
	get MARK_REMOVE() {
		return 'MarkRemove';
	}
	get HELP_NEXT_CUSTOMER() {
		return 'HelpNextCustomer';
	}
	get MARK_NOSHOW() {
		return 'MarkNoShow';
	}
	get ASSIGN_CUSTOMER() {
		this.isAssignVal = true;
		return 'AssignCustomer';
	}

	get badgeCss() {
		if (this.actionType === this.HELP_NEXT_CUSTOMER || this.actionType === this.MARK_PENDING || this.actionType === this.CONSTANTS.MOVE_UP_ACTION_TYPE || this.actionType === this.MARK_NOSHOW) {
			return 'slds-badge slds-theme_success';
		}
		else if (this.actionType === this.MARK_ARRIVED ){
			return 'slds-badge';
		}	
		else if(this.actionType == this.ASSIGN_CUSTOMER){
			if(this.recordStatus == 'Pending')
				return 'slds-badge';
			else
				return 'slds-badge slds-theme_success';
		}
		else{
			return 'slds-badge';
		}
	}
	
	get isArrived() {
        if (this.actionType === this.MARK_ARRIVED){		
			return true;
		}
		else {
			return false;
		}
    } 
	
	get isPending() {
        if (this.actionType === this.MARK_PENDING){		
			return true;
		}
		else {
			return false;
		}
	}
	get isRemove() {
        if (this.actionType === this.MARK_REMOVE){		
			return true;
		}
		else {
			return false; 
		}
	}
	get isAssign() {
        if (this.actionType === this.ASSIGN_CUSTOMER){	
			return true;
		}
		else {
			return false;
		}
	}
	get isHelpNext() {
        if (this.actionType === this.HELP_NEXT_CUSTOMER){		
			return true;
		}
		else {
			return false;
		}
    }
	
	get cardTitle(){
		if (this.actionType === this.MARK_ARRIVED) {
			return 'Mark customer arrived?';
		}
		if (this.actionType === this.MARK_PENDING) {
			return 'Mark customer pending?';
		}
		if (this.actionType === this.MARK_REMOVE) {
			return 'Remove this customer?';
		}
		if (this.actionType === this.HELP_NEXT_CUSTOMER) {
			return 'Help this customer?';
		}
		if (this.actionType === this.CONSTANTS.MOVE_UP_ACTION_TYPE) {
			return this.CONSTANTS.MOVE_UP;
		}
		
		if (this.actionType === this.MARK_NOSHOW) {
			return 'Mark customer no-Show?';
		}
		if(this.actionType === this.ASSIGN_CUSTOMER)
		{
			return 'Assign Specific Rep to Customer';
		}
		return '';
	}

	get actionLabel(){
		if (this.actionType === this.MARK_ARRIVED) {
			return 'Mark arrived';
		}
		if (this.actionType === this.MARK_PENDING) {
			return 'Mark pending';
		}
		if (this.actionType === this.MARK_REMOVE) {
			return 'Mark remove';
		}
		if (this.actionType === this.HELP_NEXT_CUSTOMER) {
			return 'Accept';
		}
		if (this.actionType === this.CONSTANTS.MOVE_UP_ACTION_TYPE) {
			return this.CONSTANTS.MOVE_UP_LABEL;
		}
		
		if (this.actionType === this.MARK_NOSHOW) {
			return 'Mark no-show';
		}
		if(this.actionType === this.ASSIGN_CUSTOMER)
		{
			return 'Assign';
		}
		return ''
		
	}

	/** Getters end here  */

	handleSubmit() {
		if (this.actionType === this.MARK_ARRIVED || this.actionType === this.MARK_PENDING || this.actionType === this.MARK_REMOVE || this.actionType === this.HELP_NEXT_CUSTOMER ||this.actionType === this.MARK_NOSHOW) {
			this.changeStatus();
		} else if (this.actionType === this.CONSTANTS.MOVE_UP_ACTION_TYPE) {
			this.swapPositions();
		}
		else if(this.actionType === this.ASSIGN_CUSTOMER)
		{
			if(this.selectedRepId!=null) {
				this.updateLeadWithRep();
			}
			else {
				this.dispatchEvent(
					new ShowToastEvent({
						title: 'Warning',
						message: 'Please select a Rep to assign',
						variant: 'Warning'
					})
				);
			}
		}
	}
	updateLeadWithRep(){
		updateLeadWithRep({ recordId: this.recordId, selectedRep: this.selectedRepId, selectedRepName: this.selectedRepName})
		.then(result => {
				this.dispatchEvent(
					new ShowToastEvent({
						title: 'Success',
						message: result,
						variant: 'success'
					})
				); 
				this.closeAction();
        })
		.catch(error => {
			var result = {
				status : 'Error',
				message: error.body.message,
				type: 'error'
			}
			const submitActionEvent = new CustomEvent("submitaction", {
				detail: { type:result.type,message:result.message,status:result.status }
			});
			this.dispatchEvent(submitActionEvent);
		});
	}
	changeStatus(){
		changeCustomerStatus({ recordId: this.recordId, action: this.actionType})
		.then(result => {
			const submitActionEvent = new CustomEvent("submitaction", {
				detail: { type:result.type,message:result.message,status:result.status }
			});
			this.dispatchEvent(submitActionEvent);
 
		})
		.catch(error => {
			var result = {
				status : 'Error',
				message: error.body.message,
				type: 'error'
			}
			const submitActionEvent = new CustomEvent("submitaction", {
				detail: { result }
			});
			this.dispatchEvent(submitActionEvent);
		});
	}

	swapPositions() {
		swapPosition({ recordId: this.recordId, action: this.actionType})
		.then(result => {
			const submitActionEvent = new CustomEvent("submitaction", {
				detail: { type:result.type,message:result.message,status:result.status }
			});
			this.dispatchEvent(submitActionEvent);
		})
		.catch(error => {
			var result = {
				status : 'Error',
				message: error.body.message,
				type: 'error'
			}
			const submitActionEvent = new CustomEvent("submitaction", {
				detail: { type:result.type,message:result.message,status:result.status }
			});
			this.dispatchEvent(submitActionEvent);
		});
	}
	
	closeAction(){   
		const closeActionEvent = new CustomEvent('closeaction');
		// Fire the custom event to aura
		this.dispatchEvent(closeActionEvent);
		if(this.actionType === this.ASSIGN_CUSTOMER)
		window.location.reload();
	}
}