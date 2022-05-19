import { LightningElement, api } from 'lwc';
import getArticleLinks from "@salesforce/apex/BWLinkValidationHelper.getKnowledgeArticleLinks";
//import formFactor from '@salesforce/client/formFactor';

/*const columns = [
    { label: 'ArticleLinkNumber', fieldName: 'nameUrl', type: 'url', typeAttributes: {label: { fieldName: 'Name' }, 
    target: '_self'}
},
    { label: 'Status', fieldName: 'Status__c' },
    { label: 'Content Sponsor', fieldName: 'ContentSponsor__c' },
    { label: 'Link Type', fieldName: 'Type__c' },
    { label: 'Link URL', fieldName: 'Link_URL__c' },
    { label: 'Validation Message', fieldName: 'ValidationMessage__c' }
];*/
export default class KnowledgeArticleLinksRelatedList extends LightningElement {
    @api recordId;
    hasRecords = false;
    title = 'Knowledge Article Links (0)';
    articleLinks;

    //largeDevice;
    //smallDevice;

    connectedCallback() {
        let nameUrl;

        /*if(formFactor == 'Medium'|| formFactor == 'Small'){
            this.smallDevice = true;
        }
        else if(formFactor == 'Large') {
            this.largeDevice = true;
        }*/

        getArticleLinks({
            articleId: this.recordId
        })
        .then(result => {
            console.log('Result', result);
            if (Array.isArray(result) && result.length > 0) {
                this.articleLinks = result.map(link => { 
                                                nameUrl = '/' + link.Id;
                                                return {...link , nameUrl}
                                            });
                this.title = 'Knowledge Article Links (' + this.articleLinks.length + ')';
                this.hasRecords = true;
            } 
        })
        .catch(error => {
            console.log(error);
            this.hasRecords = false;
            this.title = 'Knowledge Article Links (0)';
        });
    }
 
}