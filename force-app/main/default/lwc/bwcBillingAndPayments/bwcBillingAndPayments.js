import BwcPageElementBase from 'c/bwcPageElementBase';
import { api, wire } from 'lwc';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue  } from 'lightning/uiRecordApi';
import COMPLETIONMC from '@salesforce/messageChannel/BWC_Completion__c';
import * as BwcConstants from 'c/bwcConstants';
import * as BwcUtils from 'c/bwcUtils';
import * as bwcLICPublisher from 'c/bwcMsgToLICPublisher';
import * as bwcInteractActivityPublisher from 'c/bwcInteractActivityPublisher';
import * as bwcDispatchEscalationCase from 'c/bwcDispatchEscalationCase';
import * as BwcAccountServices from 'c/bwcAccountServices';
import * as BwcPayments from 'c/bwcPayments';
import * as BwcPaymentServices from 'c/bwcPaymentServices';
import * as BwcLabelServices from 'c/bwcLabelServices';
import getBillingAndPaymentsData from '@salesforce/apex/BWC_BillingAndPaymentsController.getBillingAndPaymentsData';
import getPaperlessStatus from '@salesforce/apex/BWC_BillingEnrollmentController.getPaperlessStatus';

// Custom permissions
import hasPaymentPermission from '@salesforce/customPermission/Payment_Permission';
import hasCollectionsAgentPermission from '@salesforce/customPermission/Collections_Agent';

// Import custom labels
import nobilldata from '@salesforce/label/c.BWC_BillAndPayment_NoBillData';
import nopaymentdata from '@salesforce/label/c.BWC_BillAndPayment_NoPaymentData';
import enrollPaperlessTitle from '@salesforce/label/c.BWC_Billing_Enroll_Paperless_Title';
import enrollPaperTitle from '@salesforce/label/c.BWC_Billing_Enroll_Paper_Title';
import enrollPaperlessMessage from '@salesforce/label/c.BWC_Billing_Enroll_Paperless_Message';
import enrollPaperMessage from '@salesforce/label/c.BWC_Billing_Enroll_Paper_Message';
import enrollPaperlessMessageCustomer from '@salesforce/label/c.BWC_Billing_Enroll_Paperless_Message_Customer';
import enrollPaperMessageCustomer from '@salesforce/label/c.BWC_Billing_Enroll_Paper_Message_Customer';
import unexpectedError from '@salesforce/label/c.BWC_UnexpectedError_RefreshSection';

//Person Account fields
import PERSON_EMAIL_FIELD from '@salesforce/schema/Account.PersonEmail';

//Interaction Billing Account Number
import BAN from '@salesforce/schema/Interaction__c.Billing_Account_Number__c';

const CASE_TYPE_BILLING_PAYMENT = 'Billing | Payment';

export default class BwcBillingAndPayments extends BwcPageElementBase {

    // Labels
    labels = BwcLabelServices.labels;

    billingColumns = [
        { label: this.labels.account, fieldName: 'ban', type: 'text', hideDefaultActions: true, cellAttributes: {wrapText: true}, fixedWidth: 125 },
        { label: 'LOB', fieldName: 'serviceLabel', type: 'text', hideDefaultActions: true, cellAttributes: {wrapText: true} },
        { label: 'Current Balance Due', fieldName: 'currentAmountDue', type: 'currency', cellAttributes: {alignment: 'left', wrapText: true}, hideDefaultActions: true },
        { label: 'Bill Due Date', fieldName: 'currentAmountDueDate', type: 'date-local', typeAttributes: {month: '2-digit', day: '2-digit'}, hideDefaultActions: true, wrapText: true, initialWidth: 110},
        { label: 'Billed Amt Last Bill', fieldName: 'amtDue', type: 'currency', cellAttributes: {alignment: 'left', wrapText: true}, hideDefaultActions: true },
        { label: 'Past Due Last Bill', fieldName: 'pastDue', type: 'currency', cellAttributes: {alignment: 'left', wrapText: true}, hideDefaultActions: true },
        { label: 'Autopay', fieldName: 'autoPay', type: 'text', hideDefaultActions: true, cellAttributes: {wrapText: true}, initialWidth: 75 },
        { label: 'Paperless Bill', fieldName: 'paperlessBill', type: 'text', hideDefaultActions: true, cellAttributes: {wrapText: true} },
        { label: 'Bill Cycle', fieldName: 'billCycle', type: 'text', hideDefaultActions: true,cellAttributes: {wrapText: true} },
        { label: 'Account Status', fieldName: 'accountStatus', type: 'text', hideDefaultActions: true, cellAttributes: {wrapText: true} },
        { type: 'action', typeAttributes: { rowActions: this.getBillingRowActions}}
    ];

