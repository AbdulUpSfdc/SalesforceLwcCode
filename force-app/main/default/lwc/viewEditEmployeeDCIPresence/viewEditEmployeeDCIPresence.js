import { LightningElement, wire, track,api } from 'lwc';
import getAvailableReps from '@salesforce/apex/DCIUtil.getAvailableReps';
import checkIfRepBusywithCustomer from '@salesforce/apex/DCIUtil.checkIfRepBusywithCustomer';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updateDCIPresenceOfEmployee from '@salesforce/apex/DCIController.updateDCIPresenceOfEmployee';
import updateMoDStatusOfRep from '@salesforce/apex/DCIController.updateMoDStatusOfRep';
import { NavigationMixin } from 'lightning/navigation';
import IS_MANAGER_ON_DUTY from '@salesforce/schema/EmployeeStoreRetail__c.IsManagerOnDuty__c';
import ID_FIELD from '@salesforce/schema/EmployeeStoreRetail__c.Id';
import getEmployeeStoreRetail from '@salesforce/apex/DCIController.getEmployeeStoreRetail';
import getInitialData from '@salesforce/apex/DCIController.getInitialData';

export default class ViewEditEmployeeDCIPresence extends NavigationMixin(LightningElement) {
    @track page = 1; //this will initialize 1st page
    @track items = []; //it contains all the records.
    @track data = []; //data to be displayed in the table
    @track columns; //holds column info.
    @track startingRecord = 1; //start record position per page
    @track endingRecord = 0; //end record position per page
    @track pageSize = 4; //default value we are assigning
    @track totalRecountCount = 0; //total record count received from all retrieved records
    @track totalPage = 0; //total number of page is needed to display all records

    @track empList =[];
    @track empListTemp =[];
    @track showSpinner = false;                   
    @track value;
    @track isValidated = false;
    @track isReload = false;
    @track EmployeeDetails = {};
    storeId;
    selectedRecordId;
    selectedEmpName;
    selectedEmpId;
    esrRecord;
    isMangerOnDuty;
    isComponentLoaded = false;
    setIsManagerOnDuty = false;   // to show set manager on duty popup
    unSetIsManagerOnDuty = false; // to show remove manager on duty
    header = '';
    showSetButton = false;
    showUnSetButton = false;
    showCancelButton = false;
    showButtonName = '';
    showModal = false;
    homeStoreId;
    setUnsetManagerOnDuty

    get options() {
        return [
            { label: 'Online', value: 'Online' },
            { label: 'Busy', value: 'Busy' },
            { label: 'Offline', value: 'Offline' },
        ];
    }

    //clicking on previous button this method will be called
    previousHandler() {
        if (this.page > 1) {
            this.page = this.page - 1; //decrease page by 1
            this.displayRecordPerPage(this.page);
            this.template.querySelector("c-paginator-bottom").enableNext(); 
        }
        if(this.page==1)
        this.template.querySelector("c-paginator-bottom").disablePrevious();
    }

    //clicking on next button this method will be called
    nextHandler() {
        if((this.page<this.totalPage) && this.page !== this.totalPage){
            this.page = this.page + 1; //increase page by 1
            this.displayRecordPerPage(this.page);    
            this.template.querySelector("c-paginator-bottom").enablePrevious();   
            if(this.totalPage == this.page)
            this.template.querySelector("c-paginator-bottom").disableNext();  
        }             
    }

    //this method displays records page by page
    displayRecordPerPage(page){
        this.startingRecord = ((page -1) * this.pageSize) ;
        this.endingRecord = (this.pageSize * page);

        this.endingRecord = (this.endingRecord > this.totalRecountCount) 
                            ? this.totalRecountCount : this.endingRecord; 

        this.empList = this.empListTemp.slice(this.startingRecord, this.endingRecord);
        this.startingRecord = this.startingRecord + 1;
    }

    @wire(getAvailableReps, { recordId: '', actionType: 'newCheckIn'})
    getAvailableReps({ error, data }) {
        if (data) {

                this.items = data;
                for(let i=0; i<this.items.length; i++){
                    let iconName ='';
                    let varaint = '';
                    if(this.items[i].IsManagerOnDuty__c){
                        iconName ='utility:check';
                        varaint = 'brand';
                    }
                    else
                        iconName ='utility:add';

                    let tempList = {    Id: this.items[i].Id, 
                                        Name: this.items[i].Employee__r.Name, 
                                        Status: this.items[i].DCIPresenceStatus__c,
                                        User: this.items[i].User__c,
                                        Store: this.items[i].Store__c,
                                        MoDiconName: iconName,
                                        varaint : varaint
                                    }
                    this.empListTemp.push(tempList);
                }
            if(this.empListTemp.length > 0)
            this.homeStoreId = this.empListTemp[0].Store;
            this.totalRecountCount = data.length; 
            this.totalPage = Math.ceil(this.totalRecountCount / this.pageSize); 
                        
            this.empList = this.empListTemp.slice(0,this.pageSize); 
            this.endingRecord = this.pageSize; 

        }
    }
                 
    handleChange(event) {
        this.value = event.detail.value;
        this.esrRecord = event.target.name;

        this.selectedRecordId = this.esrRecord.Id;
        this.selectedEmpName = this.esrRecord.Name;
        this.selectedEmpId = this.esrRecord.User;
        this.storeId = this.esrRecord.Store;

        if(this.value == 'Offline')
            this.isReload = true;
        
        if(this.selectedEmpId && this.selectedRecordId){
            this.showSpinner = true;
            this.validateUpdateRequest();
        }
    }

