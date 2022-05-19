import { api, track, wire } from 'lwc';
import BwcPageElementBase from 'c/bwcPageElementBase';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import * as BwcConstants from 'c/bwcConstants';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcAccountServices from 'c/bwcAccountServices';
import * as BwcBillingServices from 'c/bwcBillingServices';
import * as BwcAdjustments from 'c/bwcAdjustments';
import * as bwcInteractActivityPublisher from 'c/bwcInteractActivityPublisher';
import * as bwcDispatchEscalationCase from 'c/bwcDispatchEscalationCase';
import * as bwcLICPublisher from 'c/bwcMsgToLICPublisher';
import * as BwcLabelServices from 'c/bwcLabelServices';
import COMPLETIONMC from '@salesforce/messageChannel/BWC_Completion__c';
import OPENSUBTABMC from "@salesforce/messageChannel/BWC_OpenSubTab__c";
import hasLICPermission from '@salesforce/customPermission/LIC_Permission';
import hasCAFrontLinePermission from '@salesforce/customPermission/Credit_Adjustments_Front_Line';
import hasCABackOfficeManagerPermission from '@salesforce/customPermission/Credit_Adjustments_Back_Office_Manager';

export default class BwcBillViewer extends BwcPageElementBase {

    @api ban;
    @api accountType;
    @api interactionId;
    @api defaultStatementId;
    @api caseId;
    billInfo;
    isUnified;

    // Labels
    labels = BwcLabelServices.labels;

    // Translate account type to product name
    get product() {return this.accountType === BwcConstants.BillingAccountType.WIRELESS.value ? 'Wireless' : 'Wireline'}
    get allowEscalation(){return this.accountType === BwcConstants.BillingAccountType.WIRELESS.value || this.isUnified;}    
    isBusy;
    lastToggleState = 'collapsed';
    uniqueRowId = 0;
    parentIdMap = {};
    expandedRowIds = [];

    // Needed to subscribe to messages
    @wire(MessageContext) messageContext;

    // Completion message cgabbek subscription
    completionSubscription;

    get toggleToolTip() {return this.lastToggleState === 'collapsed' ? 'Expand All' : 'Collapse All'}

    // Combo box options
    @track statementOptions = [];
    selectedStatementId;
    dateRangeLabel;

    // Treegrid control
    get treegrid() {return this.template.querySelector('lightning-tree-grid');}

    // array to store charges that are eligible for adjustments
    ajustmentEligibleCharges = [];
    get noAdjustableCharges() {
        return this.ajustmentEligibleCharges.length == 0;
    }

    // check if user has custom permissions
    get hasCreditAdjustmentsPermission() {
        return hasCAFrontLinePermission || hasCABackOfficeManagerPermission;
    }

    // Treegrid columns
    @track statementColumns = [
        {
            label: 'Bill Charges',
            fieldName: 'description',
            hideDefaultActions: true
        },
        {
            label: 'Selected Bill',
            fieldName: 'selectedBillAmount',
            type: 'currency',
            initialWidth: 120,
            hideDefaultActions: true
        },
        {
            label: 'Previous Bill',
            fieldName: 'previousBillAmount',
            type: 'currency',
            initialWidth: 120,
            hideDefaultActions: true
        },
        {
            label: 'Difference',
            fieldName: 'differenceAmount',
            initialWidth: 120,
            hideDefaultActions: true,
            cellAttributes: {
                alignment: 'right',
                class: {fieldName: 'differenceAmountClass'}
            }
        }
    ];
    
        
    // Treegrid rows
    @track statementRows = [];

    isRendered = false;

    async renderedCallback() {

        if (this.isRendered) {
            return;
        }

        this.isRendered = true;

        super.subscribeToMessage(
            OPENSUBTABMC,
            (message) => {
                if(message.recordId === this.interactionId) {
                    this.handleOpenEscalationCase( message.pageReference, message.label );
                }
            },
            true
        );

        await this.refresh();
    
    }

    /*
        Display error to user.
    */
    reportError(error) {

        const errorReport = this.template.querySelector('c-bwc-error-report', false);
        errorReport.reportError(error, true);

    }

