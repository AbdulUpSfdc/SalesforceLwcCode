import { LightningElement, api } from 'lwc';

// Labels
import usageSummaryMixMatchDisclaimer from '@salesforce/label/c.BWC_UsageSummary_MixMatch_Disclaimer';

export default class BwcViewBANUsageSummaryCTNUsage extends LightningElement {

    @api usageSummary;
    @api planTypeSelected = 'data';

    labels = {
        mixMatchDisclaimer : usageSummaryMixMatchDisclaimer
    }

    get itemSize() {
        return this.usageSummary.showChart ? 12 : 6;
    }

    isRendered = false;
    renderedCallback() {
        if (this.isRendered) {
            return;
        }
        this.isRendered = true;
        this.initSubscriberList();
    }

    subscriberList = [];
    @api initSubscriberList() {

        // Set data for chart depending on the type selected
        // Set legends for chart depending on the type selected
        if (this.planTypeSelected === 'data') {
            this.subscriberList = this.usageSummary.dataPlanUsage.usageByCtn;
        } else if (this.planTypeSelected === 'text') {
            this.subscriberList = this.usageSummary.textPlanUsage.usageByCtn;
        } else if (this.planTypeSelected === 'talk') {
            this.subscriberList = this.usageSummary.talkPlanUsage.usageByCtn;
        } else {
            this.subscriberList = null;
        }

    }
}