import { LightningElement, api, track } from 'lwc';

const INCOMPLETE_STEP_CSS_CLASS = 'step incomplete';
const CURRENT_STEP_CSS_CLASS = 'step current';
const COMPLETE_STEP_CSS_CLASS = 'step complete';

export default class BwcPath extends LightningElement {

    @track _stages=[];

    @api currentStage;

    @api set stages(values){

        if(!Array.isArray(values) ) return;
        if(values.length===0) return;

        let indexCurrentStage=0;
        let i=0;

        // By Default all of the stages will be taken as incomplete
        let localStages = values.map((stage)=>{

            let tempStage = {
                label: stage,
                isCurrent: false,
                cssClass: INCOMPLETE_STEP_CSS_CLASS
            }

            if(stage===this.currentStage){
                console.log('current stage: Order Ready for Pickup')
                tempStage.isCurrent = true;
                tempStage.cssClass = CURRENT_STEP_CSS_CLASS;
                indexCurrentStage = i
            }

            i++;

            return tempStage;
        });

        //For loop to set complete css class
        i=0;
        localStages.forEach((stage)=>{
            if(i<indexCurrentStage){
                stage.cssClass = COMPLETE_STEP_CSS_CLASS;
            }
            i++;
        });

        this._stages = localStages;
    }

    get stages(){
        return this._stages;
    }

}