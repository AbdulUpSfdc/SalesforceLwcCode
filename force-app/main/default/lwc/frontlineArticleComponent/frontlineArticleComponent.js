import {
  LightningElement,
  wire,
  api,
  track
} from "lwc";
import {
  NavigationMixin
} from "lightning/navigation";
import getFrontLineKnowledgeArticles from "@salesforce/apex/KnowledgeLandingPageDispatcher.getFrontLineKnowledgeArticles";
import getViewAsFrontLineKnowledgeArticles from "@salesforce/apex/KnowledgeLandingPageDispatcher.getViewAsFrontLineKnowledgeArticles";
import hasKMViewAsPermission from "@salesforce/customPermission/KM_View_As";


import markArticleRead from "@salesforce/apex/KnowledgeLandingPageDispatcher.markArticleRead";


/*getViewAsFrontLineKnowledgeArticles(String channel, String market,  
  String employeeRole, String resourceType,
  String requestSource) */
import FORM_FACTOR from "@salesforce/client/formFactor";
import {
  ShowToastEvent
} from "lightning/platformShowToastEvent";
import {
  refreshApex
} from '@salesforce/apex';

export default class FrontlineArticleComponent extends NavigationMixin(
  LightningElement
) {
  wiredArticles;

  articles = [];
  frontlineViewAsArticles = [];
  frontlineArticles = [];
  selectedArticle;
  selectedFrontlineArticle;
  selectedViewAsFrontlineArticle;
  currentIndex = 0;
  error;
  @api viewMode;
  @track viewAsArticlesFound = true;

  //CSS Varialbes according to device.
  imageheight = "height:200px; cursor: pointer;";
  txtSize_sub = "slds-text-body_medium frontline-subheader slds-line-clamp_medium";
  @track largeDevice = false;

  initcss() {
    if (FORM_FACTOR === "Large") {
      this.imageheight = "background-color: #fff;height:330px; cursor: pointer;";
    } else if (FORM_FACTOR === "Medium") {
      this.imageheight = "background-color: #fff; cursor: pointer;";
    } else if (FORM_FACTOR === "Small") {}
  }

  @api handleViewAsQuery(channel, market, employeeRole, resourceType) {
    //alert('View as query submitted ' + channel + '; market: ' + market + '; employeeRole: ' + employeeRole + '; resourcetype: ' +  resourceType);
   
    this.callGetViewAsFrontLineKnowledgeArticles(channel,  market,  employeeRole, resourceType);
  }

  @api handleViewAsToggleResults(viewAsVisible) {
    console.log('User has viewas: ' + hasKMViewAsPermission);
    
    console.log('Frontline view as has been selected: ' + viewAsVisible);
    if (hasKMViewAsPermission == true) {
      if (viewAsVisible == true) {
        this.frontlineArticles = this.articles;
        this.selectedFrontlineArticle = this.selectedArticle;
        
        this.articles = this.frontlineViewAsArticles;
         this.selectedArticle = this.selectedFrontlineViewAsArticle;
         if (this.frontlineViewAsArticles.length > 0) {
           this.viewAsArticlesFound = true;
      
         }
        
        console.log('Set to view as frontline Articles');
      } else {
        this.frontlineViewAsArticles = this.articles;
        this.selectedFrontlineViewAsArticle = this.selectedArticle;
        
        this.articles = this.frontlineArticles;
         this.selectedArticle = this.selectedFrontlineArticle;
          console.log('Set to frontline Articles');
      }
    }
  }

  callGetViewAsFrontLineKnowledgeArticles(channel,  market,  employeeRole, resourceType) {
     console.log('get ViewasFrontLineCalled');

     getViewAsFrontLineKnowledgeArticles({ 
      channel : channel, 
      market: market, 
      employeeRole: employeeRole,
      resourceType: resourceType,
      requestSource: 'ViewAs'
    })
      .then(value => {
    console.log(' getViewAsFrontLineKnowledgeArticles', JSON.stringify(value));

      //this.wiredArticles = value;
      // Destructure the provisioned value 
      const {
        data,
        error
      } = value;
      if (value.isSuccess == true) {
          console.log('Successful getViewAsFrontline');
          this.articles = value.frontLineKnwList;
          this.frontlineViewAsArticles = this.articles;
          if (value.frontLineKnwList.length > 0) {
            this.selectedArticle = this.articles[this.currentIndex];
            this.selectedFrontlineArticle = this.articles[this.currentIndex];
            console.log('Number of found view as frontline articles: ' + value.frontLineKnwList.length);
            this.viewAsArticlesFound = true;
          } else {
            console.log('No articles found matching conditions');
            this.selectedArticle = null;
            this.selectedFrontlineArticle = null;
            this.viewAsArticlesFound = false;
          }
        } else {
          this.error = value.errorMessage;
        }
        console.log('getViewAsFrontLineKnowledgeArticles', this.articles);
        console.log('Selected article: ' +  this.selectedArticle );
        console.log('View as articles found: ' + this.viewAsArticlesFound);
  
        
    })
    .catch(error => {
      console.log('Error caught');
    });

  } 





  @wire(getFrontLineKnowledgeArticles)
  wiredGetActivityHistory(value) {
    console.log(' getFrontLineKnowledgeArticles value', value);
    this.wiredArticles = value;
    // Destructure the provisioned value 
    const {
      data,
      error
    } = value;
    if (data) {
      console.log('getFrontLineKnowledgeArticles data', data);
      if (data.isSuccess) {
        this.articles = data.frontLineKnwList;
        if (data.frontLineKnwList.length > 0) {
          this.selectedArticle = this.articles[this.currentIndex];
          this.viewAsArticlesFound = true;

        }
      } else {
        this.error = data.errorMessage;
      }
      console.log("getAssignedArticles", this.articles);
    } else if (error) {}
  }


  connectedCallback() {
    if (FORM_FACTOR === "Large") {
      this.largeDevice = true;
    }
    /*
    getFrontLineKnowledgeArticles()
      .then(result => {
        console.log("getFrontLineKnowledgeArticles", result);
        if (result.isSuccess) {
          this.articles = result.frontLineKnwList;
          if (result.frontLineKnwList.length > 0) {
            this.selectedArticle = this.articles[this.currentIndex];
          }
        } else {
          this.error = result.errorMessage;
        }
        console.log("getFrontLineKnowledgeArticles" + this.selectedArticle);
      })
      .catch(error => {
        this.error = error;
        this.article = undefined;
      });
      */
    this.initcss();
  }

  handlerRefresh() {
    refreshApex(this.wiredArticles);
  }

  //handle for looping backwards for the article carousel

  handlePrev(evt) {
    evt.preventDefault();
    this.currentIndex -= 1;
    if (this.currentIndex === -1) {
      this.currentIndex = this.articles.length - 1;
    }
    this.selectedArticle = this.articles[this.currentIndex];
    console.log('Next::: ', this.selectedArticle);
  }

  //loop through the articles
  handleNext(evt) {
    evt.preventDefault();
    this.currentIndex += 1;
    if (this.currentIndex === this.articles.length) {
      this.currentIndex = 0;
      //console.log("Next:", this.currentIndex);
    }
    this.selectedArticle = this.articles[this.currentIndex];
    console.log('Next::: ', this.selectedArticle);
  }

  handleClick(evt) {
    evt.preventDefault();
    let artid = evt.currentTarget.getAttribute("id").split("-")[0];
    console.log("Inside Event");
    console.log("artid", artid);
    if (!this.selectedArticle.isRead) {
      this.markArticleRead(artid);
    }
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: artid,
        actionName: "view"
      }
    });
  }

  async markArticleRead(articleId) {
    console.log("markArticleRead", articleId);
    markArticleRead({
        knowledgeId: articleId
      })
      .then(result => {
        console.log("markArticleRead", result);
        if (result.isSuccess) {
          //this.markArticleReadinList(articleId);
          this.handlerRefresh();
        } else {
          this.showToast("Something went wrong", result.errorMessage, "error");
        }
      })
      .catch(error => {
        console.log("markArticleRead", error);
        this.error = error;
      });
  }

  showToast(title, message, variant) {
    const event = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant,
      mode: "dismissable"
    });
    this.dispatchEvent(event);
  }

  markArticleReadinList(articleId) {
    let tempassigneArticle = JSON.parse(JSON.stringify(this.selectedArticle));
    tempassigneArticle.isRead = true;
    this.selectedArticle = tempassigneArticle;
    console.log("processed markArticleReadinList", this.selectedArticle);
    let tempArticles = JSON.parse(JSON.stringify(this.articles));
    for (let i = 0; i < tempArticles.length; i++) {
      console.log('articles', tempArticles[i].compId, articleId);

      if (tempArticles[i].compId === articleId) {
        tempArticles[i].isRead = true;
        break;
      }
    }
    this.articles = tempArticles;
    console.log('articles', this.articles);
  }
}