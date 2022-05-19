import { LightningElement, wire, api, track } from 'lwc';
import LEAD_OBJECT from '@salesforce/schema/Lead';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import getCheckInInfoData from '@salesforce/apex/DCIController.getCheckInInfo';
import finishCheckinRecords from '@salesforce/apex/DCIController.finishCheckin';
import formFactor from '@salesforce/client/formFactor';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import ComplianceMessage from '@salesforce/label/c.Compliance_Message';
import UnableToFindCheckinRecord from '@salesforce/label/c.UnableToFindCheckinRecord';
import validateLeadInfo from '@salesforce/apex/DCIController.validateLeadInfo';
import getCheckInStatus from '@salesforce/apex/DCIController.getCheckInStatus';
export default class DciFinishScreen extends NavigationMixin(LightningElement) {
    label = {
        ComplianceMessage,
        UnableToFindCheckinRecord
      }
    @track recordTypeInfoData = new Map();
    @track leadRecord = {};
    @track retailCheckQueueRecord = {};
    @api recordId;
    @track showSpinner = false;
    @track showForm = false;
    displayWarning = false;
    displayWarningMessage = '';
    dciCheckinDataDTO = {};

    @wire(getObjectInfo, { objectApiName: LEAD_OBJECT })
    objectInfo(result) {
        if (result.data) {
            // Field Data
            this.fieldData = result.data.fields;
            for (var recordType in result.data.recordTypeInfos) {
                if (recordType.name == 'Digital Check In')
                    this.leadRecord.recordTypeId = recordType.recordTypeId; 
            }
            console.dir(this.recordTypeInfoData);
            this.getData();
        } else if (result.error) { }
    }
    getData() {
        this.showSpinner = true;
        getCheckInInfoData({
            recordId: this.recordId
        })
        .then(data => {
            console.log(data);
            this.dciCheckinDataDTO = data;
            if(data.leadRecord)
                this.leadRecord = data.leadRecord;
            if(data.checkinRecord)
            this.retailCheckQueueRecord = data.checkinRecord;  
            this.showSpinner = false;
            this.showForm = true;
        }).catch(error => {
            console.log('Error '+error);
            this.showSpinner = false;
        });
    }

    connectedCallback() {
        this.displayWarning = false;
        if(this.recordId){
            getCheckInStatus({
                recordId: this.recordId
            })
            .then(data =>{
                this.retailCheckQueueRecord = data;
                if(this.retailCheckQueueRecord.Status__c != 'Engaged'){
                    const IsValidStatus = new CustomEvent("statusengaged");
                    this.dispatchEvent(IsValidStatus);
                }else{
                    this.showSpinner = true;
                    getCheckInInfoData({
                        recordId: this.recordId
                        })
                        .then(data => {
                            console.log(data);
                            this.dciCheckinDataDTO = data;
                            if(data.leadRecord)
                                this.leadRecord = data.leadRecord;
                                this.retailCheckQueueRecord = data.checkinRecord;  
                                this.showSpinner = false;
                                this.showForm = true;
                        }).catch(error => {
                            console.log('Error '+error);
                            this.showSpinner = false;
                    });    
                }
            }).catch(error => {
                console.log('Error '+error);
                this.showSpinner = false;
            });
        } else{
            this.populateOpusToCheckinFinish();
        } 
    }