    paymentsColumns = [
        { label: 'Pmt Date', fieldName: 'paymentDate', type: 'date-local', typeAttributes: {month: '2-digit', day: '2-digit'}, hideDefaultActions: true, wrapText: true, fixedWidth: 110, sortable: true},
        { label: 'Amount', fieldName: 'paymentAmount', type: 'currency', cellAttributes: {alignment: 'left', wrapText: true}, hideDefaultActions: true },
        { label: this.labels.account, fieldName: 'ban', type: 'text',hideDefaultActions: true, fixedWidth: 125, cellAttributes: {wrapText: true} },
        { label: 'Method Type', fieldName: 'methodTypeLabel', type: 'text',hideDefaultActions: true, cellAttributes: {wrapText: true} },
        { label: 'Pmt Method', fieldName: 'paymentMethod', type: 'text',hideDefaultActions: true, fixedWidth: 0, cellAttributes: {wrapText: true} },
        { label: 'Last 4', fieldName: 'paymentDetailMethodLastFour', type: 'text',hideDefaultActions: true, cellAttributes: {wrapText: true} },
        { label: 'Pmt Type', fieldName: 'paymentCategoryType', type: 'text',hideDefaultActions: true, cellAttributes: {wrapText: true} },
        { label: 'Status', fieldName: 'paymentStatusLabel', type: 'text',hideDefaultActions: true, cellAttributes: {wrapText: true} },
        { label: 'Confirmation #', fieldName: 'confirmationNumber', type: 'text',hideDefaultActions: true, cellAttributes: {wrapText: true} },
        { type: 'action', typeAttributes: { rowActions: this.getPaymentRowActions}}
    ];

    // Needed to subscribe to refresh message
    @wire(MessageContext)
    messageContext;

    // Message channel subscription
    subscription;

    // Completion message channge subscription
    completionSubscription;

    // The Salesforce Person Account Record Id
    @api recordId;

    //Person account information
    @wire(getRecord, {recordId: '$recordId', fields: [PERSON_EMAIL_FIELD]})
    wiredPersonAccount;

    //Interaction account information
    @wire(getRecord, {recordId: '$recordId', fields: [BAN]})
    wiredAccountInfo;

    get billingNotifications() {return this.template.querySelector('c-bwc-notifications[data-name="billingNotifications"]');}
    get paymentNotifications() {return this.template.querySelector('c-bwc-notifications[data-name="paymentNotifications"]');}

    billingData;
    paymentsData = [];
    allPaymentsData = [];
	//subscriberName;
    // Used to show spinner as the billing are being loaded.
    isLoading = true;

    // Used to show spinner as the payments are being loaded.
    isLoadingPayments = true;

    // Used to do operation once upon first render
    isRendered = false;

    label = {
        nobilldata: nobilldata,
        nopayment: nopaymentdata,
        enrollPaperlessTitle,
        enrollPaperTitle,
        enrollPaperlessMessage,
        enrollPaperMessage,
        enrollPaperlessMessageCustomer,
        enrollPaperMessageCustomer
    };
    showBillTable = false;
    showBillEmpty = false;
    showPaymentTable = false;
    showPaymentEmpty = false;

