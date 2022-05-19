import { LightningElement, api,wire, track } from 'lwc';
import {CurrentPageReference} from 'lightning/navigation';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import setArticleReaded from '@salesforce/apex/KnowledgeDisplayController.setArticleReaded';

export default class ArticleSingleItem extends LightningElement {
    @wire(CurrentPageReference) pageRef;
    @api title;
    @api previewImage;
    @api summary;
    @api isArticleReaded;
    articalFromEvent;

    connectedCallback() {
        // subscribe to inputChangeEvent event
        registerListener('inputChangeEvent', this.handleChange, this);
    }

    disconnectedCallback() {
        // unsubscribe from inputChangeEvent event
        unregisterAllListeners(this);
    }

    handleChange(inpVal) {
        this.articalFromEvent = inpVal;
        this.title = this.articalFromEvent.title;
        this.previewImage = this.articalFromEvent.previewImage;
        this.summary = this.articalFromEvent.summary;
        this.isArticleReaded = this.articalFromEvent.articleReaded;
        
        /* Set articles to be readed */
        setArticleReaded({
            articleId: this.articalFromEvent.compId
        })
        .then((data) => {
            console.log('SUCCESS', data);
        })
        .catch((error) => {
            console.log('error', error);
        });
        event.stopPropagation();
    }

}