    /*
        Clear any displayed error.
    */
    clearError() {

        const errorReport = this.template.querySelector('c-bwc-error-report', false);
        errorReport.clearError();

    }

    /*
        Refresh from server.
    */
    async refresh() {

        try {

            this.isBusy = true;

            // Get billing account record to determine unified
            const billingAccountRecord = await BwcAccountServices.getBillingAccountForBan(this.ban);
            this.isUnified = billingAccountRecord.Is_Unified__c;

            // Call to get all statements
            const billingStatements = await BwcBillingServices.getBillingStatements(billingAccountRecord.Id, this.interactionId);

            // Build combo box options
            this.statementOptions = billingStatements[this.product].map(statement => ({
                value: statement.statementID,
                label: BwcUtils.formatDate(Date.parse(statement.cycleStartDate)) + ' - ' + BwcUtils.formatDate(Date.parse(statement.cycleEndDate))
            }));

            // Auto-select first statement
            if (this.defaultStatementId) {
                this.selectedStatementId = this.defaultStatementId;
            }
            else {
                this.selectedStatementId = this.statementOptions[0].value;
            }
            await this.loadStatement();

        }
        catch(error) {
            this.reportError(error);
        }
        finally {
            this.isBusy = false;
        }

    }

    /*
        Load selected statement.
    */
   billInfoStartDate = '';
   billInfoEndDate = '';
    async loadStatement() {

        // Clear rows for load
        this.statementRows = [];
        this.statementColumns[0].label = 'Bill Charges';
        this.treegrid.columns = this.statementColumns;
        this.uniqueRowId = 0;
        this.parentIdMap = {};
        this.expandedRowIds = [];
        this.ajustmentEligibleCharges = [];
        this.billInfoStartDate = '';
        this.billInfoEndDate = '';

        // Call to get statement details
        const billingDetailsResponse = await BwcBillingServices.getBillingDetails(this.product, this.selectedStatementId);

        // Bill found?
        if (!billingDetailsResponse.content.billFound) {
            throw new Error('This bill is no longer available.');
        }

        const billingDetails = billingDetailsResponse.content;
        this.billInfo = billingDetails;
        // Customize first column label with statement dates
        this.billInfoStartDate = BwcUtils.formatDate(BwcUtils.parseIsoDateString(billingDetails.billInfo.cycleStDate));
        this.billInfoEndDate = BwcUtils.formatDate(BwcUtils.parseIsoDateString(billingDetails.billInfo.cycleEndDate));
        this.dateRangeLabel = `${this.billInfoStartDate} - ${this.billInfoEndDate}`;
        this.statementColumns[0].label = `Bill Charges for ${this.dateRangeLabel}`;
        this.treegrid.columns = this.statementColumns;

        // Generate all treegrid rows
        this.generateStatementRows(billingDetails);

        if (this.lastToggleState === 'expanded') {
            this.treegrid.expandAll();
        }

    }

    /*
        Generate all data rows for the treegrid.
    */
    generateStatementRows(billingDetails) {

        this.statementRows = [];

        // Get summary numbers
        const summary = billingDetails.billSummary;
        const remainingBalance = BwcBillingServices.getAmount(summary.rmningBal);
        const previousBalance = BwcBillingServices.getAmount(summary.prevBal);
        const payments = BwcBillingServices.getAmount(summary.totalPayments);
        const adjustments = BwcBillingServices.getAmount(summary.totalAdjustments);
        const newCharges = BwcBillingServices.getAmount(summary.newChrgs);
        const totalCharges = BwcBillingServices.getAmount(summary.totChrgs);

        // Previous activity
        const previousActivityRow = this.addRow({ description: 'Previous activity', selectedBillAmount: remainingBalance });
        this.addRow({ description: 'Previous balance', selectedBillAmount: previousBalance }, previousActivityRow);
        this.addRow({ description: 'Adjustments', selectedBillAmount: adjustments }, previousActivityRow);
        this.addRow({ description: 'Payments', selectedBillAmount: payments }, previousActivityRow);

        // Services
        const servicesRow = this.addRow({ description: 'Services', selectedBillAmount: newCharges });

        // Service charges
        BwcBillingServices.BillingDetailsChargeNodeTypes.forEach(chargeNodeType => {
            if (billingDetails[chargeNodeType]) {
                this.addServiceTypeRows(servicesRow, chargeNodeType, billingDetails[chargeNodeType]);
            }
        });

        // Totals
        this.addRow({ description: 'BILL TOTAL', selectedBillAmount: totalCharges });

        // Expand services row
        this.treegrid.expandedRows = this.expandedRowIds;//[servicesRow.id];

    }