    // show payments view all modal
    isPaymentsViewAllOpen = false;
    isEnrollModalOpen = false;

    //To store the row selected from the enroll action on billing records
    selectedRow;

    //Sorting variables
    defaultSortDirection= 'desc';
    sortDirection = 'desc';
    sortedBy;

	disableEscUnidPmtBtn = true;

    get hasPaymentPermission() {return hasPaymentPermission;}

    /*
        Handle refresh message.
    */
    handleLmsRefresh(scope, recordId) {

        if ((scope === 'paymentHistory' || !scope) && (!recordId || recordId === this.recordId)) {
            this.callGetPaymentDetails();
        }

    }

    // The LWC framework calls this method when the LWC is loaded.
    renderedCallback() {

        if (this.isRendered) {
            return;
        }
        this.isRendered = true;

        // call billing api
        this.callGetBillingAndPaymentsData();

        // call payments api
        this.callGetPaymentDetails();

    }

    addBillingError(error, details) {
        BwcUtils.error('Billing', error.message, details);
        this.billingNotifications.addNotification('inline', unexpectedError, 'error');
    }

    clearBillingErrors() {
        this.billingNotifications.clearNotifications();
    }

    addPaymentError(error, details) {
        BwcUtils.error('Payment History', error.message, details);
        this.paymentNotifications.addNotification('inline', unexpectedError, 'error');
    }

    clearPaymentErrors() {
        this.paymentNotifications.clearNotifications();
    }

    // refresh the billing data by calling the billing api
    handleBillingRefresh() {
        this.callGetBillingAndPaymentsData();
    }

    // refresh the payments data by callingthe payments api
    handlePaymentsRefresh() {
        this.callGetPaymentDetails();
    }

    // escalate the payment
    handleEscalateUnidentifiedPayment() {
		BwcUtils.log('### ENTERED handleEscalateUnidentifiedPayment');
        this.escalate(BwcConstants.HighLevelCaseType.Billing_Payment.type,
            BwcConstants.HighLevelCaseType.Billing_Payment.feature,
            undefined);
    }

    // show the payments view all modal
    showPaymentsViewAll() {
        this.isPaymentsViewAllOpen = true;

        //interaction activity event
        bwcInteractActivityPublisher.publishMessage(this.recordId,BwcConstants.InteractionActivityValueMapping.ViewPaymentHistory.action,JSON.stringify({"ban": this.billingData[0].ban, "ContextData": this.billingData[0] }),null);
    }

    // hide the payments view all modal
    closePaymentsViewAll() {
        this.isPaymentsViewAllOpen = false;
    }

    showEnrollModal(){
        this.isEnrollModalOpen = true;
    }

    closeEnrollModal(){
        this.isEnrollModalOpen = false;
    }