    validateUpdateRequest()
    {
        checkIfRepBusywithCustomer({repId: this.selectedEmpId, storeId: this.storeId})
        .then((result) =>{
            this.isValidated = result;
            if(this.isValidated){
                this.updateESR();
            }
            else{
                this.showSpinner = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: this.selectedEmpName + ' is engaged with an active customer and the customer will need to be closed or reassigned before changing that reps status.',
                        variant: 'error'
                    })
                )
            }
        })
    }
    
    updateESR(){
        updateDCIPresenceOfEmployee({recordId: this.selectedRecordId, DCIStatus: this.value, storeId: this.storeId})
        .then(() =>{
            this.showSpinner = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success!',
                    message: 'Success! '+ this.selectedEmpName + ' status is updated.',
                    variant: 'success'
                })
            )
            if(this.isReload)
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
        })
    }
    updateMoDStatus(){
        updateMoDStatusOfRep({recordId: this.selectedRecordId, ModStatus: this.isMangerOnDuty})
        .then(() =>{
            this.showSpinner = false;
            this.handleAssignUsertoPublicGroup();
            //window.location.reload();
        })
    }

    closeModal() {
        this.showModal = false;
    }

    handleManagerOnDuty(event){
        this.value = event.target.value;
        this.esrRecord = event.target.name;
        this.selectedRecordId = this.esrRecord.Id;
        console.log('InsideMethod' + event.target.value);
        this.selectedEmpName = this.esrRecord.Name;
        this.selectedEmpId = this.esrRecord.User;
        this.storeId = this.esrRecord.Store;

        console.log('this.esrRecord===' , this.esrRecord);
        if(event.target.value == 'utility:add')
            this.isMangerOnDuty = true;
        else
            this.isMangerOnDuty = false; 
        
        this.isReload = true;
        // this.updateRepModStatus();  
        
        if (!this.isMangerOnDuty) {
            this.setIsManagerOnDuty = false;
            this.showModal = true;
            this.header = 'Remove rep as manager on duty';
            this.showUnSetButton = true;
            this.showCancelButton = true;
            this.showButtonName = 'Remove';
        } else {
            this.setIsManagerOnDuty = true;
            this.showModal = true;
            this.header = 'Set rep as manager on duty';
            this.showSetButton = true;
            this.showCancelButton = true;
            this.showButtonName = 'Set';
        
        }
    }

handleSetIsManagerOnDuty() {
    const fields = {};
    fields[ID_FIELD.fieldApiName] = this.selectedRecordId;
    fields[IS_MANAGER_ON_DUTY.fieldApiName] = true;

    const recordInput = {
        fields: fields
    };
    this.showModal = false;
    this.setUnsetManagerOnDuty = true;
    this.updateMoDStatus();
}

handleUnSetIsManagerOnDuty() {
    const fields = {};
    fields[ID_FIELD.fieldApiName] = this.selectedRecordId;
    fields[IS_MANAGER_ON_DUTY.fieldApiName] = false;

    const recordInput = {
        fields: fields
    };
    this.showModal = false;
    this.setUnsetManagerOnDuty = false;
    this.updateMoDStatus();
}

showNotification(title, message, varaint){
    const successToast = new ShowToastEvent({
        title : title,
        message : message,
        variant : varaint
    });
    this.dispatchEvent(successToast);
}

handleAssignUsertoPublicGroup() {
    this.showSpinner = true;
    getEmployeeStoreRetail({ recordId: this.selectedRecordId, setUnsetManagerOnDuty: this.setUnsetManagerOnDuty })
        .then(() => {
            if (this.setUnsetManagerOnDuty) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success!',
                        message: 'You successfully set '+ this.selectedEmpName + ' as manager on duty', 
                        variant: 'success'
                    })
                )
            }
            else {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success!',
                        message: 'You successfully removed '+ this.selectedEmpName + ' as manager on duty', 
                        variant: 'success'
                    })
                ) 
            }
            
            this.empList = Array.from(this.empList).map(emp => {
                let newEmp = { ...emp };
                if (newEmp.Id == this.selectedRecordId) {
                    newEmp.IsManagerOnDuty__c = setUnsetManagerOnDuty;
                    newEmp.MoDiconName = newEmp.IsManagerOnDuty__c ? 'utility:check' : 'utility:add';
                    newEmp.varaint = newEmp.IsManagerOnDuty__c ? 'brand' : '';

                }
                return newEmp;
            });

            console.log('empList===' , JSON.stringify(this.empList));
            this.showSpinner = false;
            window.location.reload();
   
        })
        .catch(error => {
            this.showSpinner = false;
            window.location.reload();
            //this.showNotification('Error', 'ExceptionError', 'error');
        })

    }
    redirectToHomeStore() {
        console.log('result*** '+ this.homeStoreId);
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.homeStoreId,
                objectApiName: 'Store__c',
                actionName: 'view'
            }
        });
    }
    
    
    connectedCallback() {    
        getInitialData()
        .then(data => {
            this.EmployeeDetails = data.employeeDetails;
                if(this.EmployeeDetails){
                console.log(this.EmployeeDetails);
                this.homeStoreId = this.EmployeeDetails.Store__c;
                console.log('@@@: '+ this.homeStoreId);
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
    
}