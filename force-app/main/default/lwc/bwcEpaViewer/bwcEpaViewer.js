import { api, track } from 'lwc';
import BwcPageElementBase from 'c/bwcPageElementBase';
import * as BwcConstants from 'c/bwcConstants';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcBillingAccount from 'c/bwcBillingAccount';
import * as BwcAccountServices from "c/bwcAccountServices";
import * as BwcPayments from 'c/bwcPayments';
import * as BwcPaymentServices from 'c/bwcPaymentServices';
import * as BwcInteractActivityPublisher from 'c/bwcInteractActivityPublisher';
import * as BwcLabelServices from 'c/bwcLabelServices';

// Custom labels
import label_information from '@salesforce/label/c.BWC_EPA_View_Information';
import label_unexpectedError from '@salesforce/label/c.BWC_UnexpectedError_Subtab';

const COMPONENT_NAME = 'EPA Viewer';

export default class BwcEpaViewer extends BwcPageElementBase {

    @api interactionId;
    @api billingAccountId;
    billingAccount;
    ban;
    accountType;
    paymentDetails;
    extendedPa = {};
    amountDueToday;
    amountPaidToDate;
    @track installmentRows;

    isRendered = false;

    label = {
        information: label_information
    };

    // Labels
    labels = BwcLabelServices.labels;

    wizardSteps = [
        {
            name: "view",
            title: "<b>Extended Payment Arrangement Details</b>",
            panelNumber: 0,
            minHeight: 165,
            rightButton: {
                name: "makePayment",
                label: "Make a Payment",
                action: this.makePayment.bind(this)
            },
            cancelButton:
            {
                name: "close",
                label: "Close Tab",
                action: this.close.bind(this)
            }
        }
    ];

    @track installmentColumns = [
        {
            label: '#',
            fieldName: 'installmentNumber',
            hideDefaultActions: true,
        },
        {
            label: 'Installment Amount',
            fieldName: 'installmentAmount',
            hideDefaultActions: true
        },
        {
            label: 'Due Date',
            fieldName: 'dueDate',
            hideDefaultActions: true,
        },
        {
            label: 'Status',
            fieldName: 'status',
            hideDefaultActions: true
        }
    ];

    get wizard() {return this.template.querySelector('c-bwc-wizard');}

    renderedCallback() {

        if (!this.isRendered) {

            // Perform actions on first render, that way error report component is rendered and available to show error
            this.isRendered = true;
            this.wizard.open(() => this.initialize());
    
        }

    }

    /*
        Initialize to view the requested EPA details.
    */
    async initialize() {

        try {

            // Get the billing account record
            this.billingAccount = await BwcAccountServices.getInteractionBillingAccount(this.interactionId, this.billingAccountId);
            this.ban = this.billingAccount.Billing_Account_Number__c;
            this.accountType = this.billingAccount.Account_Type__c;

            // Add BAN to title
            this.wizard.setStepTitle('view', `<b>Extended Payment Arrangement Details</b>: ${this.labels.account} ${this.ban} (${this.billingAccount.Service_Type_Name__c})`);

            // Get the EPA details
            this.paymentDetails = await BwcPaymentServices.getPaymentDetails({
                recordId: this.interactionId,
                bans: [this.ban],
                topics: [BwcPayments.PaymentDetailTopic.EXTENDED_PA.value]
            });

            if (!this.paymentDetails[0].extendedPA) {
                BwcUtils.error('EPA Viewer', JSON.stringify(this.paymentDetails[0].errorextendedPA));
                throw new Error('Error retrieving extendedPA, unable to continue.');    
            }

            this.extendedPa = this.paymentDetails[0].extendedPA;
            if (this.extendedPa.installmentList) {

                // Build rows for installment table
                this.installmentRows = [];
                this.extendedPa.installmentList.forEach((installment, index) => {

                    this.installmentRows.push({
                        installmentNumber: index + 1,
                        installmentAmount: installment.amountDue === '--' ? '--' : BwcUtils.formatCurrency(installment.amountDue),
                        dueDate: installment.dueDate === '--' ? '--' : BwcUtils.formatDateShort(installment.dueDate),
                        status: installment.status
                    });

                });

                const dueRow = this.installmentRows.find(row => row.status === BwcPayments.EpaStatus.ACTIVE || row.status === BwcPayments.EpaStatus.BROKEN);
                if (dueRow) {
                    this.amountDueToday = dueRow.installmentAmount;
                }
                else {
                    this.amountDueToday = '--';
                }

            }

            this.amountDueToday = BwcUtils.formatCurrency(this.extendedPa.financePaymentAmount);
            this.amountPaidToDate = BwcUtils.formatCurrency(BwcUtils.toCurrency(this.extendedPa.financeTotalAmount) - BwcUtils.toCurrency(this.extendedPa.financeRemainingAmount));

            this.createInteractionActivity();

        }
        catch (e) {

            BwcUtils.error(COMPONENT_NAME, e);
            throw new Error(label_unexpectedError);

        }

    }

    async makePayment() {

        // Open payment wizard
        BwcPayments.openPaymentWizard(this, this.interactionId, this.ban);

    }

    /*
        Create an InteractionActivity for each payment added or edited
    */
    createInteractionActivity() {

        try {

            // Get standardized payment method and billing account
            const billingAccount = BwcBillingAccount.BillingAccount.fromRecord(this.billingAccount);

            // Determine action
            const action = BwcConstants.InteractionActivityValueMapping.BillingPaymentEpaView.action;

            // Build out details
            const details = {
                recordId: this.interactionId,
                service: this.billingAccount.Account_Type__c,
                serviceName: this.billingAccount.Service_Name__c,
                ban: this.ban,
                billingStatus: billingAccount.getBillingStatus(this.paymentDetails),
                epaDetails: {
                    epaStatus: this.extendedPa.status,
                    enrolledDate: this.extendedPa.enrolledDate,
                    origBalance: this.extendedPa.financeTotalAmount,
                    downPayment: this.extendedPa.financeDownPayment,
                    paidAmount: this.extendedPa.financePaymentAmount,
                    remainingAmount: this.extendedPa.financeRemainingAmount,
                    noOfInstallments: this.extendedPa.installments
                }
            };

            // Publish
            BwcInteractActivityPublisher.publishMessage(this.interactionId, action, JSON.stringify(details), null);

        }
        catch(error) {

            // Write any error to the log only
            BwcUtils.error(COMPONENT_NAME, 'Failed to create Interaction Activity: ' + error.message, error);

        }

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

}