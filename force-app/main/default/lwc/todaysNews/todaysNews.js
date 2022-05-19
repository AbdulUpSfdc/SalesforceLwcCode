import { LightningElement, api, wire ,track } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getAssignedArticles from "@salesforce/apex/KnowledgeFrontlineController.getAssignedKnowledgeArticles";
import markArticleReaded from "@salesforce/apex/KnowledgeFrontlineController.markArticleReaded";
import { refreshApex } from '@salesforce/apex';
export default class TodaysNews extends NavigationMixin(LightningElement) {
    articles = [];
    allArticles;
    btn_label = "View More";
    UNREAD_ARTICLES = 0;
    NUMBER_ARTICLE_TODISPLAY = 4;
    ismorethanfourArticles = true;
    recordTypeName = '';
    hasArticlesLoaded = false;

    wiredArticles;

    @wire(getAssignedArticles)
    wiredGetActivityHistory(value) {
      console.log('value', value);
      this.wiredArticles = value;
      // Destructure the provisioned value 
      const {
        data,
        error
      } = value;
      if (data) {
        console.log('data', data);
        if (data.isSuccess) {
          this.allArticles = data.frontLineKnwList;
          this.handleFilterArticles();
          if (this.btn_label === "View More") {
            this.getfirstfourArticles();
          } else {
            this.articles = this.allArticles;
          }
        } else {
          this.error = data.errorMessage;
        }
        console.log("todays news", this.articles);
      } else if (error) {}
    }


        connectedCallback(){
            getAssignedArticles()
            .then(data => {
                console.log('Art List here --- ');  
                console.log(data.frontLineKnwList); 
                this.allArticles = data.frontLineKnwList;
                this.handleFilterArticles();
                console.log(this.allArticles); 
                this.getfirstfourArticles();  
                console.log('HERE  '); 
                console.log(this.allArticles.length); 
                if(this.allArticles && this.allArticles.length>0){
                  this.hasArticlesLoaded = true;
                }
            }).catch(error => {
                console.log('No articles returned '+error);
                this.hasArticlesLoaded = false;
                this.ismorethanfourArticles = false;
             });  
        }

        handleClick(evt) {
            evt.preventDefault();
            let artid = evt.currentTarget.getAttribute("id").split("-")[0];
            this.markArticleReaded(artid);
            this[NavigationMixin.Navigate]({
                type: "standard__recordPage",
                attributes: {
                recordId: artid,
                actionName: "view"
                }
            });
        }

        markArticleReaded(articleId) {
            console.log("markArticleReaded", articleId);
            markArticleReaded({
                knowledgeId: articleId
                })
                .then((result) => {
                console.log("markArticleReaded", result);
                if (result.isSuccess) {
                    //this.markArticleReadedinList(articleId);
                    this.getfirstfourArticles();
                    this.btn_label = "View More";
                    this.handlerRefresh();
                    let assignedArticleContainer = this.template.querySelector(".assignedArticleContainer");
                    if(assignedArticleContainer){
                      assignedArticleContainer.style = "";
                    }
                } else {
                    this.showToast("Something went wrong", result.errorMessage, "error");
                }
                })
                .catch((error) => {
                console.log("markArticleReaded", error);
                this.error = error;
                });
        }

        getfirstfourArticles() {
            this.compareandProcessArticles();
            if (this.allArticles.length > this.NUMBER_ARTICLE_TODISPLAY) {
              this.ismorethanfourArticles = true;
              var tempassigneArticle = new Array();
              for (let i = 0; i < this.NUMBER_ARTICLE_TODISPLAY; i++) {
                tempassigneArticle.push(this.allArticles[i]);
              }
              this.articles = tempassigneArticle;
            } else {
              this.ismorethanfourArticles = false;
              this.articles = this.allArticles;
            }
        }

        compareandProcessArticles() {
            for (let j = 0; j < this.articles.length; j++) {
              for (let i = 0; i < this.allArticles.length; i++) {
                if (this.articles[j].compId === this.allArticles[i].compId) {
                  this.allArticles[i] = this.articles[j];
                  break;
                }
              }
            }
        }

        handlerRefresh() {
          refreshApex(this.wiredArticles);
        }
      

        handleMore(){
          console.log('handleMore');
          let assignedArticleContainer = this.template.querySelector(".assignedArticleContainer");
    
          if (this.btn_label === 'View More') {
            console.log('View More');
            this.articles = this.allArticles;
            this.btn_label = "View Less";
            if(assignedArticleContainer){
              assignedArticleContainer.style = "overflow-y:scroll;overflow-x:hidden;height:500px;";
            }
          }else{
            this.getfirstfourArticles();
            this.btn_label = "View More";
            if(assignedArticleContainer){
              assignedArticleContainer.style = "";
            }
          }
        }

        handleFilterArticles() {
          let tempArticles = [];
          this.UNREAD_ARTICLES = 0;
          for (let i = 0; i < this.allArticles.length; i++) {
            if (this.allArticles[i].recordTypeName === this.recordTypeName) {
              tempArticles.push(this.allArticles[i]);
            } else if (this.recordTypeName === "") {
              tempArticles.push(this.allArticles[i]);
            }
            if (!this.allArticles[i].isRead) {
              this.UNREAD_ARTICLES += 1;
            }
          }
          this.allArticles = tempArticles;
        }


}