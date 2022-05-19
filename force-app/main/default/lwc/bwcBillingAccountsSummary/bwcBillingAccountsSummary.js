import { track, api } from 'lwc';

import * as BwcUtils from 'c/bwcUtils';
import * as BwcLabelServices from 'c/bwcLabelServices';
import BwcPageElementBase from 'c/bwcPageElementBase';
import { getBillingAccountSummary } from 'c/bwcBillingAccountServices';

const billingAccountSummaryColumns = [
    { label: BwcLabelServices.labels.account, fieldName: 'Billing_Account_Number__c', type: 'text', hideDefaultActions: true, sortable: true},
    { label: 'LOB', fieldName: 'Service_Type_Name__c', type: 'text', hideDefaultActions: true, sortable: true },
    { label: 'Start', fieldName: 'Service_Start_Date__c', type: 'date-local',
        typeAttributes: {
            month: "2-digit",
            day: "2-digit"
        },
        hideDefaultActions: true, 
        sortable: true
    },
    { label: 'Status', fieldName: 'Account_Status__c', type: 'statusBadge',
        typeAttributes: {
            status: { fieldName: 'Account_Status__c' },
            suspensionStatus: { fieldName: 'Suspension_Status__c' }
        },
        hideDefaultActions: true, 
        sortable: true
    },
];

const COMPONENT_UI_NAME = 'Billing Accounts Summary';

export default class BwcBillingAccountsSummary extends BwcPageElementBase {

    // Labels
    labels = BwcLabelServices.labels;

    @api recordId;

    isRendered = false;
    isLoading = true;
    @track columns = billingAccountSummaryColumns;
    @track tableData=[];
    showTable = false;
    showEmpty= false;

    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedBy;

    get errorReports() {return this.template.querySelector('c-bwc-error-reports');}

    async renderedCallback() {

        if (!this.isRendered) {

            this.isRendered = true;

            await this.getBillingAccounts();

        }

    }

    async getBillingAccounts(){

        try {

            this.isLoading = true;
            super.clearNotifications();

            BwcUtils.log('call getServiceDetails: recordId: ' + this.recordId);
            const response = await getBillingAccountSummary(this.recordId);
            BwcUtils.log('result getServiceDetails: ' + response);
            this.tableData = response
            this.showTable = true;

        }
        catch (error) {
            super.handleError(error, this.labels.unexpectedError, COMPONENT_UI_NAME,'inline');
        }
        finally {
            this.isLoading = false;
        }
    }

    onHandleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.tableData];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.tableData = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    sortBy(field, reverse, primer) {
        const key = primer
            ? function (x) {
                  return primer(x[field]);
              }
            : function (x) {
                  return x[field] || '';
              };

        return function (a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }

    handleLmsRefresh(scope, recordId){
        if(!scope && recordId === this.recordId){
            this.getBillingAccounts();
        }
    }

}