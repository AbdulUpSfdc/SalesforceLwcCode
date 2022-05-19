import { api } from 'lwc';
import BwcPageElementBase from 'c/bwcPageElementBase';

import * as BwcUtils from 'c/bwcUtils';
import * as BwcAdjustments from 'c/bwcAdjustments';
import * as BwcAccountServices from 'c/bwcAccountServices';
import * as BwcAdjustmentServices from 'c/bwcAdjustmentServices';
import * as BwcConstants from 'c/bwcConstants';
import * as BwcInteractActivityPublisher from 'c/bwcInteractActivityPublisher';

export default class BwcReverseAdjustmentWizard extends BwcPageElementBase {

    // Labels
    labels = BwcAdjustments.labels;

    // Public Interface
    @api recordId;
    @api ban;
    @api adjustmentCode;
    @api createdDate;
    @api adjustmentDescription;
    @api adjustmentAmount;
    @api entSeqNo;
    @api subscriberNo;
    @api nextBillDate;

    billingAccounts = [];
    selectedBillingAccount = {};
    customerFirstName;
    customerLastName;
    accountType;
    accountTypeValue;
    reverseReasonOptions = [];
    market;
    subscriberNbr;
    action;
    details;

    // UI Variables
    isRendered = false;
    isLoading = false;

    renderedCallback() {
        if (!this.isRendered) {
            
            this.isRendered = true;

            this.open();
        }
    }

    get reverseReason() { return this.template.querySelector('[data-id="reverseReason"'); }

    /*** Wizard Logic ***/

    get wizardDefaultTitle() {
        return '<b>Reverse Adjustment</b>';
    } 

    wizardSteps = [
        {
            name: 'reverseAdjustment',
            title: `<b>Reverse Adjustment:</b> ${this.labels.account}# `,
            panelNumber: 0,
            minHeight: 165,
            rightButton: {
                name: "reverseAdjustment",
                label: "Reverse Adjustment",
                action: this.confirm.bind(this)
            },
            cancelButton:
            {
                name: "cancel",
                label: "Cancel",
                variant: "destructive-text",
                action: this.close.bind(this)
            }
        },

        {
            name: 'confirm',
            title: '<b>Adjustment Reversal Confirmation</b>',
            panelNumber: 1,
            minHeight: 80,
            rightButton: {
                name: "confirm",
                label: "Confirm Reversal",
                action: this.reverseAdjustment.bind(this)
            },
            cancelButton:
            {
                name: "cancel",
                label: "Cancel",
                variant: "destructive-text",
                action: this.close.bind(this)
            }
        }
    ];

    get wizard() {return this.template.querySelector('c-bwc-wizard');}

    open() {
        this.wizard.open(() => this.initialize());
    }

    close() {
        this.wizard.close();
    }

    /*
        Wizard closed -- bubble the close event up to any enclosing quick action.
    */
    handleWizardClose() {
        this.dispatchEvent(new CustomEvent("close"));
    }
    
    /*
        Wizard calls this when opening.
    */
    async initialize() {

        this.isLoading = true;

        this.billingAccounts = await BwcAccountServices.getBillingAccounts(this.recordId, false, false);

        this.selectedBillingAccount = this.billingAccounts.find(billingAccount => billingAccount.Billing_Account_Number__c === this.ban);

        this.customerFirstName = this.selectedBillingAccount.First_Name__c;
        this.customerLastName = this.selectedBillingAccount.Last_Name__c;
        this.ctn = this.subscriberNo;
        this.accountType = BwcAccountServices.getAccountTypeLabel(this.selectedBillingAccount.Account_Type__c);
        this.accountTypeValue = this.selectedBillingAccount.Account_Type__c;
        this.market = this.selectedBillingAccount.Billing_Market__c;

        this.wizard.setStepTitle('reverseAdjustment',`<b>Reverse Adjustment:</b> ${this.labels.account}# ${this.ban}`);
        this.isLoading = false;
        this.subscriberNbr = this.subscriberNo === undefined ? "" : this.subscriberNo.replaceAll(/[^0-9]+/g, "");
        this.details = {
            recordId: this.recordId,
            ban: this.ban,
            reverseDetails: {
                revAdjAmnt: this.adjustmentAmount,
                reasonCode: "ERROR",
                adjSeqNo: this.entSeqNo,
                chargeLevel: this.subscriberNbr == "" ? "B" : "S",
                subscriberNbr: this.subscriberNbr
            }
        }
        this.action = BwcConstants.InteractionActivityValueMapping.BillingAdjustmentsAdjustmentsReverseAdju.action;
    }

    /*
        Called from the Reverse Adjustment button 
    */
    confirm() {
        
        super.clearNotifications();

        this.wizard.gotoNextEnabledStep();

    }

    async reverseAdjustment() {
        
        let subscriberNbr = this.subscriberNo === undefined ? "" : this.subscriberNo.replaceAll(/[^0-9]+/g, "");
        let request = {
            accountNumber : this.ban,
            accountType : this.accountTypeValue,
            market : this.market,
            revAdjAmount : this.adjustmentAmount,
            reasonCode : "ERROR",
            adjSeqNumber : this.entSeqNo,
            isBillIgnore : true,
            adjRSource : "C",
            productType : "G",
            userText : "Error",
            chargeLevel : subscriberNbr == "" ? "B":"S"

        }
        subscriberNbr != "" ? (request.subscriberNumber = subscriberNbr) :  "";
        this.isLoading = true;

        try {

            const result = await BwcAdjustmentServices.reverseAdjustment(this.recordId, request);
            
            const message = 'Adjustment of $' + this.adjustmentAmount + ' from ' + this.createdDate  + ' has been successfully reversed.';

            super.showToast(null, message, 'success');
            
            this.details.status = 'success';
            
            this.createInteractionActivity(this.action, this.details);
            
            this.wizard.close();

        } catch( error ) {

            super.handleError(error, this.labels.reverseAdjustmentError, 'Reverse Adjustment Wizard', 'inline');

            this.wizard.gotoPreviousEnabledStep();

            this.details.status = 'failed';

            this.createInteractionActivity(this.action,this.details);
            
            this.isLoading = false;
        }
    }

    createInteractionActivity(action,details){
        BwcInteractActivityPublisher.publishMessage(this.recordId, action, JSON.stringify(details), null);
    }
}