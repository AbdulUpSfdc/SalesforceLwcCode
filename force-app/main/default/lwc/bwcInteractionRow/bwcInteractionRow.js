import { LightningElement,api,track,wire } from 'lwc';
import { CurrentPageReference } from "lightning/navigation";
import getRelatedRecords from '@salesforce/apex/BWC_InteractionsWithActivitiesController.getRelatedRecords';

export default class BwcInteractionRow extends LightningElement {
@api interaction=null;
@track expandRow = false;
@track interactionId;
@track activityAndCaseList = null;
@track recordNotes = null;
@track showNotes = false;
@wire(CurrentPageReference)
pageRef;

get hasRecords(){
 
  return (this.interaction.Interaction_Activity_Count__c === 0 && this.interaction.Case_Count__c === 0) ? false:true; 

}
navigateToInteraction(){

}

expandInteraction(){

  if(this.interaction.Interaction_Activity_Count__c !== 0 || this.interaction.Case_Count__c !== 0){
    
    
    this.expandRow = !this.expandRow;
    //change this logic we don't want to see the header and we want the loading to happen
    if(this.interaction.Id && !this.activityAndCaseList){
      
        getRelatedRecords({interactionId: this.interaction.Id }).then(result => {
            let listFromServer =JSON.parse(result);
            this.activityAndCaseList =listFromServer;   
            this.cleanCreatedDate();
            
            this.activityAndCaseList.sort((a, b) => 
            (a.CreatedDate < b.CreatedDate) ? 1 : (a.CreatedDate === b.CreatedDate) ? ((a.size < b.size) ? 1 : -1) : -1 )

          }).catch(error => {
            console.log(error);
          })
    } 
  }


  
}
getNotes(){
          this.showNotes = !this.showNotes;
        
}
cleanCreatedDate(){
    for(let i = 0; i < this.activityAndCaseList.length; i++){
      this.activityAndCaseList[i].CreatedDate = Date.parse(this.activityAndCaseList[i].CreatedDate); 
    }
  
  }
connectedCallback() {
    if(this.interaction){
        this.getInteractionId();
    }
 
}
@api
closeSection(){
    const promise = new Promise((resolve,reject)=>{

        this.expandRow = false;
        this.activityAndCaseList = null;
        this.activityDisplayList = null;
        resolve();
    });
    return promise;

}
getInteractionId(){
    if(this.pageRef.state && this.pageRef.attributes.objectApiName ==='Interaction__c'){
          this.interactionId = this.pageRef.attributes.recordId;

    }
    }
 
      initializeDisplayList(){
        let firstTenRecords=[];
        
        for(let i = 0; i < this.activityAndCaseList.length; i++){
            if(i<this.numberOfRecordsToDisplay){
                firstTenRecords.push(this.activityAndCaseList[i]);
            } 
          }
        this.activityDisplayList = firstTenRecords;
      }

}