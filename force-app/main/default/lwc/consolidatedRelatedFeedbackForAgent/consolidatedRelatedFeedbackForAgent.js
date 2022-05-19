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


const actions = [
   { label: 'Edit', name: 'edit' },
];

const columns = [
   // { label: 'Id', fieldName: 'Id' },
   //{ label: 'ArticleFeedbackId', fieldName: 'ArticleFeedbackId' },
    { label: 'Description', fieldName: 'DescriptionURL',wrapText: true,
        type: 'url', typeAttributes: {
            label: {
                fieldName: 'Description'
            },
            target : '_self'
        }  },
        { label: 'Version', fieldName: 'VersionNumber'},
    { label: 'FeedbackResponse', fieldName: 'FeedbackResponse'},
    { label: 'Choose a General Reason', fieldName: 'Chooseaeneralreason'},
    { label: 'Posted By', fieldName: 'Owner' },
    { label: 'Status', fieldName: 'FeedbackStatus' },

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

    error = '';

    relatedFedbackCount = 'Private Feedback Response (0)';

    artcileFeedbacks = [];

    allArtcileFeedbacks = [];

    ismorethanthreeArticles = false;

    btn_label = 'View All';

    sixFeedbacks = '';

   NUMBER_FEEDBACKS_TODISPLAY = 3;

    

  

    connectedCallback() {

        console.log('Consolidated recordId', this.knowledgeArticleId);

       

        getArticleFeedbacks({

                articleId: this.recordId

            })

            .then(result => {

                console.log("Consolidated Result", result);

                 

               let baseUrl = 'https://'+location.host+'/';

                if (result.isSuccess) {

                    this.relatedFedbackCount = 'Private Feedback Response (' + result.articleFeedbacks.length + ')';

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

                elt.FeedbackResponse=element.Feedback_Response__c;

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

 

  

 

 

    }