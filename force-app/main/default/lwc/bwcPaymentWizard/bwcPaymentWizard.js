import { LightningElement, api, track, wire } from "lwc";
import { publish, MessageContext } from 'lightning/messageService';
import * as BwcConstants from 'c/bwcConstants';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcAccountServices from "c/bwcAccountServices";
import * as BwcPayments from 'c/bwcPayments';
import * as BwcPaymentServices from 'c/bwcPaymentServices';
import * as BwcInteractActivityPublisher from 'c/bwcInteractActivityPublisher';
import * as BwcLabelServices from 'c/bwcLabelServices';

// Message channels
import REFRESHMC from '@salesforce/messageChannel/BWC_Refresh__c';

// Permissions
import hasWaiveConvenienceFeePermission from '@salesforce/customPermission/Conv_Fee_Waiver_Permission';
import hasEnterCustomerPaymentDetailsPermission from '@salesforce/customPermission/Enter_Customer_Payment_Details';

// Labels
import label_notEligible from '@salesforce/label/c.BWC_PaymentNotEligible';
import label_convenienceFeeMessage from '@salesforce/label/c.BWC_ConvenienceFeeMessage';
import label_unknownConvenienceFeeMessage from '@salesforce/label/c.BWC_UnknownConvenienceFeeMessage';
import label_paymentSuspendedScript from '@salesforce/label/c.BWC_PaymentSuspendedScript';
import label_paymentCanceledScript from '@salesforce/label/c.BWC_PaymentCanceledScript';
import label_paymentCanceledOcaScript from '@salesforce/label/c.BWC_PaymentCanceledOCAScript';
import label_lessPastDue from '@salesforce/label/c.BWC_PaymentLessPastDue';
import label_tooLow from '@salesforce/label/c.BWC_PaymentTooLow';
import label_tooHigh from '@salesforce/label/c.BWC_PaymentTooHigh';
import label_tooLowByDueDate from '@salesforce/label/c.BWC_PaymentTooLowByDueDate';
import label_tooLowAfterDueDate from '@salesforce/label/c.BWC_PaymentTooLowAfterDueDate';
import label_skipSecond from '@salesforce/label/c.BWC_PaymentSkipSecond';
import label_dateRangeInvalid from '@salesforce/label/c.BWC_DateRangeInvalid';
import label_dateMinInvalid from '@salesforce/label/c.BWC_DateMinInvalid';
import label_paymentAgreementVerify from '@salesforce/label/c.BWC_PaymentAgreementVerify';
import label_paymentSuccessMessage from '@salesforce/label/c.BWC_PaymentSuccess';
import label_promisePaymentSuccessMessage from '@salesforce/label/c.BWC_PromisePaymentSuccess';
import label_paymentSuccessSplitMessage from '@salesforce/label/c.BWC_PaymentSuccessSplit';
import label_paymentSuccessRestore from '@salesforce/label/c.BWC_PaymentSuccessRestore';
import label_paymentUpdateSuccessMessage from '@salesforce/label/c.BWC_PaymentUpdateSuccess';
import label_paymentLessThanMinSuspend from '@salesforce/label/c.BWC_PaymentLessPastDueSuspend';
import label_paymentLessThanMinCancelCollections from '@salesforce/label/c.BWC_PaymentLessPastDueCollections';
import label_paymentLessThanMinOca from '@salesforce/label/c.BWC_PaymentLessPastDueOca';
import label_unexpectedError from '@salesforce/label/c.BWC_PaymentUnexpectedError';

// Default payment details
const DEFAULT_PAYMENT_DETAILS = {
    paymentRecommendations: {
        allowPaymentOnline: {
            eligibleFlag: true
        },
        schedulePaymentAllowed: {
            eligibleFlag: true
        },
        paymentArrangementAllowed: {
            eligibleFlag: true
        },
        paymentOptionOne: {
            futurePaymentAllowed: true,
            paymentMethod: {bank: true, card: true, mail: true, agency: true, other: true},
            paymentDate: {bank: "", card: "", mail: "", agency: "", other: ""}
        },
        paymentOptionTwo: {
            futurePaymentAllowed: true,
            paymentMethod: {bank: true, card: true, mail: true, agency: true, other: true},
            paymentDate: {bank: "", card: "", mail: "", agency: "", other: ""}
        },
        eligibilityAmounts: {
            minAmountAllowed: "1.00"
        },
        billingCollectionDetails: {
        },
        paymentRecommendationDetails: {}
    },
    futurePayments: {
        allowPaymentOnline: {
            eligibleFlag: true
        },
        schedulePaymentAllowed: {
            eligibleFlag: true
        },
        paymentArrangementAllowed: {
            eligibleFlag: true
        },
        paymentOptionOne: {
            futurePaymentAllowed: true,
            paymentMethod: {bank: true, card: true, mail: true, agency: true, other: true},
            paymentDate: {bank: "", card: "", mail: "", agency: "", other: ""}
        },
        paymentOptionTwo: {
            futurePaymentAllowed: true,
            paymentMethod: {bank: true, card: true, mail: true, agency: true, other: true},
            paymentDate: {bank: "", card: "", mail: "", agency: "", other: ""}
        },
        eligibilityAmounts: {
            minAmountAllowed: "1.00"
        },
        billingCollectionDetails: {
        },
        paymentRecommendationDetails: {}
    },
    accountBalanceSummary: {
        accountStatus: ""
    }
};

export default class BwcPaymentWizard extends LightningElement {

    // Public interface
    @api recordId;              // Always passed into component
    @api defaultBan;
    @api isEdit;                // Edit a pending payment
    @api confirmationNumber;    // If editing, the confirmation of the pending payment to edit

    // Labels
    labels = BwcLabelServices.labels;

    //#region Wizard
    /********************************************************************************************************/

    get wizardDefaultTitle() {
        return '<b>Retrieving Payment Details</b>';
    }