    /*
        Add rows for top-level service node like Wireless or Uverse.
    */
    addServiceTypeRows(servicesRow, serviceType, serviceTypeData) {

        if (serviceType === 'wirelessChrgs') {

            const wirelessRow = {
                description: serviceTypeData.wirelessServiceDesc,
                selectedBillAmount: BwcBillingServices.getAmount(serviceTypeData.totalWirelessServiceAmt),
                previousBillAmount: BwcBillingServices.getAmount(serviceTypeData.prevServiceAmt)
            }
            this.addRow(wirelessRow, servicesRow);
    
            // Service list, e.g. groups or devices
            serviceTypeData.wirelessServiceList.forEach(serviceData => {
    
                let description;
                if (serviceData.ctn) {
                    // Phone number (Person Name)
                    description = `${serviceData.ctn} (${serviceData.ctnUser})`;
                }
                else {
                    description = serviceData.serviceDesc;
                }
    
                const serviceRow = {
                    description,
                    selectedBillAmount: BwcBillingServices.getAmount(serviceData.totalServiceAmt),
                    previousBillAmount: BwcBillingServices.getAmount(serviceData.prevServiceAmt)
                };
                this.addRow(serviceRow, wirelessRow);
                this.addSectionBeanRows(serviceData.sectionBeanList, serviceRow);
    
            });

        }
        else if (serviceType === 'combinedDtvChrgsList') {

            serviceTypeData.forEach(dataItem => {
                const serviceRow = {
                    description: dataItem.serviceDesc,
                    selectedBillAmount: BwcBillingServices.getAmount(dataItem.totalServiceAmt),
                    previousBillAmount: BwcBillingServices.getAmount(dataItem.prevServiceAmt)
                }
                this.addRow(serviceRow, servicesRow);
                this.addSectionBeanRows(dataItem.sectionBeanList, serviceRow);
            });

        }
        else {

            const serviceRow = {
                description: serviceTypeData.serviceDesc,
                selectedBillAmount: BwcBillingServices.getAmount(serviceTypeData.totalServiceAmt),
                previousBillAmount: BwcBillingServices.getAmount(serviceTypeData.prevServiceAmt)
            }
            this.addRow(serviceRow, servicesRow);
            this.addSectionBeanRows(serviceTypeData.sectionBeanList, serviceRow);

        }

    }
    
    /*
        Generate rows for section beans of a service.
    */
    addSectionBeanRows(sectionBeanList, parentRow) {

        if (!sectionBeanList || sectionBeanList.length === 0) {
            return;
        }

        sectionBeanList.forEach(sectionBean => {

            const row = {
                description: sectionBean.sectionDesc,
                selectedBillAmount: BwcBillingServices.getAmount(sectionBean.totalSectAmt),
                previousBillAmount: BwcBillingServices.getAmount(sectionBean.prevSectAmt)
            }
            this.addChargeListRows(sectionBean.chargeList, row);

            if (!row.description) {

                // Handles missing descriptions
                switch (sectionBean.type) {

                    case 'SURCHARGE':
                        row.description = 'Surcharges & fees';
                        break;

                    case 'GOV_TAX':
                        row.description = 'Government taxes & fees';
                        break;

                    default:
                        break;

                }

            }
            this.addRow(row, parentRow);

        });

    }

    /*
        Generate rows for individual charges of section bean.
    */
    addChargeListRows(chargeList, parentRow) {

        if (!chargeList || chargeList.length === 0) {
            return;
        }

        chargeList.forEach(charge => {

            const row = {
                description: charge.descList[0],
                selectedBillAmount: BwcBillingServices.getAmount(charge),
            }
            this.addRow(row, parentRow);

            // If charge is eligible for adjustment, add to list
            if (BwcBillingServices.isEligibleForAdjustment(charge)) {
                this.ajustmentEligibleCharges.push(charge);
            }

        });

    }

