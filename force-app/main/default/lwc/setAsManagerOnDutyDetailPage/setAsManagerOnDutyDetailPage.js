import { LightningElement, api, wire } from 'lwc';
import getEmployeeStoreRetail from '@salesforce/apex/DCIController.getEmployeeStoreRetail';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import IS_MANAGER_ON_DUTY from '@salesforce/schema/EmployeeStoreRetail__c.IsManagerOnDuty__c';
import NAME from '@salesforce/schema/EmployeeStoreRetail__c.Name';
import ID_FIELD from '@salesforce/schema/EmployeeStoreRetail__c.Id';
import { updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updateMoDStatusOfRep from '@salesforce/apex/DCIController.updateMoDStatusOfRep';

const FIELDS = [IS_MANAGER_ON_DUTY, NAME];
export default class SetAsManagerOnDutyDetailPage extends LightningElement {
    
    iconName;
    iconNameBackground;
    @api recordId;
    employeeStoreRetailRecord;
    showModal = false;
    isMangerOnDuty;
    repName;
    setIsManagerOnDuty = false;
    unSetIsManagerOnDuty = false;
    header='';
    showSetButton = false;
    showUnSetButton = false;
    showCancelButton = false;
    showButtonName = '';
    setUnsetManagerOnDuty;


    

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            this.employeeStoreRetailRecord = data;
            this.isMangerOnDuty = this.employeeStoreRetailRecord.fields.IsManagerOnDuty__c.value;
            this.repName = this.employeeStoreRetailRecord.fields.Name.value;
            if(this.employeeStoreRetailRecord.fields.IsManagerOnDuty__c.value){
                this.iconName = 'utility:check';
                this.iconNameBackground = true;
            }else{
                this.iconName ='utility:add';
                this.iconNameBackground = false;    
            }
        }
    }

    updateMoDStatus(){
        updateMoDStatusOfRep({recordId: this.recordId, ModStatus: this.setUnsetManagerOnDuty})
        .then(() =>{
            this.showSpinner = false;
            this.handleAssignUsertoPublicGroup();
        })
    }
    
    handleManagerOnDuty(){
        if(this.isMangerOnDuty){
            this.unSetIsManagerOnDuty = true;
            this.showModal = true;
            this.header = 'Remove rep as manager on duty';
            this.showUnSetButton = true;
            this.showCancelButton = true;
            this.showButtonName = 'Remove';
        }else{
            this.setIsManagerOnDuty = true;  
            this.showModal = true;
            this.header = 'Set rep as manager on duty'; 
            this.showSetButton = true; 
            this.showCancelButton = true;
            this.showButtonName = 'Set';
        }
    }

    closeModal() {
        this.showModal = false;
    }

    handleSetIsManagerOnDuty(){
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[IS_MANAGER_ON_DUTY.fieldApiName] = true;

        const recordInput = {
            fields: fields
        };
        /*updateRecord(recordInput).then((record) => {
            console.log(record);
        });*/
        this.showModal = false;
        this.setUnsetManagerOnDuty = true;
        this.updateMoDStatus();
        //this.handleAssignUsertoPublicGroup();

    }

    handleUnSetIsManagerOnDuty(){
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[IS_MANAGER_ON_DUTY.fieldApiName] = false;

        const recordInput = {
            fields: fields
        };
        /*updateRecord(recordInput).then((record) => {
            console.log(record);
        });*/
        this.showModal = false;
        this.setUnsetManagerOnDuty = false;
        this.updateMoDStatus();
        //this.handleAssignUsertoPublicGroup();
    }


    handleAssignUsertoPublicGroup(){
        getEmployeeStoreRetail({recordId: this.recordId, setUnsetManagerOnDuty: this.setUnsetManagerOnDuty})
        .then(() =>{

            if(this.setUnsetManagerOnDuty){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success!',
                        message: 'You successfully set '+ this.repName + ' as manager on duty', 
                        variant: 'success'
                    })
                )
                this.resetAll();
            }
            if(!this.setUnsetManagerOnDuty){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success!',
                        message: 'You successfully removed '+ this.repName + ' as manager on duty', 
                        variant: 'success'
                    })
                ) 
               this.resetAll();
            }
            window.location.reload();
        })
        .catch(error =>{
            this.showSpinner = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error!',
                    //message: 'Something went wrong while updating status',
                    message: error,
                    variant: 'error'
                })
            )
            this.resetAll();
            window.location.reload();
        })

    }

    resetAll(){
        this.unSetIsManagerOnDuty = false;
        this.showModal = false;
        this.header = '';
        this.showUnSetButton = false;
        this.showCancelButton = false;
        this.showButtonName = '';
        this.setIsManagerOnDuty = false;
        this.showSetButton = false; 
        this.showButtonName = '';
        this.setUnsetManagerOnDuty;
    }



}