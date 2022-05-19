import { api, wire } from 'lwc';
import BwcPageElementBase from 'c/bwcPageElementBase';
import { getRecord  } from 'lightning/uiRecordApi';
import { getEscalationCasesByBillingAccount } from 'c/bwcEscalationCaseServices';

const COMPONENT_UI_NAME = 'Escalation Case Datatable';
const INTERACTION_FIELDS = [
    'Interaction__c.Billing_Account_Number__c'
];

export default class BwcEscalationCaseDatatable extends BwcPageElementBase {
    
    @api recordId;
    @api showAllCases = false;

    @wire(getRecord, { recordId: '$recordId', fields: INTERACTION_FIELDS}) 
    interaction({data,error}) {
        if(data) {
            this.billingAccountNumber = data.fields.Billing_Account_Number__c.value;
            this.load();
        } 
        
        if(error) {
            super.handleError(error, 'Failed to load interaction: ' + error.message, COMPONENT_UI_NAME, 'inline');
        }
    };

    billingAccountNumber;

    columns = [
        { 
            label: 'Case Number', 
            type: 'actionLink',
            fieldName: 'id', 
            typeAttributes: { 
                label: { fieldName: 'caseNumber' },
                onactionclick: this.handleCaseNumberClick.bind(this)
            }, 
            hideDefaultActions: true, 
            cellAttributes: { alignment: 'left' }, 
            sortable: false 
        },
        { label: 'Type', fieldName: 'type', type: 'text', hideDefaultActions: true, cellAttributes: { alignment: 'left' }, sortable: false },
        { label: 'Case Action', fieldName: 'caseAction', type: 'text', fixedWidth: 400, hideDefaultActions: true, cellAttributes: { alignment: 'left' }, sortable: false },
        { label: 'Closed', fieldName: 'closed', type: 'text', hideDefaultActions: true, cellAttributes: { alignment: 'left' }, sortable: false },
        { label: 'Date Opened', fieldName: 'dateOpened', type: 'date', typeAttributes: { month: '2-digit', day: '2-digit', year: 'numeric' }, hideDefaultActions: true, cellAttributes: { alignment: 'left' }, sortable: false },
        { label: 'Target Close Date', fieldName: 'targetCloseDate', type: 'date', typeAttributes: { month: '2-digit', day: '2-digit', year: 'numeric' }, hideDefaultActions: true, cellAttributes: { alignment: 'left' }, sortable: false },
        { label: 'Date Closed', fieldName: 'dateClosed', type: 'date', typeAttributes: { month: '2-digit', day: '2-digit', year: 'numeric' }, hideDefaultActions: true, cellAttributes: { alignment: 'left' }, sortable: false },
    ];

    isLoading = false;

    cases = [];
    filteredCases = [];

    get length() {
        return this.cases.length;
    }

    get noRecentCases() {
        return this.length === 0 ? true : false;
    }

    async load() {
        this.isLoading = true;

        if(this.billingAccountNumber === null) {
            this.addError('Failed to get Billing Account Number for this Interaction.');
            return;
        }

        try {
            const results = await getEscalationCasesByBillingAccount(this.billingAccountNumber);

            this.cases = results.map( c => {
                return {
                    id: c.Id,
                    caseNumber: c.CaseNumber,
                    type: c.Type,
                    caseAction: c.CaseAction__c,
                    targetCloseDate: c.Target_Close_Date__c ? new Date(c.Target_Close_Date__c) : '',
                    closed: (c.IsClosed) ? 'Yes' : 'No',
                    dateOpened: new Date(c.CreatedDate),
                    dateClosed: c.ClosedDate ? new Date(c.ClosedDate) : ''
                };
            });

            if(this.showAllCases) {
                this.filteredCases = this.cases;
            }
            else {
                this.filteredCases = this.cases.slice(0, 3);
            }
        } catch(error) {
            super.handleError(error, 'Failed to load Escalation Cases: ' + error.message, COMPONENT_UI_NAME, 'inline');
        } finally {
            this.isLoading = false;
            this.dispatchOnLoad();
        }
    }
    
    /*** Event Handling ***/
    dispatchOnLoad() {
        const detail = {
            length: this.cases.length
        }

        this.dispatchEvent(new CustomEvent('datatableload', { detail }));
    }

    handleCaseNumberClick(event) {
        const caseId = event.detail.value;

        const pageReference = {
            type: 'standard__recordPage',
            attributes: {
                recordId: caseId,
                objectApiName: 'Case',
                actionName: 'view'
            },
            state: {
                ws: `/lightning/r/Interaction__c/${this.recordId}/view`
            }
        };

        super.openSubtab(pageReference, caseId, 'custom:custom86');
    }
}