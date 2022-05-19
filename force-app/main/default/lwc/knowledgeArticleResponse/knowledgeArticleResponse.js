import {
    LightningElement,
    api
} from 'lwc';
import getKnowledgeArticle from "@salesforce/apex/KnowledgeAgentController.getKnowledgeArticle";



import {
    NavigationMixin
} from 'lightning/navigation';
import formFactorPropertyName from "@salesforce/client/formFactor";

 


export default class KnowledgeArticleResponse extends NavigationMixin(LightningElement) {
    @api recordId;
    IS_DESKTOP;

    showRelatedLink = false;
    tabName = 'Knowledge_Search';
    showShareModal = false;
    smartURL = '';
    article = {
        isRead: false,
        isUrgent: false,
        title: 'Loading...',
        cspId: 'Loading...',
        updateddate: 'Loading...',
        validity: 'Loading...'
    };
    connectedCallback() {

        if (formFactorPropertyName == 'Large') {
            this.IS_DESKTOP = true;
        }

        console.log('recordId', this.recordId);
        console.log('this', this);


        getKnowledgeArticle({
                kwId: this.recordId
            })
            .then(result => {
                console.log("KnowledgeForAgent", result);

                if (result.isSuccess) {
                    this.article = result.frontLineKnwList[0];
                    this.smartURL = this.article.shareURL;
                    if (this.article.externalLink) {
                        this.showRelatedLink = true;
                    }
                    if (this.article.extrnalURL) {
                        this.showRelatedLink = true;
                    }
                } else {
                    this.error = result.errorMessage;
                }
            })
            .catch(error => {
                this.error = error;
            });
 
    }

    /*
        handleback(e) {
            this[NavigationMixin.Navigate]({
                type: 'standard__navItemPage',
                attributes: {
                    apiName: this.tabName,
                },
            });
        }
        */

    shareArticle(e) {
        this.showShareModal = true;
    }

    hideModal(e) {
        this.showShareModal = false;
    }

 
}