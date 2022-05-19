/* eslint-disable eqeqeq */
import { LightningElement, api, track, wire } from "lwc";
import { publish, MessageContext } from 'lightning/messageService';
import * as BwcConstants from 'c/bwcConstants';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcAccountServices from "c/bwcAccountServices";
import * as BwcBillingAccount from 'c/bwcBillingAccount';
import * as BwcPayments from 'c/bwcPayments';
import * as BwcPaymentServices from 'c/bwcPaymentServices';
import * as BwcInteractActivityPublisher from 'c/bwcInteractActivityPublisher';
import * as BwcLabelServices from 'c/bwcLabelServices';

// Message channels
import REFRESHMC from '@salesforce/messageChannel/BWC_Refresh__c';

// Permissions
import hasEnterCustomerPaymentDetailsPermission from '@salesforce/customPermission/Enter_Customer_Payment_Details';

// Labels
import label_paymentAgreementVerify from '@salesforce/label/c.BWC_PaymentAgreementVerify';
import label_agreeToTerms from '@salesforce/label/c.BWC_PaymentAgreeToTerms';
import label_epaEnrollmentConfirmation from '@salesforce/label/c.BWC_EPA_Enrollment_Confirmation';
import label_epaEnrollmentSuccessMessage from '@salesforce/label/c.BWC_EPA_Enrollment_SuccessMessage';
import label_epaEnrollmentMessage from '@salesforce/label/c.BWC_EPA_Enrollment_Message';
import label_epaEnrollmentDisclosureInfo from '@salesforce/label/c.BWC_EPA_Enrollment_Disclosure_Info';
import label_epaEnrollMonthlyInstallmentsHelp from '@salesforce/label/c.BWC_EPA_Enroll_Monthly_Installments_Help';
import label_epaEnrollmentDisclosureInfo_autoPay from '@salesforce/label/c.BWC_EPA_Enrollment_Disclosure_Info_Autopay';

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

// Monthly Installments Table Columns
const monthlyInstallmentsColumns = [
    { label: '#', fieldName: 'installmentNumber', type: 'text', hideDefaultActions: true, initialWidth: 100 },
    { label: 'Deferred Amount', fieldName: 'deferredAmount', type: 'text', hideDefaultActions: true },
    { label: 'Amount Due on Payment Due Date', fieldName: 'amountDue', type: 'text', hideDefaultActions: true }
];

export default class BwcEpaWizard extends LightningElement {

    monthlyInstallmentsColumns = monthlyInstallmentsColumns;
    @track monthlyInstallmentsData = [];

    // Public interface
    @api recordId;      // Always passed into component
    @api selectedBan;

    // Labels that need to be accessed in template
    labels = BwcLabelServices.labels;

    // Labels that need to be accessed in template
    label = {
        enrollmentMessage: label_epaEnrollmentMessage, 
        epaEnrollmentDisclosureInfo: label_epaEnrollmentDisclosureInfo,
        agreeToTerms: label_agreeToTerms, 
        monthlyInstallmentsHelpText: label_epaEnrollMonthlyInstallmentsHelp,
        epaEnrollmentDisclosureInfoAutoPay: label_epaEnrollmentDisclosureInfo_autoPay,
        epaEnrollmentConfirmation: label_epaEnrollmentConfirmation,
        epaEnrollmentSuccessMessage: label_epaEnrollmentSuccessMessage
    };

    get inputPaymentMethod() {return this.template.querySelector('c-bwc-input-payment-method');}

    storedProfiles = [];

    get wizardTitle() {
        return '<b>Enroll in Extended Payment Arrangement</b><br />' + this.labels.account + ' ' + this.selectedBan + ' (Wireless)';
    }

    get paymentAmountDueToday() {
        if (this.amountDueToday) {
            return BwcUtils.formatCurrency(this.amountDueToday);
        }
        return '$--.--';
    }

