import { api, track } from 'lwc';
import BwcPageElementBase from 'c/bwcPageElementBase';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcConstants from 'c/bwcConstants';
import * as BwcPaymentServices from 'c/bwcPaymentServices';
import * as BwcLabelServices from 'c/bwcLabelServices';
import * as BwcAccountServices from 'c/bwcAccountServices';
import * as BwcInteractionServices from 'c/bwcInteractionServices';

//import custom labels
import discontinueTitle from '@salesforce/label/c.BWC_Auto_Pay_Discontinue_Title';
import discontinueMessage from '@salesforce/label/c.BWC_Auto_Pay_Discontinue_Message';  
import discontinueSuccess from '@salesforce/label/c.BWC_Auto_Pay_Discontinue_Success'; 
import pauseTitle from '@salesforce/label/c.BWC_Auto_Pay_Pause_Title';
import pauseMessage from '@salesforce/label/c.BWC_Auto_Pay_Pause_Message';
import pauseSuccess from '@salesforce/label/c.BWC_Auto_Pay_Pause_Success'; 
import unexpectedError from '@salesforce/label/c.BWC_UnexpectedError_RefreshSection';

export default class BwcAutoPayProfiles extends BwcPageElementBase {

    // Labels
    labels = BwcLabelServices.labels;

    columns = [
        { label: 'Date Added', fieldName: 'dateAdded', type: 'date-local', typeAttributes: {month: '2-digit', day: '2-digit'}, hideDefaultActions: true },
        { label: this.labels.account, fieldName: 'ban', type: 'text', hideDefaultActions: true },
        { label: 'Payment Method', fieldName: 'method', type: 'text', hideDefaultActions: true },
        { label: 'Ending In', fieldName: 'last4', type: 'text', hideDefaultActions: true},
        { label: 'Account Name', fieldName: 'accountName', type: 'text', hideDefaultActions: true },
        { label: 'Status', fieldName: 'status', type: 'text', hideDefaultActions: true,
        cellAttributes: {
            class: { fieldName : 'statusClass'}
        }},
        { type: 'action', typeAttributes: {rowActions: this.getRowActions.bind(this)}}
    ];

    //public variables
    @api recordId;

    billingAccounts;

    //Reactive variables.
    isLoading = true;
    showEmpty = false;
    showTable = false;
    @track tableData = [];
    showEnrollButton = false;
    confirmReadPanelText;
    isBSSeCustomer;

    get notification() {return this.template.querySelector('c-bwc-notifications');}

    isRendered = false;
    renderedCallback(){

        if (!this.isRendered) {
            this.isRendered = true;
            this.refresh();
        }

    }

    /*
        Handle refresh message.
    */
    handleLmsRefresh(scope, recordId) {

        if ((scope === 'autoPayProfiles' || !scope) && (!recordId || recordId === this.recordId)) {
            this.refresh();
        }

    }

