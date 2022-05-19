import { LightningElement, api } from 'lwc';
import { NavigationMixin } from "lightning/navigation"; 

export default class ArticleItemGridCmp extends NavigationMixin(LightningElement) {
  @api article;
  url;
  articleRecordRef;

  connectedCallback() {
    this.articleRecordRef = {
      type: "standard__recordPage",
      attributes: {
        recordId: this.article.id,
        actionName: "view"
      }
    };
    this[NavigationMixin.GenerateUrl](this.articleRecordRef).then(
      (url) => (this.url = url)
    );
  }
  get backgroundStyle() {
    return `background-image:url(${this.article.previewImage})`;
  }

  get articleUrl() {
    return null;
  }

  navigateToArticle(event) {
    event.preventDefault();
    event.stopPropagation();
    if(!this.article.isRead) {
        console.log("in navigate to article read event for id: ", this.article.id);
        this.fireArticleReadEvent();
    }
    this[NavigationMixin.Navigate](this.articleRecordRef);
  }

  get summaryCss() {
    let cssClasses =
      "slds-p-vertical_x-small slds-p-horizontal_small slds-wrap";
      if(this.article.previewImage) {
        cssClasses +=
          " article-summary slds-line-clamp_medium";
      } else {
        cssClasses += " article-summary-no-image";
      }
      return cssClasses;

  }

  fireArticleReadEvent() {
    console.log('in fire read event for id: ', this.article.id);
    const articleReadEvent = new CustomEvent("articleread", {
      detail: { kavid: this.article.id }
    });
    this.dispatchEvent(articleReadEvent);
  }
}