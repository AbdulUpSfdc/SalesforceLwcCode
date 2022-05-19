import { LightningElement, api } from 'lwc';

export default class BwcExpandableSection extends LightningElement {

    _title='';

    set title(value){
        this._title = value;
        this.hasTitleString = value !== '';
    }

    @api get title(){
        return this._title;
    }
    @api variant;

    hasTitleString = false;

    get sectionClass() {return 'slds-section__title' + (this.variant === 'bold' ? ' section-title' : '')}

    handleExpandCollapseClick(event) {

        event.stopPropagation();

        const div = this.template.querySelector('div.slds-section');
        let isExpand;

        if (!div) {
            return;
        }

        if (div.classList.contains('slds-is-open')) {
            div.classList.remove('slds-is-open');
            div.classList.add('closed');
            isExpand = false;
        }
        else {
            div.classList.add('slds-is-open');
            div.classList.remove('closed');
            isExpand = true;
        }

        this.dispatchEvent(new CustomEvent('expand',{detail:isExpand, bubbles: true}))

    }

    @api expandCollapseSection(expand){
        const div = this.template.querySelector('div.slds-section');

        if (!div) {
            return;
        }

        if (!expand) {
            div.classList.remove('slds-is-open');
            div.classList.add('closed');
        }
        else if(expand) {
            div.classList.add('slds-is-open');
            div.classList.remove('closed');
        }
    }

    @api get isExpanded(){
        const div = this.template.querySelector('div.slds-section');

        if(!div){
            return false;
        }

        return div.classList.contains('slds-is-open');
    }

}