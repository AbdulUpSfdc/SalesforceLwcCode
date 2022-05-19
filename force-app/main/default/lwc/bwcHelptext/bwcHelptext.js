import { LightningElement, api } from 'lwc';

export default class BwcHelptext extends LightningElement {

    @api content;
    @api size = 'medium';
    @api nubbin = 'left';
    @api noIcon;

    get popoverClass() {return `slds-popover slds-hide slds-nubbin_${this.nubbin} slds-popover_${this.size}`}

    @api showPopover(target) {

        const nubbinSize = 16;

        // Show the popover
        const popover = this.template.querySelector('.slds-popover');
        popover.classList.remove('slds-hide');
        
        // Adjust absolute position to align for nubbin.
        switch (this.nubbin) {

            case 'top':
                popover.style.left = (target.offsetLeft - popover.offsetWidth / 2) + 'px';
                popover.style.top = (target.offsetTop + target.offsetHeight / 2) + 'px';
                break;

            case 'top-right':
                popover.style.left = (target.offsetLeft - popover.offsetWidth + nubbinSize * 2) + 'px';
                popover.style.top = (target.offsetTop + target.offsetHeight / 2) + 'px';
                break;

            default:
                popover.style.left = (target.offsetLeft + target.offsetWidth + nubbinSize) + 'px';
                popover.style.top = (target.offsetTop + target.offsetHeight / 2 - popover.offsetHeight / 2) + 'px';
                break;

        }

    }

    @api hidePopover() {

        // Hide the popover
        const popover = this.template.querySelector('.slds-popover');
        popover.classList.add('slds-hide');

    }

    handleMouseover(event) {

        this.showPopover(event.target);

    }

    handleMouseout() {

        this.hidePopover();

    }

}