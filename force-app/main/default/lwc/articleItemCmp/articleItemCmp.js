import { LightningElement, api } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import formFactorPropertyName from "@salesforce/client/formFactor";

export default class ArticleItemCmp extends NavigationMixin(LightningElement) {
  @api article;
  url;
  articleRecordRef;

  connectedCallback() {
    if (formFactorPropertyName == "Large") {
      this.articleRecordRef = {
        type: "standard__recordPage",
        attributes: {
          recordId: this.article.id,
          objectApiName: "Knowledge__kav",
          actionName: "view"
        }
      };
    } else {
      /* this.articleRecordRef = {
         "type": "standard__knowledgeArticlePage",
    "attributes": {
        "urlName": "Test-Glen-Raj-1"
    }
        }; */
      this.articleRecordRef = {
        type: "standard__recordPage",
        attributes: {
          recordId: this.article.id,
          objectApiName: "Knowledge__kav",
          actionName: "view"
        }
      };
    }
    this[NavigationMixin.GenerateUrl](this.articleRecordRef).then(
      (url) => (this.url = url)
    );
  }

  get backgroundStyle() {
    return `background-image:url(${this.article.previewImage})`;
  }

  get isRecommended() {
    return this.article.recommended;
  }

  get hasSnippetTitle() {
    //TODO snippet logic
    return false;
  }

  get titleCss() {
    let badgeAllowanceInt = 12 - this.getBadgeAllowance();
    let cssClasses = "slds-col slds-p-right_small slds-truncate article-title ";
    return cssClasses + "slds-size-" + badgeAllowanceInt + "-of-12";
  }

  get badgeCss() {
    let cssClasses =
      "slds-col slds-float_right slds-shrink-none slds-p-left_small ";
    return cssClasses + "slds-size-" + this.getBadgeAllowance() + "-of-12";
  }

  getBadgeAllowance() {
    let badgeAllowance = 0;
    if (this.article.recommended) badgeAllowance += 2;
    if (this.article.isUrgent) badgeAllowance += 2;
    if (this.article.isUnread) badgeAllowance += 2;
    if (badgeAllowance == 0) badgeAllowance = 2;
    return badgeAllowance;
  }

  navigateToArticle(event) {
    event.preventDefault();
    event.stopPropagation();
    if (!this.article.isRead) {
      console.log(
        "in navigate to article read event for id: ",
        this.article.id
      );
      this.fireArticleReadEvent();
    }
    this[NavigationMixin.GenerateUrl](this.articleRecordRef).then(
      (url) => (this.url = url)
    );
    if (formFactorPropertyName == "Large") {
      this[NavigationMixin.Navigate](this.articleRecordRef);
    }  else {
      //this[NavigationMixin.Navigate](this.articleRecordRef);
      // Navigate to a URL
      this[NavigationMixin.Navigate](this.articleRecordRef, false);
      
    } 
  }

  fireArticleReadEvent() {
    console.log("in fire read event for id: ", this.article.id);
    const articleReadEvent = new CustomEvent("articleread", {
      detail: { kavid: this.article.id }
    });
    this.dispatchEvent(articleReadEvent);
  }
}