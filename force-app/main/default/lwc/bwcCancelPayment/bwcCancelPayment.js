import { LightningElement, api, track, wire } from "lwc";
import { publish, MessageContext } from 'lightning/messageService';
import * as BwcConstants from 'c/bwcConstants';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcPayments from 'c/bwcPayments';
import * as BwcBillingAccount from 'c/bwcBillingAccount';
import * as BwcPaymentServices from 'c/bwcPaymentServices';
import * as BwcAccountServices from "c/bwcAccountServices";
import * as BwcInteractActivityPublisher from 'c/bwcInteractActivityPublisher';

// Message channels
import REFRESHMC from '@salesforce/messageChannel/BWC_Refresh__c';

// Labels
import label_confirm from '@salesforce/label/c.BWC_PaymentDeleteConfirm';
import label_success from '@salesforce/label/c.BWC_PaymentDeleteSuccess';

export default class BwcCancelPayment extends LightningElement {

    // Labels that need to be accessed in template
    label = {
        confirm: label_confirm
    };

    // Public interface
    @api recordId;              // Always passed into component
    @api ban;
    @api confirmationNumber;    // If editing, the confirmation of the pending payment to delete

    billingAccountRecord;
    paymentDetails;
    pendingPayment;
    accountTypeLabel;
    @track pendingPaymentDetails = {};

    wizardSteps = [
        {
            name: 'review',
            title: '<b>Cancel Payment</b>',
            panelNumber: 0,
            minHeight: 165,
            rightButton: {
                name: 'confirm',
                label: 'Confirm Cancellation',
                action: this.doCancellation.bind(this)
            },
            cancelButton: 
            {
                name: "cancel",
                label: "Close Tab",
                variant: "destructive-text",
                action: this.close.bind(this)
            }
        }

    ];

    get wizard() {return this.template.querySelector('c-bwc-wizard');}

    // Needed to send refresh message
    @wire(MessageContext)
    messageContext;

    isRendered = false;

    renderedCallback() {

        if (!this.isRendered) {

            // Perform actions on first render, that way error report component is rendered and available to show error
            this.isRendered = true;

            this.open();

        }

    }

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

        if (!this.confirmationNumber) {
            throw new Error('confirmationNumber was not passed in.')
        }

        this.paymentDetails = undefined;

        // Retrieve billing account
        this.billingAccountRecord = await BwcAccountServices.getBillingAccountForBan(this.ban);

        // Retrieve future payments
        const getPaymentDetailsArgs = {
            recordId: this.recordId,
            bans: [this.ban],
            topics: [BwcConstants.PaymentDetailTopic.BAN_BILLING_IDS.value, 
                     BwcConstants.PaymentDetailTopic.FUTURE_PAYMENTS.value,
                     BwcConstants.PaymentDetailTopic.ACCOUNT_BALANCE_SUMMARY.value]
        };
        const paymentDetailsResponses = await BwcPaymentServices.getPaymentDetails(getPaymentDetailsArgs);
        this.paymentDetails = paymentDetailsResponses[0];

        // Check returned detail:

        // System and Division Ids
        if (this.paymentDetails.errorbanBillingIds) {
            BwcUtils.error(JSON.stringify(this.paymentDetails.errorbanBillingIds));
            throw new Error('Error retrieving banBillingIds, unable to continue.');
        }

        // Pending payment
        this.pendingPayment = this.paymentDetails.payments
            ? this.paymentDetails.payments.find(payment => payment.confirmationNumber === this.confirmationNumber || payment.pendingPaymentId === this.confirmationNumber) 
            : undefined;
        if (!this.pendingPayment) {
            throw new Error('Error retrieving pending payment details, unable to continue.');
        }

        this.accountTypeLabel = BwcConstants.BillingAccountType.getLabelForValue(this.pendingPayment.accountType);

        // Set title from ban
        this.wizard.setStepTitle('review', `<b>Cancel Payment:</b> BAN# ${this.ban} (${this.accountTypeLabel})`);

