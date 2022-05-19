import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import muleReconnect from '@salesforce/apex/Mule_Reconnect.muleReconnect';

export default class MuleDataFeedResubmit extends LightningElement {
    dataset = {
        selectedValue:"",
        startDate:"",
        endDate:"",
        transactionNumbers:"",
    }
    endpoint='';
    showSpinner=false;
    maxDate = Date();
    // get options() {
    //     return [
    //         { label: '-TEST-', value: 'Centers_Case_DAILY' },
    //         { label: 'Case Daily', value: 'caseDaily' },
    //         { label: 'Users Daily', value: 'usersDaily' },
    //         { label: 'IA Daily', value: 'iaDaily' },
    //         { label: 'OMNI Channel', value: 'omniChannel' },
    //     ];
    // }

    handleSubmit(){
        try {
            this.generatePayload();
            this.validateEntries();
            this.makeCalloutToEndpoint();
        } catch (error) {
            this.showSpinner=false;
            this.showNotification('error','Submission Failed',error.message);
        }
        
    }

    // handleChange(event) {
    //     this.dataset.selectedValue = event.detail.value;
    // }
    generatePayload(){
        try {
            let inp=this.template.querySelectorAll("lightning-input");
            inp.forEach(element =>{
                this.dataset[element.name] = element.value;
            });
        } catch (error) {
            console.log(error.message);
            console.log(error.stack);
            throw "Error getting input. Contact Admin"
        }
    }

    validateEntries(){
        if(this.dataset.selectedValue && this.dataset.transactionNumbers && !this.dataset.startDate && !this.dataset.endDate) return true
        if(this.dataset.selectedValue && !this.dataset.transactionNumbers && this.dataset.startDate && this.dataset.endDate && this.validateDates()) return true
        if(!this.dataset.selectedValue) throw new Error("Enter Data Feed name")
        if(!this.validateDates()) throw new Error("Enter valid dates for Start Date and End Date. Start Date and End date has to be a past date & time. End Date has to be after start date")
        throw new Error("Enter Data Feed, then Select Transaction Numbers OR Start Date/Time & End Date/Time")   
    }
    validateDates(){
        let sd = Date.parse(this.dataset.startDate);
        let ed = Date.parse(this.dataset.endDate);
        let cur = Date.now();
        if(sd < cur && sd<ed) return true;
        return false;
    }

    checkEndDate(event){
        let edv = event.currentTarget.value;
        let edErrOverflow = event.currentTarget.messageWhenRangeOverflow;
        edErrOverflow = "End date has to be after start date"
        if(Date.parse(edv)>Date.now()){
            edErrOverflow = "End date has to be a past date";
        }
    }
    checkDates(event){
        let sd = this.template.querySelector(`[data-id="startDate"]`);
        let ed = this.template.querySelector(`[data-id="endDate"]`);

        try {
            if(Date.parse(sd.value)>Date.parse(ed.value)){
                ed.messageWhenRangeOverflow = "End date has to be after start date";
            }
            if(Date.parse(edv)>Date.now()){
                ed.messageWhenRangeOverflow = "End date has to be a past date";
            }  
        } catch (error) {
            
        }
    }
    makeCalloutToEndpoint(){
        this.showSpinner=true;
        muleReconnect({
            jobType:this.dataset.selectedValue,
            startDateTime:this.dataset.startDate,
            endDateTime:this.dataset.endDate,
            transactionNumbers:this.dataset.transactionNumbers
        })
        .then(()=>{
            this.showNotification('success','','Submission Successful');
            this.showSpinner=false;
        })
        .catch(error=>{
            this.showSpinner=false;
            this.showNotification('error','Submission Failed',`Submission Failed: ${error.body.message}. Please contact MuleSoft Ops`);
        })
    }

    showNotification(variant,title,msg) {
        const evt = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant,
            mode:"sticky"
        });
        this.dispatchEvent(evt);
    }
}