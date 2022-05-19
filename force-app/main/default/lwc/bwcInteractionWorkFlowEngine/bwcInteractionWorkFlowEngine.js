import { api, wire, track } from 'lwc';
import BwcPageElementBase from 'c/bwcPageElementBase';
import * as BwcConstants from 'c/bwcConstants';
import * as BwcBillingAccount from 'c/bwcBillingAccount';
import * as BwcAccountServices from 'c/bwcAccountServices';
import { CurrentPageReference } from 'lightning/navigation';
import * as BwcLabelServices from 'c/bwcLabelServices';
import * as BwcUtils from 'c/bwcUtils';
import { CloseActionScreenEvent } from 'lightning/actions';
import modal from "@salesforce/resourceUrl/BWC_CustomModal";
import { loadStyle } from "lightning/platformResourceLoader";
import { InteractionActivityValueMapping } from 'c/bwcInteractionActivityService';

export default class BwcInteractionWorkFlowEngine extends BwcPageElementBase {
    recordId;

    // Labels
    labels = BwcLabelServices.labels;
    title = 'Select Account'
    isOpen;
    billingAccounts;                            // All billing accounts for the interaction
    @track billingAccountOptions = [];          // Options for combo box
    selectedBillingAccountId;                   // Currently selected BAN
    selectedBillingAccount;                     // Corresponding billing account for the selected ban
    requestedBAN = [];


    @wire(CurrentPageReference)
    currentPageReference;

    connectedCallback() {
        loadStyle(this, modal);
        //Get the current record id 
        this.recordId = this.currentPageReference.state.recordId;
        this.getAssociatedBillingAccounts(this.recordId);
    }

    //Get associated billing accounts for interaction

    async getAssociatedBillingAccounts(interactionId) {
        try {
            if (interactionId) {
                const BILLING_ACCOUNT_TYPES = [
                    BwcConstants.BillingAccountType.UVERSE.value
                ];

                if (this.billingAccounts === undefined) {
                    this.billingAccounts = await BwcAccountServices.getBillingAccounts(interactionId, false, false, BILLING_ACCOUNT_TYPES, this.requestedBAN, true);
                    if (this.billingAccounts.length === 1) {
                        
                        BwcUtils.log('launch WFE');
                        this.selectedBillingAccountId = this.billingAccounts[0].Id;
                        this.handleLaunchWFE();
                        this.handleClose();
                    } else if (this.billingAccounts.length > 1) {
                        this.isOpen = true;
                        // Build options
                        this.billingAccountOptions = this.billingAccounts.map(billingAccount => {
                            return {
                                label: BwcBillingAccount.BillingAccount.fromRecord(billingAccount).serviceLabel,
                                value: billingAccount.Id,
                                accountType: billingAccount.Account_Type__c,
                                recordId: billingAccount.Id
                            };
                        });

                        // Default to first billing account
                        if (!this.selectedBillingAccountId && this.billingAccountOptions.length > 0) {
                            this.selectedBillingAccountId = this.billingAccountOptions[0].value;
                        }
                        // Initialize for selected billing account
                        this.handleBillingAccountSelected();
                    }
                }
            }
        } catch (error) {
            BwcUtils.error(error);
        }
    }
    /*
        BAN has been selected.
    */
    async handleBillingAccountSelected(event) {
        if (event) {
            this.selectedBillingAccountId = event.target.value;
        }
    }

    handleClose() {
        setTimeout(() => {
            this.dispatchEvent(new CloseActionScreenEvent());
        }, 5000);
    }
    /*
        Handle Launch WFE
    */
    async handleLaunchWFE() {
        let isBANAuthenticated;
        let ban;
        const maskPattern = "****"; 
        this.billingAccounts.forEach(billingAccount => {
            if (billingAccount.Id === this.selectedBillingAccountId) {
                if (!billingAccount.Billing_Account_Number__c.includes(maskPattern)) {
                    isBANAuthenticated = true;
                    ban = billingAccount.Billing_Account_Number__c;
                } else if (billingAccount.Billing_Account_Number__c.includes(maskPattern)) {
                    isBANAuthenticated = false;
                }
            }
        });
        if (isBANAuthenticated === false) {
            let billingAccount = await BwcAccountServices.getBillingAccountForId(this.selectedBillingAccountId);
            ban = billingAccount.Billing_Account_Number__c;
        }
        this.template.querySelector('c-bwc-launch-w-f-e').open(InteractionActivityValueMapping.WFEGeneralSupport,ban,this.selectedBillingAccountId,isBANAuthenticated,this.recordId);
    }
}