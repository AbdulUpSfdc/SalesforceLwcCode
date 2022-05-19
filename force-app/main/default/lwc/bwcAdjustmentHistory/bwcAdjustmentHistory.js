import { api, wire } from 'lwc';
import BwcPageElementBase from 'c/bwcPageElementBase';
import { getRecord, getFieldValue  } from 'lightning/uiRecordApi';

import * as BwcConstants from 'c/bwcConstants';
import * as BwcAdjustments from 'c/bwcAdjustments';
import * as BwcAccountServices from 'c/bwcAccountServices';
import * as BwcAdjustmentServices from 'c/bwcAdjustmentServices';

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

const DEFAULT_PAGE_NUMBER = 0;
const DEFAULT_PAGE_SIZE = 600;

export default class bwcAdjustmentHistory extends BwcPageElementBase {

    labels = BwcAdjustments.labels;

    columns = [
        { label: 'Date', fieldName: 'adjCreationDate', type: 'text', hideDefaultActions: true, cellAttributes: { alignment: 'left' }, sortable: true },
        { label: 'CTN', fieldName: 'ctn', type: 'text', hideDefaultActions: true, cellAttributes: { alignment: 'left' }, sortable: true },
        { label: this.labels.account, fieldName: 'accountNumber', type: 'text', hideDefaultActions: true, cellAttributes: { alignment: 'left' }, sortable: true },
        { label: 'Description', fieldName: 'userOrSystemBillText', type: 'text', hideDefaultActions: true, cellAttributes: { alignment: 'left' }, sortable: true },
        { label: 'Amount', fieldName: 'amount', type: 'currency', hideDefaultActions: true, cellAttributes: { alignment: 'left' }, sortable: true },
        { label: 'Tax', fieldName: 'tax', type: 'currency', hideDefaultActions: true, cellAttributes: { alignment: 'left' }, sortable: true },
        { label: 'Total', fieldName: 'total', type: 'currency', hideDefaultActions: true, cellAttributes: { alignment: 'left' }, sortable: true },
        { label: 'On Bill', fieldName: 'displayOnBill', type: 'boolean', hideDefaultActions: true, cellAttributes: { alignment: 'left' }, sortable: true },
        { label: 'Balance Impact', fieldName: 'balanceImpact', type: 'boolean', hideDefaultActions: true, cellAttributes: { alignment: 'left' }, sortable: true }
    ];

    // The Salesforce Interaction Record Id
    @api recordId;

    @api viewAll = false;
    
    @wire(getRecord, { recordId: '$recordId', fields: INTERACTION_FIELDS}) 
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

    /* Pagination */
    resetPagination() {
        this.billingAccounts.forEach(account => account.paginationInfo.pageNo = DEFAULT_PAGE_NUMBER);
    }

    paginate() {
        this.billingAccounts.forEach(account => account.paginationInfo.pageNo++);
    }

    /*
        Search through all the filtered billing accounts' adjustments.
        If all of the adjustments in the account have moreRows, 
        then show LoadMore Button
    */
    get showLoadMore() {

        const paginateableBillingAccounts = this.filteredBillingAccounts.filter(account => {
            const adjustments = this.adjustments.filter(adjustment =>  adjustment.accountNumber === account.accountNumber);
            
            if(adjustments.length == 0) return false;
            
            return adjustments.every(adjustment => adjustment.moreRows !== '0')
        });

        return this.viewAll && paginateableBillingAccounts.length > 0;
    }

    /* Sorting */
    defaultSortDirection = 'desc';
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
                    market: billingAccount.Billing_Market__c,
                    paginationInfo: {
                        pageNo: DEFAULT_PAGE_NUMBER,
                        pageSize: DEFAULT_PAGE_SIZE
                    }
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
            super.handleError(error, this.labels.unexpectedError, 'Adjustment History', 'inline');
        } finally {
            this.isLoading = false;
        }
    }

    async loadAdjustments(billingAccounts) {
        try {

            const adjustments = [];

            /* Get Adjustments */
            const result = await BwcAdjustmentServices.getPostedAdjustments(this.recordId, billingAccounts);

            result.forEach(account => {

                // Separate the adjustment history from the account data in the response
                const { adjHistView: history, ...accountDetails} = account;

                // Check if the account has history
                if(history == null) return;

                const ctn = this.primaryContactNumber;

                history.forEach(postedAdjustment => {
                    adjustments.push({ctn, ...accountDetails, ...postedAdjustment});
                });
            });
                
            return BwcAdjustments.sort( adjustments, 'adjCreationDate', 'desc');

        } catch( error ) {
            super.handleError(error, this.labels.unexpectedError, 'Adjustment History', 'inline');
            this.isLoading = false;
        }
    }

    /*** Event Handlers ***/
    handleRefresh() {
        this.init();
    }

    handleViewAll() {
        BwcAdjustments.openViewAllAdjustments(
            this,
            this.recordId,
            this.interactionName,
            this.interactionName__c
        );
    }

    async handleFilter(event) {

        this.isLoading = true;

        this.resetPagination();

        this.selectedFilter = event.detail.value;

        this.adjustments = await this.loadAdjustments( this.filteredBillingAccounts );

        this.isLoading = false;
    }

    async handleLoadMore() {

        this.isLoading = true;

        this.paginate();

        const adjustments =  [
            ...this.adjustments,
            ...await this.loadAdjustments( this.filteredBillingAccounts )
        ];

        this.adjustments = BwcAdjustments.sort( adjustments, 'adjCreationDate', 'desc');

        this.isLoading = false;
    }

    handleSort(event) {
     
        const { fieldName: sortedBy, sortDirection } = event.detail;
     
        this.adjustments = BwcAdjustments.sort( [...this.adjustments], sortedBy, sortDirection );
     
        this.sortDirection = sortDirection;
     
        this.sortedBy = sortedBy;
    }
}