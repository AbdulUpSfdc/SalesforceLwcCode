import { track,api } from 'lwc';

import * as BwcUtils from 'c/bwcUtils';
import * as BwcConstants from 'c/bwcConstants';
import BwcPageElementBase from 'c/bwcPageElementBase';
import { getRecommendations } from 'c/bwcRecommendationServices';

//Custom labels
import label_noIntentFounds from '@salesforce/label/c.BWC_Recommendations_not_found';
import label_mulesoftErrorCode from '@salesforce/label/c.BWC_UnexpectedError_RefreshSection';
import label_noIntentFoundAccount from '@salesforce/label/c.BWC_RecommendationsNoRecommendationsAccount';

const COMPONENT_UI_NAME = 'Recommendations (Predictive intents)';
const NO_INTENT_FOUND = 'No Intent Found'; //Value returned when there are no Intents for a given account.

export default class BWCRecommendations extends BwcPageElementBase {

    @api recordId;
    @track bANRecommendationOffers=[];

    showMore=true;
    showMoreOffers=false;
    isRendered;
    noRecommendations;
    isLoading;

    get errorReports() {return this.template.querySelector('c-bwc-error-reports');}

    async handleRefresh(){
        await this.callGetRecommendations();
    }

    async renderedCallback(){

        if (!this.isRendered) {
            this.isRendered = true;

            // Work around boxcarring by waiting so this component doesn't block product search from completion
            this.isLoading = true;
            await BwcUtils.wait(BwcConstants.BOXCAR_WAIT);

            await this.callGetRecommendations();
        }

    }

    async callGetRecommendations(){

        this.isLoading = true;

        try {

            super.clearNotifications();

            const responseWrapper = await getRecommendations(this.recordId);
            BwcUtils.log('result getRecommendations: ', responseWrapper);
            const { recommendations } = responseWrapper;

            const hasIntents = this.checkHasIntents(recommendations);

            if(hasIntents) {

                this.bANRecommendationOffers = recommendations.map(rec=> {

                    rec.offers = rec.offers.slice(0,3);
                    rec.accountTypelabel=BwcConstants.BillingAccountType.getLabelForValue(rec.accountType);

                    if(!rec.offers){
                        rec.noOffers = label_noIntentFoundAccount;
                    }

                    return rec;
                });

            }
            else {
                super.addInlineNotification(label_noIntentFounds, 'info');
            }

        }
        catch(error) {
            super.handleError(error, label_mulesoftErrorCode, COMPONENT_UI_NAME, 'inline');
        }
        finally {
            this.isLoading = false;
        }

    }

    checkHasIntents(recommendations){

        if(!recommendations || !Array.isArray(recommendations)){
            return false;
        }

        // Empty array / no accounts
        if(recommendations.length==0){
            return false;
        }

        return recommendations.some( recommendation => {

            return recommendation.offers?.some(offer=> offer.displayDescription !== NO_INTENT_FOUND);

        });

    }

    handleLmsRefresh(scope, recordId){
        if(!scope && recordId === this.recordId){
            this.handleRefresh();
        }
    }

    handleExpandCollapse(){

        this.showMoreOffers = !this.showMoreOffers;
        this.showMore= !this.showMore;

    }

    get expandCollapseLabel(){
        return this.showMore ? 'Expand All' : 'Collapse All';
    }

}