    isEligibleForAdjustment(charge) {
        if ((charge.type === BwcConstants.CHARGES.TYPES.TAXES || charge.type === BwcConstants.CHARGES.TYPES.SURCHARGES  || charge.type === BwcConstants.CHARGES.TYPES.PLAN_CHANGES) ||
            (charge.type === BwcConstants.CHARGES.TYPES.MONTHLY_CHARGES_DETAILS && charge.amtInd === BwcConstants.CHARGES.AMTIND.CR)) {
                return false;
        }
        return true;
    }

    /*
        Add a row, setting calculated values.
    */
    addRow(row, parentRow) {

        this.uniqueRowId++;
        row.id = this.uniqueRowId + '';

        if (row.selectedBillAmount !== undefined && row.previousBillAmount !== undefined) {

            // Get difference without sign
            row.difference = Math.abs(row.selectedBillAmount - row.previousBillAmount);

            // Difference column is text not currency so it can show up or down arrow
            // Format into currency string
            let differenceAmountString = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(row.difference);

            // Add down + green or up + red.
            // If stayed the same, will show zero in normal black without up or down
            if (row.selectedBillAmount < row.previousBillAmount) {
                // Amount decreased -- show in green with downarrow
                differenceAmountString = '↓' + differenceAmountString;
                row.differenceAmountClass = 'slds-text-color_success';
            }
            else if (row.selectedBillAmount > row.previousBillAmount) {

                // Amount increased -- show in red with uparrow
                row.differenceAmountClass = 'slds-text-color_error';
                differenceAmountString = '↑' + differenceAmountString;

            }

            row.differenceAmount = differenceAmountString;

        }

        if (!parentRow) {

            this.statementRows.push(row);

        }
        else {

            this.parentIdMap[row.id] = parentRow.id;

            if (row.difference) {
                this.expandRow(parentRow.id);
            }

            if (!parentRow._children) {
                parentRow._children = [row];
            }
            else {
                parentRow._children.push(row);
            }

        }

        return row;

    }

    /*
        Format a Date value to string like "Jun 14, 2020".
    */
    getFormattedDate(dateValue) {

        return new Intl.DateTimeFormat('en-US', {year: 'numeric', month: 'short', day: 'numeric' }).format(dateValue);

    }

    /*
        Expand row and all parents.
    */
    expandRow(rowId) {

        let currentRowId = rowId;
        while (currentRowId) {

            if (!this.expandedRowIds.includes(currentRowId)) {
                this.expandedRowIds.push(currentRowId);
            }
            currentRowId = this.parentIdMap[currentRowId];

        }

    }

    async viewPdf() {

        try {

            const message = {
                url: `/apex/BWCBillPdfViewer?product=${this.product}&statementId=${this.selectedStatementId}`,
                label: 'Bill PDF: ' + BwcLabelServices.Account + ' ' + this.ban + ' ' + this.dateRangeLabel,
                icon: 'doctype:pdf'
            };

            BwcUtils.openSubTab(message);
            //one and done solution / interaction activity
            bwcInteractActivityPublisher.publishMessage(this.interactionId,BwcConstants.InteractionActivityValueMapping.ViewBillPDF.action,JSON.stringify({ "ban" :this.ban, "ContextData": this.billInfo }),null);

        }
        catch(error) {
            this.reportError(error);
        }
        finally {
            this.isBusy = false;
        }

    }

    /*
        Create escalation Case. 
    */    
    async escalate() {
        console.log('Escalating...');

        // show spinner 
        this.isBusy = true;

        // subscribe to completion LMC
        this.completionSubscription = subscribe(
            this.messageContext,
            COMPLETIONMC, (message) => {
                this.escalationComplete(message);
            });

        const ecType = BwcConstants.HighLevelCaseType.Billing_Inquiry.type;
        const ecFeature = BwcConstants.HighLevelCaseType.Billing_Inquiry.feature;
        const details = {'ban': this.ban};
        const detailRecord = JSON.stringify(details);

        bwcDispatchEscalationCase.publishEscalationCaseMessage(this.interactionId, ecType, ecFeature, detailRecord);
        this.template.querySelector('div').click();

    }

