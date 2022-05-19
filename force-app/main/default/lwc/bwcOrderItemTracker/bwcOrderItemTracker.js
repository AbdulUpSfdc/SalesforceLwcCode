import { LightningElement, api, track } from 'lwc';
//Other components
import * as BwcUtils from 'c/bwcUtils';

const C2S_STAGES = [
    {
        label:'Order Received',
        chevron: 1,
        index:0
    },
    {
        label:'Order Submitted',
        chevron: 1,
        index:1
    },
    {
        label:'Order Ready for Pickup',
        chevron: 2,
        index:2
    },
    {
        label:'Order Pickedup',
        chevron: 2,
        index:3
    },
    {
        label:'Order Fulfilled',
        chevron: 3,
        index:4
    },
];

const DF_STAGES = [
    {
        label:'Order Received',
        chevron: 1,
        index:0
    },
    {
        label:'Order Submitted',
        chevron: 1,
        index:1
    },
    {
        label:'Order Shipped',
        chevron: 2,
        index:2
    },
    {
        label:'Order Delivered',
        chevron: 2,
        index:3
    },
    {
        label:'Order Fulfilled',
        chevron: 3,
        index:4
    },
];

const PDO_DOO_STAGES = [
    {
        label:'Order Received',
        chevron: 1,
        index:0
    },
    {
        label:'Order Submitted',
        chevron: 1,
        index:1
    },
    {
        label:'Order Scheduled',
        chevron: 2,
        index:2
    },
    {
        label:'Expert On the way',
        chevron: 2,
        index:3
    },
    {
        label:'Expert Onsite',
        chevron: 2,
        index:4
    },
    {
        label:'Order Delivered',
        chevron: 2,
        index:5
    },
    {
        label:'Order Fulfilled',
        chevron: 3,
        index:6
    },
];

const fulfillmentTypeStages = {
    DF: {value: 'DF', stages: DF_STAGES},
    DirectFulfillment: {value: 'Direct Fulfillment', stages: DF_STAGES},
    C2S: {value: 'C2S', stages: C2S_STAGES},
    ClickToStore: {value: 'Click to Store', stages: C2S_STAGES},
    PDO: {value: 'PDO', stages: PDO_DOO_STAGES},
    PremiumDeliveryOption: {value: 'Premium Delivery Option', stages: PDO_DOO_STAGES},
    DOO: {value: 'DOO', stages: PDO_DOO_STAGES},
    DropOffOption: {value: 'Drop off Option', stages: PDO_DOO_STAGES},

    getStagesForValue: value => {
        return Object.values(fulfillmentTypeStages).find(item => item.value === value)?.stages;
    }
}

export default class BwcOrderItemTracker extends LightningElement {

    @track _milestones;
    @track currentMilestone='';

    @api fulfillmentType;

    @api set itemStatus(values){
        BwcUtils.log({values});
        if(values==undefined || values == null) return;

        let stages = fulfillmentTypeStages.getStagesForValue(this.fulfillmentType);

        if(!stages) return;
        let {milestone} = values;

        let chevronStages = [];

        let currentStage = stages.find((stage)=>stage.label==milestone);

        if(!currentStage) return;

        this.currentMilestone = currentStage.label;
        for(let i=0; i<stages.length; i++){
            let stage = stages[i];

            if(stage.label == currentStage.label){
              chevronStages.push(stage);
              continue;
            }

            if(stage.chevron<currentStage.chevron
              && stage.chevron != stages[i+1]?.chevron
              && chevronStages.length<stage.chevron
              ){
              chevronStages.push(stage);
              continue;
            }

            if(stage.chevron>currentStage.chevron
              && stage.chevron != stages[i+1]?.chevron
              && chevronStages.length<stage.chevron){
              chevronStages.push(stage);
            }
        }

        let applicableMilestones = chevronStages.map((stage)=>stage.label);

        if(applicableMilestones==null || applicableMilestones == undefined) return;

        this._milestones = applicableMilestones;
    }

    get itemStatus(){
        return this._milestones;
    }
}