    // get billing data
    async callGetBillingAndPaymentsData() {

        this.clearBillingErrors();

        // hide table
        this.showBillTable = false;

        // hide empty message
        this.showBillEmpty = false;

        // show spinner
        this.isLoading = true;

        let paymentDetails;
        try {

            // Get account balance summary, use to enhance some billing data
            // Also get payment recommendations to get Extended Payment Arrangement info
            paymentDetails = await BwcPaymentServices.getPaymentDetails({
                recordId: this.recordId,
                topics: [BwcConstants.PaymentDetailTopic.ACCOUNT_BALANCE_SUMMARY.value, 
                        BwcConstants.PaymentDetailTopic.PAYMENT_RECOMMENDATIONS.value,
                        BwcConstants.PaymentDetailTopic.EXTENDED_PA.value]
            });

        }
        catch(error) {
            this.addBillingError(new Error(`Error retrieving payment details`), error.message);
        }

        // Get billing accounts for status
        const billingAccountRecords = await BwcAccountServices.getBillingAccounts(this.recordId);

		const hasOneWirelessBan = billingAccountRecords.some(account => account.Account_Type__c === BwcConstants.BillingAccountType.WIRELESS.value);
		this.disableEscUnidPmtBtn = !hasOneWirelessBan;

        // get the billing and payments data
        getBillingAndPaymentsData({recordId: this.recordId})
        .then(result => {
            // Added error handling to display readable erro to Agent/user
            if (!result.success) {
                this.addBillingError(new Error(result.message));
                this.isLoading = false;
                return;
            }

            this.billingData = [];
            result.billingData.forEach(data => {
                if (data.errorMessage) {
                    this.addBillingError(new Error(`Error retrieving billing data for BAN ${data.ban}`), data.errorMessage);
                }
                else {

                    // Find corresponding account balance summary
                    if (paymentDetails) {

                        const paymentDetail = paymentDetails.find(details => details.ban === data.ban);
                        if (!paymentDetail) {
                            this.addBillingError(new Error(`Payment details not found for BAN ${data.ban}`), data.errorMessage);
                        }
                        else {

                            if (paymentDetail.erroraccountBalanceSummary) {
                                this.addBillingError(new Error(`Error retrieving accountBalanceSummary for BAN ${data.ban}`), JSON.stringify(paymentDetail.erroraccountBalanceSummary));
                            }
                            else {
                                data.currentAmountDue = BwcUtils.toCurrency(paymentDetail.accountBalanceSummary.amountDue);
                                data.currentAmountDueDate = BwcUtils.toIsoDate(new Date(BwcUtils.parseIsoDateString(paymentDetail.accountBalanceSummary.billDueDate)));
                            }

                            // Determine EPA eligibility and enrollment
                            data.isEpaEligible = paymentDetail.isEpaEligible;
                            data.isEpaEnrolled = paymentDetail.isEpaEnrolled;

                        }

                    }

                    const billingAccountRecord = billingAccountRecords.find(record => record.Billing_Account_Number__c === data.ban);
                    if (!billingAccountRecord) {
                        this.addBillingError(new Error(`Billing Account Record not found for BAN ${data.ban}`));
                    }
                    data.accountStatus = billingAccountRecord.Account_Status__c;

                    this.billingData.push(data);

                }
            });

            // Sort by account status: Active then Suspended then Canceled
            const sortMap = {
                [BwcConstants.BillingAccountStatus.ACTIVE.value]: 1,
                [BwcConstants.BillingAccountStatus.SUSPENDED.value]: 2,
                [BwcConstants.BillingAccountStatus.CANCELED.value]: 3
            }
            const sortFunction = (a, b) => {
                if (a.accountStatus === b.accountStatus) {
                    // Same status, sort by BAN,  which will never be the same
                    return a.ban < b.ban ? -1 : 1;
                }
                return sortMap[a.accountStatus] > sortMap[b.accountStatus] ? 1 : -1;
            };
            this.billingData = this.billingData.sort(sortFunction);

            if(this.billingData.length > 0) {
                this.showBillTable = true;
            } else if (!this.billingNotifications.hasErrorNotifications) {
                this.showBillEmpty = true;
            }
            // Stop spinner.
            this.isLoading = false;
        })
        .catch(error => {
            this.addBillingError('Error calling getBillingData.', error);
            this.isLoading = false;
        });
    }

