import { LightningElement, api, wire } from "lwc";
import getknowledgeList from "@salesforce/apex/RecommandedRelatedArticleController.getknowledgeList";

export default class RecommandedRelatedKnowledgeArticle extends LightningElement {
  @api recordId;
  knowledgeList;
  resultObj;

  @wire(getknowledgeList, { knowledgeRecordId: "$recordId" })
  wiredknowledgeArticles(result) {
    this.resultObj = result;
    console.log("value: ", result);
    if (result.data) {
      this.knowledgeList = result.data.knowledegArtileList;
      console.log("knowledgeList", this.knowledgeList);
    }
  }
}