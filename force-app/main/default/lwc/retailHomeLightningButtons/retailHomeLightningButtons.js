import { LightningElement, wire, api, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import updateIsCurrentlyAvailable from '@salesforce/apex/RetailHomePageController.updateIsCurrentlyAvailable';
import getIsCurrentlyAvailable from '@salesforce/apex/RetailHomePageController.getIsCurrentlyAvailable';
import getCurrentUserforWalkinCustomer from '@salesforce/apex/RetailHomePageController.getCurrentUserforWalkinCustomer';
import getInitialData from '@salesforce/apex/DCIController.getInitialData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import getRetailQueues from '@salesforce/apex/customerUpNextController.getRetailQueues';
import changeCustomerStatus from '@salesforce/apex/DCIChangeCustomerStatusController.changeCustomerStatus';
import getNextCheckinCustomer from '@salesforce/apex/DCIController.getCustomer';
import Id from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.Name';
import cancelAllCheckins from '@salesforce/apex/DCIController.cancelAllCheckins'; //tapaswini
import getCustomer from '@salesforce/apex/DCIController.getBusyCustomer';
import DCIcheckIfBusywithCustomer from '@salesforce/apex/DCIController.DCIcheckIfBusywithCustomer';

export default class RetailHomeLightningButtons extends NavigationMixin(LightningElement) {
    @wire(CurrentPageReference) pageRef;
    @track EmpIsCurrentlyAvailable=false;
    @track currentlyAvailableRep = false;
    @track retailCheckinQueueExists = false;
    @track retailWalkinCustomerProfile = false;
    @track retailHelpNextCustomerProfile = false;
    @track showNextCustomerName = false;
    @track HelpNextCustomerClicked = false;
    @track isNextCustomerAvailable = false;
    @track isRepBusy=false;
    @track currentUserName = '';
    @track retailQueueNextPerson = [];
    @track nextPersoninQueue = '';
    @track nextPersonId = '';
    @track url;
    @track StoreDetails = {};
    @track EmployeeDetails = {};
    @track showCurrentLoggedInUser = false;
    @track showcancelcheckin = false;	
    @track openModal = false;	
    showcancelall=true;
    @track showCustInfo = false;
    @track custmerName;
    @track CustId;

    showModal() {	
      this.openModal = true;	
      }	
      closeModal() {	
          this.openModal = false;	
      }	
      cancelAllCheckins() {	
          //tapaswini
          let inputFields = this.template.querySelector(".cancelcombobox");
          let value = inputFields.value;
          if (value == undefined) {
              inputFields.setCustomValidity("");
              inputFields.reportValidity();
              return;
          } 
          //upto
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
    connectedCallback() {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__component',
            attributes: {
                componentName: 'c__dciForm'
            },
            state: {
                c__isFromHome: 'true',
                c__customerToQueue: 'true'
            }
        }).then((url) => (this.url = url));

        /*getInitialData()
            .then(data => {
                if (data.employeeDetails) {
                    this.EmployeeDetails = data.employeeDetails;
                    this.StoreDetails = data.employeeDetails['Store__r'];
                    console.log('store details===' + this.StoreDetails);
                }
            }).catch(error => {
                console.log("Error thrown in getInitialData" + JSON.stringify(error));
            });*/

            getInitialData()
            .then(data => {
            this.EmployeeDetails = data.employeeDetails;
                if(this.EmployeeDetails){
                console.log(this.EmployeeDetails);
                this.StoreDetails = this.EmployeeDetails['Store__r'];
                //this.EmpIsCurrentlyAvailable = this.EmployeeDetails['IsCurrentlyAvailable__c'];
                this.EmpIsCurrentlyAvailable = (this.EmployeeDetails['SFProfileId__c'] == 'RSC-MGR'?true:(this.EmployeeDetails['SFProfileId__c'] == 'RSC-REP'? this.EmployeeDetails['IsCurrentlyAvailable__c'] : false));
                console.log(' The Employee Current Availability is '+this.EmployeeDetails['IsCurrentlyAvailable__c']);
                console.log(this.StoreDetails);
                this.customersArrivedCount = data.customerArrivedCount;
                this.options = data.massCancellationReason;   
                var profile = this.EmployeeDetails.SFProfileId__c;
                //var ismanager = this.EmployeeDetails.IsManagerOnDuty__c;
                //this.showcancelcheckin=false;
                //this.showcancealll= true;
                
                //if(data.hasCustomerEngaged == true || data.pendingRecordsCount.size() == 0)
                    //this.isRepBusy = true;  
                      //tapaswini	

                    if (this.EmployeeDetails.SFProfileId__c == "RSC-MGR" && (data.customerArrivedCount > 0 || data.pendingRecordsCount > 0)){
                        this.showcancelall =true;
                    }
                    if ((this.EmployeeDetails.SFProfileId__c == "RSC-REP" && this.EmployeeDetails.IsManagerOnDuty__c == true) && (data.customerArrivedCount > 0 || data.pendingRecordsCount > 0)){
                        this.showcancelall =true;
                    }

                    /*  if (this.EmployeeDetails.SFProfileId__c == "ARSM" || this.EmployeeDetails.SFProfileId__c == "Retail DOS"
                        || this.EmployeeDetails.SFProfileId__c == "Retail AVP"){
                        this.showcancelall = false;
                    }

                    if(data.customerArrivedCount == 0 && data.pendingRecordsCount == 0 &&
                        this.EmployeeDetails.SFProfileId__c != "RSC-REP" && this.EmployeeDetails.IsManagerOnDuty__c == false){      
                       this.showcancelcheckin =true;
                   }
                   else if(data.customerArrivedCount == 0 && data.pendingRecordsCount == 0 &&
                       this.EmployeeDetails.SFProfileId__c == "RSC-MGR"){ 
                      this.showcancelcheckin =true;
                  }
                  else if ((data.customerArrivedCount > 0 || data.pendingRecordsCount > 0) && (this.EmployeeDetails.IsManagerOnDuty__c && profile == "RSC-REP") ){
                           this.showcancelcheckin = false;
                           this.showcancelall = true;
                    }
                   else if (data.customerArrivedCount == 0 && data.pendingRecordsCount == 0 && this.EmployeeDetails.IsManagerOnDuty__c && profile == "RSC-REP") {
                               this.showcancelcheckin = true;
                               this.showcancelall = true;
                    }

               else if(this.EmployeeDetails.SFProfileId__c == "RSC-REP" && this.EmployeeDetails.IsManagerOnDuty__c == false) {
                   this.showcancelcheckin= true;
                   this.showcancelall = false;
               }*/

                    
                    
                if(this.EmployeeDetails.DCIPresenceStatus__c === 'Busy' || data.hasCustomerEngaged == true)
                    this.isRepBusy = true;                
                
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

        getCurrentUserforWalkinCustomer()
            .then(result => {
                this.retailWalkinCustomerProfile = result;
                if (result == true)
                    this.retailHelpNextCustomerProfile = false;
                else
                    this.retailHelpNextCustomerProfile = true;
            }).catch(error => {
                console.log(error);
            });

        getIsCurrentlyAvailable()
            .then(result => {

                this.currentlyAvailableRep = result;

            }).catch(error => {
                console.log(error);
            });

        getCustomer()
        .then(result => { 
            if(result != 'null'){             
            this.custmerName=result.Lead__r.Name;
            this.CustId=result.Id;
            this.showCustInfo=true;
            }
        })
        .catch(error => {
            console.log(error);
        });

        // Instead of this we will get next customer.
        // this.getQueues(this.params);
       // this.inactivityTime();
    }

    // Not Required as different method and logic is used 
    /* get params(){
    return { limitVal : 499};
    }*/

    // Fetch the Current Logged in User Name
    @wire(getRecord, { recordId: Id, fields: [NAME_FIELD] })
    userDetails({ error, data }) {
        if (error) {
            console.log('the error from getRecord is ' + JSON.stringify(error));
        } else if (data && data.fields.Name.value != null) {
            console.log('The logged in Username is ' + data.fields.Name.value);
            //console.log(data.fields.Name.value);
            this.currentUserName = data.fields.Name.value;
            // Fetch the Next Queue Person
            this.ShowNextCust();
        }
    }

    ShowNextCust() {
        this.showNextCustomerName = true;
        getRetailQueues({ limitVal: 499 })
            .then(result => {
                //alert(result);
                if (result != null && result != '') {
                    this.retailCheckinQueueExists = true;
                }
                else {
                    this.isNextCustomerAvailable = true;
                }
                console.log('The retailQueue is ' + JSON.stringify(result));
                for (let i = 0; i < result.length; i++) {
                    var currentItem = result[i];
                    console.log('Inside for loop');
                    if (currentItem.CustomerRequestedRep__c == this.currentUserName) {
                        this.showCurrentLoggedInUser = true;
                        console.log('Inside if Condition');
                        this.retailQueueNextPerson = currentItem;
                        this.nextPersoninQueue = currentItem.Name;
                        this.nextPersonId = currentItem.Id;
                        break;
                    }
                }
                if (!this.showCurrentLoggedInUser) {
                    for (let i = 0; i < result.length; i++) {
                        var currentItem = result[i];
                        console.log('Inside for loop');
                        if (currentItem.CustomerRequestedRep__c == undefined) {
                            this.retailQueueNextPerson = currentItem;
                            this.nextPersoninQueue = currentItem.Name;
                            this.nextPersonId = currentItem.Id;
                            break;
                        }
                    }
                }

                console.log('outside of loop');
            })
            .catch(error => {
                console.log(error);
                // TODO Error handling
            });
    }
    NextCustomer() {
        this.showNextCustomerName = true;
        //alert(this.nextPersonId);
        changeCustomerStatus({ recordId: this.nextPersonId, action: 'HelpNextCustomer' })
            .then(result => {
                console.log(result);
                if (result != null && result != '') {

                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: this.nextPersonId,
                            objectApiName: 'RetailCheckinQueue__c',
                            actionName: 'view'
                        }
                    });

                }
            })
            .catch(error => {
                console.log(error);
                // TODO Error handling
            });

    }

    OpenNewCheckinForm() {
        /*if(this.isRepBusy){
            const toastEvent = new ShowToastEvent({
                title: 'Warning',
                message : 'You are currently busy with a customer, a new customer cannot be assigned to you.',
                variant: 'warning'
            });
            this.dispatchEvent(toastEvent);
        }
        else{*/

            DCIcheckIfBusywithCustomer()
            .then(data => { 
                if(!data){
                    location.href = this.url;
                }else{
                   const toastEvent = new ShowToastEvent({
                        title: 'Warning!',
                        message : 'You are currently busy with a customer, a new customer cannot be assigned to you.',
                        variant: 'warning',
                    });
                    this.dispatchEvent(toastEvent);
                    window.location.reload();
                }  
            
            }).catch(error => {   
                console.log("Error thrown in getCustomer" + JSON.stringify(error));
                const toastEvent = new ShowToastEvent({
                    title: 'Warning',
                    message: 'An unexpected error occurred. Please try again.',
                    variant: 'warning'
                });
                this.dispatchEvent(toastEvent);
            });
        //}
        
    }

    // Anvesh start CDEX:85663
    getCustomer(event){
        /*if(this.showCustInfo){        
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__recordPage',
                attributes: {
                    "recordId": this.CustId,
                        "objectApiName": "RetailCheckinQueue__c",
                        "actionName": "view"
                },
            }).then((url) => {
                const event = new ShowToastEvent({
                    title: 'Warning!',
                    //message: "You're still helping "+this.custmerName+" {1}?",
                    message : 'You are currently busy with a customer, a new customer cannot be assigned to you.',
                    variant: 'warning',
                    messageData: [
                        'Salesforce',
                        {
                            url,
                            label:'Close out',
                        },
                    ],
                });
                this.dispatchEvent(event);
                //window.location.reload();
            });
        }
        else{ */
            getNextCheckinCustomer({
                empStore: this.EmployeeDetails,
                store: this.StoreDetails 
            })
            .then(data => { 
                console.log(data);
                var customerInfo = data;
                if(customerInfo && customerInfo.checkinId){
                    //location.assign('/lightning/r/RetailCheckinQueue__c/'+customerInfo.checkinId+'/view');
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
                    window.location.reload();
                }  
            
            }).catch(error => {   
                console.log("Error thrown in getCustomer" + JSON.stringify(error));
                const toastEvent = new ShowToastEvent({
                    title: 'Warning',
                    message: 'An unexpected error occurred. Please try again.',
                    variant: 'warning'
                });
                this.dispatchEvent(toastEvent);
            });
        //}
        // this.updateRepStatus();
    }
// Anvesh  end CDEX:85663

    //Abhilash Chikoti
    /*inactivityTime() {
        var time;
        window.onload = resetTimer;
        //DOM Events
        document.onmousemove = resetTimer;
        document.onkeydown = resetTimer;
        document.ontouchstart = resetTimer;
        //Touchpad clicks
        document.onclick = resetTimer;
        //document.onkeydown = resetTimer;

        function logout() {

            var isAvailable = false;
            updateIsCurrentlyAvailable({ currentlyAvailable: isAvailable })
                .then(data => {

                }).catch(error => {

                });

            //window.location.reload();
        }

        function resetTimer() {
            clearTimeout(time);
            time = setTimeout(logout, 600000);
            //1000 milliseconds = 1 second   6000000
        }
    }*/
    navigateToNewCheckin() {
       location.href = this.url;
       /*this[NavigationMixin.Navigate]({
        "type": "standard__webPage",
        "attributes": {
            "url": "/lightning/cmp/c__dciForm?c__isFromHome=true"
        }
    });*/
    }
}