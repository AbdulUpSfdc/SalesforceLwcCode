import { LightningElement, track, api, wire } from 'lwc';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

//apex
import getQueues from'@salesforce/apex/BWC_OverrideRoutingActionController.getQueue';

//case fields
import RECORD_ID from "@salesforce/schema/Case.Id";
import CASE_OWNER from "@salesforce/schema/Case.OwnerId";
import CASE_STATUS_FIELD from '@salesforce/schema/Case.Status';

const CASE_FIELDS = [
    CASE_OWNER,
    CASE_STATUS_FIELD,
   
];

const CANCELLED_STATUS = 'Cancelled';
const CLOSED_STATUS = 'Closed';
const MERGED_STATUS = 'Merged';
const CASE_NEW_STATUS = 'New'; // Mohammad Rahman MSS_307628564 3/4/2022 

const CLOSED_STATUSES = [
    CANCELLED_STATUS,
    CLOSED_STATUS,
    MERGED_STATUS,
]

export default class OverrideRoutingAction extends LightningElement {
@api recordId;

@track allQueues;
@track queueOptions;
@track selectedValue;
@track intcomments;
@track isLoading=true;
@track isCaseClosed = false;
@track currentCase;

@wire(getRecord, {recordId: '$recordId', fields: CASE_FIELDS })
wiredCase({error, data}){
    console.log(data);
    if(data){
        this.currentCase = data;
        let caseStatus = getFieldValue(this.currentCase, CASE_STATUS_FIELD);
        console.log('caseStatus***'+caseStatus);
        if(CLOSED_STATUSES.some((status)=>status===caseStatus)){
            this.isCaseClosed = true;
            this.isLoading=false;
            return;
        }
    }
}


@wire(getQueues, {})
WiredGetQueues({ error, data }) {
    if (data) {
        //hide spinner
        this.isLoading=false;
        try {
            this.allQueues = data; 
            let options = [];   
            for (var key in data) {
                options.push({ label: data[key].Queue.Name, value: data[key].QueueId });
                }
                this.queueOptions = options; 
            } catch(error){
                BwcUtils.error(error);
            }
        } 
    }
 
    handleTypeChange(event){
        this.selectedValue = event.target.value; 
    }

    handleSubmit(event){
         console.log('In Handle Submit');
         const fields = {};
            fields[RECORD_ID.fieldApiName] = this.recordId;
            fields[CASE_OWNER.fieldApiName] = this.selectedValue;
            fields[CASE_STATUS_FIELD.fieldApiName] = CASE_NEW_STATUS;// Mohammad Rahman MSS_307628564 3/4/2022
            const recordInput = { fields };
            try{
                updateRecord(recordInput);
    
                //Notify Aura wrapper, so quickAction is closed
                this.dispatchEvent(new CustomEvent('caseupdated'));
    
                const event = new ShowToastEvent({
                    "variant": "success",
                    "title": "Success",
                    "message": "The case was updated!",
                });
                this.dispatchEvent(event);
    
                }   catch(error){
                    BwcUtils.error('Error updating case Routing Action component');
                    BwcUtils.error(error);
                    let errorMessage = '';
        
                    //Errors related to the record
                    if(error?.body?.output?.errors){
                        for(let outputError of error.body.output.errors){
                            BwcUtils.log({outputError});
                            //IF user doesn't have access to the record (User not in QUEUE) show a more friendly error message
                            if(outputError.errorCode === 'INSUFFICIENT_ACCESS_OR_READONLY'){
                                errorMessage+=' \n User does not have access to the Case Record';
                            }else{
                                errorMessage+=' \n'+outputError.message;
                            }
                        }
                    }
        
                    this.showErrorMessage(errorMessage);
                    //hide spinner
                    this.isLoading = false;
                }
    }
   

}