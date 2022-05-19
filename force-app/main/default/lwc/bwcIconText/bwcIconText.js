import { LightningElement, api } from 'lwc';

const RIGHT_POSITION = 'right';

export default class BwcIconText extends LightningElement {

    @api iconAlternativeText;
    @api iconName;
    @api iconVariant;
    @api value;
    @api position;

    get gridClass(){
        let cssClass = 'slds-grid slds-p-horizontal_x-small ';
        if(this.position === RIGHT_POSITION){
            cssClass+=' slds-grid_align-end slds-grid_reverse '
        }

        return cssClass;
    }
}