    // get payments data
    callGetPaymentDetails() {

        // hide payments table
        this.showPaymentTable = false;

        // hide empty message
        this.showPaymentEmpty = false;

        // show spinner
        this.isLoadingPayments = true;

        this.clearPaymentErrors();

        // get the payments data
        BwcPaymentServices.getPaymentDetails({recordId: this.recordId, topics: ["paymentHistory", "futurePayments"]})
        .then(result => {

            // two array are maintained.
            // one to show max 10 rows
            // other to show all payments ina popup.
            this.paymentsData = [];
            this.allPaymentsData = [];
            result.forEach(acc => {

                if (acc.errorpaymentHistory) {
                    this.addPaymentError(new Error(`Error retrieving payment history for BAN ${acc.ban}`), JSON.stringify(acc.errorpaymentHistory));
                }
                if (acc.errorfuturePayments) {
                    this.addPaymentError(new Error(`Error retrieving future payments for BAN ${acc.ban}`), JSON.stringify(acc.errorfuturePayments));
                }

                if (acc.payments != null) {
                    acc.payments.forEach(payment => {

                        payment.autopayIcon = payment.autopay?'utility:check':'utility:close';

                        switch (payment.paymentMethod) {

                            case 'CREDITCARD':
                                payment.methodTypeLabel = BwcConstants.CardType.getLabel(payment.paymentDetailMethodType);
                                break;

                            case 'ACH':
                                payment.methodTypeLabel = BwcConstants.BankAccountType.getLabel(payment.paymentDetailMethodType);
                                break;

                            case 'PROMISETOPAY':
                                payment.methodTypeLabel = BwcConstants.PromiseToPayMethod.getLabel(payment.paymentDetailMethodType);
                                break;

                            default:
                                if (payment.paymentMethod != null && payment.paymentDetailMethodType != null) {
                                    payment.methodTypeLabel = payment.paymentMethod + '-' + payment.paymentDetailMethodType;
                                }
                                else if (payment.paymentMethod != null) {
                                    payment.methodTypeLabel = payment.paymentMethod;
                                }
                                else if (payment.paymentDetailMethodType != null) {
                                    payment.methodTypeLabel = payment.paymentDetailMethodType;
                                }
                                break;

                        }

                        if (!payment.paymentCategoryType) {
                            payment.paymentCategoryType = payment.paymentType;
                        }

                        payment.paymentStatusLabel = BwcConstants.PaymentStatus.getLabel(payment.paymentStatus);

                        this.allPaymentsData.push(payment);

                    });
                }
            });
            if(this.allPaymentsData.length > 0) {
                this.allPaymentsData.sort((a,b)=>{
                    let dateA = Date.parse(a.paymentDate);
                    let dateB = Date.parse(b.paymentDate);
                    return dateB-dateA;
                });
                // from all payments, get max 10 payments to show on main ui.
                this.paymentsData = this.allPaymentsData.slice(0,10);
                this.showPaymentTable = true;
            } else if (!this.paymentNotifications.hasErrorNotifications) {
                this.showPaymentEmpty = true;
            }

            // Stop spinner.
            this.isLoadingPayments = false;
        })
        .catch(error => {
            this.addPaymentError('Error calling getPaymentHistory.', error);
            this.isLoadingPayments = false;
        });
    }

    /*
        Get billing actions based upon row data.
    */
    getBillingRowActions(row, doneCallback) {

        const actions = [
            {label: 'View Bill', name: 'viewBill'},
            //PO doesn't want this functionality here.
            //{label: 'Escalate', name: 'escalate'},
            {label: row.paperlessBill.toLowerCase() === 'enrolled' ? 'De-Enroll Paperless Billing' : 'Enroll', name:'enroll'}
        ];

        if (hasPaymentPermission) {
            actions.unshift({label: 'Make a Payment', name: 'makePayment'});
        }

        if (hasPaymentPermission && row.isEpaEnrolled) {
            actions.push({label: 'View Extd Pymt Arrangement', name: 'epaView'});
        }        
        else if (hasPaymentPermission && hasCollectionsAgentPermission && row.isEpaEligible) {
            actions.push({label: 'Enroll in Extd Pymt Arrangement', name: 'epaEnroll'});
        }

        doneCallback(actions);

    }

