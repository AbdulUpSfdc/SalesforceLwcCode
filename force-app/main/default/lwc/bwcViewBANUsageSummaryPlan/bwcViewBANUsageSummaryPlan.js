import { LightningElement, api } from 'lwc';

export default class BwcViewBANUsageSummaryPlan extends LightningElement {
    @api usageSummary;

    get ctnUsageCardSize() {
        return this.usageSummary.showChart ? 6 : 12;
    }

    handleDetailsTypeClick(event) {
        if (this.usageSummary.showChart) {
            // Re-initialize chart in chart component
            const chartComponent = this.template.querySelector('c-bwc-view-b-a-n-usage-summary-chart');
            chartComponent.planTypeSelected = event.target.name;
            chartComponent.initializeChart();
        }

        const subscriberComponent = this.template.querySelector('c-bwc-view-b-a-n-usage-summary-c-t-n-usage');
        subscriberComponent.planTypeSelected = event.target.name;
        subscriberComponent.initSubscriberList();

        this.highlightSelectedTypeButton(event.target.name);
    }

    dataButtonVariant = 'brand';
    textButtonVariant = 'neutral';
    talkButtonVariant = 'neutral';
    highlightSelectedTypeButton(type) {
        switch (type) {
            case 'data':
                this.dataButtonVariant = 'brand';
                this.textButtonVariant = 'neutral';
                this.talkButtonVariant = 'neutral';
                break;
            case 'text':
                this.textButtonVariant = 'brand';
                this.dataButtonVariant = 'neutral';
                this.talkButtonVariant = 'neutral';
                break;
            case 'talk':
                this.talkButtonVariant = 'brand';
                this.textButtonVariant = 'neutral';
                this.dataButtonVariant = 'neutral';
                break;
            default:
                break;
        }
    }
}