    /*
        Received message that escalation Case was created 
    */        
    escalationComplete(payload) {
        if (payload.scope === 'Billing') {
            // unsubscribe
            unsubscribe(this.completionSubscription);
            this.completionSubscription = null;

            // hide spinner
            this.isBusy = false;
        }

    }

    handleGoodwillAdjustment(event) {
        BwcAdjustments.openGoodwillAdjustmentWizard(
            this,
            this.interactionId,
            this.ban,
            this.accountType,
            this.billInfo.billInfo.address.name,
            this.billInfo.billInfo.billSeqNbr,
            this.billInfo.billInfo.cycleStDate,
            this.billInfo.billInfo.cycleEndDate,
            this.dateRangeLabel,
            'TODO',
            this.caseId,
            this.selectedStatementId
        );
    }

    handleMakeAdjustment(event) {
        BwcAdjustments.openAdjustmentWizard(
            this,
            this.interactionId,
            this.ban,
            this.accountType,
            this.billInfo.billInfo.address.name,
            this.selectedStatementId,
            this.billInfo.billInfo.billSeqNbr,
            this.billInfo.billInfo.cycleStDate,
            this.billInfo.billInfo.cycleEndDate,
            this.dateRangeLabel,
            'TODO',
            this.caseId
        );
    }

    handleOpenEscalationCase(pageReference, label) {
        super.openSubtab( pageReference, label, 'custom:custom86');
    }

    /*
        Statement was selected from the combo.
    */
    async handleStatementChange(event) {

        try {
    
            this.clearError();
            this.isBusy = true;
            this.selectedStatementId = event.target.value;
            await this.loadStatement();

        }
        catch(error) {
            this.reportError(error);
        }
        finally {
            this.isBusy = false;
        }

    }

    async handleToggleButtonClick() {

        // Flip state
        if (this.lastToggleState === 'expanded') {
            this.lastToggleState = 'collapsed';
        }
        else {
            this.lastToggleState = 'expanded';
                //one and done solution / interaction activity
                bwcInteractActivityPublisher.publishMessage(this.interactionId,BwcConstants.InteractionActivityValueMapping.ViewBill.action,JSON.stringify({ "ban" :this.ban, "ContextData": this.billInfo }),null);

        }

        // Allow button icon to update to give feedback, because table toggle is slow
        await BwcUtils.nextTick();

        if (this.lastToggleState === 'collapsed') {
            this.treegrid.collapseAll();
        }
        else {
            this.treegrid.expandAll();
        }

    }

    get menuItems() {

        if( !hasLICPermission ) {
            return [];
        }

        /* First part of menu */
        let menuItems = [
            {
                label: 'Change Bill Cycle Date',
                value: 'ChangeBillCycleDate'
            },
            {
                label: 'Change Bill Ownership',
                value: 'ChangeBillOwnership'
            },
            {
                label: 'View/Change Installments',
                value: 'ViewChangeInstallments'
            },
            {
                label: 'Make a Collection Payment',
                value: 'MakeCollectionPayment'
            }
        ]; 

        /* excluded values for wireless accounts if user doesn't have permission */
        if( 
            !( this.accountType === BwcConstants.BillingAccountType.WIRELESS.value && this.hasCreditAdjustmentsPermission )
        ) {
            menuItems = [
                ...menuItems, 
                {
                    label: 'Add Charges',
                    value: 'AddCharges'
                },
                {
                    label: 'Add Adjustment',
                    value: 'AddAdjustment'
                },
                {
                    label: 'Add Goodwill Adjustment',
                    value: 'AddGoodwillAdjustment'
                },
                {
                    label: 'Add Pending Charge Adjustment',
                    value: 'AddPendingChargeAdjustment'
                }
            ];
        }

        /* 3rd part of menu */
        menuItems = [
            ...menuItems,
            {
                label: 'Make Pmt/Adj on Suspended Acct',
                value: 'MakePmtAdjonSuspendedAcct'
            },
            {
                label: 'Make Pmt/Adj on Cancelled Acct',
                value: 'MakePmtAdjonCancelledAcct'
            },
            {
                label: 'View Promotion',
                value: 'ViewPromotion'
            }
        ];

        return menuItems;
    }