    populateOpusToCheckinFinish(){
        try {
            var toString = Object.prototype.toString;
            let url = window.location;
            let urlString = decodeURI(url);
            let subUrl = urlString.split("?");
            let requiredUrl = '';
            subUrl.forEach(function(row) {
                if (row.indexOf("c__finishRequest") >= 0) {
                    requiredUrl = row.split("&");
                }
            });
            if(requiredUrl != ''){
                const table = requiredUrl.map(pair => pair.split("="));
                const result = {};
                table.forEach(([key, value]) => result[key] = value);
                this.param = result["c__finishRequest"];
                this.param = decodeURIComponent(this.param)
                var obj = JSON.parse(this.param);
                this.recordId = obj.sfRecordId;
                validateLeadInfo({
                    recordId: obj.sfRecordId,
                    firstName: obj.opusCustomerFirstName,
                    lastName:  obj.opusCustomerLastName
                }).then(data => {
                    if(data.checkinRecord == undefined){
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: UnableToFindCheckinRecord,
                                variant: 'error'
                            }));
                        //Navigate to New Checkin page
                        this.navigateNext();    
                    }else if(data.checkinRecord.Status__c!='Engaged'){
                        const IsValidStatus = new CustomEvent("statusengaged");
                        this.dispatchEvent(IsValidStatus);
                        this.navigateNext();
                    //}else if(data.leadRecord != undefined && (data.leadRecord.FirstName != obj.opusCustomerFirstName || data.leadRecord.LastName != obj.opusCustomerLastName)){
                    }else if(data.leadRecord != undefined && (data.leadRecord.FirstName.toUpperCase() != obj.opusCustomerFirstName.toUpperCase() || data.leadRecord.LastName.toUpperCase() != obj.opusCustomerLastName.toUpperCase())){
                        this.leadRecord = data.leadRecord;
                        this.displayWarning = true;
                        this.displayWarningMessage = `The customer helped in OPUS was  ${obj.opusCustomerFirstName} ${obj.opusCustomerLastName}. Please confirm the information is accurate for this check-in before finishing the check-in.`;
                        this.leadRecord['Name'] = data.leadRecord.FirstName+' '+ data.leadRecord.LastName;
                        //this.leadRecord['OtherNotes__c'] = data.leadRecord.OtherNotes__c!=undefined?data.leadRecord.OtherNotes__c+' '+obj.closingNotes:obj.closingNotes;
                        this.leadRecord['OtherNotes__c'] = data.leadRecord.OtherNotes__c!=undefined?data.leadRecord.OtherNotes__c+' '+obj.closingNotes+' '+obj.opusCustomerFirstName+' '+obj.opusCustomerLastName:obj.closingNotes+' '+obj.opusCustomerFirstName+' '+obj.opusCustomerLastName;
                        this.showSpinner = false;
                        this.showForm = true;    
                    }else {
                        this.leadRecord = data.leadRecord;
                        this.leadRecord['Name'] = obj.opusCustomerFirstName+' '+ obj.opusCustomerLastName;
                        //this.leadRecord['OtherNotes__c'] = data.leadRecord.OtherNotes__c!=undefined?data.leadRecord.OtherNotes__c+' '+obj.closingNotes:obj.closingNotes;
                        this.leadRecord['OtherNotes__c'] = data.leadRecord.OtherNotes__c!=undefined?data.leadRecord.OtherNotes__c+' '+obj.closingNotes+' '+obj.opusCustomerFirstName+' '+obj.opusCustomerLastName:obj.closingNotes+' '+obj.opusCustomerFirstName+' '+obj.opusCustomerLastName;
                        this.showSpinner = false;
                        this.showForm = true;       
                    }
                    this.dciCheckinDataDTO = data;
                    this.retailCheckQueueRecord = data.checkinRecord;
                }).catch(error => {
                    console.log('Error '+error);
                    this.showSpinner = false;
                });
            }
        } catch(e) {

        }    
    }
    
    handleCancel(event) { 
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'RetailCheckinQueue__c',
                actionName: 'view'
            }
        });         
    }

    handleSubmit(event) {
        this.showSpinner = true;
        var result;
        event.preventDefault(); 
        this.submitForm(event, false);

    }

    handleBindingFields(event) {
        this.leadRecord[event.target.fieldName] = event.target.value; 
        this.dciCheckinDataDTO.leadRecord[event.target.fieldName] = event.target.value; 
    }

    validateForm(event){
       let isFormValid = true;
        if (this.leadRecord.OtherNotes__c) {
            console.log('LENGTH!!!! '+this.leadRecord.OtherNotes__c.length);
            if(this.leadRecord.OtherNotes__c.length>1000){
                isFormValid = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Other notes supports maximum of 1000 characters',
                        variant: 'error'
                    }));
            }    
        }
        return isFormValid;
    }

    handleConsumer(event) {
        this.submitForm(event, true);
    }

    redirectToLead(event) {
        var param = "{"+
                    "\"firstName\": \""+this.leadRecord.FirstName+"\","+
                    "\"lastName\": \""+this.leadRecord.LastName+"\","+
                    "\"phone\": \""+this.leadRecord.MobilePhone+"\","+
                    "\"dciLeadId\": \""+this.leadRecord.Id+"\""+
                    "}";
        console.log(param);
        param = encodeURI(param);
        console.log(param);
        /*this[NavigationMixin.Navigate]({
            type: 'standard__component',
            attributes: {
                componentName: 'c__leadForm'
            },
            state : {
                c__leadDetails : param
            }
        });*/

        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/lightning/n/LeadForm?c__leadDetails='+param
            }
        }
      );
    }

    submitForm(event, isCallback) {
        if(this.validateForm(event)){
            console.log('handleSubmit ');
            this.leadRecord['Status'] = 'Closed' ;
            this.leadRecord['ClosedStatus__c'] = 'Completed' ;
            this.retailCheckQueueRecord['Status__c'] = 'Completed';

            this.dciCheckinDataDTO.leadRecord['Status'] = 'Closed' ;
            this.dciCheckinDataDTO.leadRecord['ClosedStatus__c'] = 'Completed' ;
            this.dciCheckinDataDTO.checkinRecord['Status__c'] = 'Completed';
            console.log(this.dciCheckinDataDTO);
            
            finishCheckinRecords({
                checkinInfo: this.dciCheckinDataDTO
            })
            .then(data => {
                if(isCallback) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: data,
                            variant: 'success'
                        })
                    );
                    this.redirectToLead(event);
                    this.showSpinner = false;
                } else {
                    /*var result = {
                        status : 'Success',
                        message: data,
                        type: 'success'
                    }
                
                    const submitActionEvent = new CustomEvent("submitaction", {
                        detail: { result }
                    });
                    this.dispatchEvent(submitActionEvent);*/

                    this.dispatchEvent(
                        new ShowToastEvent({
                        title: 'Success',
                        message: data,
                        variant: 'success'
                    }));
                    this.navigateNext(event);
                    this.showSpinner = false;        
                }
    
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
                this.showSpinner = false;
            });
        }else{
            this.showSpinner = false;
        }
    }

    navigateNext(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
            apiName: 'Retail_Home_Page',
         }
        });
    }
}