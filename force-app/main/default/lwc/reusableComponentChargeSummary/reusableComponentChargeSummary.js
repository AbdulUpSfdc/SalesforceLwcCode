import { LightningElement, api } from 'lwc';

export default class ReusableComponentChargeSummary extends LightningElement {
    @api originalvalue;
    @api newvalue;
    @api displaylist;
}