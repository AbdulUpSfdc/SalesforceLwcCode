import { LightningElement, api } from 'lwc';

export default class BwcCardItem extends LightningElement {

    @api label;
    @api noBottomBorder;

    get topClass() {return 'slds-grid slds-p-horizontal_small slds-p-vertical_x-small' + (!this.noBottomBorder ? ' slds-border_bottom' : '');}

}