    /*
        Get payment actions based on row data.
    */
    getPaymentRowActions(row, doneCallback) {

        const actions = [];
        if (hasPaymentPermission && row.paymentStatus === BwcConstants.PaymentStatus.PENDING.value && row.editEligible && row.editEligible.eligibleFlag) {

            // Agent has permissions and row is eligible for editing.
            actions.push({
                label: 'Edit Payment',
                name: 'editPayment',
            });

        }
        if (hasPaymentPermission && row.paymentStatus === BwcConstants.PaymentStatus.PENDING.value && row.deleteEligible && row.deleteEligible.eligibleFlag) {
            // Agent has permissions and row is eligible for editing.
            actions.push({
                label: 'Cancel Payment',
                name: 'cancelPayment',
            });

        }

        if (row.accountType === BwcConstants.BillingAccountType.WIRELESS.value) {
            actions.push({label: 'Create Escalation Case', name: 'createEscalationCase'});
        }

        doneCallback(actions);

    }

    handleMakePayment() {

        // Make payment, no default ban
        BwcPayments.openPaymentWizard(this, this.recordId);

    }

    /*
        Handle action menu selection for billing table row.
    */
    handleBillingRowAction(event) {

        switch (event.detail.action.name) {

            case "makePayment":

                {
                    // Make payment, default ban
                    BwcPayments.openPaymentWizard(this, this.recordId, event.detail.row.ban);
                }
                break;

            case "viewBill":

                this.viewBill(event.detail.row);
                //one and done solution / interaction activity
                bwcInteractActivityPublisher.publishMessage(this.recordId,BwcConstants.InteractionActivityValueMapping.ViewBill.action,JSON.stringify(event.detail.row),null);

                break;

            case 'escalate':
                this.escalate(BwcConstants.HighLevelCaseType.Billing_Inquiry.type,
                    BwcConstants.HighLevelCaseType.Billing_Inquiry.feature,
                    event.detail.row);
                break;

            case 'enroll':
                this.showEnrollModal();
                this.selectedRow = event.detail.row;
                break;

            case "epaEnroll":
                BwcPayments.epaOpenWizard(this, this.recordId, event.detail.row.ban);
                break;

            case "epaView":
                BwcPayments.epaOpenViewer(this, this.recordId, event.detail.row.billingAccountId);
                break;

            default:
                BwcUtils.error('Unknown action: ' + event.detail.action.name);
                break;

        }
        //move
       }
    messageOpus(event){
        let msg = 'PostToOpus';
        const licObj = {};
        licObj.launchPoint = 'Launch Point';
        licObj.JsonData = event.detail.row;
        if(licObj.JsonData.ban)
        bwcLICPublisher.publishMessage(msg,licObj,licObj.JsonData.ban);

    }
    /*
        Handle action menu selection for billing table row.
    */
    handlePaymentRowAction(event) {
		BwcUtils.log('### ENTERED handlePaymentRowAction');
        switch (event.detail.action.name) {

            case "editPayment":
                {
                    BwcPayments.openPaymentWizard(this, this.recordId, event.detail.row.ban, true, event.detail.row.confirmationNumber ? event.detail.row.confirmationNumber : event.detail.row.pendingPaymentId);
                }
                break;

            case "cancelPayment":
                {
                    BwcPayments.openCancelPayment(this, this.recordId, event.detail.row.ban, event.detail.row.confirmationNumber ? event.detail.row.confirmationNumber : event.detail.row.pendingPaymentId);
                }
                break;

			/* case 'escalate':*/
            case 'createEscalationCase':
                this.escalate(BwcConstants.HighLevelCaseType.Billing_Payment.type,
                    BwcConstants.HighLevelCaseType.Billing_Payment.feature,
                    event.detail.row);
                break;

            default:
                BwcUtils.error('Unknown action: ' + event.detail.action.name);
                break;

        }

    }

    /*
        Open bill viewer in subtab. Requires sending message to hidden BWCOpenSubTab.
    */
    viewBill(row) {

        // Build page reference to viewer component
        const message = {
            pageReference: {
                type: 'standard__component',
                attributes: {
                    componentName: 'c__BWCBillViewerPage'
                },
                state: {
                    c__ban: row.ban,
                    c__accountType: row.service,
                    c__interactionId: this.recordId
                }
            },
            label: `Bill: ${this.labels.account} ${row.ban}`,
            icon: 'custom:custom40'
        };

        BwcUtils.openSubTab(message);

    }