    handleMenuButtonSelection(event) {
       
        switch (event.target.value) {

            case 'ChangeBillCycleDate':
                //one and done solution / interaction activity
                bwcInteractActivityPublisher.publishMessage(this.interactionId, BwcConstants.InteractionActivityValueMapping.BillingChangeCycleDate.action, JSON.stringify({ "ban" :this.ban, "ContextData": this.billInfo }), null);
            
                break;
            case 'ChangeBillOwnership':
                //one and done solution / interaction activity
                bwcInteractActivityPublisher.publishMessage(this.interactionId, BwcConstants.InteractionActivityValueMapping.ChangeBillOwnership.action, JSON.stringify({ "ban" :this.ban, "ContextData": this.billInfo }), null);
            
                break;
            case 'ViewChangeInstallments':
                //one and done solution / interaction activity
                bwcInteractActivityPublisher.publishMessage(this.interactionId, BwcConstants.InteractionActivityValueMapping.ViewChangeInstallments.action, JSON.stringify({ "ban" :this.ban, "ContextData": this.billInfo }), null);
            
                break;
            case 'MakeCollectionPayment':
                //one and done solution / interaction activity
                bwcInteractActivityPublisher.publishMessage(this.interactionId, BwcConstants.InteractionActivityValueMapping.MakeCollectionPayment.action, JSON.stringify({ "ban" :this.ban, "ContextData": this.billInfo }), null);

                break;
            case 'AddCharges':
                //one and done solution / interaction activity
                bwcInteractActivityPublisher.publishMessage(this.interactionId, BwcConstants.InteractionActivityValueMapping.PaymentAdjustmentAddCharges.action, JSON.stringify({ "ban" :this.ban, "ContextData": this.billInfo }), null);

                break;
            case 'AddAdjustment':
                //one and done solution / interaction activity
                bwcInteractActivityPublisher.publishMessage(this.interactionId, BwcConstants.InteractionActivityValueMapping.PaymentAdjustmentAddBillAdj.action, JSON.stringify({ "ban" :this.ban, "ContextData": this.billInfo }), null);

                break;
            case 'AddGoodwillAdjustment':
                //one and done solution / interaction activity
                bwcInteractActivityPublisher.publishMessage(this.interactionId, BwcConstants.InteractionActivityValueMapping.PaymentAdjustmentAddGoodwillAdj.action, JSON.stringify({ "ban" :this.ban, "ContextData": this.billInfo }), null);

                break;
            case 'AddPendingChargeAdjustment':
                //one and done solution / interaction activity
                bwcInteractActivityPublisher.publishMessage(this.interactionId, BwcConstants.InteractionActivityValueMapping.PaymentAdjustmentAddPendingChargeAdj.action, JSON.stringify({ "ban" :this.ban, "ContextData": this.billInfo }), null);

                break;
            case 'MakePmtAdjonSuspendedAcct':
                //one and done solution / interaction activity
                bwcInteractActivityPublisher.publishMessage(this.interactionId, BwcConstants.InteractionActivityValueMapping.PaymentAdjustmentSuspendedAccount.action, JSON.stringify({ "ban" :this.ban, "ContextData": this.billInfo }), null);

                break;
            case 'MakePmtAdjonCancelledAcct':
                //one and done solution / interaction activity
                bwcInteractActivityPublisher.publishMessage(this.interactionId, BwcConstants.InteractionActivityValueMapping.PaymentAdjustmentCancelledAccount.action, JSON.stringify({ "ban" :this.ban, "ContextData": this.billInfo }), null);

                break;
            case 'ViewPromotion':
                //one and done solution / interaction activity
                bwcInteractActivityPublisher.publishMessage(this.interactionId, BwcConstants.InteractionActivityValueMapping.ViewPromo.action, JSON.stringify({ "ban" :this.ban, "ContextData": this.billInfo }), null);
                break;
        }
        this.LuanchOPUS(event);

    }
    LuanchOPUS(event){
        let msg = 'PostToOpus';
        const licObj = {};
        licObj.JsonData = {};
        licObj.launchPoint = 'Launch Point';
        licObj.eventAction = event.target.value;
        bwcLICPublisher.publishMessage(msg,licObj,this.ban);


    }

}