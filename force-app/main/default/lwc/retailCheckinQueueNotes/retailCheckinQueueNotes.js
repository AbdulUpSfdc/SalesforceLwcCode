import {LightningElement, api, track, wire} from 'lwc';
// importing apex class methods
import getNotes from '@salesforce/apex/DCIController.getAllNotes';
// datatable columns with row actions
export default class RetailCheckinQueueNotes extends LightningElement {
@api recordId;
@track data;		
// reactive variable
 
 @wire(getNotes,{
   RCQId:'$recordId'
}) notesData;
   

}