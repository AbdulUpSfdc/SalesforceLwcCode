import { api, LightningElement, track } from 'lwc';

// Other components
import * as BwcUtils from 'c/bwcUtils';

const LINE_INFORMATION_FIELDS = [
    {
        label: 'Line Market',
        fieldPath: 'lineMarket',
        value: '',
        isTextType:true,
    },
    {
        label: 'Line Sub-Market',
        fieldPath: 'lineSubMarket',
        value: '',
        isTextType:true,
    },
]

export default class BwcOrderLineDetails extends LightningElement {

    _line;

    @track lineInformationFields=[];

    @api get line(){
        return this._line;
    }

    set line(values){

        if(!values){
            return;
        }

        this.lineInformationFields = LINE_INFORMATION_FIELDS.map(tempField=>{
            const field = {...tempField};

            field.value = BwcUtils.getValueFromField(values, tempField.fieldPath);

            return field;
        });

    }

    @api expandCollapseSections(expand){

        const expandableSections = this.template.querySelectorAll('c-bwc-expandable-section');
        expandableSections.forEach(section=>{
            section.expandCollapseSection(expand);
        });

    }

    handleExpand(event){
        event.stopPropagation();

        this.dispatchEvent(new CustomEvent('expand',{detail:event.detail, bubbles: true}))
    }

    @api get expandedSections(){

        const expandableSections = [...this.template.querySelectorAll("c-bwc-expandable-section")];
        const sectionsCounter = {
            expanded: 0,
            closed:0
        };

        expandableSections.forEach((section)=>{
            const key = section.isExpanded ? 'expanded' : 'closed';
            sectionsCounter[key]++;
        });

        return sectionsCounter;

    }

}