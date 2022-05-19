/* eslint-disable no-console */
import { LightningElement, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getArticles from '@salesforce/apex/KnowledgeDisplayController.getKnowledgeArticle';
import setArticleReaded from '@salesforce/apex/KnowledgeDisplayController.setArticleReaded';

export default class ArticleListItem extends NavigationMixin(LightningElement) {
    @api title;
    articlesBycolumn = [];
    @api key;
    @api selectedArticle;
    @api isgridView;
    
    get selectNumberofColumnClass(){
        if(this.isgridView){
            return 'slds-col slds-size_1-of-5'
        }
        return 'slds-col slds-size_1-of-1';
    }  

    /* Load Articles from Controller */
    @wire(getArticles)
    wiredArticles({ error, data }) {
        if (data) {
            console.log('getArticles', data);
            //this.articlesBycolumn = data.homePageKnwList;
            this.processArticleResponse(data.homePageKnwList);
            console.log('getArticles processed', this.articlesBycolumn);
        } else if (error) {
            console.log(error);
        }
    }
    handleNumberOfColumnSelect(event){
        this.selectNumberofColumnClass = event.detail.value;// + ' slds-p-around--small';
    }

    processArticleResponse(homePageKnwbyIndex){
        var tempArticlesBycolumn = new Array();
        for(let key in homePageKnwbyIndex) {
            // Preventing unexcepted data
            if (homePageKnwbyIndex.hasOwnProperty(key)) { // Filtering the data in the loop
                tempArticlesBycolumn.push({value:homePageKnwbyIndex[key], key:key});
            }
        }
        this.articlesBycolumn = tempArticlesBycolumn;
    }

    handleClick(e){
        let artid = e.currentTarget.getAttribute("id").split('-')[0];
        console.log('artid', artid);
        //window.open('/' + artid,'_blank');
        setArticleReaded({
            articleId: artid
        })
        .then((data) => {
            console.log('SUCCESS', data);
            this.processArticles(artid);
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: artid,
                    actionName: 'view'
                }
            });
        })
        .catch((error) => {
            console.log('error', error);
        });
    }

    processArticles(articleId){
        let tempArticles = JSON.parse(JSON.stringify(this.articlesBycolumn));
        let i;
        for(i=0; i< tempArticles.length; i++){
            let matchFound = false;
            for(let k=0; k<tempArticles[i].value.length;k++){
                if(tempArticles[i].value[k].compId === articleId){
                    tempArticles[i].value[k].articleReaded = true;
                    matchFound = true;
                    break;
                }
            }
            if(matchFound)
                break;
        }
        this.articlesBycolumn = tempArticles;
    }
}