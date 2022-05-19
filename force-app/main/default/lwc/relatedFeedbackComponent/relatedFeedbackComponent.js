import {
    LightningElement,
    api
} from 'lwc';
import {
    NavigationMixin
} from "lightning/navigation";
import getArtcileFeedbacks from "@salesforce/apex/RelatedFeedbackController.getArtcileFeedbacks";

export default class RelatedFeedbackComponent extends NavigationMixin(
    LightningElement
) {
    @api knowledgeArticleId;
    error = '';
    relatedFedbackCount = 'Feedback Responses (0)';
    artcileFeedbacks = [];
    allArtcileFeedbacks = [];
    ismorethanthreeArticles = false;
    btn_label = 'View All';
    sixFeedbacks = '';

    NUMBER_FEEDBACKS_TODISPLAY = 3;

    connectedCallback() {
        console.log('RelatedFeedbackComponent recordId', this.knowledgeArticleId);
        getArtcileFeedbacks({
                knowledgeArticleId: this.knowledgeArticleId
            })
            .then(result => {
                console.log("RelatedFeedbackComponent Result", result);
                if (result.isSuccess) {
                    this.relatedFedbackCount = 'Feedback Responses (' + result.articleFeedbacks.length + ')';
                    this.allArtcileFeedbacks = result.articleFeedbacks;
                    this.getfirstthreeArticles();
                } else {
                    this.error = result.errorMessage;
                }
            })
            .catch(error => {
                this.error = error;
            });
    }

    getfirstthreeArticles() {
        if (this.allArtcileFeedbacks.length > this.NUMBER_FEEDBACKS_TODISPLAY) {
            this.ismorethanthreeArticles = true;
            let tempfeedbacks = new Array();
            for (let i = 0; i < this.NUMBER_FEEDBACKS_TODISPLAY; i++) {
                tempfeedbacks.push(this.allArtcileFeedbacks[i]);
            }
            this.artcileFeedbacks = tempfeedbacks;
        } else {
            this.ismorethanthreeArticles = false;
            this.artcileFeedbacks = this.allArtcileFeedbacks;
        }
        this.btn_label = "View All";
        this.sixFeedbacks = '';
    }

    handleTextClick(evt) {
        let artid = evt.currentTarget.getAttribute("id").split("-")[0];
        this[NavigationMixin.Navigate]({
            type: "standard__recordPage",
            attributes: {
                recordId: artid,
                actionName: "view"
            }
        });
    }

    handleViewAll(evt) {
        if (this.btn_label === 'View All') {
            this.artcileFeedbacks = this.allArtcileFeedbacks;
            this.btn_label = "Collapse";
            this.sixFeedbacks = 'dislayfullcss';
        } else if (this.btn_label === 'Collapse') {
            this.getfirstthreeArticles();
        }
    }
}