import {
    LightningElement,
    api,
    wire,
    track 
} from 'lwc';
import {
    NavigationMixin
} from "lightning/navigation";
import getArticleFeedbacks from "@salesforce/apex/ArticleFeedbackController.getArticleFeedbacks";
import getProfile from '@salesforce/apex/ArticleFeedbackController.getProfile';
const actions = [
   { label: 'Edit', name: 'edit' },
   
];
const columns = [
   // { label: 'Id', fieldName: 'Id' },
   { label: 'Status', fieldName: 'FeedbackStatus',sortable: "true" },
  
    { label: 'Description', fieldName: 'DescriptionURL',wrapText: true,sortable: "true",
        type: 'url', typeAttributes: {
            label: { 
                fieldName: 'Description' 
            },
            target : '_self'
        }  },
    { label: 'Version', fieldName: 'VersionNumber',sortable: "true"},
    { label: 'Choose a general reason', fieldName: 'Chooseaeneralreason',sortable: "true"},
    { label: 'Posted By', fieldName: 'Owner',sortable: "true" },
   { label: 'CreatedDate', fieldName: 'CreatedDate',sortable: "true" },
     { label: 'ArticleFeedbackId', fieldName: 'ArticleFeedbackId' ,sortable: "true" },
      {
        type: 'action',
        typeAttributes: { rowActions: actions ,target : '_self' },
    }, 
    
];

 

export default class ConsolidatedRelatedFeedback extends NavigationMixin(
    LightningElement
) {
    
     @track columns=columns;
    @api recordId;
   @track sortBy;
    @track sortDirection;
   @track data;
    ShowBtn = false;
    error;
  wiredActivities;
    error = '';
    relatedFedbackCount = 'Related Feedback (0)';
    artcileFeedbacks = [];
    allArtcileFeedbacks = [];
    ismorethanthreeArticles = false;
    btn_label = 'View All';
    sixFeedbacks = '';
   NUMBER_FEEDBACKS_TODISPLAY = 3;
     @wire(getProfile)
  wiredActivities({ error, data }) {
    if (data){
      console.log('Data==> '+JSON.stringify(data));
      
      this.data = data;
      if(this.data != 'Minimum Access Admin'){
        this.ShowBtn = true;
      }else{
      this.ShowBtn = false;
}
      console.log(this.data);
      this.error = undefined;
     } else if (error) {
      this.error = error;
      this.data = undefined;
     
  }
}
  
    connectedCallback() {
        console.log('Consolidated recordId', this.knowledgeArticleId);
        
        getArticleFeedbacks({
                articleId: this.recordId
            })
            .then(result => {
                console.log("Consolidated Result", result);
                  
               let baseUrl = 'https://'+location.host+'/';
                if (result.isSuccess) {
                    this.relatedFedbackCount = 'Related Feedback (' + result.articleFeedbacks.length + ')';
                     let d = [];
                result.articleFeedbacks.forEach(element => {
                let elt = {};
                elt.Description = element.Description__c;
                elt.DescriptionURL = baseUrl+element.Id;
                elt.VersionNumber = element.Knowledge__r.VersionNumber ;
                elt.FeedbackStatus =  element.Feedback_Status__c ;
                elt.Owner=element. Owner.Name;
                elt.Id=element.Id;
                elt.ArticleFeedbackId=element.Name;
                elt.Chooseaeneralreason=element.Reason__c;
                elt.CreatedDate=element.CreatedDate;
                d.push(elt);
            });
           
                    this.allArtcileFeedbacks = d;
                    this.getfirstthreeArticles();
                } else {
                    this.error = result.errorMessage;
                }
            })
            .catch(error => {
                console.log("ERROR", error);
                this.error = error;
            });
    }

    getfirstthreeArticles() {
        if (this.allArtcileFeedbacks.length > this.NUMBER_FEEDBACKS_TODISPLAY) {
            this.ismorethanthreeArticles = true;
            let tempfeedbacks = new Array();
            for (let i = 0; i < this.NUMBER_FEEDBACKS_TODISPLAY; i++) {
                tempfeedbacks.push(this.allArtcileFeedbacks[i]);
            }
            this.artcileFeedbacks = tempfeedbacks;
            console.log('this is view all ');
        } else {
            this.ismorethanthreeArticles = false;
            this.artcileFeedbacks = this.allArtcileFeedbacks;
        }
        this.btn_label = "View All";
        this.sixFeedbacks = '';
    }

  handleSortdata(event) {
     
        // field name
        this.sortBy = event?.detail?.fieldName;

           
        // sort direction
        this.sortDirection = event?.detail?.sortDirection;
          
        // calling sortdata function to sort the data based on direction and selected field
        this.sortData(event?.detail?.fieldName, event.detail.sortDirection);
       
    }

    sortData(fieldname, direction) {
         
        // serialize the data before calling sort function
        let parseData = JSON.parse(JSON.stringify(this.allArtcileFeedbacks));
          
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };

        // cheking reverse direction 
        let isReverse = direction === 'asc' ? 1: -1;

        // sorting data 
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';

            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });

        // set the sorted data to data table data
        this.artcileFeedbacks = parseData;

    }


    handleViewAll(evt) {
        if (this.btn_label === 'View All') {
            this.artcileFeedbacks = this.allArtcileFeedbacks;
            this.btn_label = "Collapse";
           // this.sixFeedbacks = 'dislayfullcss';
        } else if (this.btn_label === 'Collapse') {
            this.getfirstthreeArticles();
        }
    }


  
     handleMenuItem(event) {
        //console.log('articleid',evt.currentTarget.getAttribute("id"));
        console.log('event', event);
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        console.log('artid',row.currentTarget);
       console.log('artid',row.Id);
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId:  row.Id, //evt.detail.value "a2N0U000000qSa7UAE"
                objectApiName: "KM_Article_Feedback__c",
                actionName: "edit"
            }
        });
       
    }

    Newfeedbackcomponent(event)
    {
event.preventDefault();
        let componentDef = {
            componentDef: "c:knowledgeArticleResponse",
            attributes: {
                label: 'Navigated From Another LWC Without Using Aura'
            }
    };
let encodedComponentDef = btoa(JSON.stringify(componentDef));
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/one/one.app#' + encodedComponentDef,
                recordId: this.recordId
            }
        });
    }
@track seefeedback=false;
Newfeedbackcomponent1() {
        this.seefeedback=true
    }

    closeModal(){

        this.seefeedback=false;
    
    }


    }