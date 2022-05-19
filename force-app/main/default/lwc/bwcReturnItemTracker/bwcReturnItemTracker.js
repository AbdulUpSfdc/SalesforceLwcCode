import { LightningElement, api, track } from 'lwc';
//Other components
import * as BwcUtils from 'c/bwcUtils';

//Apex
import getStagesByFulfillmentType from '@salesforce/apex/BWC_OrderItemStageSelector.getStagesByFulfillmentType';

const RETURNS_FULFILLMENT_STATUS = 'Returns';

export default class BwcReturnItemTracker extends LightningElement {

    @track _milestones;
    @track currentMilestone = '';

    @api set itemStatus(values) {
        this.processItemStatus(values);
    }

    get itemStatus() {
        return this._milestones;
    }

    async processItemStatus(itemStatus) {
        try {

            BwcUtils.log({ itemStatus });
            if (itemStatus == undefined || itemStatus == null) return;

            let stages = await getStagesByFulfillmentType({ fulfillmentType: RETURNS_FULFILLMENT_STATUS });

            let { milestone } = itemStatus;
            let { code } = itemStatus;

            let chevronStages = [];

            let currentStage = stages.find((stage) => {
                return stage.Milestone__c == milestone || stage.Item_Status_Code__c === code
            });

            if (!currentStage) return;

            this.currentMilestone = currentStage.Chevron_label__c;
            for (let i = 0; i < stages.length; i++) {
                let stage = stages[i];

                if (stage.Chevron_label__c == currentStage.Chevron_label__c) {
                    chevronStages.push(stage);
                    continue;
                }

                if (stage.Chevron_index__c < currentStage.Chevron_index__c
                    && stage.Chevron_index__c != stages[i + 1]?.Chevron_index__c
                    && chevronStages.length < stage.Chevron_index__c
                ) {
                    chevronStages.push(stage);
                    continue;
                }

                if (stage.Chevron_index__c > currentStage.Chevron_index__c
                    && stage.Chevron_index__c != stages[i + 1]?.Chevron_index__c
                    && chevronStages.length < stage.Chevron_index__c) {
                    chevronStages.push(stage);
                }
            }

            let applicableMilestones = chevronStages.map((stage) => stage.Chevron_label__c);

            if (applicableMilestones == null || applicableMilestones == undefined) return;

            this._milestones = applicableMilestones;
        } catch (error) {
            BwcUtils.error(error);
        }

    }


}