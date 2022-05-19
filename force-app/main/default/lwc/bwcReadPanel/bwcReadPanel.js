import { LightningElement, api } from 'lwc';

export default class BwcReadPanel extends LightningElement {

    @api title = 'Read to the Customer:';
    @api iconName;
    @api text;
    @api variant = 'announcement';
    @api collapsible;
    @api collapsedTitle;
    @api defaultExpanded;

    isExpanded;

    get displayTitle() {return !this.collapsible ? this.title : ((this.isExpanded || !this.collapsedTitle) ? this.title : this.collapsedTitle);}
    get panelClass() {return 'slds-grid slds-grid_vertical slds-box slds-section panel' + (this.variant ? ' ' + this.variant : '');}
    get showText() {return !this.collapsible || this.isExpanded;}
    get switchIconName() {return this.isExpanded ? 'utility:chevrondown' : 'utility:chevronright';}

    get _iconName() {

        if (this.iconName) {
            return this.iconName;
        }
        switch (this.variant) {
            case 'info':
                return 'utility:info';
            default:
                return 'utility:announcement';
        }

    }

    handleExpandCollapseClick(event) {

        event.stopPropagation();

        const div = this.template.querySelector('div.slds-section');

        if (!div) {
            return;
        }

        if (div.classList.contains('slds-is-open')) {
            div.classList.remove('slds-is-open');
            this.isExpanded = false;
        }
        else {
            div.classList.add('slds-is-open');
            this.isExpanded = true;
        }

    }

}