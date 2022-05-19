import { LightningElement,api,track } from 'lwc';
import * as openSubTab from 'c/bwc_OpenSubTabFromUtilBarPublisher';

export default class BwcInteractionActivityRow extends LightningElement {
    @api activity = null;
    @track expandActivityRow = false;
    @track recordNotes = null;
    @track showNotes = false;
    navigateToRecord(){
        switch (this.activity.attributes.type){
            case "Case_Interaction__c":
                
                openSubTab.publishMessage(this.activity.Case__r.Id);

                break;

            case "Interaction_Activity__c":
                
                openSubTab.publishMessage(this.activity.Id);

            break;

        }
    }
    
    expandActivity(){
        this.expandActivityRow =!this.expandActivityRow;
        
    }
    getNotes(){
        this.showNotes = !this.showNotes;
      
}
    connectedCallback() {
        if(this.activity){
            
        }
    }
}