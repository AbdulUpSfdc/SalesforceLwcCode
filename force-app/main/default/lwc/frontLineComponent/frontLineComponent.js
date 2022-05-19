/* eslint-disable no-console */
/* eslint-disable no-unused-vars */

import { LightningElement, api, track} from 'lwc';
import getSingleKnowledge from '@salesforce/apex/KnowledgeFrontline.getSingleKnowledge';
//import getKnowledgeList from '@salesforce/apex/Knowledge.getKnowledgeList';
import { NavigationMixin } from 'lightning/navigation';


export default class ApexImperativeMethodWithParams extends  NavigationMixin(LightningElement) {
    
     @api recordId;
     articles;
     selectedAticle;
     currentIndex = 0;
     @track error;

     connectedCallback() {
        getSingleKnowledge({ knowledgerecordid: this.recordId})
            .then(result => {
                if(result.isSuccess){
                    this.articles= result.frontLineKnwList;
                    if(result.frontLineKnwList.length > 0){
                        this.selectedAticle = this.articles[this.currentIndex];
                    }
                }else{
                    this.error = result.errorMessage;
                }
            })
            .catch(error => {
                this.error = error;
                this.article= undefined;
            });
    }

    //handle for looping backwards for the article carousel
    
    handlePrev(e){
        this.currentIndex -= 1;
        if(this.currentIndex === -1){
            this.currentIndex = this.articles.length - 1;
        }
        this.selectedAticle = this.articles[this.currentIndex];
    }

    //loop through the articles
    handleNext(e){
        this.currentIndex += 1;
        if(this.currentIndex === this.articles.length){
            this.currentIndex = 0;
            //console.log("Next:", this.currentIndex);
        }
        this.selectedAticle = this.articles[this.currentIndex];
    }


    handleClick(evt){
        let artid = evt.currentTarget.getAttribute("id").split('-')[0];
        console.log('Inside Event');
        console.log('artid', artid);
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: artid,
                actionName: 'view'
            }
        });
    }
   
}