    async refresh() {
    
        this.tableData = [];
        this.showTable = false;
        this.showEmpty = false;
        this.showEnrollButton = false;

        try {

            this.notification.clearNotifications();
            this.isLoading = true;

            // Check if is BSSe customer
            const interaction = await BwcInteractionServices.getInteraction(this.recordId);
            this.isBSSeCustomer = interaction.Customer__r.Is_Digital_Customer__c;

            // Get all billing accounts
            this.billingAccounts = await BwcAccountServices.getBillingAccounts(this.recordId, undefined, undefined, undefined, undefined, true);

            let topics = [];
            topics.push(this.isBSSeCustomer ? BwcConstants.PaymentDetailTopic.PAYMENT_PROFILES.value : BwcConstants.PaymentDetailTopic.AUTOPAY.value);

            const paymentDetailsResponseObjects = await BwcPaymentServices.getPaymentDetails({
                recordId: this.recordId, 
                topics: topics
            });
            paymentDetailsResponseObjects.forEach(responseObject => {

                if (responseObject.errorautopay) {
                    const error = new Error(`Error retrieving autopay details for BAN ${responseObject.ban}: ${JSON.stringify(responseObject.errorautopay)}`);
                    super.handleError(error, unexpectedError, 'AutoPay Profiles', 'inline');
                }
                else if (responseObject.autopay && responseObject.autopay.paymentPlanInfo && responseObject.autopay.paymentPlanInfo[0]) {

                    const paymentPlanInfo = responseObject.autopay.paymentPlanInfo[0];

                    let method;
                    let last4;
                    let accountName;
                    if (paymentPlanInfo.card) {
                        method = BwcConstants.CardType.getLabel(paymentPlanInfo.card.cardType);
                        last4 = BwcUtils.right(paymentPlanInfo.card.cardNumber, 4);
                        accountName = paymentPlanInfo.card.cardHolderName;
                    }
                    else if (paymentPlanInfo.bankAccount) {
                        method = BwcConstants.BankAccountType.getLabel(paymentPlanInfo.bankAccount.accountType);
                        last4 = BwcUtils.right(paymentPlanInfo.bankAccount.bankAccountNumber, 4);
                        accountName = paymentPlanInfo.bankAccount.accountHolderName;
                    }
                    else {
                        BwcUtils.error('No card or bankAccount found on autopay details.');
                    }                    

                    let status;
                    const trackingStatus = responseObject.autopay.autoPayTrackingStatus;

                    if (trackingStatus) {

                        const firstStatus = trackingStatus.substring(0, trackingStatus.indexOf('_'));
                        switch (firstStatus) {

                            case 'NotScheduled':
                                status = 'Not Scheduled';
                                break;

                            case 'NotAvailable':
                                status = 'Not Available';
                                break;

                            default:
                                status = firstStatus;
                                break;

                        }

                    }

                    this.tableData.push({
                        dateAdded: paymentPlanInfo.entryDate,
                        ban: responseObject.ban,
                        accountType: responseObject.accountType,
                        method: method,
                        last4: last4,
                        accountName: accountName,
                        status: status,
                        cancelNextAutopayPaymentAllowed: responseObject.autopay.cancelNextAutopayPaymentAllowed,
                        autoPayPaymentDate: responseObject.autopay.autoPayPaymentDate,
                        autoPayPaymentCancelled: responseObject.autopay.autoPayPaymentCancelled,
                        statusClass: trackingStatus === 'Failed_BalanceDue' ? 'slds-text-color_error' : undefined
                    });

                } 
                else if (responseObject.paymentProfiles && responseObject.paymentProfiles.paymentProfileList) {

                    // Get autopay profiles for BSSe customers
                    responseObject.paymentProfiles.paymentProfileList.forEach(profile => {
                        // Add only those profiles to the table which match the Default_Payment_Profile__c from related billing accounts
                        let matchedBillingAccount = this.billingAccounts.find(billingAccount => billingAccount.Default_Payment_Profile__c === profile.profileName); 
                        if (matchedBillingAccount) {

                            const row = BwcUtils.cloneObject(profile);

                            let method;
                            let last4;
                            let accountName;
                            if (profile.card) {
                                method = BwcConstants.CardType.getLabel(profile.card.cardType);
                                last4 = BwcUtils.right(profile.card.cardNumber, 4);
                                accountName = profile.card.cardHolderName;
                            }
                            else if (profile.bankAccount) {
                                method = BwcConstants.BankAccountType.getLabel(profile.bankAccount.accountType);
                                last4 = BwcUtils.right(profile.bankAccount.bankAccountNumber, 4);
                                accountName = profile.bankAccount.accountHolderName;
                            }
                            else {
                                BwcUtils.error('No card or bankAccount found on payment profile details.');
                            } 

                            row.dateAdded = profile.profileCreatedTime;
                            row.ban = null;
                            row.accountType = null;
                            row.method = method;
                            row.last4 = last4;
                            row.accountName = accountName;
                            row.status = 'Scheduled';
                            row.cancelNextAutopayPaymentAllowed = false;
                            row.autoPayPaymentDate = null;
                            row.autoPayPaymentCancelled = null;
                            row.statusClass = undefined;
                            row.profileName = profile.profileName;

                            // Enrich row data
                            row.paymentMethodTypeLabel = BwcConstants.PaymentMethodType[profile.paymentMethodType].label;
                            row.accountType = responseObject.accountType;
                            if (responseObject.individualId) {
                                row.individualId = responseObject.individualId;
                            }

                            if (profile.paymentMethodType === BwcConstants.PaymentMethodType.CARD.value) {
                                // Expiration date
                                row.expiration = profile.card.expireMonth + '/' + profile.card.expireYear;
                            }

                            this.tableData.push(row);

                        } 
                    });
                }
                else {

                    if (responseObject.autopay && responseObject.autopay.paymentPlanEligibility && 
                        responseObject.autopay.paymentPlanEligibility.paymentMethodAllowed && 
                        (responseObject.autopay.paymentPlanEligibility.paymentMethodAllowed.card || responseObject.autopay.paymentPlanEligibility.paymentMethodAllowed.bank)) {

                        // Something is not enrolled and can be enrolled -- show button
                        this.showEnrollButton = true;
                            
                    }

                }

            });

        }
        catch(error) {
            super.handleError(error, unexpectedError, 'AutoPay Profiles', 'inline');
        }
        finally {
            this.isLoading = false;
        }

        if (this.tableData.length === 0){
            this.showEmpty = true;
        }
        else {
            this.showTable = true;
            this.showEmpty = false;
        }

    }