    /*
        Create escalation Case.
    */
   escalate(type, feature, row) {
    BwcUtils.log('### ENTERED escalate');
    if(row){
			BwcUtils.log('### escalate ROW: ', JSON.stringify(row));
			BwcUtils.log('dispatching escalation case for row: ' + row.ban);
		}

       // show spinner
       switch(type) {
           case BwcConstants.HighLevelCaseType.Billing_Inquiry.type:
               this.isLoading = true;
               break;
            case BwcConstants.HighLevelCaseType.Billing_Payment.type:
                this.isLoadingPayments = true;
                break;
            default:
                break;
       }

        // subscribe to completion LMC
        this.completionSubscription = subscribe(
            this.messageContext,
            COMPLETIONMC, (message) => {
                this.escalationComplete(message);
            });

            // publish message to create escalation case
		if(!row){
			let ban = getFieldValue(this.wiredAccountInfo.data, BAN);
			bwcDispatchEscalationCase.publishEscalationCaseMessage(this.recordId, type, feature, JSON.stringify({
                ban: ban,
			}));
		}else{
			//let paymentsInfoAry = [];
			let paymentMethod;
			let paymentType;
			let paymentAmount;
			let paymentDate;
			let paymentStatus;
			this.paymentsData.forEach(pmt => {

                if(pmt.confirmationNumber === row.confirmationNumber){

					paymentMethod = pmt.paymentMethod;
					paymentType = pmt.paymentCategoryType;
					paymentAmount = pmt.paymentAmount;
					paymentDate = pmt.paymentDate;
					paymentStatus = pmt.paymentStatus;
					/*BwcUtils.log('### paymentDate: ', JSON.stringify(paymentDate));
					BwcUtils.log('### paymentAmount: ', JSON.stringify(paymentAmount));
					BwcUtils.log('### ban: ', JSON.stringify(row.ban));
					BwcUtils.log('### paymentMethod: ', JSON.stringify(paymentMethod));
					BwcUtils.log('### paymentType: ', JSON.stringify(paymentType));
					BwcUtils.log('### methodTypeLabel: ', JSON.stringify(row.methodTypeLabel));
					BwcUtils.log('### paymentMethodLastFour: ', row.paymentDetailMethodLastFour);
					BwcUtils.log('### paymentStatus: ', JSON.stringify(paymentStatus));
					BwcUtils.log('### confirmationNumber: ', JSON.stringify(row.confirmationNumber));
					paymentsInfoAry.push({
										paymentDate: paymentDate,
										paymentAmount: paymentAmount,
										ban: row.ban,
										paymentMethod: paymentMethod,
										paymentMethodLastFour: row.paymentDetailMethodLastFour,						
										paymentType: paymentType,
										paymentStatus: paymentStatus,
										confirmationNumber: row.confirmationNumber
										});
					*/
					
				}
			});
			bwcDispatchEscalationCase.publishEscalationCaseMessage(this.recordId,
				type,
				feature,
				JSON.stringify(
					{
						paymentDate: paymentDate,
						paymentAmount: paymentAmount,
						ban: row.ban,
						paymentMethod: paymentMethod,
						paymentMethodLastFour: row.paymentDetailMethodLastFour,						
						paymentType: paymentType,
						paymentStatus: paymentStatus,
						confirmationNumber: row.confirmationNumber,
						methodTypeLabel: row.methodTypeLabel,
						paymentCategoryType: row.paymentCategoryType,
						ctn: '',
						caseType: CASE_TYPE_BILLING_PAYMENT,
						caseAction: '',
						//paymentsInfoAry
					}
				)
			);
			//bwcDispatchEscalationCase.publishEscalationCaseMessage(this.recordId, type, feature, detailRecord);

			try{
				this.template.querySelector('lightning-datatable').click();
			}catch(e){
				BwcUtils.error('Error query selector datatable');
				BwcUtils.error(e);
			}
        }
    }

