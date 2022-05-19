import { LightningElement, api } from 'lwc';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcBillingServices from 'c/bwcBillingServices';
import * as BwcAdjustments from 'c/bwcAdjustments';

const STEP_NAME = 'chargeSelector';

export default class BwcMakeAdjustmentChargeSelector extends LightningElement {

    @api recordId;
    @api accountNumber;
    @api serviceType;
    @api selectedStatementId;

    statementRows = [];

    get serviceProduct() {
        return BwcAdjustments.ServiceProduct.getValueFromType(this.serviceType);
    }
    
    set isLoading(status) {
        this.dispatchLoad(status);
    }

    statementColumns = [
        {
            label: 'Service',
            fieldName: 'service', 
            initialWidth: 120,
            hideDefaultActions: true
        },
        {
            label: 'Group',
            fieldName: 'lineItemGroup',
            hideDefaultActions: true
        },
        {
            label: 'Bill Charges',
            fieldName: 'description',
            hideDefaultActions: true
        },
        {
            label: 'Selected Bill',
            fieldName: 'selectedBillAmount',
            initialWidth: 120,
            type: 'currency',
            hideDefaultActions: true
        }
    ];

    /*
        Get Statement
    */
    @api async loadBillingStatement() {

        // Clear rows for load
        this.statementRows = [];
        this.uniqueRowId = 0;
        this.isLoading = true;

        try {

            // Call to get statement details
            const billingDetails = await BwcBillingServices.getEligibleForAdjustmentLineItems(
                this.serviceProduct, 
                this.selectedStatementId, 
                this.accountNumber
            );

            // Generate all treegrid rows
            this.generateStatementRows(billingDetails);

        } catch (error) {
            
            this.addError('Failed to load charges.', error.message);

        } finally {
            
            this.isLoading = false;

        }

    }

    /*
        Generate all data rows for the datatable
    */
    generateStatementRows(billingDetails) {

        this.statementRows = [];

        billingDetails.adjustableLineItems.forEach((lineItem, index) => {
            lineItem.id = index + '';
            lineItem.interactionId = this.recordId;
            lineItem.ban = this.accountNumber;
            lineItem.accountType = this.serviceType;
            lineItem.statementId = this.selectedStatementId;
            
            this.statementRows.push(lineItem);
        });
    }

    /*** Error Handling ***/
    addError(message, details) {
        this.dispatchError(message, details);
    }

    /*** Event Handlers ***/
    handleSelectedRow(event) {
        const selectedLineItems = event.detail.selectedRows;
        BwcUtils.log(`selectedLineItems: ${JSON.stringify(selectedLineItems)}`);

        if (selectedLineItems.length > 10 || selectedLineItems.length == 0) {
            this.addError(
                `A maximum of 10 line items can be selected. Current selection: ${selectedLineItems.length}`,
                ''    
            );
        }
        else {
            this.dispatchRowSelection(selectedLineItems);
        }
    }

    /*** Event Dispatchers ***/
    dispatchError(message, details) {
    
        const detail = { 
            stepName: STEP_NAME,
            message, details,
        };

        this.dispatchEvent(new CustomEvent( 'error', { detail } ));
    }

    dispatchLoad(isLoading) {

        const detail = { isLoading };

        this.dispatchEvent(new CustomEvent( 'load', { detail } ));
    }

    dispatchRowSelection(selectedLineItems) {

        const detail = { selectedLineItems };

        this.dispatchEvent(new CustomEvent( 'rowselection', { detail } ));
    }

}