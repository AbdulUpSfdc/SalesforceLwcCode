import { LightningElement, wire, api, track } from "lwc";
import { getRecord } from 'lightning/uiRecordApi';
import LEAD_OBJECT from '@salesforce/schema/Lead';
import {getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createDCILead from '@salesforce/apex/DCILeadUtil.createDCILead';
import getHomeStore from '@salesforce/apex/LeadForm.getHomeStore';
import formFactor from '@salesforce/client/formFactor';
import { NavigationMixin } from 'lightning/navigation';
import Id from '@salesforce/user/Id';
import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';
import getonLoadDCIDetails from '@salesforce/apex/DCIController.getonLoadDCIDetails';
import createDCILeadOnHelp from '@salesforce/apex/DCILeadUtil.createDCILeadOnHelp';
import Error from '@salesforce/label/c.Error';
import Cancel from '@salesforce/label/c.Cancel';
import PhoneFormatError from '@salesforce/label/c.PhoneFormatError';
import DuplicateLeadDCI from '@salesforce/label/c.DuplicateLeadDCI';
import ComplianceMessage from '@salesforce/label/c.Compliance_Message';
import CustomerRequestedRep from '@salesforce/label/c.CustomerRequestedRep';
import getAvailableReps from '@salesforce/apex/DCIUtil.getAvailableReps';
import dciFormLwcHandleSubmit from '@salesforce/apex/DCIController.dciFormLwcHandleSubmit';
import orderCallOut from '@salesforce/apex/DCIController.BopisOrderCallout';//krishna
import { CurrentPageReference } from "lightning/navigation";//Abhi
let i=0;
export default class DciFormLwc extends NavigationMixin(LightningElement) {
    @wire(CurrentPageReference)
    currentPageReference;
    @api isFromHome;
    isOther;
    @track custReqRepOptions = [];
    customerRequestedRep = 'Select a rep';
    apiFieldName = 'Lead.ReasonforLeaving__c';
    @track options;
    changedValue;
    @track languageOptions;
    changedLanguageValue;
    fieldLabel ='--Select a reason--';
    @api recordTypeId;
    @track items = [];
    selectedRepId;
	selectedRepName;
    disableHelpButtonApex;
    @api customerToQueue = false;//Abhilash
    @track isPickup = false;//Krishna
    label = {
        Cancel,
        Error,
        PhoneFormatError,
        ComplianceMessage,
        DuplicateLeadDCI,
        CustomerRequestedRep
    }
    @track leadid;
    @track prfName;
    @track storeId;
    @track showSpinner = true;
    @track isHelpButtonDisabled = false;
    @track isButtonDisabled = false;
    @track helpButtonClicked = false;
    @track leadRecord = {};
    @track retailCheckQueueRecord = {};
    @track leadStoreRecord = {};
    @track fieldData = {
        Email: { label: "" },
        MobilePhone: { label: "" },
        FirstName: { label: "" },
        LastName: { label: "" },
        Store__c: { label: "" },
        Street: { label: "" },
        City: { label: "" },
        PostalCode: { label: "" },
        ContactFirst2__c: { label: "" },
        ContactLast2__c: { label: "" },
        Phone: { label: "" },
        Company: { label: "" },
        ReasonforLeaving__c: { label: "" },
        DCIOtherVisitReason__c: { label: "" }
    }

    get userOptions() {
        return this.items;
    }
	
	@wire(getAvailableReps, { recordId: '', actionType: 'newCheckIn'})
    getAvailableReps({ error, data }) {
        if (data) {
            this.items = [...this.items ,{value: "" , label: "First Available"}];
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
        if(this.disableHelpButtonApex == true){
            if(this.selectedRepName!= 'First Available'){
                this.isHelpButtonDisabled = true;    
            }else{
                this.isHelpButtonDisabled = false;  
            }
        }
    }

    @track recordTypeInfoData = new Map();

    
    @wire(getRecord, {
        recordId: Id,
        fields: [PROFILE_NAME_FIELD]
    }) wireuser({
        error,
        data
    }) {
        if (error) {
            this.error = error;
        } else if (data) {
            this.prfName = data.fields.Profile.value.fields.Name.value;
            console.log('  this.prfName' + this.prfName);
        }
    }

    @wire(getObjectInfo, { objectApiName: LEAD_OBJECT })
    objectInfo(result) {
        if (result.data) {
            // Field Data
            this.fieldData = result.data.fields;
            
            for (var recordTypeId in result.data.recordTypeInfos) {
                //if(result.data.recordTypeInfos.hasOwnProperty(result.data.recordTypeInfos[recordTypeId])) {
                    var recordType = result.data.recordTypeInfos[recordTypeId];
                    this.setrecordtypeid(recordType);
              //}                      
            }
            this.showSpinner = false;
        } else if (result.error) {
            this.showSpinner = false;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: '$apiFieldName' })
    getPicklistValues({ error, data }) {
        if (data) {
            // Map picklist values
            let filterOptions = [];
            filterOptions = data.values.map(plValue => {
          //  this.options = data.values.map(plValue => {
                return {
                    label: plValue.label,
                    value: plValue.value
                };
            });
            if(this.prfName != 'System Administrator')
            filterOptions = filterOptions.filter(pValue => pValue.label != 'Get help from a rep in OPUS');
            this.options = filterOptions;

        } else if (error) {
            // Handle error
            console.log('==============Error  ' + error);
            console.log(error);
        }
    }

    handleChange(event) {
        console.log(event.detail.value + 'event.detail.value');
        this.leadRecord['DCIOtherVisitReason__c'] = '';
        this.leadRecord['ReasonforLeaving__c'] =event.detail.value;
        this.changedValue = event.detail.value;

        if(this.leadRecord.ReasonforLeaving__c && this.leadRecord.ReasonforLeaving__c.toLowerCase() == 'get help with something else') {
            this.isOther = true;
        }else{
            this.isOther = false;
        }
        //Krishna start
        if(this.leadRecord.ReasonforLeaving__c && this.leadRecord.ReasonforLeaving__c == 'Pick up online order') {
            this.isPickup = true;
        }else{
            this.isPickup = false;
        }
        //Krishna end
    
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: 'Lead.PreferedLanguage__c' })
    getLanguages({ error, data }) {
        if (data) {
            // Map picklist values
            this.languageOptions = data.values.map(plValue => {
                return {
                    label: plValue.label,
                    value: plValue.value
                };
            });

            this.changedLanguageValue = this.languageOptions.filter(lang => lang.value === 'English')[0].value;
        } else if (error) {
            // Handle error
            console.log('==============Error  ' + error);
            console.log(error);
        }
    }
    handleLanguageChange(event) {
        this.leadRecord['PreferedLanguage__c'] = event.detail.value;
        this.changedLanguageValue = event.detail.value;
    }

    setrecordtypeid(recordType){
        if (recordType.name == 'Digital Check In'){
            this.leadRecord.RecordTypeId = recordType.recordTypeId;
            this.recordTypeId =  recordType.recordTypeId;
        }
    }

    connectedCallback() {
        let custoQueue = this.currentPageReference.state.c__customerToQueue;
        if ( custoQueue )
            this.customerToQueue = custoQueue;
        this.getonLoadDCIDetails();
    
    }


    getonLoadDCIDetails(){
        getonLoadDCIDetails()
            .then(result => {
                if (result) {
                    this.leadStoreRecord.Id = result.storeDetails.Id;
                    this.leadStoreRecord.Name = result.storeDetails.Name;
                    this.leadStoreRecord.DCIStoreRepActiveCapacity__c = result.storeDetails.DCIStoreRepActiveCapacity__c;
                    this.leadStoreRecord.DCIStoreRepCurrentCapacity__c = result.storeDetails.DCIStoreRepCurrentCapacity__c;
                    this.leadStoreRecord.DCIShortestTUF__c= result.storeDetails.DCIShortestTUF__c;    
                    this.disableHelpButtonApex = result.enableHelpNextButton;
                    if(result.enableHelpNextButton == false)
                    this.isHelpButtonDisabled = true;
                    else
                    this.isHelpButtonDisabled = false;
                }  

            });
    }
    handlehelpCustomerButton(event) {
        this.helpButtonClicked = true;
    }

    handleCancel(event) {
        this.handleReset(event);
        console.log('this.isFromHome'+ this.isFromHome);
        if(formFactor && (formFactor=='Medium' || formFactor =='Small')){
            
            if(this.customerToQueue) {
                this[NavigationMixin.Navigate]({
                    type: 'standard__navItemPage',
                    attributes: {
                        apiName: 'Retail_Home_Page'
                    },
                }); 
            }
            else if(this.isFromHome) {
                this[NavigationMixin.Navigate]({
                    type: 'standard__navItemPage',
                    attributes: {
                        apiName: 'Retail_Home_Page'
                    },
                }); 
            } else {
                this[NavigationMixin.Navigate]({
                    type: 'standard__objectPage',
                    attributes: {
                        objectApiName: 'RetailCheckinQueue__c',
                        actionName: 'list'
                    },
                });
            }
        } else {
            this.handleReset(event);
            window.history.back();
        }

    }

    handleSubmit(event) {
        event.preventDefault();   
        this.isButtonDisabled = true;
        this.showSpinner = true;
        this.leadRecord['PreferredMethodofContact__c'] = 'SMS';
        this.leadRecord['CallConsent__c'] = 'No';
        this.leadRecord['SmsConsent__c'] = 'Yes';
        this.leadRecord['LeadSource'] = 'In-Store Check-in';
        this.leadRecord['DCICheckinType__c'] = 'Same Day';
        this.leadRecord['Store__c'] = this.leadStoreRecord.Id ;
        this.leadRecord['CustomerRequestedRep__c'] = '';
        this.selectedRepName != '' && this.selectedRepName!= 'Fist Available'? this.leadRecord['CustomerRequestedRep__c'] = this.selectedRepId: '';
        this.leadRecord['ReasonforLeaving__c'] = this.changedValue;
        this.leadRecord['PreferedLanguage__c'] = this.changedLanguageValue;
        this.retailCheckQueueRecord['Status__c'] = 'Arrived';
        if(this.helpButtonClicked){
            console.log('error1');
               this.handleSubmitOnHelpButtonClicked();
                return;
        }
        
        var newDate = new Date(); 
        console.log(' newDate.toISOString()' +  newDate.toISOString());
        this.retailCheckQueueRecord['CheckInTime__c'] =  newDate.toISOString();
        console.log('event.detail.id' + event.detail.id);
        // this.leadRecord.Id = event.detail.id;
                //Krishna Callout Info
                console.log('reason: *********' +this.changedValue);
       
                if(this.changedValue==='Pick up online order' && this.validateForm() ){
                   
                    orderCallOut({ BOPISOrder :this.leadRecord.DCIBOPISOrder__c, OrderPhNumber:this.leadRecord.MobilePhone})
                    .then(result => {
                        console.log('success1: *********'+result);
                        console.log('success2: status*********'+result.substring(0, result.indexOf("-")));
                        console.log('success2: Message*********'+result.substring(result.indexOf("-")+1, result.length));
                        
                        if(result.substring(0, result.indexOf("-"))==='250'){
                            this.dispatchEvent(
                                new ShowToastEvent({
                                title: this.label.Error,
                                message: result.substring(result.indexOf("-")+1, result.length),
                                variant: 'error'
                                }));
                                this.showSpinner = false;
                                this.isButtonDisabled = false;
                        
                        }else if(result.substring(0, result.indexOf("-"))==='404' || result.substring(0, result.indexOf("-"))==='400'){
                            this.dispatchEvent(
                            new ShowToastEvent({
                            title: this.label.Error,
                            message: result.substring(result.indexOf("-")+1, result.length),
                            variant: 'error'
                            }));
                            this.showSpinner = false;
                            this.isButtonDisabled = false;
                        }else if(result.substring(0, result.indexOf("-"))==='200') {
                            console.log('success31: *********'+result);
                            this.calloutSuccess=true;
                            console.log('success31: *********'+this.calloutSuccess);
                            console.log('success3: ***in after callout submission******');
                            
                            dciFormLwcHandleSubmit({
                            dciLeadApi: this.leadRecord,
                            newCheckinDci: this.retailCheckQueueRecord,
                            leadStore: this.leadStoreRecord,
                            selectedRepId: this.selectedRepId    
                            }) .then(result => {
                            this.handleSubmitResult(result, true);
                            }).catch(error => {  
                            this.handleSubmitErrors(error);
                            });
                        } else {
                            this.showSpinner = false;
                            this.isButtonDisabled = false;
                        }
                     
                    }).catch(error => {
                        console.log('Error1: *********'+error);
                    });
             
               }else{
        if(this.validateForm()) {
            dciFormLwcHandleSubmit({
                dciLeadApi: this.leadRecord,
                newCheckinDci: this.retailCheckQueueRecord,
                leadStore: this.leadStoreRecord,
                selectedRepId: this.selectedRepId    
            })




           /* createDCILead({
                dciLeadApi: this.leadRecord,
                newCheckinDci: this.retailCheckQueueRecord,
                leadStore: this.leadStoreRecord
            })*/
                .then(result => {
                    this.handleSubmitResult(result, true);
                }).catch(error => {   
                    this.handleSubmitErrors(error);
                });
        }  else {
            this.showSpinner = false;
            this.isButtonDisabled = false;
        }
    }
     }//krishna end
    handleSubmitOnHelpButtonClicked() {
        var newDate = new Date(); 
        console.log(' newDate.toISOString()' +  newDate.toISOString());
        this.retailCheckQueueRecord['CheckInTime__c'] =  newDate.toISOString();
       // console.log('event.detail.id' + event.detail.id);
        //this.leadRecord.Id = event.detail.id;
		console.log('reason: *********' +this.changedValue);
       
                if(this.changedValue==='Pick up online order' && this.validateForm() ){
                   
                    orderCallOut({ BOPISOrder :this.leadRecord.DCIBOPISOrder__c, OrderPhNumber:this.leadRecord.MobilePhone})
                    .then(result => {
                        console.log('success1: *********'+result);
                        console.log('success2: status*********'+result.substring(0, result.indexOf("-")));
                        console.log('success2: Message*********'+result.substring(result.indexOf("-")+1, result.length));
                        
                        if(result.substring(0, result.indexOf("-"))==='250'){
                            this.dispatchEvent(
                                new ShowToastEvent({
                                title: this.label.Error,
                                message: result.substring(result.indexOf("-")+1, result.length),
                                variant: 'error'
                                }));
                                this.showSpinner = false;
                                this.isButtonDisabled = false;
                        
                        }else if(result.substring(0, result.indexOf("-"))==='404' || result.substring(0, result.indexOf("-"))==='400'){
                            this.dispatchEvent(
                            new ShowToastEvent({
                            title: this.label.Error,
                            message: result.substring(result.indexOf("-")+1, result.length),
                            variant: 'error'
                            }));
                            this.showSpinner = false;
                            this.isButtonDisabled = false;
                        }else if(result.substring(0, result.indexOf("-"))==='200') {
                            console.log('success31: *********'+result);
                            this.calloutSuccess=true;
                            console.log('success31: *********'+this.calloutSuccess);
                            console.log('success3: ***in after callout submission******');
                            
                            dciFormLwcHandleSubmit({
                            dciLeadApi: this.leadRecord,
                            newCheckinDci: this.retailCheckQueueRecord,
                            leadStore: this.leadStoreRecord,
                            selectedRepId: this.selectedRepId    
                            }) .then(result => {
                            this.handleSubmitResult(result, true);
                            }).catch(error => {  
                            this.handleSubmitErrors(error);
                            });
                        } else {
                            this.showSpinner = false;
                            this.isButtonDisabled = false;
                        }
                     
                    }).catch(error => {
                        console.log('Error1: *********'+error);
                    });
             
               }else{
					if(this.validateForm()) {
						createDCILeadOnHelp({
							dciLeadApi: this.leadRecord,
							newCheckinDci: this.retailCheckQueueRecord,
							leadStore: this.leadStoreRecord
						})
							.then(result => {
								this.handleSubmitResult(result, false);
							}).catch(error => {   
								this.handleSubmitErrors(error);
							});
					}  else {
						this.showSpinner = false;
						this.isButtonDisabled = false;
					}
			   }	
    }
	handleSubmitResult(result, dciLeadCheck){
        let displayToastMessage = '';
        this.isOther = false;
        if(dciLeadCheck){
            this.leadid = result.dciResponseDTO.leadid;
            if(result.custReqRepName!= undefined){
                displayToastMessage = 'Success! You assigned '+ result.dciResponseDTO.leadName + ' to ' + result.custReqRepName;    
            }else {
                displayToastMessage =  'Success! You added  ' + result.dciResponseDTO.leadName + ' to the queue';    
            }
        }else{
            this.leadid = result.leadid;
            displayToastMessage =  'Success! You added  ' + result.leadName + ' to '+result.assignedRSC;
        }
		
		
		this.dispatchEvent(
			new ShowToastEvent({
				title: 'Success',
				message:  displayToastMessage,
				variant: 'success'
			})
		);
        /*if(this.customerToQueue){
            window.history.back();
            return;
        }*/
        
        if(this.helpButtonClicked){
            this.navigateToRetailCheckinDetail(result.checkinid);
            return;
        }
            else{
                if (this.prfName.includes('Rep')) {
                    this.navigateNext();
                } else {
                    this.navigateToRetailCheckinDetail(result.dciResponseDTO.checkinid);
                }
            }
		//this.navigateNext();
		this.showSpinner = false;
		this.isButtonDisabled = false;
		this.handleReset();
	}
	
	handleSubmitErrors(error){
		var message = error.body.message;
		if(message.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
		 this.dispatchEvent(
			 new ShowToastEvent({
				 title: 'Error',
				 message: this.label.DuplicateLeadDCI,
				 variant: 'error'
			 })
		 );
		}else{
		 this.dispatchEvent(
			 new ShowToastEvent({
				 title: 'Error',
				 message:  error.body.message,
				 variant: 'error'
			 })
		 );
		}
		 
		this.showSpinner = false;
		this.isButtonDisabled = false;
	}
    navigateToRetailCheckinDetail(retailchekinId) {
        console.log("hello1"+ retailchekinId);
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: retailchekinId,
                objectApiName: 'RetailCheckinQueue__c',
                actionName: 'view'
            }
        });
    }
    

    navigateToDetail() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.leadid,
                objectApiName: 'Lead',
                actionName: 'view'
            }
        });
    }

    navigateNext() {
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'Retail_Home_Page',
            }
        });
    }

    validateForm() {
        let allValid = true;
        let mobphone = this.leadRecord.MobilePhone;

        if(!this.validatePhoneNumber(mobphone)){
            allValid = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: this.label.Error,
                    message: this.label.PhoneFormatError,
                    variant: 'error'
                }));
        } 
        
        if (this.leadRecord.OtherNotes__c) {
            if(this.leadRecord.OtherNotes__c.length>1000){
                allValid = false;
                this.dispatchEvent(
                new ShowToastEvent({
                    title: this.label.Error,
                    message: 'Details of visit supports maximum of 1000 characters',
                    variant: 'error'
                }));
            }
        }

        if(this.leadRecord.ReasonforLeaving__c == null || this.leadRecord.ReasonforLeaving__c == ''){
            console.log('this.leadRecord.ReasonforLeaving__c' +this.leadRecord.ReasonforLeaving__c);
                  allValid = false;
                  this.dispatchEvent(
                  new ShowToastEvent({
                      title: this.label.Error,
                      message: 'The Reason for visit field is required for every check-in.',
                      variant: 'error'
                  }));
        }

 
        if(this.isOther && this.leadRecord.DCIOtherVisitReason__c === ''){
            allValid = false;
            this.dispatchEvent(
            new ShowToastEvent({
                title: this.label.Error,
                message: 'Be sure to enter information about why this customer is visiting the store.',
                variant: 'error'
            }));
        }

        if (this.leadRecord.FirstName === '') {
            allValid = false;
            this.dispatchEvent(
            new ShowToastEvent({
                title: this.label.Error,
                message: 'Please enter a valid first name',
                variant: 'error'
            }));
        }

        if (this.leadRecord.LastName === '') {
            allValid = false;
            this.dispatchEvent(
            new ShowToastEvent({
                title: this.label.Error,
                message: 'Please enter a valid last name',
                variant: 'error'
            }));
        }
        

        return allValid;
    }

    handleBindingFields(event) {
        if (event.target.value) {
            this.leadRecord[event.target.fieldName] = event.target.value.trim();
        }   
    
    }

    handleBindingField(event) {
        if (event.target.value) {
            this.leadRecord['DCIOtherVisitReason__c'] = event.target.value.trim();
        }
    }
        

    //krishna start
    handleBindingFieldBOP(event) {
        //Lakshmi
        const order =this.leadRecord['DCIOtherVisitReason__c'] = event.target.value.trim();
        if(order == 'Pick up online order'){
        this.leadRecord['DCIBOPISOrder__c'] = event.target.value.trim();
        }
        else{
            this.leadRecord['DCIBOPISOrder__c'] = '';
        }
        //Lakshmi
    }

  /*  get isOther() {
        if(this.leadRecord.ReasonforLeaving__c && this.leadRecord.ReasonforLeaving__c.toLowerCase() == 'get help with something else') {
            return true;
        }
        
        return false;
    }*/


    handleReset(event) {
        const inputFields = this.template.querySelectorAll(
            'lightning-input-field'
        );
        this.changedValue = '';
        if (inputFields) {
            inputFields.forEach(field => {
                field.reset();

            });
        }
        this.selectedRepId = '';
		this.selectedRepName = '';
        this.template.querySelector("c-employee-selection-picklist").handleResetPicklist();
    }
    
    validatePhoneNumber(strPhone) {
        var phoneRe = /^\(?([2-9]{1}[0-9]{2})\)?[-. ]?([0-9]{3})[-. ]?([0-9]{4})$/; 
        //var digits = strPhone.replace(/\D/g, "");
        return phoneRe.test(strPhone);

    }
}