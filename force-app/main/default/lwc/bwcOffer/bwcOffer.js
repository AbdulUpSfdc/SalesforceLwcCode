import { LightningElement, api } from 'lwc';
import * as BwcConstants from 'c/bwcConstants';
// static resorurce svg icons
import recommendationiconsSvg from '@salesforce/resourceUrl/BWC_RecommendationIcons';

const HELP_TEXT = `This intent doesn't have an article attached.
                   Open a trouble ticket to report a missing knowledge article.`;

export default class BWCOffer extends LightningElement {

    @api index;
    @api offer;
    @api showMore;

    helptext = HELP_TEXT;

    /**  Always display the first recommendation for an account.
     * If user click on Expand All, display remaining recommendations
    */
    get displayOffer() {

        return this.index === 0 || this.showMore;

    }
    get iconName(){

        return `${recommendationiconsSvg}#${this.offer.SFDCIconType}`;
    }

    get hasUrl(){

        return this.offer?.url;
    }
    get showReadMore(){

        return this.offer?.url && this.offer?.url !== BwcConstants.NO_ARTICLE_NEEDED;
    }

    get showTooltip(){

        const isNoIntent = this.offer?.displayDescription === BwcConstants.NO_INTENT_FOUND;

        return (!this.hasUrl && !isNoIntent) ;
    }




}