    wizardSteps = [
        {
            name: "selectPaymentInformation",
            title: "<b>Select Payment Information</b>",
            panelNumber: 0,
            minHeight: 130,
            rightButton: {
                name: "continue",
                label: "Continue",
                action: this.selectPaymentInformation.bind(this)
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
            name: "firstPayment",
            title: "<b>Make Payment</b>",
            panelNumber: 1,
            minHeight: 165,
            initAction: this.loadFirstPayment.bind(this),
            finishAction: this.saveCurrentPayment.bind(this),
            leftButton: {
                name: "back",
                label: "Back"
            },
            rightButton: {
                name: "continue",
                label: "Continue to Review",
                action: this.validateCurrentPayment.bind(this)
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
            name: "secondPayment",
            title: "<b>Make Payment</b>",
            panelNumber: 1,
            minHeight: 165,
            initAction: this.loadSecondPayment.bind(this),
            finishAction: this.saveCurrentPayment.bind(this),
            leftButton: {
                name: "back",
                label: "Back"
            },
            rightButton: {
                name: "continue",
                label: "Continue to Review",
                action: this.validateCurrentPayment.bind(this)
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
            name: 'reviewPayment',
            title: '<b>Review Payment</b>',
            panelNumber: 2,
            minHeight: 165,
            initAction: this.loadReviewPayment.bind(this),
            leftButton: {
                name: 'editPaymentInfo',
                label: 'Edit Payment Info'
            },
            rightButton: {
                name: 'submitPayment',
                label: 'Submit Payment',
                action: this.submitPayment.bind(this)
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
            name: 'paymentConfirmation',
            title: '<b>Payment Confirmation</b>',
            panelNumber: 3,
            initAction: this.loadPaymentConfirmation.bind(this),
            leftButton: {
                name: 'makeAnotherPayment',
                label: 'Make Another Payment',
                action: this.open.bind(this)
            },
            rightButton: {
                name: 'close',
                label: 'Close'
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

        try {

            // Reset everything
            this.billingAccounts = [];
            this.billingAccountOptions = [];
            this.selectedBan = undefined;
            this.selectedBillingAccount = {};
            this.paymentTypeOptions = [];
            this.skipSecondPayment = false;
            this.paymentDetailsResponses = undefined;
            this.paymentDetailsRetrieved = false;
            this.selectedPaymentDetails = undefined;
            this.pendingPayments = undefined;
            this.editablePendingPayments = undefined;
            this.convenienceFeeIndicator = undefined;
            this.convenienceFeeWaiveReasonOptions = [];
            this.selectedWaiveReason = undefined;
            this.convenienceFeeCode = undefined;
            this.convenienceFeeAmount = undefined;
            this.noFutureAllowed = false;
            this.selectedPaymentMethod = undefined;
            this.currentPayment = this.getDefaultPayment();
            this.firstPayment = this.getDefaultPayment();
            this.secondPayment = this.getDefaultPayment();

            // Defaults
            this.selectedPaymentDetails = BwcUtils.cloneObject(DEFAULT_PAYMENT_DETAILS);

            // Get all payment details that might be needed.
            await this.getPaymentDetails();

            // Get valid billing accounts: must be L1, not unified, and only of a valid type
            this.billingAccounts = await BwcAccountServices.getBillingAccounts(this.recordId, true, true, BwcConstants.PaymentBillingAccountTypes);

            if (!this.isEdit) {

                // **************
                // NEW PAYMENT
                // **************

                // Enable Select Information panel, but disable the Continue button
                this.wizard.enableStep('selectPaymentInformation');
                this.wizard.enableButton('selectPaymentInformation', 'right', false);

                // Disable convenience fee and second payment until we know they apply
                this.wizard.enableStep('secondPayment', false);

                // Show "Make Another Payment" button
                this.wizard.showButton('paymentConfirmation', 'left');

                // Set all cancel button labels
                this.wizard.setButtonLabel('selectPaymentInformation', 'cancel', 'Cancel Payment');
                this.wizard.setButtonLabel('firstPayment', 'cancel', 'Cancel Payment');
                this.wizard.setButtonLabel('secondPayment', 'cancel', 'Cancel Payment');
                this.wizard.setButtonLabel('reviewPayment', 'cancel', 'Cancel Payment');

                // Build selection list of billing accounts
                this.billingAccountOptions = this.billingAccounts.map(billingAccount => {
                    return {
                        label: billingAccount.Service_Label__c,
                        value: billingAccount.Billing_Account_Number__c
                    };
                });

                // Set default selected ban
                if (this.defaultBan) {

                    // Default BAN passed in
                    this.selectedBan = this.defaultBan;

                }
                else if (this.billingAccounts.length === 1) {

                    // Only one BAN, default to it
                    this.selectedBan = this.billingAccounts[0].Billing_Account_Number__c;

                }
                else {

                    this.selectedBan = undefined;

                }

                if (this.selectedBan) {
                    // Now that we have payment details if there's already a selected ban then handle.
                    this.handleBanSelected();
                }

                // If only one ban or default is specified
                if (this.skipSelectPaymentInformation) {

                    // Skip payment information step
                    this.wizard.enableStep('selectPaymentInformation', false);

                    await this.selectPaymentInformation();

                }

            }
            else {

                // **************
                // EDIT PAYMENT
                // **************

                // BAN was passed in
                this.selectedBan = this.defaultBan;
                this.handleBanSelected();

                // Confirmation number was passed in -- find pending payment
                if (!this.confirmationNumber) {
                    throw new Error('confirmationNumber was not passed in.')
                }

                // Start with first payment
                this.wizard.enableStep('selectPaymentInformation', false);
                this.wizard.enableStep('secondPayment', false);

                // Hide "Make Another Payment" button
                this.wizard.showButton('paymentConfirmation', 'left', false);

                // Set all cancel button labels
                this.wizard.setButtonLabel('selectPaymentInformation', 'cancel', 'Cancel Edit');
                this.wizard.setButtonLabel('firstPayment', 'cancel', 'Cancel Edit');
                this.wizard.setButtonLabel('secondPayment', 'cancel', 'Cancel Edit');
                this.wizard.setButtonLabel('reviewPayment', 'cancel', 'Cancel Edit');

                // Set payment information based upon pending payment
                await this.selectPaymentInformation();

            }

            return undefined;

        }
        catch (e) {

            BwcUtils.error('Payment Wizard', e);
            throw new Error(label_unexpectedError);

        }

    }

    /********************************************************************************************************/
    //#endregion

    //#region Payment Details from API
    /********************************************************************************************************/

    paymentDetailsResponses;
    paymentDetailsRetrieved;
    pendingPayments;
    editablePendingPayments;
    @track selectedPaymentDetails = BwcUtils.cloneObject(DEFAULT_PAYMENT_DETAILS);
    get paymentRecommendations() {return this.isEdit ? this.selectedPaymentDetails.futurePayments : this.selectedPaymentDetails.paymentRecommendations;}
    get minimumImmediatePayment() {return BwcUtils.toCurrency(this.paymentRecommendations.paymentRecommendationDetails.minimumImmediatePayment);}
    get minimumTotalAmountByDueDate() {return BwcUtils.toCurrency(this.paymentRecommendations.paymentRecommendationDetails.minimumTotalAmountByDueDate);}
    get minimumTotalAmountAfterDueDate() {return BwcUtils.toCurrency(this.paymentRecommendations.paymentRecommendationDetails.minimumTotalAmountAfterDueDate);}
    get isBillingAccountActive() {return this.selectedBillingAccount.Account_Status__c === BwcConstants.BillingAccountStatus.ACTIVE.value;}
    get isBillingAccountSuspended() {return this.selectedBillingAccount.Account_Status__c === BwcConstants.BillingAccountStatus.SUSPENDED.value;}
    get isBillingAccountSuspendedInvoluntary() {
        return this.isBillingAccountSuspended &&
        this.paymentRecommendations.billingCollectionDetails &&
        this.paymentRecommendations.billingCollectionDetails.accountMessageStatusGroup === 'SUSPENDEDFORNONPAYMENT';
    }
    get isBillingAccountCanceled() {return this.selectedBillingAccount.Account_Status__c === BwcConstants.BillingAccountStatus.CANCELED.value;}
    get isBillingAccountOca() {
        return this.isBillingAccountCanceled &&
        this.paymentRecommendations.billingCollectionDetails &&
        this.paymentRecommendations.billingCollectionDetails.ocaName;
    }
    get lastPayment() {return this.isSplitPayment ? this.secondPayment : this.firstPayment;}
    get isLastPayment() {return this.currentPayment === this.lastPayment;}

    storedProfiles = [];
    refreshStoredProfiles() {

        this.storedProfiles = [];

        const storedProfiles = this.selectedPaymentDetails.paymentProfiles ? this.selectedPaymentDetails.paymentProfiles.paymentProfileList : [];
        const tempProfiles = this.selectedPaymentDetails.temporaryPaymentProfiles ? this.selectedPaymentDetails.temporaryPaymentProfiles.paymentProfileList : [];
        this.storedProfiles = tempProfiles.concat(storedProfiles);

    }

    /*
        Get payment details for every BAN.
    */
     async getPaymentDetails() {

        const getPaymentDetailsArgs = {
            recordId: this.recordId,
            bans: this.billingAccounts.map(billingAccount => billingAccount.Billing_Account_Number__c),
            topics: [
                BwcConstants.PaymentDetailTopic.PAYMENT_PROFILES.value,
                BwcConstants.PaymentDetailTopic.CONVENIENCE_FEE_ELIGIBILITY.value,
                BwcConstants.PaymentDetailTopic.LAST_PAYMENT_METHOD.value,
                BwcConstants.PaymentDetailTopic.ACCOUNT_BALANCE_SUMMARY.value,
                BwcConstants.PaymentDetailTopic.BAN_BILLING_IDS.value,
                BwcConstants.PaymentDetailTopic.PAYMENT_RECOMMENDATIONS.value,
                BwcConstants.PaymentDetailTopic.FUTURE_PAYMENTS.value,
                BwcConstants.PaymentDetailTopic.TEMPORARY_PAYMENT_PROFILES.value,
                BwcConstants.PaymentDetailTopic.AUTOPAY.value,
                BwcConstants.PaymentDetailTopic.EXTENDED_PA.value
            ]
        };

        try {
            this.paymentDetailsResponses = await BwcPaymentServices.getPaymentDetails(getPaymentDetailsArgs)
        }
        finally {
            this.paymentDetailsRetrieved = true;
        }

    }

    /********************************************************************************************************/
    //#endregion

    //#region General
    /********************************************************************************************************/

    /*
        General handler for changed inputs.
    */
    async handleInputCommit(event) {

        try {

            // Clear any custom validity message
            event.target.setCustomValidity('');

            switch(event.target.name) {

                case 'waiveReason':
                    this.selectedWaiveReason = event.target.value;
                    break;

                case 'amountPaidOther':
                    this.currentPayment.amountPaid = BwcUtils.toCurrency(event.target.value);
                    await this.setCurrentAmountAndDateValidations();
                    this.validateTotalAmountPaid();
                    break;

                case 'securityCode':
                    this.currentPayment.paymentMethod.securityCode = event.target.value;
                    this.currentPayment.paymentMethod.card.securityCode = event.target.value;
                    break;

                case 'paymentDate':
                    this.currentPayment.paymentDate = event.target.value;
                    await this.setCurrentAmountAndDateValidations();
                    this.validateTotalAmountPaid();
                    break;

                case 'storeProfile':
                    this.currentPayment.savePaymentProfile = event.target.checked;
                    break;

                case 'enrollInautoPay':
                    this.currentPayment.enrollInAutoPay = event.target.checked;
                    this.refreshEnrollInAutopay();
                    break;

                case 'convertToSinglePayment':
                    this.currentPayment.convertToSinglePayment = event.target.checked;
                    this.convertSplit();
                    break;

                case 'splitThisPayment':
                    this.currentPayment.splitThisPayment = event.target.checked;
                    this.convertSplit();
                    break;

                default:
                    break;

            }

        }
        catch(error) {
            // Log to console and report generic error
            BwcUtils.error('Payment Wizard', error);
            this.wizard.reportError(new Error(label_unexpectedError));
        }

    }

    /*
        Convert single payment to split or split to single.
    */
    convertSplit() {

        // Save current so selections don't get wiped out when we re-initialize payments
        this.saveCurrentPayment();

        if (this.isEditingSplitPayment) {

            // When converting to single payment we just retain first payment, do NOT add both or anything else.
            this.initFirstPayment();
            this.initSecondPayment();

        }
        else {

            if (this.currentPayment.splitThisPayment) {

                if (this.isEdit) {
                    // We started by editing a single payment
                    this.firstPayment.amountPaid = BwcUtils.toCurrency(BwcUtils.toCurrency(this.pendingPayments[0].paymentAmount) / 2);
                    this.initSecondPayment();
                    this.secondPayment.amountPaid = BwcUtils.toCurrency(this.pendingPayments[0].paymentAmount) - this.firstPayment.amountPaid;
                }
                else {
                    this.initFirstPayment();
                    this.initSecondPayment();
                }

            }
            else {

                // NOT converting single to split
                // Reset to original payment
                this.initFirstPayment();

            }

        }

        // This forces refresh of controls bound to currentPayment -- we will always be on first payment
        this.currentPayment = this.firstPayment;
        this.loadCurrentPayment();
        this.refreshSplitUi();

    }

    refreshSplitUi() {

        const baseTitle = this.isEdit ? 'Edit Payment' : 'Make a Payment';

        if (!this.isSplitPayment) {

            this.firstPayment.indexLabel = '';
            this.wizard.enableStep('secondPayment', false);
            this.wizard.setStepTitle('firstPayment', `<b>${baseTitle}:</b> ${this.selectedBanLabel}`);
            this.wizard.setButtonLabel('firstPayment', 'right', 'Continue to Review');

        }
        else {

            this.firstPayment.indexLabel = '(1 of 2)';
            this.wizard.enableStep('secondPayment', true);
            this.wizard.setStepTitle('firstPayment', `<b>${baseTitle} (1 of 2):</b> ${this.selectedBanLabel}`);
            this.wizard.setStepTitle('secondPayment', `<b>${baseTitle} (2 of 2):</b> ${this.selectedBanLabel}`);
            this.wizard.setButtonLabel('firstPayment', 'right', 'Continue to Second Payment');

        }

    }

    /*
        Custom validation for total amount paid.
    */
    validateTotalAmountPaid() {

        this.firstPayment.amountPaidOtherMessage = undefined;
        this.lastPayment.amountPaidOtherMessage = undefined;
        this.skipSecondPayment = false;

        // Check if we need to show non-error warning based on total amount being paid vs. past due
        if (this.isLastPayment && this.currentPayment.paymentDate === this.today && this.totalAmountAttempted < this.minimumImmediatePayment) {

            const immediateAmount = BwcUtils.formatCurrency(this.minimumImmediatePayment);

            if (this.isBillingAccountSuspendedInvoluntary) {
                this.lastPayment.amountPaidOtherMessage = {
                    variant: 'warning',
                    iconName: 'utility:warning',
                    text: label_lessPastDue.replace('{0}', immediateAmount)
                };
            }
            else if (this.isBillingAccountOca) {
                this.lastPayment.amountPaidOtherMessage = {
                    variant: 'warning',
                    iconName: 'utility:warning',
                    text: label_paymentLessThanMinOca.replace('{0}', immediateAmount)
                };
            }
            else if (this.isBillingAccountCanceled) {
                this.lastPayment.amountPaidOtherMessage = {
                    variant: 'warning',
                    iconName: 'utility:warning',
                    text: label_paymentLessThanMinCancelCollections.replace('{0}', immediateAmount)
                };
            }
            else {
                this.lastPayment.amountPaidOtherMessage = {
                    variant: 'warning',
                    iconName: 'utility:warning',
                    text: label_paymentLessThanMinSuspend.replace('{0}', immediateAmount)
                };
            }

        }
        else if (this.isFirstPayment && this.firstPayment.splitThisPayment &&
                 this.paymentRecommendations.eligibilityAmounts.maxAmountAllowed !== undefined &&
                 this.currentPayment.amountPaid > BwcUtils.toCurrency(this.paymentRecommendations.eligibilityAmounts.maxAmountAllowed) - 1) {

            // We're on first payment and at exactly max amount
            this.firstPayment.amountPaidOtherMessage = {
                variant: 'info',
                iconName: 'utility:info',
                text: label_skipSecond
            };
            this.skipSecondPayment = true;

        }

        // Refresh in case skipping or not skipping second payment
        this.refreshSplitUi();

    }

    /*
        Set visibility of Enroll in Autopay checkboxes
    */
    refreshEnrollInAutopay() {

        if (this.alreadyAutopayEnrolled || this.isEdit) {
            // AutoPay never available in edit or if already enrolled
            this.firstPayment.showEnrollInAutoPay = false;
            this.secondPayment.showEnrollInAutoPay = false;
            return;
        }

        if ((this.firstPayment.paymentMethodType === BwcConstants.PaymentMethodType.CARD.value &&
             this.selectedPaymentDetails.autopay?.paymentPlanEligibility?.paymentMethodAllowed?.card) ||
            (this.firstPayment.paymentMethodType === BwcConstants.PaymentMethodType.BANKACCOUNT.value &&
                this.selectedPaymentDetails.autopay?.paymentPlanEligibility?.paymentMethodAllowed?.bank)) {

            // Secured payment and eligigble for autopay
            this.firstPayment.showEnrollInAutoPay = true;

        }
        else {

            this.firstPayment.showEnrollInAutoPay = false;

        }

        if (this.isSplitPayment && !this.firstPayment.enrollInAutoPay) {

            if ((this.secondPayment.paymentMethodType === BwcConstants.PaymentMethodType.CARD.value &&
                this.selectedPaymentDetails.autopay?.paymentPlanEligibility?.paymentMethodAllowed?.card) ||
                (this.secondPayment.paymentMethodType === BwcConstants.PaymentMethodType.BANKACCOUNT.value &&
                    this.selectedPaymentDetails.autopay?.paymentPlanEligibility?.paymentMethodAllowed?.bank)) {
    
                this.secondPayment.showEnrollInAutoPay = true;
    
            }
            else {
    
                this.secondPayment.showEnrollInAutoPay = false;
    
            }

        }
        else {
            this.secondPayment.showEnrollInAutoPay = false;
        }

    }

    get inputPaymentMethod() {return this.template.querySelector('c-bwc-input-payment-method');}

    /********************************************************************************************************/
    //#endregion

    //#region Select Payment Information Panel
    /********************************************************************************************************/

    // All billing accounts for the person account, use for multi-selection
    billingAccounts = [];
    @track billingAccountOptions = [];
    selectedBan;
    selectedAccountType;
    selectedBillingAccount = {};
    @track paymentTypeOptions = [];
    get isSelectPaymentTypeDisabled() {return !this.selectedBan || this.paymentTypeOptions.length === 0;}

    get selectedBanLabel() {return `${this.labels.account}# ${this.selectedBan} (${this.selectedAccountType})`;}

    // Skip second payment because first payment is at maximum
    skipSecondPayment = false;

    // These properties simplify logic
    get isEditingSplitPayment() {
        return (this.isEdit && this.pendingPayments && this.editablePendingPayments.length === 2);
    }
    get isConvertToSplit() {return this.firstPayment.splitThisPayment;}
    get isConvertToSingle() {return this.firstPayment.convertToSinglePayment;}
    get isSplitPayment() {
        return (this.isEdit && ((this.pendingPayments && this.editablePendingPayments.length === 2 && !this.isConvertToSingle) || this.isConvertToSplit)) || 
               (!this.isEdit && this.firstPayment.splitThisPayment && !this.skipSecondPayment);}
    get isPromiseToPay() {return this.selectedPaymentMethod === BwcConstants.PaymentMethodType.PROMISE_TO_PAY.value;}
    get isFirstPayment() {return this.currentPayment === this.firstPayment;}
    get isSecondPayment() {return this.currentPayment === this.secondPayment;}
    get firstPaymentCoversAmountDue() {return this.firstPayment.amountPaid >= this.pastDueAmount;}
    get currentPaymentOption() {

        if (this.isSecondPayment && this.firstPaymentCoversAmountDue) {
            // This is split payment and we're on second payment and first payment covers the amount due, we can use second payment option
            return this.paymentRecommendations.paymentOptionTwo;
        }

        // This is not split, or we're on the first payment, or we're on second payment but first payment does NOT cover the amount due
        // In all cases, use first payment option
        return this.paymentRecommendations.paymentOptionOne;

    }
    get isEpaActive() {return this.selectedPaymentDetails.isEpaActive;}
    get hideSelectPaymentType() {return this.isEpaActive;}
    get skipSelectPaymentInformation() {return this.isEdit || (this.defaultBan || this.billingAccounts?.length === 1);}
    get alreadyAutopayEnrolled() {return this?.selectedPaymentDetails?.autopay?.paymentPlanInfo?.[0];}
    get showEpaAutopayReviewInformation() {return this.alreadyAutopayEnrolled || this.firstPayment?.enrollInAutoPay || this.secondPayment?.enrollInAutoPay;}

    // RAISR - smart-fields data and context
    spiData = [ ];
    get inputPaymentContext() {
        if (this.isSecondPayment) {
            // If is second payment, add '2' to the context so RAISR can differentiate smart-fields
            return this.isEdit ? BwcPayments.RaisrContext.UPDATE_PAYMENT.value + ' 2' : BwcPayments.RaisrContext.MAKE_PAYMENT.value + ' 2';
        } else {
            return this.isEdit ? BwcPayments.RaisrContext.UPDATE_PAYMENT.value : BwcPayments.RaisrContext.MAKE_PAYMENT.value;
        }
    }
    get spiDataFirstPayment() { return this.spiData.length > 0 ? this.spiData[0] : { spiDataList: [] }; }
    get spiDataSecondPayment() { return this.spiData.length > 1 ? this.spiData[1] : { spiDataList: [] }; }

    /*
        Set the payment details for the selected ban.
    */
    handleBanSelected(event) {

        try {

            this.wizard.clearError();
            this.paymentTypeOptions = [];

            this.selectedPaymentDetails = BwcUtils.cloneObject(DEFAULT_PAYMENT_DETAILS);

            if (event) {
                this.selectedBan = event.target.value;
            }

            // Find corresponding billing account record
            this.selectedBillingAccount = this.billingAccounts.find(billingAccount => billingAccount.Billing_Account_Number__c === this.selectedBan);
            this.selectedAccountType = BwcConstants.BillingAccountType.getLabelForValue(this.selectedBillingAccount.Account_Type__c);

            // Find details for ban
            const newSelectedPaymentDetails  = this.paymentDetailsResponses.find(paymentDetailsResponse => paymentDetailsResponse.ban === this.selectedBan);

            if (!newSelectedPaymentDetails) {
                throw new Error('Payment Details not found for BAN, unable to continue.');
            }

            // Check for partial errors for payment details topics that are required to proceed:

            // Account Balance Summary
            if (newSelectedPaymentDetails.erroraccountBalanceSummary) {
                BwcUtils.error('Payment Wizard', JSON.stringify(newSelectedPaymentDetails.erroraccountBalanceSummary));
                newSelectedPaymentDetails.accountBalanceSummary = {
                    accountStatus: ''
                };
                throw new Error('Error retrieving accountBalanceSummary, unable to continue.');
            }

            // System and Division Ids
            if (newSelectedPaymentDetails.errorbanBillingIds) {
                BwcUtils.error('Payment Wizard', JSON.stringify(newSelectedPaymentDetails.errorbanBillingIds));
                throw new Error('Error retrieving banBillingIds, unable to continue.');
            }

            // Saved profiles
            if (newSelectedPaymentDetails.errorpaymentProfiles) {
                BwcUtils.error('Payment Wizard', new Error('Error retrieving stored profiles.'), JSON.stringify(newSelectedPaymentDetails.errorpaymentProfiles) );
            }

            // Payment recommendations
            if (newSelectedPaymentDetails.errorPaymentRecommendations) {
                BwcUtils.warn('Payment Wizard', 'paymentRecommendations are not available for the selected BAN. Using default behaviors. Error follows:');
                BwcUtils.error('Payment Wizard', JSON.stringify(newSelectedPaymentDetails.errorPaymentRecommendations));
                newSelectedPaymentDetails.paymentRecommendations = BwcUtils.cloneObject(DEFAULT_PAYMENT_DETAILS.paymentRecommendations);
            }

            // Payment recommendation details
            if (!newSelectedPaymentDetails.paymentRecommendations.paymentRecommendationDetails) {
                BwcUtils.warn('Payment Wizard', 'paymentRecommendationDetails details are not available for the selected BAN.:');
                // Default object
                newSelectedPaymentDetails.paymentRecommendations.paymentRecommendationDetails = {};
            }

            // Future payments
            if (newSelectedPaymentDetails.errorfuturePayments) {
                BwcUtils.warn('Payment Wizard', 'Future payment information is not available for the selected BAN. Using default behaviors. Error follows:');
                BwcUtils.error('Payment Wizard', JSON.stringify(newSelectedPaymentDetails.errorfuturePayments));
                newSelectedPaymentDetails.futurePayments = BwcUtils.cloneObject(DEFAULT_PAYMENT_DETAILS.futurePayments);
                if (!newSelectedPaymentDetails.payments) {
                    newSelectedPaymentDetails.payments = [];
                }
            }

            // Future recommendation details
            if (this.isEdit && !newSelectedPaymentDetails.futurePayments.paymentRecommendationDetails) {
                BwcUtils.warn('Payment Wizard', 'futurePayments.paymentRecommendationDetails details are not available for the selected BAN.:');
                // Default object
                newSelectedPaymentDetails.futurePayments.paymentRecommendationDetails = {};
            }

            // Autopay details
            if (newSelectedPaymentDetails.errorautopay) {
                BwcUtils.warn('Payment Wizard', 'AutoPay details are not available for the selected BAN.:');
                BwcUtils.error('Payment Wizard', JSON.stringify(newSelectedPaymentDetails.errorautopay));
            }

            // EPA
            if (newSelectedPaymentDetails.errorextendedPA) {
                BwcUtils.warn('Payment Wizard', 'ExtendedPA details are not available for the selected BAN.:');
                BwcUtils.error('Payment Wizard', JSON.stringify(newSelectedPaymentDetails.errorextendedPA));
            }

            // Leave this comment, uncomment for testing OCA
            // this.paymentRecommendations.paymentRecommendationDetails.minimumImmediatePayment = "123.00";
            // this.paymentRecommendations.billingCollectionDetails = {
            //     ocaName: 'Collectors, Inc.',
            //     ocaPhone: '603-555-1212'
            // };

            // Now set the member
            this.selectedPaymentDetails = newSelectedPaymentDetails;

            // Initialize list of stored profiles
            this.refreshStoredProfiles();

            if (!this.isEdit) {

                // **************
                // NEW PAYMENT
                // **************

                // Eligible to pay online?
                if (!this.paymentRecommendations.allowPaymentOnline.eligibleFlag) {
                    throw new Error(label_notEligible);
                }

                //
                // Payment Type Options
                //

                // Immediate allowed?
                if (this.paymentRecommendations.paymentOptionOne.paymentMethod.bank ||
                    this.paymentRecommendations.paymentOptionOne.paymentMethod.card) {
                        this.paymentTypeOptions.push({label: 'Immediate/Future Payment', value: 'singlePayment'});
                }

                // Split allowed?

                // Find if there are two or more pending payments
                this.pendingPayments = this.selectedPaymentDetails.payments.filter(payment => payment.paymentStatus === BwcConstants.PaymentStatus.PENDING.value);
                this.editablePendingPayments = this.pendingPayments.filter(payment => payment?.editEligible?.eligibleFlag);
                const twoPendingPayments = this.pendingPayments.length >= 2;
                if (twoPendingPayments) {
                    BwcUtils.log('There are two or more pending payments: split will not be allowed.');
                }

                // Find if no future payments allowed
                this.noFutureAllowed =
                    !this.paymentRecommendations.paymentOptionOne.futurePaymentAllowed &&
                    !this.paymentRecommendations.paymentOptionTwo.futurePaymentAllowed;
                if (this.noFutureAllowed) {
                    BwcUtils.log('No future payments are allowed: split will not be allowed.');
                }

                // Only allow split if both of those things are NOT true
                if (!twoPendingPayments && !this.noFutureAllowed) {
                    BwcUtils.log('Less than 2 pending payments and future payments are allowed: split will be allowed.');
                    this.paymentTypeOptions.push({label: 'Split Payment', value: 'splitPayment'});
                }

                // Promise-to-pay allowed?
                const paymentOptionOne = this.paymentRecommendations.paymentOptionOne;
                if (paymentOptionOne.paymentMethod.mail || paymentOptionOne.paymentMethod.agency || paymentOptionOne.paymentMethod.other) {

                    // Promise to pay is allowed
                    this.paymentTypeOptions.push({label: 'Promise-to-Pay', value: 'promiseToPay'});

                }

                if (this.paymentTypeOptions.length === 0) {
                    throw new Error('No payment options are allowed for this BAN.');
                }

                this.wizard.enableButton('selectPaymentInformation', 'right');

            }
            else {

                // **************
                // EDIT PAYMENT
                // **************

                // Get all pending payments for the BAN
                this.pendingPayments = this.selectedPaymentDetails.payments.filter(payment => payment.paymentStatus === BwcConstants.PaymentStatus.PENDING.value);
                this.editablePendingPayments = this.pendingPayments.filter(payment => payment?.editEligible?.eligibleFlag);
                if (this.pendingPayments.length === 0) {

                    // Something wrong because we're editing a pending payment
                    throw new Error('No pending payments were found.');

                }

            }

        }
        catch (error) {
            if (event) {
                // Called from event, report error

                // Log to console and report generic error
                BwcUtils.error('Payment Wizard', error);
                this.wizard.reportError(new Error(label_unexpectedError));

                // Don't allow continue to next step
                this.wizard.enableButton('selectPaymentInformation', 'right', false);

            }
            else {
                // Called from other code, just rethrow
                throw error;
            }
        }

    }

    /*
        Called from Continue button for Select Payment Information panel.
    */
    async selectPaymentInformation() {

        if (!this.skipSelectPaymentInformation) {

            // **************
            // NEW PAYMENT
            // **************

            // Get Select Payment Information panel and vaidate entries
            const panel = this.template.querySelector('div[data-name="selectPaymentInformation"');

            // Validate all inputs on Select Payment Information panel
            let isValid = BwcUtils.reportValidity(panel);
            if (!isValid) {
                throw new Error();
            }

            if (this.isSelectPaymentTypeDisabled) {
                throw new Error();
            }

        }

        // Init options for convenience fee
        this.initConvenienceFee();

        // Init overall balance information
        this.initBalanceDetails();
 
        // Setup first payment
        this.initFirstPayment();
        this.currentPayment = this.firstPayment;

        // Setup any second payment
        if (this.isSplitPayment) {
            this.initSecondPayment();
        }

        // Set all UI for single or split
        this.refreshSplitUi();

        // Set step titles
        this.wizard.setStepTitle('reviewPayment', `<b>Review Payment:</b> ${this.selectedBanLabel}`);
        this.wizard.setStepTitle('paymentConfirmation', `<b>Payment Confirmation:</b> ${this.selectedBanLabel}`);

    }

    /*
        Initialize overall balance details shown while making payment.
    */
    initBalanceDetails() {

        const accountBalanceSummary = this.selectedPaymentDetails.accountBalanceSummary;
        this.dueDate = BwcUtils.parseIsoDateString(accountBalanceSummary.billDueDate);
        this.totalAmountDueByDueDate = BwcUtils.toCurrency(accountBalanceSummary.amountDue);
        this.pastDueAmount = BwcUtils.toCurrency(accountBalanceSummary.amountPastDue);

        if (this.pastDueAmount > 0) {
            this.pastDueMessage = 'due Immediately';
        }
        else {
            this.pastDueMessage = undefined
        }

        this.decisionDescription = this.paymentRecommendations.paymentRecommendationDetails.experienceCodeDescription;

    }

    getDefaultBankAccount() {
        return {
            accountType: BwcConstants.BankAccountType.CHECKING.value,
            accountHolderName: this.selectedBillingAccount.First_Name__c + ' ' + this.selectedBillingAccount.Last_Name__c,
            routingNumber: '',
            bankAccountNumber: '',
            bankAccountNumberVisibleValue: '',
            bankAccountNumberToken: ''
        };
    }

    getDefaultCard() {
        return {
            cardHolderName: this.selectedBillingAccount.First_Name__c + ' ' + this.selectedBillingAccount.Last_Name__c,
            billingAddress: {
                zipCode: this.selectedBillingAccount.Billing_Zipcode__c
                    ? this.selectedBillingAccount.Billing_Zipcode__c.substring(0, 5)
                    : undefined
            },
            cardNumber: '',
            cardNumberVisibleValue: '',
            cardNumberToken: '',
            expirationDate: '',
            securityCode: '',
            securityCodeVisibleValue: '',
            securityCodeToken: ''
        };
    }

    getDefaultPayment() {
        return {
            paymentMethod: {
                bankAccount: this.getDefaultBankAccount(),
                card: this.getDefaultCard(),
                promiseToPay: {}
            },
            paymentAmountOptions: [],
            promiseToPayMethodOptions: []
        };
    }

    /*
        Initialize values for first (or only) payment.
    */
    initFirstPayment() {

        if (!this.isEdit) {

            // **************
            // NEW PAYMENT
            // **************

            const isFirstInit = !this.firstPayment.isAdd;
            if (isFirstInit) {
                this.firstPayment = this.getDefaultPayment();
                this.firstPayment.isAdd = true;
            }
            else {
                this.firstPayment.paymentState = undefined;
            }

            //
            //  Payment Amount Options
            //

            const paymentAmountOptions = [];
            this.firstPayment.paymentAmountOptions = paymentAmountOptions;

            if (!this.isSplitPayment) {

                // Total amount
                if (this.totalAmountDueByDueDate && this.totalAmountDueByDueDate > 0) {
                    paymentAmountOptions.push({
                        index: paymentAmountOptions.length,
                        key: 'paymentAmountOption' + paymentAmountOptions.length,
                        label: 'Total Amount',
                        amount: this.totalAmountDueByDueDate
                    });
                }

            }
            else {

                if (this.totalAmountDueByDueDate && this.totalAmountDueByDueDate > 0) {

                    // Half of total amount
                    paymentAmountOptions.push({
                        index: paymentAmountOptions.length,
                        key: 'paymentAmountOption' + paymentAmountOptions.length,
                        label: 'Half of Total Amount',
                        amount: BwcUtils.toCurrency(this.totalAmountDueByDueDate / 2) // If cents are odd, toCurrency will round it
                    });

                }

            }

            // Past due
            if (this.isPastDueAmount) {

                paymentAmountOptions.push({
                    index: paymentAmountOptions.length,
                    key: 'paymentAmountOption' + paymentAmountOptions.length,
                    label: 'Past Due Amount',
                    amount: this.pastDueAmount,
                    class: 'past-due'
                });
            }

            // EPA
            if (this.isEpaActive) {

                // Find next installment that's active or broken -- favor active first then broken
                let nextDueInstallmentIndex = this.selectedPaymentDetails.extendedPA.installmentList.findIndex(installment => installment.status === BwcPayments.EpaStatus.ACTIVE);
                if (nextDueInstallmentIndex === -1) {
                    // Look for broken
                    nextDueInstallmentIndex = this.selectedPaymentDetails.extendedPA.installmentList.findIndex(installment => installment.status === BwcPayments.EpaStatus.BROKEN);
                }

                if (nextDueInstallmentIndex !== -1) {

                    const nextDueInstallment = this.selectedPaymentDetails.extendedPA.installmentList[nextDueInstallmentIndex];
                    paymentAmountOptions.push({
                        index: paymentAmountOptions.length,
                        key: 'paymentAmountOption' + paymentAmountOptions.length,
                        label: `Extended Payment Arrangement Installment #${nextDueInstallmentIndex + 1} Due Amount`,
                        amount: BwcUtils.toCurrency(nextDueInstallment.amountDue)
                    });

                }

            }

            // Other
            paymentAmountOptions.push({
                index: paymentAmountOptions.length,
                key: 'paymentAmountOption' + paymentAmountOptions.length,
                label: 'Other',
                amount: 0.00,
                isOther: true
            });

            // Default to first payment amount option
            this.firstPayment.selectedPaymentAmountOptionIndex = 0;
            this.firstPayment.selectedPaymentAmountOption = paymentAmountOptions[0];
            this.firstPayment.amountPaid = paymentAmountOptions[0].amount;

            // Other payment amount min and max

            if (isFirstInit) {

                //
                // Payment Method Types
                //
                this.setPaymentMethodTypeOptions(this.firstPayment, this.paymentRecommendations.paymentOptionOne);

                // Default payment method type
                this.firstPayment.paymentMethod.type = this.firstPayment.paymentMethodTypeOptions[0].value;

                //
                // Default Payment Date
                //
                this.firstPayment.paymentDate = this.today;

                // Option to split payment
                if (this.pendingPayments.length < 2 && !this.noFutureAllowed) {
                    this.firstPayment.showSplitThisPayment = true;
                }

            }

            // Convenience fee?
            if (BwcConstants.PaymentMethodType.isSecured(this.firstPayment.paymentMethod.type) && (!this.isSplitPayment || !this.secondPayment?.hasNewConvenienceFee)) {
                // Unsecured payment is being changed to secured -- now requires acceptance of convenience fee
                this.firstPayment.hasNewConvenienceFee = true;
            }
            else {
                // No new convenience fee
                this.firstPayment.hasNewConvenienceFee = false;
            }

        }
        else {

            // **************
            // EDIT PAYMENT
            // **************

            this.firstPayment.isEdit = true;

            if (!this.firstPayment.pendingPayment) {

                // Pending payment hasn't been set yet -- do it first time
                // (In case of split or merge, do NOT want to do this again as it resets the payment method)

                // Link the pending payment
                if (this.editablePendingPayments.length === 2) {
                    // When there are two pending payments, the first one is the last one in the pending payments array
                    this.firstPayment.pendingPayment = this.editablePendingPayments[1];
                }
                else {
                    // There is only one pending payment
                    this.firstPayment.pendingPayment = this.editablePendingPayments[0];
                }
                this.setPendingPayment(this.firstPayment, this.selectedPaymentDetails.futurePayments.paymentOptionOne);

            }

            this.firstPayment.isEdit = true;

            // Option to split or convert to single
            if (this.isEditingSplitPayment) {
                this.firstPayment.showConvertToSinglePayment = true;
            }
            else if (this.pendingPayments.length === 1) {
                this.firstPayment.showSplitThisPayment = true;
            }

        }

        this.validateTotalAmountPaid();

    }

    /*
        Initialize values for second payment of a split payment.
    */
    initSecondPayment() {

        this.secondPayment = this.getDefaultPayment();
        this.secondPayment.indexLabel = '(2 of 2)';

        if (!this.isEdit) {

            // **************
            // NEW PAYMENT
            // **************

            this.secondPayment.isAdd = true;

            //
            //  Payment Amount Options
            //

            const paymentAmountOptions = [];
            this.secondPayment.paymentAmountOptions = paymentAmountOptions;

            // Total amount
            paymentAmountOptions.push({
                index: paymentAmountOptions.length,
                key: 'paymentAmountOption' + paymentAmountOptions.length,
                label: 'Remaining Amount',
                amount: 0.00
            });

            // Other
            paymentAmountOptions.push({
                index: paymentAmountOptions.length,
                key: 'paymentAmountOption' + paymentAmountOptions.length,
                label: 'Other',
                amount: 0.00,
                isOther: true
            });

            // Default to first payment amount option
            this.secondPayment.selectedPaymentAmountOptionIndex = 0;
            this.secondPayment.selectedPaymentAmountOption = paymentAmountOptions[0];
            this.secondPayment.amountPaid = paymentAmountOptions[0].amount;

            // Other payment amount min and max

            //
            // Payment Method Types
            //
            this.setPaymentMethodTypeOptions(this.secondPayment, this.paymentRecommendations.paymentOptionTwo);

            // Default payment method type
            this.secondPayment.paymentMethod.type = this.secondPayment.paymentMethodTypeOptions[0].value;

            //
            // Default Payment Date
            //
            this.secondPayment.paymentDate = this.today;

            // Convenience fee?
            if (BwcConstants.PaymentMethodType.isSecured(this.secondPayment.paymentMethod.type) &&  !this.firstPayment.hasNewConvenienceFee) {
                // Unsecured payment is being changed to secured -- now requires acceptance of convenience fee
                this.secondPayment.hasNewConvenienceFee = true;
            }
            else {
                // No new convenience fee
                this.secondPayment.hasNewConvenienceFee = false;
            }

        }
        else {

            // **************
            // EDIT PAYMENT
            // **************

            if (this.firstPayment.convertToSinglePayment) {
                // We're converting to single, so second payment is getting canceled
                this.secondPayment.isCancel = true;
            }
            else if (this.firstPayment.splitThisPayment) {
                // We're converting to split, so second payment is being added
                this.secondPayment.isAdd = true;
            }
            else {
                // We're editing a split so second payment is being edited
                this.secondPayment.isEdit = true;
            }

            // Link the pending payment
            if (!this.secondPayment.pendingPayment) {
                // This will always be the right pending payment:
                //   If we are editing a split, then payment 2 is always the first one in the array of 2
                //   If we are splitting a single payment, then we use the first payment
                this.secondPayment.pendingPayment = this.editablePendingPayments[0];
                this.setPendingPayment(this.secondPayment, this.selectedPaymentDetails.futurePayments.paymentOptionTwo);
            }

        }

    }

    /*
        Get payment methods allowed based upon first or second option. If option not available, return them all.
    */
    setPaymentMethodTypeOptions(payment, paymentOption) {

        const paymentMethodTypeOptions = [];
        const promiseToPayMethodOptions = [];

        // Allowed Promise to Pay Methods -- mail, agency, other
        if (paymentOption.paymentMethod.mail) {
            promiseToPayMethodOptions.push({value: BwcConstants.PromiseToPayMethod.MAIL.value, label: BwcConstants.PromiseToPayMethod.MAIL.longLabel});
        }
        if (paymentOption.paymentMethod.agency) {
            promiseToPayMethodOptions.push({value: BwcConstants.PromiseToPayMethod.AGENCY.value, label: BwcConstants.PromiseToPayMethod.AGENCY.longLabel});
        }
        if (paymentOption.paymentMethod.other) {
            promiseToPayMethodOptions.push({value: BwcConstants.PromiseToPayMethod.OTHER.value, label: BwcConstants.PromiseToPayMethod.OTHER.longLabel});
        }

        if (!paymentOption || paymentOption.paymentMethod.bank) {
            // Bank account is allowed
            paymentMethodTypeOptions.push(BwcConstants.PaymentMethodType.BANKACCOUNT);
        }

        if (!paymentOption || paymentOption.paymentMethod.card) {
            // Card is allowed
            paymentMethodTypeOptions.push(BwcConstants.PaymentMethodType.CARD);
        }

        if ((this.isSplitPayment && promiseToPayMethodOptions.length > 0) ||
            (this.isEdit && this.firstPayment.pendingPayment.paymentMethod === BwcConstants.PaymentMethodType.PROMISE_TO_PAY.value) ||
            (!this.isEdit && promiseToPayMethodOptions.length > 0)) {

            // Either:
            // 1. This is a split payment, and there's at least one promise-to-pay method, so promise-to-pay is allowed
            // OR
            // 2. We're editing an existing Promise to Pay so have to show it
            // OR
            // 3. is a new payment and there's at least one promise-to-pay method
            paymentMethodTypeOptions.push(BwcConstants.PaymentMethodType.PROMISE_TO_PAY);

        }

        // }

        // Set options onto payment
        payment.paymentMethodTypeOptions = paymentMethodTypeOptions;
        payment.promiseToPayMethodOptions = promiseToPayMethodOptions;

        if (promiseToPayMethodOptions && promiseToPayMethodOptions.length > 0) {
            // Default promise to pay method to first available option
            payment.paymentMethod.promiseToPay = {
                method: promiseToPayMethodOptions[0].value
            };
        }

    }

    /*
        Apply values from the pending payment.
    */
    setPendingPayment(payment, paymentOption) {

        // Link the pending payment
        payment.pendingPaymentId = payment.pendingPayment.confirmationNumber
            ? payment.pendingPayment.confirmationNumber
            : payment.pendingPayment.pendingPaymentId;

        // Default from existing pending payment amount
        payment.amountPaid = BwcUtils.toCurrency(payment.pendingPayment.paymentAmount);

        // Default from existing pending payment date
        payment.paymentDate = BwcUtils.toIsoDate(new Date(BwcUtils.parseIsoDateString(payment.pendingPayment.paymentDate)));

        // Construct original payment method to use later for comparison
        payment.originalPaymentMethod = {
            type: BwcConstants.PaymentDetailToPaymentMethodType[payment.pendingPayment.paymentMethod].value,
        };
        switch (payment.originalPaymentMethod.type) {

            case BwcConstants.PaymentMethodType.BANKACCOUNT.value:
                payment.originalPaymentMethod.bankAccount = {
                    accountType: payment.pendingPayment.paymentDetailMethodType,
                    bankAccountNumber: payment.pendingPayment.paymentDetailMethodLastFour
                }
                break;

            case BwcConstants.PaymentMethodType.CARD.value:
                payment.originalPaymentMethod.card = {
                    cardType: payment.pendingPayment.paymentDetailMethodType,
                    cardNumber: payment.pendingPayment.paymentDetailMethodLastFour
                }
                break;

            case BwcConstants.PaymentMethodType.PROMISE_TO_PAY.value:
                payment.originalPaymentMethod.promiseToPay = {
                    method: payment.pendingPayment.paymentDetailMethodType
                }
                break;
                
            default:
                break;

        }

        // Payment Method Types
        this.setPaymentMethodTypeOptions(payment, paymentOption);

        // Default payment method from existing pending payment method
        payment.paymentMethod.type = BwcConstants.PaymentDetailToPaymentMethodType[payment.pendingPayment.paymentMethod].value;
        if (payment.pendingPayment.card) {
            payment.paymentMethod.card = payment.pendingPayment.card;
            payment.paymentMethod.card.billingAddress = {
                zipCode: payment.pendingPayment.card.zipCode
            };
        }
        payment.paymentMethod.bankAccount = payment.pendingPayment.bankAccount;

    }

    /********************************************************************************************************/
    //#endregion

    //#region Convenience Fee Panel
    /********************************************************************************************************/

    convenienceFeeIndicator;
    get isConvenienceFeeEligible() {return this.convenienceFeeIndicator === 'Y';}
    get isConvenienceFeeWaivable() {return hasWaiveConvenienceFeePermission && this.convenienceFeeIndicator === 'Y';}
    get showInlineConvenienceFee() {return this.currentPayment.hasNewConvenienceFee && this.isConvenienceFeeEligible;}
    @track convenienceFeeWaiveReasonOptions = [];
    convenienceFeeCode;
    convenienceFeeAmount;   // Amount of convenience fee, if eligible
    get convenienceFeeMessage() {
        if (!this.selectedBillingAccount) {
            return '';
        }
        if (this.convenienceFeeIndicator === 'U') {
            return label_unknownConvenienceFeeMessage;
        }
        return label_convenienceFeeMessage.replace('{0}', this.selectedBillingAccount.Last_Name__c).replace('{1}', BwcUtils.formatCurrency(this.convenienceFeeAmount));
    }

    selectedWaiveReason;    // Selected Waive code
    get waiveFeeDisabled() {return !this.selectedWaiveReason;}

    /*
        Set convenience fee info based upon returned payment details conveniencefeeEligibility.
    */
    initConvenienceFee() {

        // Uncomment for test data
        // conveniencefeeEligibility = {feeEligibilityInfo: {eligibilityIndicator: 'Y', rate: 5, waiveReasonList: [{waiveCode: 'T', waiveDescription: 'Test'}]}}

        const conveniencefeeEligibility = this.selectedPaymentDetails.conveniencefeeEligibility;
        if (this.selectedPaymentDetails.errorconveniencefeeEligibility) {
            BwcUtils.warn('Payment Wizard', 'Error retrieving conveniencefeeEligibility, using Unknown. Error follows:');
            BwcUtils.error('Payment Wizard', JSON.stringify(this.selectedPaymentDetails.errorconveniencefeeEligibility));
        }

        let feeEligibilityInfo;

        if (!conveniencefeeEligibility) {

            // Error retrieving, use U indicator
            this.convenienceFeeIndicator = 'U';

        }
        else {

            feeEligibilityInfo = conveniencefeeEligibility.feeEligibilityInfo;
            this.convenienceFeeIndicator = feeEligibilityInfo.eligibilityIndicator;
            this.convenienceFeeAmount = BwcUtils.toCurrency(feeEligibilityInfo.rate);

        }

        switch (this.convenienceFeeIndicator) {

            case 'Y':
                {

                    // Eligible for convenience fee
                    // Build list of waive reasons
                    this.convenienceFeeWaiveReasonOptions = feeEligibilityInfo.waiveReasonList.map(reason => ({
                        value: reason.waiveCode,
                        label: reason.waiveDescription
                    }));

                    // Add blank option
                    this.convenienceFeeWaiveReasonOptions.unshift({value: '', label: ''});

                }
                break;

            case 'N':

                // Not eligible for convenience fee
                this.convenienceFeeCode = 'N';
                break;

            case 'U':

                // Unable to determine convenience fee
                this.convenienceFeeCode = 'U';
                break;

            default:
                throw new Error('Unexpected convenienceFeeCode ' + this.convenienceFeeCode);

        }

    }

    /*
        Waive Fee button clicked.
    */
    handleWaiveFee() {

        this.convenienceFeeCode = this.selectedWaiveReason;
        this.wizard.gotoNextEnabledStep();

    }

    /********************************************************************************************************/
    //#endregion

    //#region Make Payment Panels
    /********************************************************************************************************/

    today = BwcUtils.toIsoDate(new Date());
    dueDate;
    totalAmountDueByDueDate;
    pastDueAmount;
    get isPastDueAmount() {return this.pastDueAmount > 0;}
    get pastDueClass() {return this.isPastDueAmount ? 'payment-amount past-due' : 'payment-amount';}
    pastDueMessage = 'due Immediately';
    decisionDescription;

    @track currentPayment = {
        paymentMethod: {},
        paymentAmountOptions: []
    };
    @track firstPayment = {
        paymentMethod: {},
        paymentAmountOptions: []
    };
    @track secondPayment = {
        paymentMethod: {},
        paymentAmountOptions: [],
        amountPaid: 0
    };

    // Script at top of Make Payment panel
    get makePaymentScript() {

        if (this.isBillingAccountSuspendedInvoluntary) {
            // Involuntary suspension, show warning
            return label_paymentSuspendedScript;
        }
        if (this.isBillingAccountOca) {
            // In collections, show warning including collections agency details
            return label_paymentCanceledOcaScript
                .replace('{0}', this.selectedPaymentDetails.paymentRecommendations.billingCollectionDetails.ocaName)
                .replace('{1}', this.selectedPaymentDetails.paymentRecommendations.billingCollectionDetails.ocaPhone);
        }
        if (this.isBillingAccountCanceled) {
            // Canceled, show warning
            return label_paymentCanceledScript;
        }

        return undefined;

    }

    // Help text next to "How would customer like to pay"
    get paymentAmountHelp() {

        let content = '';

        const accountBalanceSummary = this.selectedPaymentDetails ? this.selectedPaymentDetails.accountBalanceSummary : undefined;

        if (accountBalanceSummary) {

            const dueDate = BwcUtils.parseIsoDateString(accountBalanceSummary.billDueDate);

            if (this.minimumImmediatePayment) {
                content = `Minimum Immediate Payment: ${BwcUtils.formatCurrency(this.minimumImmediatePayment)}`;
            }

            if (this.minimumTotalAmountByDueDate) {
                content += `<br/>Minimum Payment by ${BwcUtils.formatDateShort(dueDate)}: ${BwcUtils.formatCurrency(this.minimumTotalAmountByDueDate)}`;
            }

            if (this.minimumTotalAmountAfterDueDate) {
                content += `<br/>Minimum Payment After ${BwcUtils.formatDateShort(dueDate)}: ${BwcUtils.formatCurrency(this.minimumTotalAmountAfterDueDate)}`;
            }

        }

        if (content.startsWith('<br/>')) {
            // Strip leading linebreak
            content = content.substring(5);
        }
        return content;

    }

    get paymentDateHelp() {

        const maxPaymentDate = this.currentPayment.maxPaymentDate ? this.currentPayment.maxPaymentDate : this.currentPayment.maxPaymentDateIfEdited;

        if (this.currentPayment.paymentDateDisabled || maxPaymentDate === this.today) {
            return 'Future payments are not allowed.'
        }

        if (maxPaymentDate) {
            const help = 'Customer is eligible to pick only these days - {0} to {1}';
            return help.replace('{0}', BwcUtils.formatDateShort(this.today)).replace('{1}', BwcUtils.formatDateShort(maxPaymentDate));
        }

        // Recommendation not available, but cannot be in past
        return 'Payment date must be today or later.';

    }

    /*
        Load the first payment panel from the first payment data.
    */
    async loadFirstPayment() {

        this.currentPayment = this.firstPayment;

        await this.loadCurrentPayment();

    }

    /*
        Load the second payment panel from the second payment data.
    */
    async loadSecondPayment() {

        this.currentPayment = this.secondPayment;

        //
        // Payment Method Types
        //
        if (this.firstPaymentCoversAmountDue) {
            // First payment covers past amount due, we can use paymentOptionTwo
            this.setPaymentMethodTypeOptions(this.secondPayment, this.paymentRecommendations.paymentOptionTwo);
        }
        else {
            // First payment does NOT cover the amount due, even though this is second payment, we still use paymentOptionOne
            this.setPaymentMethodTypeOptions(this.secondPayment, this.paymentRecommendations.paymentOptionOne);
        }

        if (!this.isEdit) {

            // **************
            // NEW PAYMENT
            // **************

            // Update second payment amount remaining option based upon first payment amount
            this.secondPayment.paymentAmountOptions[0].amount = Math.max(0, BwcUtils.toCurrency(this.totalAmountDueByDueDate - this.firstPayment.amountPaid));
            if (this.secondPayment.selectedPaymentAmountOptionIndex === 0) {
                this.secondPayment.amountPaid = this.secondPayment.paymentAmountOptions[0].amount;
            }
    
        }

        this.validateTotalAmountPaid();

        await this.loadCurrentPayment();

    }

    /*
        Load the current payment panel from the current payment data.
    */
    async loadCurrentPayment() {

        // Allow input payment to render
        await BwcUtils.nextTick();

        if (this.currentPayment.paymentState) {
            // Set it back to last state
            this.inputPaymentMethod.state = this.currentPayment.paymentState;
            this.inputPaymentMethod.refreshCardProfileList();
        }
        else {
            // Set state from the payment method itself
            this.inputPaymentMethod.initialize(
                this.currentPayment.paymentMethodTypeOptions, 
                this.storedProfiles, 
                this.currentPayment.promiseToPayMethodOptions, 
                this.currentPayment.paymentMethod,
                this.getDefaultBankAccount(),
                this.getDefaultCard());
        }

        // Allow convenience fee component to render based upon payment method
        await BwcUtils.nextTick();

        if (this.currentPayment.convenienceFeeState) {

            const convenienceFeeComponent = this.template.querySelector('c-bwc-convenience-fee');
            if (convenienceFeeComponent) {
                convenienceFeeComponent.state = this.currentPayment.convenienceFeeState;
            }

        }

        // Allow render to pick up the change of current payment so that expected elements are rendered
        await BwcUtils.nextTick();

        if (!this.isEdit) {

            // **************
            // NEW PAYMENT
            // **************

            // Set amount paid option radio
            this.template.querySelector(`input[data-payment-amount-option-radio][data-index="${this.currentPayment.selectedPaymentAmountOptionIndex}"]`).checked = true;  
            if (this.currentPayment.selectedPaymentAmountOption.isOther) {
                this.template.querySelector('lightning-input[data-name="amoutPaidOther"]').disabled = false;
            }

        }

        await this.setCurrentAmountAndDateValidations();

    }

    /*
        Tells if this is special case where we should ignore recommender.
    */
    get isBypassRecommender() {

        let bypassRecommender = false;
        if (this.currentPayment.pendingPayment) {

            // True if current payment is being edited and the date is in the future and payment amount and date have not been modified.
            const pendingPaymentDate = this.currentPayment.pendingPayment && BwcUtils.toIsoDate(new Date(BwcUtils.parseIsoDateString(this.currentPayment.pendingPayment.paymentDate)));
            const paymentDateIsInFuture = pendingPaymentDate > this.today;
            const paymentDateNotChanged = pendingPaymentDate === this.currentPayment.paymentDate;
            const paymentAmountNotChanged = BwcUtils.toCurrency(this.currentPayment.pendingPayment.paymentAmount) === this.currentPayment.amountPaid;
            const notSecuredToUnsecured = 
                !(BwcConstants.PaymentMethodType.isSecured(this.currentPayment.originalPaymentMethod.type) &&
                !BwcConstants.PaymentMethodType.isSecured(this.currentPayment.paymentMethodType));

                bypassRecommender = this.currentPayment.isEdit && paymentDateIsInFuture && paymentDateNotChanged && paymentAmountNotChanged && notSecuredToUnsecured;
        }

        return bypassRecommender;

    }

    /*
        Update all validations and messages for payment amount and payment date.
    */
    async setCurrentAmountAndDateValidations() {

        //
        // Set min and max for Other Amount paid:
        //

        if (!this.isBypassRecommender) {

            // Min
            this.currentPayment.amountPaidMin = BwcUtils.toCurrency(this.paymentRecommendations.eligibilityAmounts.minAmountAllowed);

            // Max
            const maxEligible = this.paymentRecommendations.eligibilityAmounts.maxAmountAllowed;
            if (maxEligible !== undefined) {

                if (this.isSplitPayment && this.isSecondPayment) {

                    // It's second payment of split payment, total paid cannot exceed eligible
                    this.currentPayment.amountPaidMax = BwcUtils.toCurrency(BwcUtils.toCurrency(maxEligible) - this.firstPayment.amountPaid);

                }
                else {
                    // Only one payment, cannot exceed max eligible
                    this.currentPayment.amountPaidMax = BwcUtils.toCurrency(maxEligible);
                }

            }
            else {
                this.currentPayment.amountPaidMax = undefined;
            }
            
            // Error messages for payment amount
            this.currentPayment.amountPaidMinError = label_tooLow.replace('{0}', BwcUtils.formatCurrency(this.currentPayment.amountPaidMin));
            this.currentPayment.amountPaidMaxError = label_tooHigh.replace('{0}', BwcUtils.formatCurrency(this.currentPayment.amountPaidMax));

        }
        else {

            // When date and amount are not changed on an edit, allow value to remain, regardless of recommender
            this.currentPayment.amountPaidMin = undefined;
            this.currentPayment.amountPaidMax = undefined;

        }

        //
        // Set max payment date
        //
        let maxPaymentDate;
        switch (this.currentPayment.paymentMethodType) {

            case BwcConstants.PaymentMethodType.CARD.value:
                maxPaymentDate = this.currentPaymentOption.paymentDate.card;
                break;

            case BwcConstants.PaymentMethodType.BANKACCOUNT.value:
                maxPaymentDate = this.currentPaymentOption.paymentDate.bank;
                break;

            case BwcConstants.PaymentMethodType.PROMISE_TO_PAY.value:
                if (this.currentPayment.promiseToPayMethod) {
                    // Get the corresponding date field from the recommender data
                    maxPaymentDate = this.currentPaymentOption.paymentDate[this.currentPayment.promiseToPayMethod.toLowerCase()];
                }
                else {
                    maxPaymentDate = undefined;
                }
                break;

            default:
                break;

        }

        if (this.isBypassRecommender) {
            // When date and amount are not changed on an edit, allow value to remain, regardless of recommender
            // But we retain the max date to show in help message
            this.currentPayment.maxPaymentDate = undefined;
            this.currentPayment.maxPaymentDateIfEdited = maxPaymentDate;
        }
        else {
            this.currentPayment.maxPaymentDate = maxPaymentDate;
            this.currentPayment.maxPaymentDateIfEdited = undefined;
        }

        // Future payment allowed?
        if (!this.isEdit) {
            this.currentPayment.paymentDateDisabled = !this.currentPaymentOption.futurePaymentAllowed;
        }

        // Error messages for payment date
        if (this.currentPayment.maxPaymentDate) {
            this.currentPayment.maxPaymentDateError = label_dateRangeInvalid.replace('{0}', BwcUtils.formatDateShort(this.today)).replace('{1}', BwcUtils.formatDateShort(this.currentPayment.maxPaymentDate));
        }
        else {
            this.currentPayment.maxPaymentDateError = label_dateMinInvalid.replace('{0}', BwcUtils.formatDateShort(this.today));
        }
        this.currentPayment.minPaymentDateError = this.currentPayment.maxPaymentDateError;

        // Apply validation to show/clear error messages
        await BwcUtils.nextTick();
        const amountInput = this.template.querySelector('lightning-input[data-name="amountPaidOther"]');
        if (amountInput && !amountInput.disabled) {
            amountInput.reportValidity();
        }
        const dateInput = this.template.querySelector('lightning-input[data-name="paymentDate"]');
        if (dateInput && !dateInput.disabled) {
            dateInput.reportValidity();
        }

    }

    /*
        Selected profile radio button changed.
    */
    handlePaymentAmountOptionChange(event) {

        const index = parseInt(event.target.dataset.index, 10);

        this.currentPayment.selectedPaymentAmountOptionIndex = index;
        this.currentPayment.selectedPaymentAmountOption = this.currentPayment.paymentAmountOptions[index];

        const amountPaidOtherInput = this.template.querySelector('lightning-input[data-name="amoutPaidOther"]');
        if (this.currentPayment.selectedPaymentAmountOption.isOther) {

            amountPaidOtherInput.disabled = false;
            this.setOtherPaymentAmount(amountPaidOtherInput);

        }
        else {

            amountPaidOtherInput.disabled = true;
            amountPaidOtherInput.reportValidity();
            this.currentPayment.amountPaid = this.currentPayment.selectedPaymentAmountOption.amount;

        }

        this.validateTotalAmountPaid();

    }

    /*
        When the Other radio is selected for payment amount, set the input's value
    */
    setOtherPaymentAmount(amountPaidOtherInput) {

        const amountDue = BwcUtils.toCurrency(this.selectedPaymentDetails.accountBalanceSummary.amountDue);

        // Default to amount due
        amountPaidOtherInput.value = this.currentPayment.amountPaid
            ? this.currentPayment.amountPaid
            : (amountDue > 0 ? amountDue : undefined);
        if (!BwcUtils.toCurrency(amountPaidOtherInput.value)) {

            // Nothing is owed, use minimum since zero is not allowed
            amountPaidOtherInput.value = BwcUtils.toCurrency(this.currentPayment.amountPaidMin);

        }

        if (this.currentPayment.selectedPaymentAmountOption.isOther) {
            // Other is selected, so update the underlying value
            this.currentPayment.amountPaid = BwcUtils.toCurrency(amountPaidOtherInput.value);
        }

        amountPaidOtherInput.reportValidity();

    }

    /*
        Handle changes to payment method type or the selected stored profile.
    */
    async handlePaymentMethodChange(event) {

        try {

            this.currentPayment.isUseNew = false;
            this.currentPayment.showStoreProfile = false;

            const autopayDetails = this.selectedPaymentDetails.autopay;

            if (event.detail.paymentMethod.type === BwcConstants.PaymentMethodType.CARD.value ||
                (event.detail.paymentMethod.type === BwcConstants.PaymentMethodType.PAYMENT_PROFILE.value &&
                event.detail.state.selectedPaymentMethodType === BwcConstants.PaymentMethodType.CARD.value)) {
                
                this.selectedPaymentMethod = BwcConstants.PaymentMethodType.CARD.value;
                this.currentPayment.paymentMethodType = BwcConstants.PaymentMethodType.CARD.value;
                this.currentPayment.isUseNew = event.detail.state.isNewCard;
                this.currentPayment.showStoreProfile = this.currentPayment.isUseNew && (hasEnterCustomerPaymentDetailsPermission || event.detail.state.temporaryProfile);
             

            }
            else if (event.detail.paymentMethod.type === BwcConstants.PaymentMethodType.BANKACCOUNT.value ||
                    (event.detail.paymentMethod.type === BwcConstants.PaymentMethodType.PAYMENT_PROFILE.value &&
                    event.detail.state.selectedPaymentMethodType === BwcConstants.PaymentMethodType.BANKACCOUNT.value)) {

                this.selectedPaymentMethod = BwcConstants.PaymentMethodType.BANKACCOUNT.value;
                this.currentPayment.paymentMethodType = BwcConstants.PaymentMethodType.BANKACCOUNT.value;
                this.currentPayment.isUseNew = event.detail.state.isNewBankAccount;
                this.currentPayment.showStoreProfile = this.currentPayment.isUseNew && (hasEnterCustomerPaymentDetailsPermission || event.detail.state.temporaryProfile);

            }
            else if (event.detail.paymentMethod.type === BwcConstants.PaymentMethodType.PROMISE_TO_PAY.value) {
                
                this.currentPayment.paymentMethodType = BwcConstants.PaymentMethodType.PROMISE_TO_PAY.value;
                this.selectedPaymentMethod = BwcConstants.PaymentMethodType.PROMISE_TO_PAY.value;

            }

            this.refreshEnrollInAutopay();

            // Set current payment date max and messages based upon options.
            await this.setCurrentAmountAndDateValidations();

            if (!this.isEdit) {

                // **************
                // NEW PAYMENT
                // **************
                if (BwcConstants.PaymentMethodType.isSecured(this.currentPayment.paymentMethodType) && (this.isFirstPayment || !this.firstPayment.hasNewConvenienceFee)) {
                    // Unsecured payment is being changed to secured -- now requires acceptance of convenience fee
                    this.currentPayment.hasNewConvenienceFee = true;

                    // If now convenience fee on first payment, don't show on second
                    if (this.isFirstPayment && this.secondPayment?.hasNewConvenienceFee) {
                        this.secondPayment.hasNewConvenienceFee = false;
                    }

                }
                else {
                    // No new convenience fee
                    this.currentPayment.hasNewConvenienceFee = false;
                }

            }
            else {

                // **************
                // EDIT PAYMENT
                // **************

                if (this.currentPayment?.pendingPayment?.paymentMethod === BwcConstants.PaymentMethodType.PROMISE_TO_PAY.value &&
                    event.detail.paymentMethod.type !== BwcConstants.PaymentMethodType.PROMISE_TO_PAY.value &&
                    (this.isFirstPayment || !this.firstPayment.hasNewConvenienceFee)) {

                    // Unsecured payment is being changed to secured -- now requires acceptance of convenience fee
                    this.currentPayment.hasNewConvenienceFee = true;

                }
                else {

                    // No new convenience fee
                    this.currentPayment.hasNewConvenienceFee = false;

                }

            }

        }
        catch(error) {
            // Log to console and report generic error
            BwcUtils.error('Payment Wizard', error);
            this.wizard.reportError(new Error(label_unexpectedError));
        }

    }

    /*
        Returns true if payment methods are equivalent.
    */
    paymentMethodIsSame(paymentMethod1, paymentMethod2) {

        // Have to reduce to CARD or BANKACCOUNT, in case one or both are references to a payment profile.
        const baseMethod1 = this.getBasePaymentMethod(paymentMethod1);
        const baseMethod2 = this.getBasePaymentMethod(paymentMethod2);

        if (baseMethod1.type !== baseMethod2.type) {
            // Methods aren't same -- done
            return false;
        }

        if (baseMethod1.type === BwcConstants.PaymentMethodType.CARD.value) {

            return  baseMethod1.card && baseMethod2.card &&
                    baseMethod1.card.cardType === baseMethod2.card.cardType &&
                    BwcUtils.right(baseMethod1.card.cardNumber, 4) === BwcUtils.right(baseMethod2.card.cardNumber, 4);

        }

        if (baseMethod1.type === BwcConstants.PaymentMethodType.BANKACCOUNT.value) {

            return  baseMethod1.bankAccount && baseMethod2.bankAccount &&
                    baseMethod1.bankAccount.accountType === baseMethod2.bankAccount.accountType &&
                    BwcUtils.right(baseMethod1.bankAccount.bankAccountNumber, 4) === BwcUtils.right(baseMethod2.bankAccount.bankAccountNumber, 4);

        }

        return true;

    }

    /*
        Return a payment method that is a card, bank account, or promise to pay -- even if payment method is reference to stored procedure.
    */
    getBasePaymentMethod(paymentMethod) {

        let baseMethod = paymentMethod;
        if (baseMethod.type === BwcConstants.PaymentMethodType.PAYMENT_PROFILE.value) {
            baseMethod = {
                type: paymentMethod.bankAccount ? BwcConstants.PaymentMethodType.BANKACCOUNT.value : BwcConstants.PaymentMethodType.CARD.value,
                bankAccount: paymentMethod.bankAccount,
                card: paymentMethod.card
            };
        }
        return baseMethod;

    }
    
    /*
        Promise to Pay method (mail, agency, other) has changed. This affects the max date, which recommender specifies by method.
    */
    handlePromiseToPayMethodChange(event) {

        if (event) {
            this.currentPayment.promiseToPayMethod = event.detail.newValue;
        }
        else {
            this.currentPayment.promiseToPayMethod = this.inputPaymentMethod.paymentMethod.method;
        }

    }

    /*
        Redaction has created a new temporary profile, add it to the list of available.
    */
    handleNewTemporaryProfile(event) {

        if (!this.selectedPaymentDetails.temporaryPaymentProfiles) {
            this.selectedPaymentDetails.temporaryPaymentProfiles = {
                paymentProfileList: []
            };
        }
        if (!this.selectedPaymentDetails.temporaryPaymentProfiles.paymentProfileList) {
            this.selectedPaymentDetails.temporaryPaymentProfiles.paymentProfileList = [];
        }

        this.selectedPaymentDetails.temporaryPaymentProfiles.paymentProfileList.push(event.detail);

        this.currentPayment.showStoreProfile = true;

        this.refreshStoredProfiles();

    }

    /*
        Called from Continue button for Make Payment panel.
    */
    async validateCurrentPayment() {

        // Get payment panel
        const panel = this.template.querySelector('div[data-name="makePayment"]');

        // Validate all inputs on payment panel
        let isValid = BwcUtils.reportValidity(panel, 'c-bwc-input-payment-method,c-bwc-convenience-fee');

        //
        // Additional custom validation for amount paid
        //
        
        const amountPaidOtherInput = this.template.querySelector('lightning-input[data-name="amoutPaidOther"]');
        if (!amountPaidOtherInput.disabled) {

            const today = BwcUtils.parseIsoDateString(this.today);
            let amountPaid = BwcUtils.toCurrency(amountPaidOtherInput.value);
            const minDueBy = BwcUtils.toCurrency(this.paymentRecommendations.paymentRecommendationDetails.minimumTotalAmountByDueDate);
            const minDueAfter = BwcUtils.toCurrency(this.paymentRecommendations.paymentRecommendationDetails.minimumTotalAmountAfterDueDate);
            const paymentDate = BwcUtils.parseIsoDateString(this.currentPayment.paymentDate);

            if (this.isSecondPayment) {
                amountPaid = BwcUtils.toCurrency(this.firstPayment.amountPaid + amountPaid);
            }

            if ((!this.isSplitPayment || this.isSecondPayment) && !this.isBypassRecommender) {

                if (paymentDate !== today && paymentDate <= this.dueDate && minDueBy && amountPaid < minDueBy) {
                    amountPaidOtherInput.setCustomValidity(label_tooLowByDueDate.replace('{0}', BwcUtils.formatDateShort(this.dueDate)).replace('{1}', BwcUtils.formatCurrency(minDueBy)));
                    isValid = false;
                }
                else if (paymentDate !== today && paymentDate > this.dueDate && minDueAfter && amountPaid < minDueAfter) {
                    amountPaidOtherInput.setCustomValidity(label_tooLowAfterDueDate.replace('{0}', BwcUtils.formatDateShort(this.dueDate)).replace('{1}', BwcUtils.formatCurrency(minDueAfter)));
                    isValid = false;
                }
                else {
                    amountPaidOtherInput.setCustomValidity('');
                }

            }
            else {
                amountPaidOtherInput.setCustomValidity('');
            }

            amountPaidOtherInput.reportValidity();

        }

        if (!isValid) {
            throw new Error();
        }

    }

    /*
        Save the value from the input payment component before moving to another step.
    */
    async saveCurrentPayment() {

        this.currentPayment.paymentMethod = BwcUtils.cloneObject(this.inputPaymentMethod.paymentMethod);
        this.currentPayment.paymentState = this.inputPaymentMethod.state;

        const spiDataValues = this.inputPaymentMethod.spiDataValues;
        // If this is first payment and there is already a first payment saved, replace it
        if (this.isFirstPayment && this.spiData.length > 0) {
            this.spiData[0] = spiDataValues;
        } 
        // If is second payment and there is already a second payment saved, replace it
        else if (this.isSecondPayment && this.spiData.length > 1) {
            this.spiData[1] = spiDataValues;
        } 
        // Add first or second payment spiData values if not present
        else {
            this.spiData.push(spiDataValues);
        }
        BwcUtils.log(`bwcPaymentWizard spiData: ${JSON.stringify(this.spiData)}`);

        this.inputPaymentMethod.saveProfileSecurityCodes();

        if (this.currentPayment.hasNewConvenienceFee) {

            if (this.showInlineConvenienceFee) {

                const convenienceFeeComponent = this.template.querySelector('c-bwc-convenience-fee');

                this.currentPayment.convenienceFeeState = convenienceFeeComponent.state;
                if (convenienceFeeComponent.isAccepted) {
                    this.currentPayment.convenienceFeeCode = 'Y';
                }
                else {
                    this.currentPayment.convenienceFeeCode = convenienceFeeComponent.waiveReason;
                }

            }
            else {

                // Not eligible, just pass the default code
                this.currentPayment.convenienceFeeCode = this.convenienceFeeCode;

            }

        }

    }

    /********************************************************************************************************/
    //#endregion

    //#region Review Payment Panel
    /********************************************************************************************************/

    tncVerbiage;
    tncId;
    tncKey;
    agreedToTerms;

    // Shown in yellow message bar
    get reviewMessage() {
        return this.lastPayment.amountPaidOtherMessage && this.lastPayment.amountPaidOtherMessage.variant === 'warning' ? this.lastPayment.amountPaidOtherMessage : undefined;
    }
    get totalAmountAttemptedLabel() {return this.isSplitPayment ? 'Total amount of two (2) payments:' : 'Total payment amount:'}
    get totalAmountAttempted() {return this.firstPayment.amountPaid + this.secondPayment.amountPaid;}
    get agreeToTermsCheckbox() {return this.template.querySelector('lightning-input[data-name="agreeToTerms"]');}

    /*
        Get terms and conditions and any other init for the review panel.
    */
    async loadReviewPayment() {

        this.tncId = undefined;
        this.tncKey = undefined;
        this.tncVerbiage = undefined;

        // Always require re-confirm
        let agreeToTermsCheckbox = this.agreeToTermsCheckbox;
        if (agreeToTermsCheckbox) agreeToTermsCheckbox.checked = false;

        // Determine single paymentEventType based upon combination of saving profile and autopay conditions:
        const isAnySecured =
            BwcConstants.PaymentMethodType.isSecured(this.firstPayment.paymentMethod.type) ||
            BwcConstants.PaymentMethodType.isSecured(this.secondPayment.paymentMethod.type);

        if (isAnySecured) {

            const savingProfile =
                (this.firstPayment.savePaymentProfile && BwcConstants.PaymentMethodType.isNewSecured(this.firstPayment.paymentMethod.type)) ||
                (this.secondPayment.savePaymentProfile && BwcConstants.PaymentMethodType.isNewSecured(this.secondPayment.paymentMethod.type));
            const autopay = this.firstPayment.enrollInAutoPay || this.secondPayment.enrollInAutoPay;

            let paymentEventType;
            if (!savingProfile && !autopay) {
                paymentEventType = BwcConstants.PaymentEventType.OF.value;
            }
            else if (savingProfile && !autopay) {
                paymentEventType = BwcConstants.PaymentEventType.OP.value;
            }
            else if (!savingProfile && autopay) {
                paymentEventType = BwcConstants.PaymentEventType.OA.value;
            }
            else {
                paymentEventType = BwcConstants.PaymentEventType.ME.value;
            }

            try {

                const termsAndConditions = await BwcPaymentServices.getTermsAndConditions(paymentEventType);

                this.tncId = parseInt(termsAndConditions.tncId__c, 10);
                this.tncKey = termsAndConditions.tncKey__c;
                this.tncVerbiage = termsAndConditions.tncVerbiage__c;

            }
            catch(e) {
                BwcUtils.error('Payment Wizard', e);
                this.tncId = -1;
                this.tncVerbiage = `<span style="color: red;">${e.message ? e.message : JSON.stringify(e)}</span>`;
            }

        }
        else {

            // Will hide terms and send this code
            this.tncKey = "TNC_PTP";

        }

    }

    /*
        Agree to terms checkbox clicked.
    */
    handleAgreeToTermsChange() {

        // Clear validity check each time it's changed
        const agreeToTerms = this.agreeToTermsCheckbox;
        agreeToTerms.setCustomValidity('');
        agreeToTerms.reportValidity();

    }

    /*
        Called from Submit Payment button for Review Payment panel.
    */
    async submitPayment() {

        // Verify checkbox
        if (this.tncId) {

            const agreeToTerms = this.agreeToTermsCheckbox;
            if (!agreeToTerms.checked) {

                agreeToTerms.setCustomValidity(label_paymentAgreementVerify);
                agreeToTerms.reportValidity();
                throw new Error();

            }
            else {

                agreeToTerms.setCustomValidity('');
                agreeToTerms.reportValidity();

            }

        }

        await this.sendPayment();

    }

    /*
        Call API to make the payment.
    */
    async sendPayment() {

        let paymentRequest;

        if(!this.isEdit) {

            // **************
            // NEW PAYMENT
            // **************

            paymentRequest = {
                transactionId: BwcUtils.generateUUID(),
                convenienceFee: this.convenienceFeeCode,
                tncId: this.tncId,
                customerAgreement: this.tncKey,
                storeTermsConditionConsent: !!this.tncKey,
                makePaymentAccountRequest: [
                    {
                        accountNumber: this.selectedBillingAccount.Billing_Account_Number__c,
                        accountType: this.selectedBillingAccount.Account_Type__c,
                        firstName: this.selectedBillingAccount.First_Name__c,
                        lastName: this.selectedBillingAccount.Last_Name__c,
                        systemId: this.selectedPaymentDetails.banBillingIds.systemId,
                        divisionId: this.selectedPaymentDetails.banBillingIds.divisionId,
                        makePaymentItemRequest: [this.buildPaymentItemRequest(this.firstPayment, '1')]
                    }
                ]
            };

            if (this.isSplitPayment) {

                // Add second payment
                paymentRequest.makePaymentAccountRequest[0].makePaymentItemRequest.push(this.buildPaymentItemRequest(this.secondPayment, '2'));

            }

        }
        else {

            // **************
            // EDIT PAYMENT
            // **************

            let convenienceFeeCode;
            if (this.firstPayment.hasNewConvenienceFee) {
                // There's convenience fee associated with first payment edit
                convenienceFeeCode = this.firstPayment.convenienceFeeCode;
            }
            else if (this.secondPayment.hasNewConvenienceFee) {
                // There's convenience fee associated with second payment edit
                convenienceFeeCode = this.secondPayment.convenienceFeeCode;
            }

            paymentRequest = {
                transactionId: BwcUtils.generateUUID(),
                convenienceFee: convenienceFeeCode,
                tncId: this.tncId,
                customerAgreement: this.tncKey,
                storeTermsConditionConsent: !!this.tncKey,
                accountNumber: this.selectedBillingAccount.Billing_Account_Number__c,
                accountType: this.selectedBillingAccount.Account_Type__c,
                firstName: this.selectedBillingAccount.First_Name__c,
                lastName: this.selectedBillingAccount.Last_Name__c,
                systemId: this.selectedPaymentDetails.banBillingIds.systemId,
                divisionId: this.selectedPaymentDetails.banBillingIds.divisionId,
                existingPendingPaymentId: [
                    {
                        pendingPaymentId: this.firstPayment.pendingPaymentId
                    }
                ],
                modifyFuturePaymentRequest: [this.buildPaymentItemRequest(this.firstPayment, '1')]
            };

            if (this.isSplitPayment) {

                if (!this.isConvertToSplit) {

                    // Editing existing split, push the second pendingPaymentId -- if converting to split there is no second pendingPaymentId
                    paymentRequest.existingPendingPaymentId.push(
                        {
                            pendingPaymentId: this.secondPayment.pendingPaymentId
                        }
                    );

                }

                // Add second payment
                paymentRequest.modifyFuturePaymentRequest.push(this.buildPaymentItemRequest(this.secondPayment, '2'));

            }
            else if (this.isConvertToSingle) {

                // Need to add the other pending payment ID to the existing Ids
                const secondPendingPayment = this.pendingPayments[0];   // This is correct -- second payment is first in array
                paymentRequest.existingPendingPaymentId.push(
                    {
                        pendingPaymentId: secondPendingPayment.confirmationNumber ? secondPendingPayment.confirmationNumber : secondPendingPayment.pendingPaymentId
                    }
                );

            }

        }

        try {

            this.wizard.setBusy(true);

            let firstPaymentResponse;
            let secondPaymentResponse;

            if (!this.isEdit) {

                let paymentResponse;
                try {
                    paymentResponse = await BwcPaymentServices.makePaymentRaisr(paymentRequest, this.spiData);
                }
                catch(error) {

                    this.firstPayment.status = 'failure';
                    this.firstPayment.message = error.message;
                    this.createInteractionActivity(this.firstPayment);
                    if (this.isSplitPayment || (this.isEdit && this.firstPayment.convertToSinglePayment)) {
                        // It's a split OR split is converted to single and second payment needs to have an interaction activity for the cancel
                        this.secondPayment.status = 'failure';
                        this.secondPayment.message = error.message;
                        this.createInteractionActivity(this.secondPayment);
                    }    
                    throw error;
                }

                firstPaymentResponse = paymentResponse.content.makePaymentAccountResponse[0].makePaymentItemResponse[0];
                if (this.isSplitPayment) {
                    secondPaymentResponse = paymentResponse.content.makePaymentAccountResponse[0].makePaymentItemResponse[1];
                }

            }
            else {

                let paymentResponse;
                try {
                    paymentResponse = await BwcPaymentServices.updatePaymentRaisr(paymentRequest, this.spiData);
                }
                catch(error) {
                    this.firstPayment.status = 'failure';
                    this.firstPayment.message = error.message;
                    this.createInteractionActivity(this.firstPayment);
                    if (this.isSplitPayment || (this.isEdit && this.firstPayment.convertToSinglePayment)) {
                        // It's a split OR split is converted to single and second payment needs to have an interaction activity for the cancel
                        this.secondPayment.status = 'failure';
                        this.secondPayment.message = error.message;
                        this.createInteractionActivity(this.secondPayment);
                    }    
                    throw error;
                }

                firstPaymentResponse = paymentResponse.content.modifyFuturePaymentResponse[0];
                if (this.isSplitPayment) {
                    secondPaymentResponse = paymentResponse.content.modifyFuturePaymentResponse[1];
                }

            }

            // Check first payment and set status and message
            if (firstPaymentResponse.error) {

                this.firstPayment.status = 'failure';
                this.firstPayment.message = firstPaymentResponse.error.message + ': ' + JSON.stringify(firstPaymentResponse.error);

            }
            else {

                this.firstPayment.confirmationNumber = firstPaymentResponse.paymentConfirmationNumber;
                this.firstPayment.status = 'success';

            }
            if (this.isConvertToSingle) {
                this.secondPayment.status = this.firstPayment.status;
                this.secondPayment.message = this.firstPayment.message;
            }

            if (this.isSplitPayment) {

                // Check second payment and set status and message
                if (secondPaymentResponse.error) {

                    this.secondPayment.status = 'failure';
                    this.secondPayment.message = secondPaymentResponse.error.message + ': ' + JSON.stringify(secondPaymentResponse.error);

                }
                else {

                    this.secondPayment.confirmationNumber = secondPaymentResponse.paymentConfirmationNumber;
                    this.secondPayment.status = 'success';

                }

            }

            // Create interaction activities
            this.createInteractionActivity(this.firstPayment);
            if (this.isSplitPayment || (this.isEdit && this.firstPayment.convertToSinglePayment)) {
                // It's a split OR split is converted to single and second payment needs to have an interaction activity for the cancel
                this.createInteractionActivity(this.secondPayment);
            }

            // Handle error display and refresh
            if (!this.isSplitPayment && this.firstPayment.status === 'failure') {

                // No split payment and there's an error, just throw it now to stop on review screen
                throw new Error(this.firstPayment.message);

            }
            else if (this.isSplitPayment && this.firstPayment.status === 'failure' && this.secondPayment.status  === 'failure') {

                // Both payments failed, throw now to stop on review screen
                throw new Error('First payment failed: ' + this.firstPayment.message + ' \r\nSecond payment failed: ' + this.secondPayment.message);

            }
            else {

                // Something succeeded, refresh -- other error will show on confirmation screen
                publish(this.messageContext, REFRESHMC, {scope: 'paymentHistory', recordId: this.recordId});
                publish(this.messageContext, REFRESHMC, {scope: 'paymentProfiles', recordId: this.recordId});
                publish(this.messageContext, REFRESHMC, {scope: 'autoPayProfiles', recordId: this.recordId});

            }

        }
        finally {

            this.wizard.setBusy(false);

        }

    }

    /*
        Build the API makePaymentItemRequest object for the specified payment details
    */
    buildPaymentItemRequest(paymentDetails, sequenceNumber) {

        const paymentMethod = BwcUtils.cloneObject(paymentDetails.paymentMethod);

        // Remove any card or bank information associated with profile
        // Input component sends it so we have complete information, but cannot send it on the payment itself
        if (paymentMethod.type === BwcConstants.PaymentMethodType.PAYMENT_PROFILE.value) {
            paymentMethod.card = undefined;
            paymentMethod.bankAccount = undefined;
        }

        const result = {
            sequenceNumber: sequenceNumber,
            amount: paymentDetails.amountPaid.toFixed(2),
            paymentItemCategory: 'PMT',
            futurePaymentDate: paymentDetails.paymentDate === this.today ? undefined : paymentDetails.paymentDate,
            paymentMethod: paymentMethod,
            savePaymentProfile: paymentDetails.savePaymentProfile,
            enrollInAutopay: paymentDetails.enrollInAutoPay,
            profileName: paymentDetails.savePaymentProfile ? BwcUtils.buildPaymentMethodName(paymentDetails.paymentMethod) : undefined,
            pendingPaymentId: paymentDetails.pendingPaymentId
        };

        return result;

    }

    /*
        Create an InteractionActivity for each payment added or edited
    */
    createInteractionActivity(payment) {

        try {

            // Get values from original payment for canceled
            const paymentMethod = payment.isCancel ? payment.originalPaymentMethod : payment.paymentMethod;
            const paymentDate = payment.isCancel ? payment.pendingPayment.paymentDate : payment.paymentDate
            const paymentAmount = payment.isCancel ? payment.pendingPayment.paymentAmount : payment.amountPaid.toFixed(2);

            // Secured?
            const isPaymentSecured = BwcConstants.PaymentMethodType.isSecured(paymentMethod.type);

            // Figure out action, could be one of six for secured/unsecured and add/edit/cancel
            let action;
            if (payment.isAdd) {

                // Add
                action = isPaymentSecured
                    ? BwcConstants.InteractionActivityValueMapping.BillingPaymentSecuredAdd.action
                    : BwcConstants.InteractionActivityValueMapping.BillingPaymentPromiseAdd.action;

            }
            else if (payment.isEdit) {

                // Edit
                action = isPaymentSecured
                    ? BwcConstants.InteractionActivityValueMapping.BillingPaymentSecuredEdit.action
                    : BwcConstants.InteractionActivityValueMapping.BillingPaymentPromiseEdit.action;
            }
            else if (payment.isCancel) {

                // Cancel
                action = isPaymentSecured
                    ? BwcConstants.InteractionActivityValueMapping.BillingPaymentSecuredCancel.action
                    : BwcConstants.InteractionActivityValueMapping.BillingPaymentPromiseCancel.action;

            }

            if (!action) {
                // There's no action, meaning the payment wasn't edited or canceled
                return;
            }

            // Determine payment method type
            const basePaymentMethod = this.getBasePaymentMethod(paymentMethod);
            const paymentMethodType = isPaymentSecured ? basePaymentMethod.type.toLowerCase() : basePaymentMethod.promiseToPay.method.toLowerCase();

            // Determine convenience fee status
            let convenienceFeeCode;
            if (payment === this.firstPayment && !payment.hasNewConvenienceFee) {
                convenienceFeeCode = this.convenienceFeeCode;
            }
            else if (payment.hasNewConvenienceFee) {
                convenienceFeeCode = payment.convenienceFeeCode;
            }

            let convFeeStatus;
            let convFeeAmount;
            if (convenienceFeeCode === 'Y') {
                // Convenience fee accepted
                convFeeStatus = 'Accepted';
                convFeeAmount = this.convenienceFeeAmount.toFixed(2);
            }
            else if (convenienceFeeCode && convenienceFeeCode !== 'N' && convenienceFeeCode !== 'U') {
                // Convenience fee waived
                convFeeStatus = 'Waived';
            }
            else {
                // Not eligible, unknown, or denied
            }

            // Build out details
            const details = {
                recordId: this.recordId,
                service: this.selectedBillingAccount.Account_Type__c,
                serviceName: this.selectedBillingAccount.Service_Name__c,
                ban: this.selectedBan,
                paymentTrx: {
                    trxDate: this.today,
                    paymentDate: paymentDate,
                    paymentMethod: paymentMethodType,
                    paymentAmount: paymentAmount,
                    convFeeStatus: convFeeStatus,
                    convFeeAmount: convFeeAmount,
                    totalAmountDue: this.totalAmountDueByDueDate !== undefined ? this.totalAmountDueByDueDate.toFixed(2) : '0.00',
                    pastAmountDue: this.pastDueAmount !== undefined ? this.pastDueAmount.toFixed(2) : '0.00',
                    splitPayment: this.isSplitPayment
                },
                status: payment.status,
                errorMessage: payment.status === 'failure' ? payment.message : undefined
            };

            // Construct billingStatus
            if (this.isBillingAccountActive) {
                if (!this.pastDueAmount) {
                    details.billingStatus = 'GoodStanding';
                }
                else {
                    details.billingStatus = 'PastDue';
                }
            }
            else if (this.isBillingAccountSuspended) {
                details.billingStatus = 'Suspended';
            }
            else if (this.isBillingAccountCanceled) {
                details.billingStatus = 'Canceled';
            }
            else if (this.isBillingAccountOca) {
                details.billingStatus = 'OCA';
            }

            // Publish
            BwcInteractActivityPublisher.publishMessage(this.recordId, action, JSON.stringify(details), null);

        }
        catch (error) {
            // Write any error to the log only
            BwcUtils.error('Payment Wizard', 'Failed to create Interaction Activity: ' + error.message);
            BwcUtils.error('Payment Wizard', error);
        }

    }

    /********************************************************************************************************/
    //#endregion

    //#region Confirmation Panel
    /********************************************************************************************************/

    // Total amount actually paid -- depends upon which payments succeeded
    get totalAmountPaid() {
        return (this.firstPayment.status !== 'Failure' ? this.firstPayment.amountPaid : 0) +
               (this.isSplitPayment && this.secondPayment.status !== 'Failure' ? this.secondPayment.amountPaid : 0);
    }

    get paymentSuccessfulMessage() {
        if (!this.isEdit) {
            const paymentSuccessMessage = this.paymentMethodType == BwcPayments.PaymentMethodType.PROMISE_TO_PAY.value 
            ? label_promisePaymentSuccessMessage.replace('{0}', BwcUtils.formatCurrency(this.totalAmountPaid))
            : label_paymentSuccessMessage.replace('{0}', BwcUtils.formatCurrency(this.totalAmountPaid));
            return this.isSplitPayment
                ? label_paymentSuccessSplitMessage.replace('{0}', BwcUtils.formatCurrency(this.totalAmountPaid))
                : paymentSuccessMessage;
        }
        BwcUtils.log('paymentSuccessfulMessage: ' + label_paymentUpdateSuccessMessage.replace('{0}', BwcUtils.formatCurrency(this.totalAmountPaid)));
        return label_paymentUpdateSuccessMessage.replace('{0}', BwcUtils.formatCurrency(this.totalAmountPaid));
    }

    // Shown in green message bar
    get confirmationMessage() {

        if (this.lastPayment.amountPaidOtherMessage && this.lastPayment.amountPaidOtherMessage.variant === 'warning') {
            return this.lastPayment.amountPaidOtherMessage;
        }
        else if (this.isBillingAccountSuspendedInvoluntary) {

                // Customer paid at least minimum immediate due
                return {
                    variant: 'success',
                    text: label_paymentSuccessRestore
                };

        }

        return undefined;

    }

    /*
        Set values for rendering of confirmation panel.
    */
    loadPaymentConfirmation() {

        let errorMessage;

        // Check for partial success -- full failure won't make it here so don't need to check for both.
        if (this.isSplitPayment) {

            if (this.firstPayment.status !== 'success') {
                errorMessage = 'First payment failed: ' + this.firstPayment.message + '\r\n(Second payment succeeded.)'
            }
            else if (this.secondPayment.status !== 'success') {
                errorMessage = 'Second payment failed: ' + this.secondPayment.message + '\r\n(First payment succeeded.)'
            }

        }

        if (errorMessage) {
            // Don't throw, report so it doesn't stop from going to confirmation panel
            this.wizard.reportError(new Error(errorMessage));
        }

    }

    /********************************************************************************************************/
    //#endregion

}