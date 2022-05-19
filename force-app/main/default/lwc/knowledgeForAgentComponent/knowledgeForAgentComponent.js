import {
    LightningElement,
    api
} from 'lwc';
import getKnowledgeArticle from "@salesforce/apex/KnowledgeAgentController.getKnowledgeArticle";
import getPublicLink from "@salesforce/apex/KnowledgeAgentController.getPublicLink";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


import {
    NavigationMixin
} from 'lightning/navigation';
import formFactorPropertyName from "@salesforce/client/formFactor";

 


export default class KnowledgeForAgentComponent extends NavigationMixin(LightningElement) {
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

    URL2Clipboard() {
        var copyText = document.createElement('input');
        copyText.setAttribute("value", this.smartURL);
        document.body.appendChild(copyText);
        copyText.select();
        copyText.setSelectionRange(0, 99999)
        document.execCommand("copy");
        //alert(" \r\nThis URL has been copied to the clipboard: \r\n  \r\n" + this.smartURL );
        var message = " \r\nThis URL has been copied to the clipboard: \r\n  \r\n" + this.smartURL;
        this.showToast("URL Copied",message,'success'); 

        // alert("This URL has been copied to the clipboard: \r\n" + this.smartURL);

    }


    getTheUrl()
    {
        console.log('--recordId--'+this.recordId);

        getPublicLink({ ArticleId: this.recordId })
        .then(result => {

            var message = "";
            var n = result.search("http");                
            if( n < 0 )
            {

                message ="\r\n" + result;
            }
            else
            {

                var copyText = document.createElement('input');
                copyText.setAttribute("value",result);
                document.body.appendChild(copyText);
                copyText.select();
                copyText.setSelectionRange(0, 99999)
                document.execCommand("copy"); 
                
                message =" \r\nThis URL has been copied to the clipboard: \r\n \r\n" + result;
            }



           // alert(message);

            this.showToast("URL Copied",message,'success'); 

        })
        .catch(error => {
            this.resultsum = undefined;
            //alert("Error occured: " + error);
            this.showToast("Could not copy URL",error,'error'); 

            //this.error = error;
        });
        
   } 

   showToast(title,msg,type) {
    const event = new ShowToastEvent({
        title: title,
        message: msg,
        variant: type,
        mode: 'dismissable'
    });
    this.dispatchEvent(event);
}

}