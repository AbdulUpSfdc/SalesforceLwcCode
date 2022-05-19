import { api, wire } from 'lwc';
import BwcPageElementBase from 'c/bwcPageElementBase';
import { getRecord, getFieldValue  } from 'lightning/uiRecordApi';

import * as BwcUtils from 'c/bwcUtils';
import * as BwcConstants from 'c/bwcConstants';
import * as BwcAdjustments from 'c/bwcAdjustments';
import * as BwcAccountServices from 'c/bwcAccountServices';
import * as BwcAdjustmentServices from 'c/bwcAdjustmentServices';

// Custom Permissions
import hasCAFrontLinePermission from '@salesforce/customPermission/Credit_Adjustments_Front_Line';
import hasCABackOfficeManagerPermission from '@salesforce/customPermission/Credit_Adjustments_Back_Office_Manager';

const INTERACTION_FIELDS = [
    'Interaction__c.Name', 
    'Interaction__c.Name__c', 
    'Interaction__c.Primary_Contact_Number__c'
];

const BILLING_ACCOUNT_TYPES = [
    BwcConstants.BillingAccountType.WIRELESS.value
];

const DEFAULT_FILTER_OPTION = {
    label: 'All BANs',
    value: ''
};

const DEFAULT_ROW_ACTION = {
    label: '- No Actions -', 
    name: 'noactions', 
    disabled : true
};

export default class bwcPendingChargesCredits extends BwcPageElementBase {

    labels = BwcAdjustments.labels;

    columns = [
        { label: 'Creation Date', fieldName: 'transactionDate', type: 'text', hideDefaultActions: true, cellAttributes: { alignment: 'left' }, sortable: true },
        { label: 'CTN', fieldName: 'subscriberNumber', type: 'text', hideDefaultActions: true, cellAttributes: { alignment: 'left' }, sortable: true },
        { label: 'Bill Date', fieldName: 'nextBillDate', type: 'text', hideDefaultActions: true, cellAttributes: { alignment: 'left' }, sortable: true },
        { label: this.labels.account, fieldName: 'accountNumber', type: 'text', hideDefaultActions: true, cellAttributes: { alignment: 'left' }, sortable: true },
        { label: 'Code', fieldName: 'transactionCode', type: 'text', hideDefaultActions: true, cellAttributes: { alignment: 'left' }, sortable: true },
        { label: 'Description', fieldName: 'description', type: 'text', hideDefaultActions: true, cellAttributes: { alignment: 'left' }, sortable: true },
        { label: 'Amount', fieldName: 'amount', type: 'currency', hideDefaultActions: true, cellAttributes: { alignment: 'left' }, sortable: true },
        { label: 'Tax', fieldName: 'taxAmount', type: 'currency', hideDefaultActions: true, cellAttributes: { alignment: 'left' }, sortable: true },
        { label: 'Total', fieldName: 'totalAmount', type: 'currency', hideDefaultActions: true, cellAttributes: { alignment: 'left' }, sortable: true },
        { label: 'Type', fieldName: 'type', type: 'text', hideDefaultActions: true, cellAttributes: { alignment: 'left' }, sortable: true },
        { type: 'action', typeAttributes: { rowActions: this.getRowActions }}
    ];

    /*
        Get Pending Actions based upon row data
    */
    getRowActions(row, doneCallback) {

        const actions = [];

        if ( hasCAFrontLinePermission || hasCABackOfficeManagerPermission ) {

            const reverse = { label: 'Reverse', name: 'reverse' };

            if(row.type !== 'Credit') {
                reverse.disabled = true;
            }

            actions.push(reverse);
        }

        if (actions.length == 0) {
            actions.push( DEFAULT_ROW_ACTION );
        }
        
        doneCallback(actions);
    }

    // The Salesforce Interaction Record Id
    @api recordId;

    @api viewAll = false;

    @wire(getRecord, { recordId: '$recordId', fields: INTERACTION_FIELDS }) 
    interaction;

    get interactionName() {
        return getFieldValue(this.interaction.data, 'Interaction__c.Name');
    }

    get interactionName__c() {
        return getFieldValue(this.interaction.data, 'Interaction__c.Name__c');
    }

    get primaryContactNumber() {
        return getFieldValue(this.interaction.data, 'Interaction__c.Primary_Contact_Number__c');
    }

    billingAccounts = [];
    adjustments = [];

    /*** Custom Permissions ***/
    get hasCreditAdjustmentsPermission() {
        return hasCAFrontLinePermission || hasCABackOfficeManagerPermission;
    }

    /***  UI Variables ***/
    isLoading = false;

    get isError() {
        return super.hasErrorNotifications;
    }
    
    get showTable() {
        return !this.isError && this.billingAccounts.length > 0 && this.adjustments.length > 0;
    }
    
    get showEmpty() {
        return !this.isLoading 
            && !this.isError 
            && !( this.billingAccounts.length > 0 && this.adjustments.length > 0 );
    }