        // Build details
        const paymentMethod = BwcUtils.cloneObject(this.pendingPayment);
        paymentMethod.type = BwcConstants.PaymentDetailToPaymentMethodType[paymentMethod.paymentMethod].value;
        this.pendingPaymentDetails = {
            amountPaid: BwcUtils.toCurrency(this.pendingPayment.paymentAmount),
            paymentDate: BwcUtils.toIsoDate(new Date(BwcUtils.parseIsoDateString(this.pendingPayment.paymentDate))),
            paymentMethod
        };

        return undefined;

    }

    /*
        Perform the cancellation.
    */
    async doCancellation() {

        const deleteRequest = {
            accountNumber: this.pendingPayment.ban,
            accountType: this.pendingPayment.accountType,
            systemId: this.paymentDetails.banBillingIds.systemId,
            divisionId: this.paymentDetails.banBillingIds.divisionId,
            pendingPaymentId: this.pendingPayment.confirmationNumber ? this.pendingPayment.confirmationNumber : this.pendingPayment.pendingPaymentId
        };

        try {

            this.wizard.setBusy(true);

            let deletePaymentResponse;
            try {
                deletePaymentResponse = await BwcPaymentServices.deletePayment(deleteRequest);
            }
            catch(error) {
                this.createInteractionActivity(error);
                throw error;
            }

            this.createInteractionActivity(deletePaymentResponse);

            if (deletePaymentResponse.content.responseCode !== "1") {
                throw new Error(deletePaymentResponse.content.message);
            }

            // Close tab
            this.close();

            // Show success
            const confirmationNumber = this.pendingPayment.confirmationNumber ? this.pendingPayment.confirmationNumber : this.pendingPayment.pendingPaymentId;
            const successMessage =
                label_success.replace("{0}", confirmationNumber).replace("{1}", BwcUtils.formatCurrency(this.pendingPaymentDetails.amountPaid));
            BwcUtils.showToast(this, {message: successMessage, variant: 'success'});

            // Refresh history table
            publish(this.messageContext, REFRESHMC, {scope: 'paymentHistory', recordId: this.recordId});

        }
        finally {
            this.wizard.setBusy(false);
        }
        
    }

    /*
        Create an InteractionActivity for each payment added or edited
    */
    createInteractionActivity(response) {

        try {

            // Get standardized payment method and billing account
            const paymentMethod = BwcPayments.PaymentMethod.fromPendingPayment(this.pendingPayment);
            const billingAccount = BwcBillingAccount.BillingAccount.fromRecord(this.billingAccountRecord);

            // Determine action
            const action = paymentMethod.isSecured
                ? BwcConstants.InteractionActivityValueMapping.BillingPaymentSecuredCancel.action
                : BwcConstants.InteractionActivityValueMapping.BillingPaymentPromiseCancel.action;

            // Build out details
            const details = {
                recordId: this.recordId,
                service: this.billingAccountRecord.Account_Type__c,
                serviceName: this.billingAccountRecord.Service_Name__c,
                ban: this.ban,
                billingStatus: billingAccount.getBillingStatus(this.paymentDetails),
                paymentTrx: {
                    trxDate: BwcUtils.toIsoDate(new Date()),
                    paymentDate: this.pendingPayment.paymentDate,
                    paymentMethod: paymentMethod.interactionActivityType,
                    paymentAmount: this.pendingPayment.paymentAmount
                }
            };

            // Set status and error message
            if (response instanceof Error) {
                details.status = 'failure';
                details.errorMessage = response.message;
            }
            else {
                details.status = response.content.responseCode === "1" ? "success" : "failure";
                details.errorMessage = response.content.responseCode === "1" ? undefined : response.content.message
            }

            // Publish
            BwcInteractActivityPublisher.publishMessage(this.recordId, action, JSON.stringify(details), null);

        }
        catch(error) {

            // Write any error to the log only
            BwcUtils.error('Failed to create Interaction Activity: ' + error.message);
            BwcUtils.error(error);

        }

    }

}