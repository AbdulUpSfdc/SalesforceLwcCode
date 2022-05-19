import { LightningElement, api, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import getAssignedArticles from "@salesforce/apex/KnowledgeLandingPageDispatcher.getAssignedKnowledgeArticles";
import markArticleRead from "@salesforce/apex/KnowledgeLandingPageDispatcher.markArticleRead";

import clearSessionCache from "@salesforce/apex/KnowledgeLandingPageDispatcher.emptySessionCache";

import getViewAsAssignedKnowledgeArticles from "@salesforce/apex/KnowledgeLandingPageDispatcher.getViewAsAssignedKnowledgeArticles";
import hasKMViewAsPermission from "@salesforce/customPermission/KM_View_As";

import formFactorPropertyName from "@salesforce/client/formFactor";


/* import getAssignedArticles from "@salesforce/apex/KnowledgeFrontlineController.getAssignedKnowledgeArticles";
import markArticleReaded from "@salesforce/apex/KnowledgeFrontlineController.markArticleReaded"; */
import formFactor from "@salesforce/client/formFactor";
import { refreshApex } from "@salesforce/apex";
//import { formatCurrency } from "../bwcUtils/bwcUtils";

export default class AssignedArticlesComponent extends NavigationMixin(
  LightningElement
) {


  IS_DESKTOP;

  articles = [];
  noUnreadArticles = false;
  assignedViewAsArticles = [];
  assigedArticles = [];
  articleCount;
  showArticleHeader=true;
  allArticles = [];
  allAssignedArticles;
  allAssignedViewAsArticles = [];
  NUMBER_ARTICLE_TODISPLAY = 3;
  ITEMS_DISPLAYING = 0;
  TOTAL_ARTICLES = 0;
  UNREAD_ARTICLES = 0;
  ismorethanthreeArticles = true;
  error;
  viewAllbtncss = "viewall-btn";
  largeDevice = true;
  btn_label = "View All";
  viewAsArticlesFound = true;
  inRegularMode = true;

  //Apply Filters.
  @api recordTypeName = "";

  //handle css
  assignedArticleCss = "assignedArticle-OverLay";

  @api handleViewAsQuery(channel, market, employeeRole, resourceType) {
    console.log('View as query submitted assigned artilces' + channel + '; market: ' + market + '; employeeRole: ' + employeeRole + '; resourcetype: ' +  resourceType);
    this.callGetViewAsAssignedArticles(
      channel,
      market,
      employeeRole,
      resourceType
    );
  }

  get hasViewAsPermission() {
    console.log('User has view as permission: ' + hasKMViewAsPermission);
    return hasKMViewAsPermission;
  }

  callGetViewAsAssignedArticles(channel, market, employeeRole, resourceType) {
    console.log("get ViewasAssigned called");

    getViewAsAssignedKnowledgeArticles({
      channel: channel,
      market: market,
      employeeRole: employeeRole,
      resourceType: resourceType,
      requestSource: "ViewAs"
    })
      .then((value) => {
        console.log(
          " getViewAsAssignedKnowledgeArticles",
          JSON.stringify(value)
        );

        //this.wiredArticles = value;
        // Destructure the provisioned value
        const { data, error } = value;
        if (value.isSuccess == true) 
        {
          console.log("Successful getViewAsAssigned");
          this.allArticles = value.frontLineKnwList;
          if (value.frontLineKnwList.length > 0) 
          {
            console.log(
              "Number of found assigned vis as  articles: " +
                value.frontLineKnwList.length
            );
            this.TOTAL_ARTICLES = this.allArticles.length;

            console.log("TLU we make it here1? ");

            if (this.btn_label === "View All") 
            {
              console.log("TLU we make it here2? ");
              this.getfirstthreeArticles();
            } 
            else 
            {
              console.log("TLU we make it here3? ");
              this.articles = this.allArticles;
            }

            console.log("TLU we make it here4? ");
            this.articleCount = "Assigned Articles";
            this.viewAsArticlesFound = true;
          } 
          else 
          {
            console.log("No articles found matching conditions");
            this.articles = [];
            this.articleCount = "Assigned Articles";
            this.viewAsArticlesFound = false;
          }
        } 
        else 
        {
          this.error = value.errorMessage;
        }
        console.log("getViewAsAssignednowledgeArticles", this.allArticles);
        console.log("View as assigned articles found: " + this.viewAsArticlesFound);
      })
      .catch((error) => {
        console.log("Error caught " + error );
      });
  }

  @api collapseArticle() {
    this.getfirstthreeArticles();
  }
  wiredArticles;
  @wire(getAssignedArticles)
  wiredGetActivityHistory(value) {
    console.log("value", value);
    
    this.wiredArticles = value;
    // Destructure the provisioned value
    const { data, error } = value;
    if (data) {
      console.log("data", data);
      if (data.isSuccess) {
        this.allArticles = data.frontLineKnwList;
        this.allAssignedArticles = data.frontLineKnwList;
        this.handleFilterArticles();
        this.TOTAL_ARTICLES = this.allArticles.length;
        if (this.TOTAL_ARTICLES>0) {
          this.noUnreadArticles = false;
        } else {
          this.noUnreadArticles = true;
        }
        if (this.btn_label === "View All") {
          this.getfirstthreeArticles();
        } else {
          this.articles = this.allArticles;
          this.assignedArticles = this.allArticles;
        }
        this.articleCount = "Assigned Articles (" + this.UNREAD_ARTICLES + ")";
      } else {
        this.error = data.errorMessage;
      }
      console.log("getAssignedArticles", this.articles);
    } else if (error) {
    }
  }

  @api handleViewAsToggleResults(viewAsVisible) {
    console.log('User has viewas: ' + hasKMViewAsPermission);
    console.log('Assigned view as has been selected: ' + viewAsVisible);
    if (hasKMViewAsPermission == true) {
      if (viewAsVisible == true) {
        this.assignedArticles = this.articles;
        this.allAssignedArticles = this.allArticles;
        this.articles = this.assignedViewAsArticles;
        this.allArticles = this.allAssignedViewAsArticles;
        this.inRegularMode = false;
        this.articleCount = "Assigned Articles";

        console.log('Set to view as assigned Articles');
      } else {
        this.assignedViewAsArticles = this.articles;
        this.allAssignedViewAsArticles = this.allArticles;
        this.articles = this.assignedArticles;
        this.allArticles = this.allAssignedArticles;
        this.inRegularMode = true;
        this.articleCount = "Assigned Articles (" + this.UNREAD_ARTICLES + ")";

          console.log('Set to assigned Articles');
      }
    }  
  }


  connectedCallback() {

    if (formFactorPropertyName == 'Large') {
      this.IS_DESKTOP = true;
    }
    else 
    {
      this.IS_DESKTOP = false;
    }

    // for testing
    //this.IS_DESKTOP = false;

    /*let self = this;
    window.addEventListener("scroll", function () {
      if (self.btn_label !== "View All") {
        if (window.pageYOffset > 410) {
          self.viewAllbtncss = "viewall-btn";
        } else {
          self.viewAllbtncss = "viewall-btn-sticky";
        }
      }
    });
    */
    /*
    getAssignedArticles()
      .then(result => {
        console.log("getAssignedArticles", result);
        if (result.isSuccess) {
          this.allArticles = result.frontLineKnwList;
          this.handleFilterArticles();

          this.TOTAL_ARTICLES = this.allArticles.length;
          this.getfirstthreeArticles();
          this.articleCount = "Assigned Articles (" + this.UNREAD_ARTICLES + ")";
        } else {
          this.error = result.errorMessage;
        }
        console.log("getAssignedArticles", this.articles);
      })
      .catch(error => {
        this.error = error;
      });
*/

    if (formFactor == "Medium" || formFactor == "Small") {
      this.largeDevice = false;
    }
  }

  handlerRefresh() {
    refreshApex(this.wiredArticles);
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

  getfirstthreeArticles() {

    console.log("getfirstthreeArticles 1");

    //this.compareandProcessArticles();

    console.log("getfirstthreeArticles 2");

    if (this.allArticles.length > this.NUMBER_ARTICLE_TODISPLAY) 
    {
      this.ismorethanthreeArticles = true;
      let tempassigneArticle = new Array();
      for (let i = 0; i < this.NUMBER_ARTICLE_TODISPLAY; i++) 
      {
        tempassigneArticle.push(this.allArticles[i]);
      }
      this.articles = tempassigneArticle;
    } 
    else 
    {
      this.ismorethanthreeArticles = false;
      this.articles = this.allArticles;
    }
    console.log("getfirstthreeArticles", this.articles);

    this.btn_label = "View All";
    this.assignedArticleCss = "assignedArticle-OverLay";
    this.viewAllbtncss = "viewall-btn";

    let assignedArticle = this.template.querySelector(".asignedArticle");
    if (assignedArticle && this.largeDevice)
    {
      assignedArticle.style = "overflow-y:scroll;overflow-x:hidden;";
    }

  }

  handleClick(evt) {
    evt.preventDefault();
    let artid = evt.currentTarget.getAttribute("id").split("-")[0];
    this.markArticleRead(artid);
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: artid,
        actionName: "view"
      }
    });
  }

  resetCache() {
    console.log("Clear Session cache");
    clearSessionCache({
      
    })
      .then((result) => {
        console.log("ClearSession Cache", result);
        if (result) {
          //this.markArticleReadinList(articleId);
          console.log("Calling handlerRefesh");
          this.handlerRefresh();
          console.log("HandlerRefes complete");
        } else {
          this.showToast("Error Refreshing Cache", result.errorMessage, "error");
        }
      })
      .catch((error) => {
        console.log("ClearSessionCache", error);
        this.showToast("Something went wrong", result.errorMessage, "error");
        this.error = error;
      });
  }

  async markArticleRead(articleId) {
    console.log("markArticleRead", articleId);
    markArticleRead({
      knowledgeId: articleId
    })
      .then((result) => {
        console.log("markArticleRead", result);
        if (result.isSuccess) {
          //this.markArticleReadinList(articleId);
          this.handlerRefresh();
        } else {
          this.showToast("Something went wrong", result.errorMessage, "error");
        }
      })
      .catch((error) => {
        console.log("markArticleRead", error);
        this.error = error;
      });
  }
  /*
    markArticleReadinList(articleId) {
      let tempassigneArticle = JSON.parse(JSON.stringify(this.articles));
      for (let i = 0; i < this.TOTAL_ARTICLES; i++) {
        if (
          tempassigneArticle[i].compId === articleId &&
          !tempassigneArticle[i].isRead
        ) {
          tempassigneArticle[i].isRead = true;
          this.UNREAD_ARTICLES -= 1;
          break;
        }
      }
      this.articles = tempassigneArticle;
      this.articleCount = "Assigned Articles (" + this.UNREAD_ARTICLES + ")";
      console.log(
        "processed markArticleReadinList",
        this.articles,
        "UNREAD_ARTICLES",
        this.UNREAD_ARTICLES
      );
      this.handleFilterArticles();
    }
  */

  handleViewAll(evt) {
    let assignedArticle = this.template.querySelector(".asignedArticle");
    evt.preventDefault();
    if (this.btn_label === "View All") {
      this.articles = this.allArticles;
      this.btn_label = "Close";

      if (assignedArticle && this.largeDevice) {
        assignedArticle.style =
          "overflow-y:scroll;overflow-x:hidden;margin-bottom:13%";
        this.assignedArticleCss = "assignedArticle-OverLay-fixed";
        this.viewAllbtncss = "viewall-btn-sticky";
      }
    } else {
      this.getfirstthreeArticles();
      if (assignedArticle && this.largeDevice) {
        assignedArticle.style.overflow = "hidden";
        this.assignedArticleCss = "assignedArticle-OverLay";
        this.viewAllbtncss = "viewall-btn";
      }
    }

    console.log("processed markArticleReadinList", this.articles);
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

  compareandProcessArticles() 
  {


    //herehere
    // tmp_allArticles = [];
//    tmp_allArticles  = this.allArticles;

console.log('this.articles.length='+this.articles.length);
console.log('this.allArticles.length='+this.allArticles.length);
//console.log('tmp_allArticles.length='+tmp_allArticles.length);

    for (let j = 0; j < this.articles.length; j++) 
    {
      for (let i = 0; i < this.allArticles.length; i++) 
      {
        if (this.articles[j].compId === this.allArticles[i].compId) 
        {
          console.log("in loop number",i);
          this.allArticles[i] = this.articles[j];
          break;
        }
      }
    }
  }
}