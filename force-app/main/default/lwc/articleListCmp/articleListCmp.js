/* eslint-disable no-console */
import { LightningElement, track, api, wire } from 'lwc';
import setArticleReaded from '@salesforce/apex/KnowledgeDisplayController.setArticleReaded';
import getFronLineArticles from '@salesforce/apex/KnowledgeDisplayController.getFronLineArticle';

export default class ArticleListCmp extends LightningElement {
    @api title;
    @track displayPreviewPane = false;
    @api previewSRC;
    @api selectedArticle;

    @wire(getFronLineArticles)
    wiredArticles({ error, data }) {
        if (data) {
            console.log('getFronLineArticle', data);
            if(data.frontLineKnwList.length > 0){
                this.selectedArticle = data.frontLineKnwList[0];
                this.displayPreviewPane = true;
            }
        } else if (error) {
            console.log(error);
        }
    }

    handleClick(event) {
        event.stopPropagation();
        console.log('Inside Event');
        console.log(event);
        this.previewSRC = event.detail.previewLink;
        this.displayPreviewPane = true;
        this.selectedArticle = event.detail.articledata;
        console.log(this.previewSRC);
        
        /* Set articles to be readed */
        setArticleReaded({
            articleId: event.detail.articleId
        })
        .then((data) => {
            console.log('SUCCESS', data);
        })
        .catch((error) => {
            console.log('error', error);
        });
    }
}