    get showViewAllLink() {
        return this.adjustments.length > 10 && !this.viewAll;
    }

    /* Filtering */
    filterOptions;

    selectedFilter = '';

    get filteredBillingAccounts() {
        return this.billingAccounts.filter(
            account => this.selectedFilter === '' ? true : account.accountNumber = this.selectedFilter
        );
    }

    /* Sorting */
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedBy;
    
    /*** LWC Callbacks ***/
    connectedCallback() {

        super.connectedCallback();
        
        this.init();
    }

    async init() {

        // Reset errors
        super.clearNotifications();

        // Wipe the data clean.
        this.adjustments = [];

        // show spinner
        this.isLoading = true;

        try {
            
            /* Get Billing Accounts */
            this.billingAccounts = ( await BwcAccountServices.getBillingAccounts(this.recordId, true, true, BILLING_ACCOUNT_TYPES) )
            .map(billingAccount => {
                return {
                    accountNumber: billingAccount.Billing_Account_Number__c,
                    accountType: billingAccount.Account_Type__c,
                    market: billingAccount.Billing_Market__c
                };
            });

            if(this.billingAccounts.length === 0) {
                return;
            }

            /* Set Filter Options */
            this.filterOptions = this.billingAccounts.map(account => {
                
                const label = 
                    BwcConstants.BillingAccountType.getLabelForValue(account.accountType)
                    + ' - ' +
                    account.accountNumber;

                return { label, value: account.accountNumber };
            });

            this.filterOptions.unshift( DEFAULT_FILTER_OPTION );

            this.adjustments = await this.loadAdjustments(this.billingAccounts);
            
            // Slice the length if we are only previewing adjustments
            if(this.adjustments.length > 10 && !this.viewAll) {
                this.adjustments = this.adjustments.slice(0,10);
            }

        } catch(error) {
            super.handleError(error, this.labels.unexpectedError, 'Pending Charges & Credits', 'inline');
        } finally {
            this.isLoading = false;
        }
    }

    async loadAdjustments(billingAccounts) {
        try {
            
            const adjustments = [];
            
            /* Get Adjustments */
            const result = await BwcAdjustmentServices.getPendingAdjustments(this.recordId, billingAccounts);

            result.forEach(account => {

                // Separate the adjustment history from the account data in the response
                const { pendingAdjCredits: pendingAdjustments, ...accountDetails} = account;

                // Check if the account has pendingAdjustments
                if(pendingAdjustments == null) return;

                const ctn = this.primaryContactNumber;

                pendingAdjustments.forEach(pendingAdjustment => {

                    pendingAdjustment.subscriberNumber = BwcUtils.formatPhone(pendingAdjustment.subscriberNumber);

                    pendingAdjustment.subscriberNumber = BwcUtils.formatPhone(pendingAdjustment.subscriberNumber);
                    adjustments.push({ctn, ...accountDetails, ...pendingAdjustment});

                });
            });

            return BwcAdjustments.sort( adjustments, 'transactionDate', 'desc');

        } catch(error)   {
            super.handleError(error, this.labels.unexpectedError, 'Pending Charges Credits', 'inline');
            this.isLoading = false;
        }
    }

    /* Event Handling */
    handleLmsRefresh(scope, recordId) {

        if ((scope === 'pendingChargesCredits' || !scope) && (!recordId || recordId === this.recordId)) {
            this.init();
        }
    }

    handleRefresh() {
        this.init();
    }

    /*
        Handle action menu selection for pending table row.
    */
    handleRowAction(event) {

        const row = event.detail.row;
        const name = event.detail.action.name;

        if(name === 'reverse') {
            BwcAdjustments.openReverseAdjustmentWizard( 
                this,
                this.recordId,
                this.interactionName,
                this.interactionName__c,
                row.accountNumber,
                row.transactionCode,
                row.transactionDate,
                row.description,
                row.amount,
                row.entSeqNo,
                row.subscriberNumber,
                row.nextBillDate
            );
        }
    }

    handleAddCharge() {
        BwcAdjustments.openAddNewChargeWizard(
            this,
            this.recordId
        );
    }

    handleViewAll() {
        BwcAdjustments.openViewAllPendingChargesCredits(
            this,
            this.recordId,
            this.interactionName,
            this.interactionName__c
        );
    }

    async handleFilter(event) {

        this.isLoading = true;

        this.selectedFilter = event.detail.value;

        this.adjustments = await this.loadAdjustments( this.filteredBillingAccounts );

        this.isLoading = false;
    }

    handleSort(event) {

        const { fieldName: sortedBy, sortDirection } = event.detail;
     
        this.adjustments = BwcAdjustments.sort( [...this.adjustments], sortedBy, sortDirection );
     
        this.sortDirection = sortDirection;
     
        this.sortedBy = sortedBy;
    }
}