    getRowActions(row, doneCallback){

        const actions = [];
        actions.push({label: 'Edit AutoPay Profile', name: 'edit'});
        if (row.cancelNextAutopayPaymentAllowed && !row.autoPayPaymentCancelled) {
            // Cancel is allowed and not already canceled
            actions.push({label: 'Pause AutoPay', name: 'pause'});
        }
        actions.push({label: 'Cancel AutoPay', name: 'cancel'});

        doneCallback(actions);
    }

    async handleRowAction(event){

        BwcUtils.log(`event.detail.row: ${JSON.stringify(event.detail.row)}`);

        switch(event.detail.action.name){

            case 'edit':
                if (this.isBSSeCustomer) {
                    // For BSSe, open modal to edit payment profile
                    this.template.querySelector('c-bwc-payment-profile-add-edit').open(this.recordId, event.detail.row, this.isBSSeCustomer);
                } else {
                    this.openAutoPayTab(event.detail.row.ban);
                }
                break;

            case 'pause':
                await this.confirmPause(event.detail.row);
                break;

            case 'cancel':
                if (this.isBSSeCustomer) {
                    // For BSSe, cancel autopay is not available
                    // Show toast message only
                    BwcUtils.showToast(this, {message: this.labels.cancelAutoPayNotAvailableBsse, variant: 'info'} );
                } else {
                    await this.confirmDiscontinue(event.detail.row);
                }
                break;

            default:
                BwcUtils.error('Unknown menu action: ' + event.detail.action.name);
                break;

        }

    }

    handleNewAutoPay() {

        this.openAutoPayTab();

    }

    async confirmDiscontinue(row){

        this.confirmReadPanelText = discontinueMessage.replace('{0}', row.ban);

        // Build confirmation options
        const confirmOptions = {
            title: discontinueTitle.replace('{0}', row.ban).replace('{1}', BwcConstants.BillingAccountType.getLabelForValue(row.accountType)),
            okLabel: 'Confirm',
            okCallback: async () => {
                await this.discontinueAutoPay(row);
            },
            cancelLabel: 'Cancel'
        };

        // Show confirmation modal
        this.template.querySelector('c-bwc-confirm').open(confirmOptions);        
        
    }

    async discontinueAutoPay(row){
        
        let autoPayProfile = {
            'accountNumber': row.ban,
            'accountType': row.accountType
        }

        await BwcPaymentServices.postAutoPayProfile(autoPayProfile, 'delete');

        super.showToast(undefined, discontinueSuccess.replace('{0}', row.ban), 'success', 'dismissable');

        await this.refresh();
        
    }
    
    async confirmPause(row){

        this.confirmReadPanelText = pauseMessage.replace('{0}', row.ban);

        // Build confirmation options
        const confirmOptions = {
            title: pauseTitle.replace('{0}', row.ban).replace('{1}', BwcConstants.BillingAccountType.getLabelForValue(row.accountType)),
            okLabel: 'Confirm',
            okCallback: async () => {
                await this.pauseAutoPay(row);
            },
            cancelLabel: 'Cancel'
        };

        // Show confirmation modal
        this.template.querySelector('c-bwc-confirm').open(confirmOptions);
        
    }

    async pauseAutoPay(row){

        if (!row.autoPayPaymentDate) {
            throw new Error('Cannot pause because no autoPayPaymentDate is available.');
        }

        const autoPayProfile = {
            'accountNumber': row.ban,
            'accountType': row.accountType,
            'autopayPaymentDate': row.autoPayPaymentDate
        }

        await BwcPaymentServices.postAutoPayProfile(autoPayProfile, 'pause');

        super.showToast(undefined, pauseSuccess.replace('{0}', row.ban), 'success', 'dismissable');

        await this.refresh();

    }

    openAutoPayTab(autoPayIdentifier) {

        let state = {}
        if (this.isBSSeCustomer) {
            state = {
                c__recordId: this.recordId,
                c__profileName: autoPayIdentifier
            } 
        } else {
            state = {
                c__recordId: this.recordId,
                c__editBan: autoPayIdentifier
            } 
        }

        const message = {
            pageReference: {
                type: 'standard__component',
                attributes: {
                    componentName: 'c__BWCAutoPayWizardPage',
                },
                state: state               
            },
            label: autoPayIdentifier ? 'Edit AutoPay' : 'Enroll in AutoPay',
            icon: 'custom:custom41'
        };

        BwcUtils.openSubTab(message);        

    }

}