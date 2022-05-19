import { LightningElement, wire, api, track } from 'lwc';
import formFactor from '@salesforce/client/formFactor';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getInitialData from '@salesforce/apex/DCIController.getInitialData';
import getNextCheckinCustomer from '@salesforce/apex/DCIController.getCustomer';
import changeRepStatus from '@salesforce/apex/DCIController.changeRepStatus';
import cancelAllCheckins from '@salesforce/apex/DCIController.cancelAllCheckins';
import updateRepStatus from '@salesforce/apex/DCIController.updateRepStatus';
import displayStoreManagementTab from '@salesforce/apex/DCIController.displayStoreManagementTab';
export default class DCIHomeCmp extends NavigationMixin(LightningElement) {
    @track EmployeeDetails = {};
    @track StoreDetails = {};
    @track isManager = true;
    @track isRepOnline = false;
    @track isRepBusy = false;
    @track showHomePage = true;
    @track url;
    @track customersArrivedCount;
    @track value = '';
    @track openModal = false;
    @track disableButton = true;
    @track cancellationReason = "";
    @track options ;
    @track showCancelButton = false;
    displaySMTab = true;
	
    showModal() {
        this.openModal = true;
    }
    closeModal() {
        this.openModal = false;
    }
    cancelAllCheckins() {
		cancelAllCheckins({
            cancellationReason: this.cancellationReason,
            storeId: this.StoreDetails.Id 
        })
        .then(data => { 
            console.log(data);
			if(data == "All Checkins Cancelled"){
				this.openModal = false;
				const toastEvent = new ShowToastEvent({
					title: 'Success',
					message: 'Success! You canceled all remaining check-ins at the store today',
					variant: 'success'
				});
				this.dispatchEvent(toastEvent); 
			}
			else{
				const toastEvent = new ShowToastEvent({
					title: 'Error',
					message: data,
					variant: 'error'
				});
				this.dispatchEvent(toastEvent); 
			}
            
          
        }).catch(error => {
			const toastEvent = new ShowToastEvent({
				title: 'Error',
				message: 'Error! '+JSON.stringify(error),
				variant: 'error'
			});
			this.dispatchEvent(toastEvent);
            console.log("Error thrown in getCustomer" + JSON.stringify(error));
         });
    }
    handleChange(event) {
        this.cancellationReason = event.detail.value;
        if(event.detail.value != null && event.detail.value != '')
        this.disableButton = false;
    }
    connectedCallback(){
        this.displayStoreManagementTab();
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__component',
            attributes: {
                componentName: 'c__dciForm'
            },
            state : {
                c__isFromHome : 'true'
            }
        }).then((url) => (this.url = url));
        console.log('url');


        getInitialData()
        .then(data => {
            this.EmployeeDetails = data.employeeDetails;
            this.customersArrivedCount = data.customerArrivedCount;
            this.options = data.massCancellationReason;
                if(this.EmployeeDetails){
                console.log(this.EmployeeDetails);
                this.StoreDetails = this.EmployeeDetails['Store__r'];
                console.log(this.StoreDetails);
                if(this.EmployeeDetails.SFProfileId__c === 'RSC-REP'&& this.EmployeeDetails.IsManagerOnDuty__c == false)
                    this.isManager = false;
                if(this.EmployeeDetails.DCIPresenceStatus__c === 'Online' || this.EmployeeDetails.DCIPresenceStatus__c === 'Busy')
                    this.isRepOnline = true;
                if(this.EmployeeDetails.DCIPresenceStatus__c === 'Busy' || data.hasCustomerEngaged == true)
                    this.isRepBusy = true;
                    if(data.pendingRecordsCount > 0 && this.isManager)
                    this.showCancelButton = true;
            }else{
                this.showHomePage = false;
                const toastEvent = new ShowToastEvent({
                    title: 'Error',
                    message: 'No store association data found for logged in user.',
                    variant: 'error',
                    mode:'sticky'
                });
                this.dispatchEvent(toastEvent);
                
            }
            
        }).catch(error => {   
            console.log("Error thrown in getInitialData" + JSON.stringify(error));
         });
    }
    updateRepStatus(){
        updateRepStatus()
        .then(data => { 
           

          
        }).catch(error => {   
            console.log("Error thrown in update rep status" + JSON.stringify(error));
         });
    }
    displayStoreManagementTab(){
        displayStoreManagementTab()
         .then(data => { 
           this.displaySMTab = data;

          
        }).catch(error => {   
            console.log("Error thrown in get display tab" + JSON.stringify(error));
         });
    }
    getCustomer(event){
        getNextCheckinCustomer({
            empStore: this.EmployeeDetails,
            store: this.StoreDetails 
        })
        .then(data => { 
            console.log(data);
            var customerInfo = data;
            if(customerInfo && customerInfo.checkinId){
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: customerInfo.checkinId,
                        objectApiName: 'RetailCheckinQueue__c',
                        actionName: 'view'
                    }
                });
            }else{
                const toastEvent = new ShowToastEvent({
                    title: 'Warning',
                    message: customerInfo.message,
                    variant: 'warning'
                });
                this.dispatchEvent(toastEvent);
            }  
          
        }).catch(error => {   
            console.log("Error thrown in getCustomer" + JSON.stringify(error));
         });
    }

    changeRepStatus(event){
        var Status = event.target.name;
        console.log(Status);

        changeRepStatus({
            status: Status,
            empStore: this.EmployeeDetails 
        })
        .then(data => {  
            const toastEvent = new ShowToastEvent({
                title: 'Success',
                message: 'Presence status changed successfully to '+Status,
                variant: 'success'
            });
            this.dispatchEvent(toastEvent);     
            window.location.reload();
        }).catch(error => {   
            console.log("Error thrown in changeRepStatus" + JSON.stringify(error));
        });
    }

    navigateToNewCheckin() {
      /*  this[NavigationMixin.Navigate]({
            type: 'standard__component',
            attributes: {
                componentName: 'c__dciForm'
            },
            state : {
                c__isFromHome : 'true'
            }
        });  */
        location.href = this.url;   
    }

    refreshPage(){
        window.location.reload();
    } 
}