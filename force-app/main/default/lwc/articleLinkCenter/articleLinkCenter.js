/* eslint-disable no-console */
import { LightningElement, wire, api } from 'lwc';
import getLinkCentralArticles from '@salesforce/apex/KnowledgeDisplayController.getLinkCentralArticle';
import { NavigationMixin } from 'lightning/navigation';

export default class ArticleLinkCenter extends NavigationMixin(LightningElement) {
    @api linkCentralArticles

    /* Load Articles from Controller */
    @wire(getLinkCentralArticles)
    wiredArticles({ error, data }) {
        if (data) {
            console.log('getLinkCentralArticle', data);
            this.linkCentralArticles = data.linkCentralKnwList;
        } else if (error) {
            console.log(error);
        }
    }


    handleClick(evt){
        let artid = evt.currentTarget.getAttribute("id").split('-')[0];
        console.log('artid', artid);
        /*********
         * Refused to run the JavaScript URL because it violates the following Content Security Policy directive: 
         * "script-src 'self' 'nonce-5557240c-59a2-b642-48ed-5a6117e5204c' chrome-extension:
         * 'unsafe-eval' *.canary.lwc.dev *.visualforce.com 
         * https://ssl.gstatic.com/accessibility/ https://static.lightning.force.com". 
         * Either the 'unsafe-inline' keyword, a hash ('sha256-...'), 
         * or a nonce ('nonce-...') is required to enable inline execution.
        */
        // Navigate to a URL
        /*
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: 'http://salesforce.com'
            }
        },
        true // Replaces the current page in your browser history with the URL
      );
      */
    }
}