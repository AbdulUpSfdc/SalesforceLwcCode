import { LightningElement, track, api } from 'lwc';

export default class LwcReusableAccordian extends LightningElement {
    @api header = 'AT&T Wi-Fi Gateway';
    @api subheader = 'May 28th - May 30th';
    @api expandable = false;
    @api expanded = false;
    @api description = 'AT&T Companies provide Internet Access through AT&T supported gateways to all authorized employees, and agents of the Company, for appropriate business purposes. Employees must exercise good judgment that is consisten';
    @api rightColumnKeywords = 'Included';

    handleAccordianClick(event){
        this.expanded = !this.expanded;
    }

    connectedCallback(){
        this.expandable = true;
    }

    get isShowDescription(){
        return this.description && ((this.expanded && this.expandable) || !this.expandable);
    }
}