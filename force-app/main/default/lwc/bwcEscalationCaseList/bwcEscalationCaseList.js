import { api } from 'lwc';
import BwcPageElementBase from 'c/bwcPageElementBase';

export default class BwcEscalationCaseList extends BwcPageElementBase {

    @api recordId;

    length = 0;

    get viewAll() {
        return this.length > 3 ? true : false;
    }

    /*** Event Handlers ***/
    handleOnLoad(event) {
        this.length = event.detail.length;
    }

    handleViewAllClick(event) {

        const pageReference = {
            type: 'standard__component',
            attributes: {
                componentName: 'c__bwcEscalationCaseListViewAllPage'
            },
            state: {
                c__recordId: this.recordId
            }
        };

        super.openSubtab(pageReference, 'Escalation Cases', 'custom:custom86');
    }
}