    escalationComplete(payload) {
        BwcUtils.log('Escalation complete received');
        // unsubscribe
        unsubscribe(this.completionSubscription);
        this.completionSubscription = null;

        // hide spinner
        switch(payload.scope) {
            case BwcConstants.HighLevelCaseType.Billing_Inquiry.type:
                this.isLoading = false;
                break;
            case BwcConstants.HighLevelCaseType.Billing_Payment.type:
                this.isLoadingPayments = false;
                break;
            default:
                break;
        }
    }

    //Call API to enroll or de-enroll a billing record.
    enroll(){

        //Success toast params
        let toastMsg = this.isEnrolled ? "You have been successfully de-enrolled from Paperless Billing" : "You have been successfully enrolled in Paperless Billing";
        let toastVariant  = "success";
        let toastMode = "dismissable";

        //API params
        let ban = this.selectedRow.ban;
        let accountType = this.selectedRow.service.toLowerCase() === 'wireless' ? 'Wireless' : 'Wireline';
        let status = this.isEnrolled ? 'Paper' : 'Paperless';

        this.closeEnrollModal();

        //Calling API via APEX
        getPaperlessStatus({ban: ban, accountType: accountType, status: status})
        .then((result)=>{
            let response = JSON.parse(result);
            BwcUtils.log(response);
            //If any error, update toast params
            if(!response.success){
                toastMsg = 'At this moment we cannot process your request';
                toastVariant = 'error';
            }

            this.fireToast(toastMsg, toastVariant, toastMode);
        })
        .catch(error => {
            this.addBillingError('Error calling getPaperlessStatus.', error);
            this.isLoading = false;
        });
    }

    fireToast(message, variant, mode){
        let title = variant.charAt(0).toUpperCase() + variant.slice(1)

        const evt = new ShowToastEvent({
            title,
            message,
            variant,
            mode,
        });
        this.dispatchEvent(evt);
    }

    onHandleSort(event){

        const { fieldName, sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.paymentsData];
        let parser = (v)=>v;
        let column = this.paymentsColumns.find(c=>c.fieldName===fieldName);
        if(column.type === 'date' || column.type === 'datetime' || column.type === 'date-local'){
            parser = (v) => (new Date(v));
        }

        this.sortDirection = sortDirection;
        this.sortedBy = fieldName;
        let sortMult = sortDirection === 'asc'? 1: -1;
        this.paymentsData = cloneData.sort((a,b) => {
            let a1 = parser(a[fieldName]);
            let b1 = parser(b[fieldName]);
            let r1 = a1 < b1;
            return  r1 ? sortMult: -sortMult;
        });
    }

    //Getter that returns the correct title depending on the selected billing row values
    get EnrollModalTitle(){
        if(!this.selectedRow) {
            return '';
        }

        return this.isEnrolled ? this.label.enrollPaperTitle : this.label.enrollPaperlessTitle;
    }

    //Getter that returns the correct message depending on the selected billing row values
    get EnrollModalMessage(){
        if(!this.selectedRow) {
            return '';
        }

        return this.isEnrolled ? this.label.enrollPaperMessage : this.label.enrollPaperlessMessage;
    }

    //Getter that returns the correct message the agent needs to read to the customer depending on the selected billing row values
    get EnrollModalMessageCustomer(){
        if (!this.selectedRow) {
            return '';
        }

        let personEmail = getFieldValue(this.wiredPersonAccount.data, PERSON_EMAIL_FIELD);
        //If not enrolled in paperless bill yet, add the customer email to the message.
        let result = this.isEnrolled ? this.label.enrollPaperMessageCustomer : this.label.enrollPaperlessMessageCustomer.replace('{email}',personEmail);

        return result;
    }

    //Getter to know if the selected billing row is enrolled in Paperless billing or not.
    get isEnrolled(){
        if(!this.selectedRow) {
            return '';
        }

        return this.selectedRow.paperlessBill.toLowerCase() === 'enrolled';
    }




}