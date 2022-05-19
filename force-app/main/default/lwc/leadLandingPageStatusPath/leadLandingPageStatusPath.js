import { LightningElement, track , wire} from 'lwc';
import getListViewCount from '@salesforce/apex/cLeadHomePageController.getListViewCount';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import STATUS_FIELD from '@salesforce/schema/Lead.Status';
import getDefaultRT from "@salesforce/apex/LogACallController.getDefaultRT";


export default class LeadLandingPageStatusPath extends LightningElement {
@track listviewData = {}
@track capturedLabel;
@track contactedLabel;
@track connectedLabel;
@track closedLabel;
@track recTypeId;

    connectedCallback() {
        getListViewCount().then(data => {
           console.log(data);
           this.listviewData =  data;
            this.listviewData.capturedCountX = this.getPostion( this.listviewData.capturedCount);
            this.listviewData.contactedCountX = this.getPostion( this.listviewData.contactedCount);
            this.listviewData.connectedCountX = this.getPostion( this.listviewData.connectedCount);
            this.listviewData.closedCountX = this.getPostion( this.listviewData.closedCount);
        });

        getDefaultRT({
          ObjName: "LEAD"
        })
          .then((res) => {
            this.recTypeId = res;
          })
          .catch((err) => {});   


       

    }

     getPostion = (numberX) => {
       console.log('=='+numberX);
       if(numberX == undefined || numberX == null){
        numberX = 0;
       }
       let  position = 39;
      if(numberX < 10 ){
       position = 39;
      }
      else if(numberX < 100 ){
       position = 35;
      }
     else  if(numberX < 1000 ){
       position = 31;
      }
     else if(numberX < 10000 ){
       position = 27;
      }
      else if(numberX < 100000 ){
       position = 23;
      }
      return position;
    }

    @wire(getPicklistValues, { 
      recordTypeId: "$recTypeId",
     fieldApiName: STATUS_FIELD })
    wiredRecord({error, data}) {
        if (error) {
        
        } else if (data) {
           console.log(data);
           for(let i=0; i<data.values.length; i++){
            console.log(data.values[i]);
            if(data.values[i].value == "Captured"){
              this.capturedLabel  = data.values[i].label;      
            }
            if(data.values[i].value == "Contacted"){
                this.contactedLabel  = data.values[i].label;      
              }
              if(data.values[i].value == "Connected"){
                this.connectedLabel  = data.values[i].label;      
              }
              if(data.values[i].value == "Closed"){
                this.closedLabel  = data.values[i].label;      
              }
           }
        }
    }
    
}