    get pastDueAmount() {
        return BwcUtils.formatCurrency(this.pastDue);
    }

    get totalDueAmount() {
        return BwcUtils.formatCurrency(this.totalDue);
    }

    get dueDate() {
        return this.adjustForTimezone(new Date());
    }

    // RAISR 
    get inputPaymentContext() {return BwcPayments.RaisrContext.EPA_ENROLL.value;}
    spiData = {spiDataList: []};

    //#region Wizard
    /********************************************************************************************************/

    wizardSteps = [
        {
            name: "enroll",
            title: "<b>Enroll in Extended Payment Arragement</b>",
            panelNumber: 0,
            minHeight: 165,
            finishAction: this.savePaymentDetails.bind(this),
            rightButton: {
                name: "review",
                label: "Continue to Review",
                action: this.validatePaymentDetails.bind(this)
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
            name: 'review',
            title: '<b>Review Payment</b>',
            panelNumber: 1,
            minHeight: 165,
            initAction: this.loadReview.bind(this),
            leftButton: {
                name: 'editPaymentDetails',
                label: 'Back to Payment Info'
            },
            rightButton: {
                name: 'completeEnrollment',
                label: 'Submit Payment & Enroll',
                action: this.completeEnrollment.bind(this)
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
            name: 'confirmation',
            title: '<b>Payment Confirmation</b>',
            panelNumber: 2,
            initAction: this.loadConfirmation.bind(this),
            rightButton: {
                name: 'ok',
                label: 'Close Tab'
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
            this.wizard.open(() => this.initialize());
    
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

    /*
        Wizard calls this when opening.
    */
    async initialize() {

        // Reset everything
        this.billingAccounts = [];
        this.monthlyInstallmentOptions = [];
        this.selectedBillingAccount = {};
        this.paymentDetailsResponses = undefined;
        this.paymentDetailsRetrieved = false;
        this.selectedPaymentDetails = undefined;

        // Defaults
        this.selectedPaymentDetails = BwcUtils.cloneObject(DEFAULT_PAYMENT_DETAILS);

        // Get all billing accounts for the person account, excluding ones that fall under a unified
        this.billingAccounts = await BwcAccountServices.getBillingAccounts(this.recordId, false, true);

        // Start the calls to get all payment details that might be needed
        await this.getPaymentDetails();

        // Set Payment Amounts and Monthly Installment options for combobox
        if (this.selectedPaymentDetails.paymentRecommendations.paymentRecommendationDetails.extendedPa) {

            // Monthly Installment options
            const minInstallment = parseInt(this.selectedPaymentDetails.paymentRecommendations.paymentRecommendationDetails.extendedPa.minInstallment, 10);
            const maxInstallment = parseInt(this.selectedPaymentDetails.paymentRecommendations.paymentRecommendationDetails.extendedPa.maxInstallment, 10);
            this.monthlyInstallmentOptions = [];
            for (let i = minInstallment; i <= maxInstallment; i++) {
                this.monthlyInstallmentOptions.push({ label: i, value: i });
            }
            // Set default value if min and max installments are the same
            if (minInstallment === maxInstallment) {
                this.selectedNoOfMonths = minInstallment;
                this.setAmountsForMonthlyInstallments();
            }

            // Total Due Amount: BAU on Payment Screen ??
            this.totalDue = this.selectedPaymentDetails.accountBalanceSummary.amountDue;
            // Past Due Amount: paymentRecommendationDetails -> extendedPa -> financeTotalAmount 
            this.pastDue = this.selectedPaymentDetails.paymentRecommendations.paymentRecommendationDetails.extendedPa.financeTotalAmount;
        }

        // Set billing cycle end date
        this.billCycleEndDate = this.selectedPaymentDetails.accountBalanceSummary.billCycleEndDate;

        this.experienceCodeDescription = this.selectedPaymentDetails.paymentRecommendations.paymentRecommendationDetails.experienceCodeDescription;

        // Setup payment
        this.initPayment();

        return undefined;

    }

    async setAmountsForMonthlyInstallments() {

        const paymentOptions = this.selectedPaymentDetails.paymentRecommendations.paymentRecommendationDetails.extendedPa.paymentOptions;
        const selectedPaymentOption = paymentOptions.find(option => option.installment == this.selectedNoOfMonths);

        // Payment Amount Due Today: paymentRecommendationDetails -> extendedPa -> paymentOptions -> financeDownPayment
        this.amountDueToday = selectedPaymentOption.financeDownPayment;

        // Refresh Installments Table
        this.refreshInstallmentsTable();

        await this.handlePaymentDetails();

    }

    financePaymentAmount;
    refreshInstallmentsTable() {
        this.showMonthlyInstallments = false;
        this.monthlyInstallmentsData = [];
        this.futureInstallmentsData = [];

        const paymentOptions = this.selectedPaymentDetails.paymentRecommendations.paymentRecommendationDetails.extendedPa.paymentOptions;
        const selectedPaymentOption = paymentOptions.find(option => option.installment == this.selectedNoOfMonths);

        this.financePaymentAmount = selectedPaymentOption.financePaymentAmount;

        // add installments data to table
        for (let i = 0; i <= selectedPaymentOption.installment; i++) {
            const installment = i == 0 ? 'Today' : i;
            const amountDue = i == 0 ? selectedPaymentOption.financeDownPayment : selectedPaymentOption.financePaymentAmount + ' + current charges';
            const deferredAmount = i == 0 ? selectedPaymentOption.financeDownPayment : selectedPaymentOption.financePaymentAmount;
            this.monthlyInstallmentsData.push({
                id: installment,
                installmentNumber: installment,
                deferredAmount: '$' + deferredAmount,
                amountDue: '$' + amountDue,
            });
        }

        // Copy monthly installments data to future installments data and remove first item
        this.futureInstallmentsData = [...this.monthlyInstallmentsData];
        this.futureInstallmentsData.shift();

        // Show table and payment methods
        this.showMonthlyInstallments = true;

    }

    /********************************************************************************************************/
    //#endregion

    //#region Payment Details from API
    /********************************************************************************************************/

    paymentDetailsResponses;
    paymentDetailsRetrieved;
    @track selectedPaymentDetails = BwcUtils.cloneObject(DEFAULT_PAYMENT_DETAILS);

    storedProfiles = [];
    refreshStoredProfiles() {

        this.storedProfiles = [];

        const storedProfiles = this.selectedPaymentDetails.paymentProfiles ? this.selectedPaymentDetails.paymentProfiles.paymentProfileList : [];
        const tempProfiles = this.selectedPaymentDetails.temporaryPaymentProfiles ? this.selectedPaymentDetails.temporaryPaymentProfiles.paymentProfileList : [];

        // For cards, only verified profiles can be used unless agent has permission to enter details (i.e. no redaction)
        this.storedProfiles = tempProfiles.concat(storedProfiles).filter(profile => hasEnterCustomerPaymentDetailsPermission || profile.paymentMethodType !== BwcConstants.PaymentMethodType.CARD.value || profile.card.verified);

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
                BwcConstants.PaymentDetailTopic.AUTOPAY.value
            ]
        };

        try {

            this.paymentDetailsResponses = await BwcPaymentServices.getPaymentDetails(getPaymentDetailsArgs);
            this.paymentDetailsRetrieved = true;

            // Allow render
            await BwcUtils.nextTick();

            // Now that we have payment details, load amounts and payment profiles
            await this.setSelectedPaymentDetails();

        }
        catch(error) {
            this.wizard.reportError(error);
        }
        finally {
            this.paymentDetailsRetrieved = true;
        }

    }

    /********************************************************************************************************/
    //#endregion

    //#region Enroll Panel
    /********************************************************************************************************/

    // All billing accounts for the person account, use for multi-selection
    billingAccounts = [];
    @track monthlyInstallmentOptions = [];
    selectedBillingAccount = {};
    selectedAccountTypeLabel;
    amountDueToday;
    pastDue;
    totalDue;
    showMonthlyInstallments;
    showPaymentMethods;
    billCycleEndDate;
    experienceCodeDescription;

    @track autoPayDetails = {
        paymentMethod: {
            billingAddress: {}
        }
    };
    paymentMethod;


    // get numberOfMonthsSelected() {
    //     return this.selectedNoOfMonths ? this.selectedNoOfMonths : '';
    // }
    selectedNoOfMonths;

    /*
        Set the payment details for the selected ban.
    */
    handleMonthlyInstallmentsChanged(event) {
        const monthsSelected = event.target.value;
        if (monthsSelected) {
            this.selectedNoOfMonths = parseInt(event.target.value, 10);
            BwcUtils.log(`monthsSelected: ${monthsSelected} - this.selectedNoOfMonths: ${this.selectedNoOfMonths}`);
            this.setAmountsForMonthlyInstallments();
        } else {
            this.showMonthlyInstallments = false;
            this.showPaymentMethods = false;
        }
    }

    async setSelectedPaymentDetails() {
        try {
            this.selectedPaymentDetails = BwcUtils.cloneObject(DEFAULT_PAYMENT_DETAILS);

            // Find corresponding billing account record
            this.selectedBillingAccount = this.billingAccounts.find(billingAccount => billingAccount.Billing_Account_Number__c === this.selectedBan);
            this.selectedAccountTypeLabel = BwcConstants.BillingAccountType.getLabelForValue(this.selectedBillingAccount.Account_Type__c);

            // Find details for ban
            this.selectedPaymentDetails = this.paymentDetailsResponses.find(paymentDetailsResponse => paymentDetailsResponse.ban === this.selectedBan);

            // Update all step titles to include BAN
            this.wizard.setStepTitle('enroll', `<b>Enroll in Extended Payment Arrangement</b><br />${this.labels.account} ${this.selectedBan} (${this.selectedAccountTypeLabel})`);
            this.wizard.setStepTitle('review', `<b>Review Payment:</b> ${this.labels.account} ${this.selectedBan} (${this.selectedAccountTypeLabel})`);
            this.wizard.setStepTitle('confirmation', `<b>Payment Confirmation:</b> ${this.labels.account} ${this.selectedBan} (${this.selectedAccountTypeLabel})`);
        }
        catch (error) {
            this.wizard.reportError(error);
        }
    }

    /*
        Set the payment details for the selected ban.
    */
    async handlePaymentDetails() {

        try {

            this.wizard.clearError();
            this.showPaymentMethods = false;

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

            this.autoPayDetails.paymentMethodTypeOptions = [];
            if (newSelectedPaymentDetails.autopay.paymentPlanEligibility.paymentMethodAllowed.bank) {
                this.autoPayDetails.paymentMethodTypeOptions.push(BwcPayments.PaymentMethodType.BANKACCOUNT);
            }
            if (newSelectedPaymentDetails.autopay.paymentPlanEligibility.paymentMethodAllowed.card) {
                this.autoPayDetails.paymentMethodTypeOptions.push(BwcPayments.PaymentMethodType.CARD);
            }

            // Now set the member
            this.selectedPaymentDetails = newSelectedPaymentDetails;

            const storedProfiles = this.selectedPaymentDetails.paymentProfiles ? this.selectedPaymentDetails.paymentProfiles.paymentProfileList : [];
    
            // For cards, only verified profiles can be used unless agent has permission to enter details (i.e. no redaction)
            this.storedProfiles = storedProfiles.filter(profile => hasEnterCustomerPaymentDetailsPermission || profile.paymentMethodType !== BwcPayments.PaymentMethodType.CARD.value || profile.card.verified);

            // Default billing information
            this.autoPayDetails.paymentMethod = {
                paymentMethodType: BwcPayments.PaymentMethodType.CARD.value,
                card: {
                    cardHolderName: this.selectedBillingAccount.First_Name__c + ' ' + this.selectedBillingAccount.Last_Name__c,
                    billingAddress: {
                        zipCode: this.selectedBillingAccount.Billing_Zipcode__c
                            ? this.selectedBillingAccount.Billing_Zipcode__c.substring(0, 5)
                            : undefined
                    }
                },
                bankAccount: {
                    accountType: BwcPayments.BankAccountType.CHECKING.value,
                    accountHolderName: this.selectedBillingAccount.First_Name__c + ' ' + this.selectedBillingAccount.Last_Name__c
                }
            };

            this.showPaymentMethods = true;

            // Wait for render
            await BwcUtils.nextTick();

            this.inputPaymentMethod.initialize(
                this.autoPayDetails.paymentMethodTypeOptions, 
                this.storedProfiles, 
                undefined, 
                undefined,
                this.getDefaultBankAccount(), 
                this.getDefaultCard());

        }
        catch (error) {
            this.wizard.reportError(error);
        }

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
    initPayment() {

        // **************
        // NEW PAYMENT
        // **************

        this.firstPayment = this.getDefaultPayment();

        this.firstPayment.isAdd = true;

        //
        //  Payment Amount Options
        //

        const paymentAmountOptions = [];
        this.firstPayment.paymentAmountOptions = paymentAmountOptions;

        // Total amount
        if (this.paymentAmountDueToday && this.paymentAmountDueToday > 0) {
            paymentAmountOptions.push({
                index: paymentAmountOptions.length,
                key: 'paymentAmountOption' + paymentAmountOptions.length,
                label: 'Payment Amount Due Today',
                amount: this.paymentAmountDueToday
            });
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

        //
        // Payment Method Types
        //
        this.setPaymentMethodTypeOptions(this.firstPayment, this.selectedPaymentDetails.paymentRecommendations.paymentOptionOne);

        // Default payment method type
        this.firstPayment.paymentMethod.type = this.firstPayment.paymentMethodTypeOptions[0].value;

        //
        // Default Payment Date
        //
        this.firstPayment.paymentDate = this.today;

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

        if (this.isPromiseToPay) {

            paymentMethodTypeOptions.push(BwcConstants.PaymentMethodType.PROMISE_TO_PAY);

        }
        else {

            if (!paymentOption || paymentOption.paymentMethod.bank) {
                // Bank account is allowed
                paymentMethodTypeOptions.push(BwcConstants.PaymentMethodType.BANKACCOUNT);
            }

            if (!paymentOption || paymentOption.paymentMethod.card) {
                // Card is allowed
                paymentMethodTypeOptions.push(BwcConstants.PaymentMethodType.CARD);
            }

            if (this.isEdit && this.firstPayment.pendingPayment.paymentMethod === BwcConstants.PaymentMethodType.PROMISE_TO_PAY.value) {

                // We're editing an existing Promise to Pay so have to show it
                paymentMethodTypeOptions.push(BwcConstants.PaymentMethodType.PROMISE_TO_PAY);

            }

        }

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
        Called from Continue button for Make Payment panel.
    */
    async validatePaymentDetails() {

        // Get panel
        const panel = this.template.querySelector('div[data-name="enroll"');

        // Validate all inputs on payment panel
        let isValid = BwcUtils.reportValidity(panel);

        if (!isValid) {
            throw new Error();
        }

        if (!this.showPaymentMethods) {
            throw new Error('No payment methods are available.');
        }

        // Validate all inputs on payment panel
        isValid = BwcUtils.reportValidity(panel, 'c-bwc-input-payment-method');

        if (!isValid) {
            throw new Error();
        }

    }

    /*
        Save the value from the input payment method component before moving to another step.
    */
    @track paymentDetails = {};
    async savePaymentDetails() {

        this.paymentMethod = this.inputPaymentMethod.paymentMethod;

        this.spiData = this.inputPaymentMethod.spiDataValues;
        BwcUtils.log(`bwcEpaWizard spiData: ${JSON.stringify(this.spiData)}`);

        // Get the payment method 
        this.paymentDetails = {
            amountPaid: this.amountDueToday,
            paymentDate: this.adjustForTimezone(new Date()),
            paymentMethod: this.inputPaymentMethod.paymentMethod
        };

    }

    adjustForTimezone(date){
        var timeOffsetInMS = date.getTimezoneOffset() * 60000;
        date.setTime(date.getTime() + timeOffsetInMS);
        return date
    }

    /********************************************************************************************************/
    //#endregion

    //#region Review Payment Panel
    /********************************************************************************************************/

    tncVerbiage;
    tncId;
    tncKey;
    disclosureInfo;

    // Process EPA Enrollment Disclosure info
    get epaEnrollmentDisclosureInfo() {
        let disclosure = this.label.epaEnrollmentDisclosureInfo.replace('{0}', BwcUtils.formatCurrency(BwcUtils.toCurrency(this.amountDueToday)));
        disclosure = disclosure.replace('{1}', this.selectedNoOfMonths + ' months');

        if (this.selectedPaymentDetails?.autopay?.paymentPlanInfo?.[0]) {
            disclosure = disclosure.replace('{2}', this.label.epaEnrollmentDisclosureInfoAutoPay);
        } else {
            disclosure = disclosure.replace('{2}', '');
        }
        return disclosure;
    }

    // Shown in yellow message bar
    get agreeToTermsCheckbox() {return this.template.querySelector('lightning-input[data-name="agreeToTerms"]');}

    /*
        Get terms and conditions and any other init for the review panel.
    */
    async loadReview() {

        // Always require re-confirm
        this.agreeToTermsCheckbox.checked = false;

        // Determine paymentEventType based upon whether saving profile
        const paymentEventType = BwcConstants.PaymentEventType.OF.value;

        this.tncId = undefined;
        this.tncKey = undefined;
        this.tncVerbiage = undefined;

        try {

            const termsAndConditions = await BwcPaymentServices.getTermsAndConditions(paymentEventType);

            this.tncId = parseInt(termsAndConditions.tncId__c, 10);
            this.tncKey = termsAndConditions.tncKey__c;
            this.tncVerbiage = termsAndConditions.tncVerbiage__c;

        }
        catch(e) {
            BwcUtils.error(e);
            this.tncVerbiage = `<span style="color: red;">${e.message ? e.message : JSON.stringify(e)}</span>`;
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
    async completeEnrollment() {

        // Verify checkbox
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

        await this.sendPayment();

    }

    /*
        Call API to make the payment.
    */
    confirmationNumber;
    async sendPayment() {

        let paymentRequest = {
            accountType: this.selectedBillingAccount.Account_Type__c,
            appName: "SFORCECC",
            customerAgreement: this.tncKey,
            tncId: this.tncId,
            accountNumber: this.selectedBillingAccount.Billing_Account_Number__c,
            systemId: this.selectedPaymentDetails.banBillingIds.systemId,
            divisionId: this.selectedPaymentDetails.banBillingIds.divisionId,
            enrollmentSource: "F",
            financeDownPayment: this.amountDueToday,
            financePaymentAmount: this.financePaymentAmount,
            financeTotalAmount: this.pastDue,
            installments: this.selectedNoOfMonths,
            billCycleEndDate: this.billCycleEndDate,
            experienceCodeDescription: this.experienceCodeDescription,
            makePaymentItemRequest: this.buildPaymentItemRequest(this.inputPaymentMethod)
        };

        try {

            this.wizard.setBusy(true);


            let paymentResponse;
            try {
                paymentResponse = await BwcPaymentServices.epaEnrollRaisr(paymentRequest, this.spiData);
            }
            catch(error) {

                this.firstPayment.status = 'failure';
                this.firstPayment.message = error.message;  
                throw error;
            }

            BwcUtils.log(`paymentResponse: ${JSON.stringify(paymentResponse)}`);

            // Check first payment and set status and message
            if (paymentResponse.error) {

                this.firstPayment.status = 'failure';
                this.firstPayment.message = paymentResponse.error.message + ': ' + JSON.stringify(paymentResponse.error);

            }
            else {

                this.confirmationNumber = paymentResponse.paymentConfirmationNumber;
                BwcUtils.log(`paymentResponse.paymentConfirmationNumber: ${paymentResponse.paymentConfirmationNumber}`);
                this.firstPayment.status = 'success';

            }

            // Create interaction activity
            this.createInteractionActivity();

            // Handle error display and refresh
            if (this.firstPayment.status === 'failure') {

                // No split payment and there's an error, just throw it now to stop on review screen
                throw new Error(this.firstPayment.message);

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
    buildPaymentItemRequest(paymentDetails) {

        const paymentMethod = BwcUtils.cloneObject(paymentDetails.paymentMethod);

        // Remove any card or bank information associated with profile
        // Input component sends it so we have complete information, but cannot send it on the payment itself
        if (paymentMethod.type === BwcConstants.PaymentMethodType.PAYMENT_PROFILE.value) {
            paymentMethod.card = undefined;
            paymentMethod.bankAccount = undefined;
        }

        const result = {
            amount: this.amountDueToday,
            paymentMethod: paymentMethod
        };

        return result;

    }

    /*
        Create an InteractionActivity for each payment added or edited
    */
    createInteractionActivity() {

        try {

            // Determine action
            const action = BwcConstants.InteractionActivityValueMapping.BillingPaymentEpaEnroll.action;

            // Get standardized payment method and billing account
            const selectedBillingAccount = this.billingAccounts.find(billingAccount => billingAccount.Billing_Account_Number__c === this.selectedBan);
            const billingAccount = BwcBillingAccount.BillingAccount.fromRecord(selectedBillingAccount);
            const paymentMethod = new BwcPayments.PaymentMethod(this.firstPayment.paymentMethod);
            const paymentMethodType = paymentMethod.getBasePaymentMethod().type.toLowerCase();

            // Build out details
            const details = {
                recordId: this.recordId,
                service: selectedBillingAccount.Account_Type__c,
                serviceName: selectedBillingAccount.Service_Name__c,
                ban: this.selectedBan,
                billingStatus: billingAccount.getBillingStatus(this.selectedPaymentDetails),
                epaDetails: {
                    paymentDate: BwcUtils.toIsoDate(new Date()),
                    paymentMethod: paymentMethodType,
                    paymentAmount: this.amountDueToday,
                    totalAmountDue: this.totalDue,
                    pastAmountDue: this.pastDue,
                    noOfInstallments: this.selectedNoOfMonths,
                    installmentAmount: this.financePaymentAmount
                },
                status: this.firstPayment.status
            };

            // Publish
            BwcInteractActivityPublisher.publishMessage(this.recordId, action, JSON.stringify(details), null);

        }
        catch(error) {

            // Write any error to the log only
            BwcUtils.error('EPA Wizarrd', 'Failed to create Interaction Activity: ' + error.message, error);

        }

    }

    /********************************************************************************************************/
    //#endregion

    //#region Confirmation Panel
    /********************************************************************************************************/    

    confirmationMessage;

    /*
        Set values for rendering of confirmation panel.
    */
    loadConfirmation() {

        this.confirmationMessage = this.label.epaEnrollmentConfirmation.replace('{0}', BwcUtils.formatCurrency(this.amountDueToday));

    }

    /********************************************************************************************************/    
    //#endregion

}