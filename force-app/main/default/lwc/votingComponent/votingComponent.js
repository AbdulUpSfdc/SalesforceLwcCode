import {
    LightningElement,
    track,
    api,
    wire
} from 'lwc';
import getLikeDislikeCount from "@salesforce/apex/VotingComponentController.getLikeDislikeCount";
import doVoting from "@salesforce/apex/VotingComponentController.doVoting";

export default class VotingComponent extends LightningElement {
    @track likeState = false;
    @track dislikeState = false;
    @track responseObj;
    @track error;
    @track existingVoteId='';

    @api knowledgeArticleId;
    @api recordId;

    likeCount = 0;
    dislikeCount = 0;

    connectedCallback() {    
        this.knowledgeArticleId=this.recordId;
        getLikeDislikeCount({
                knowledgeArticleId: this.recordId
            })
            .then(result => {
                if (result.isSuccess) {
                    this.processCountUIs(result);
                } else {
                    this.error = result.errorMessage;
                }
            })
            .catch(error => {
                this.error = error;
            });
    }

    processCountUIs(result) {
        this.likeCount = result.likeCount;
        this.dislikeCount = result.dislikeCount;
        if (result.voteObj.Id) {
            this.existingVoteId = result.voteObj.Id;
            if (result.voteObj.Type === '5') {
                this.likeState = true;
                this.dislikeState = !this.likeState;
            } else {
                this.dislikeState = true;
                this.likeState = !this.dislikeState;
            }  
        }
    }

    handleLikeButtonClick() {
        if (!this.likeState) {
            this.handleVoting(true);
        }
    }

    handleDislikeButtonClick() {
        if (!this.dislikeState) {
            this.handleVoting(false);
        }
    }

    handleVoting(upvoteState) {
        let params = {
            existingVoteId: this.existingVoteId,
            knowledgeArticleId: this.knowledgeArticleId,
            isLike: upvoteState
        };
        doVoting(params)
            .then(result => {
                if (result.isSuccess) {
                    this.processCountUIs(result);
                } else {
                    this.error = result.errorMessage;
                }
            })
            .catch(error => {
                this.error = error;
            });
    }
}