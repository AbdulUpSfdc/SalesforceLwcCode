import { api, track } from 'lwc';
import BwcPageElementBase from 'c/bwcPageElementBase';
import * as BwcConstants from 'c/bwcConstants';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcPaymentServices from 'c/bwcPaymentServices';
import * as BwcPayments from 'c/bwcPayments';
import * as bwcInteractActivityPublisher from 'c/bwcInteractActivityPublisher';
import * as BwcLabelServices from 'c/bwcLabelServices';
import * as BwcInteractionServices from 'c/bwcInteractionServices';
import * as BwcAccountServices from 'c/bwcAccountServices';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import hasPaymentPermission from '@salesforce/customPermission/Payment_Permission';

export default class BwcPaymentProfiles extends BwcPageElementBase {

    // Labels
    labels = BwcLabelServices.labels;

    columns = [
        { label: 'Date Added', fieldName: 'profileCreatedTime', type: 'date-local', typeAttributes: {month: '2-digit', day: '2-digit'}, hideDefaultActions: true },
        { label: this.labels.account, fieldName: 'ban', type: 'text', hideDefaultActions: true },
        { label: 'Last Used', fieldName: 'isLastUsed', type: 'boolean', initialWidth: 100},
        { label: 'Profile Name', fieldName: 'label', type: 'text', hideDefaultActions: true },
        { label: 'Payment Method', fieldName: 'paymentMethodTypeLabel', type: 'text', hideDefaultActions: true },
        { label: 'Expiration', fieldName: 'expiration', type: 'iconText', hideDefaultActions: true,
            typeAttributes: {
                iconName: {fieldName: 'expirationIcon'},
                iconVariant: {fieldName: 'expirationVariant'},
                iconAlternativeText: {fieldName: 'expirationAlternativeText'}
            },
            cellAttributes: {
                class: {fieldName: 'expirationClass'}
            }
        },
        { type: 'action', typeAttributes: {
            rowActions: hasPaymentPermission
                ? [
                    {label: 'Edit Payment Profile', name: 'editProfile'},
                    {label: 'Delete Payment Profile', name: 'deleteProfile'}]
                : []
        }}
    ];

    // Public variables
    @api recordId;

    isRendered;
    isLoading;
    enrolledInAutoPay;
    @track tableData;
    isBSSeCustomer;

    get notifications() {return this.template.querySelector('c-bwc-notifications');}
    get showTable() {return !this.isLoading && this.tableData && this.tableData.length !== 0;}
    get showEmpty() {return (!this.notifications || !this.notifications.hasErrorNotifications) && !this.isLoading && this.tableData && this.tableData.length === 0;}
    get dataTable() {return this.template.querySelector('lightning-datatable');}
    get hasPaymentPermission() {return hasPaymentPermission;}

    /*
        Refresh on first render.
    */
    renderedCallback() {

        if (!this.isRendered) {
            this.isRendered = true;
            this.refresh();
        }

    }

    /*
        Handle refresh message.
    */
    handleLmsRefresh(scope, recordId) {

        if ((scope === 'paymentProfiles' || !scope) && recordId === this.recordId) {
            this.refresh();
        }

    }

    /*
        Retrieve the profiles and build list.
    */
    async refresh(){

        this.notifications.clearNotifications();

        this.isLoading = true;

        this.isBSSeCustomer = undefined;

        try {

            // Check if is BSSe customer
            const interaction = await BwcInteractionServices.getInteraction(this.recordId);
            this.isBSSeCustomer = interaction.Customer__r.Is_Digital_Customer__c;

            // Get all billing accounts
            const billingAccounts = await BwcAccountServices.getBillingAccounts(this.recordId, undefined, undefined, undefined, undefined, true);

            // Get the profiles
            const paymentDetailsResponseObjects = await BwcPaymentServices.getPaymentDetails({
                recordId: this.recordId,
                topics: [
                    BwcConstants.PaymentDetailTopic.PAYMENT_PROFILES.value,
                    BwcConstants.PaymentDetailTopic.LAST_PAYMENT_METHOD.value,
                    BwcConstants.PaymentDetailTopic.AUTOPAY.value,
                ]
            });

            // Build single list for all bans
            this.tableData = [];

            paymentDetailsResponseObjects.forEach(responseObject => {

                let lastPaymentMethods = {};
                if (responseObject.errorlastPaymentMethod) {
                    BwcUtils.error('Payment Profiles', `Error retrieving last used payment methods for BAN ${responseObject.ban}: ` + JSON.stringify(responseObject.errorlastPaymentMethod));
                }
                else {
                    lastPaymentMethods = responseObject.lastPaymentMethod;
                }

                if (responseObject.errorpaymentProfiles) {

                    const error = new Error(`Error retrieving profiles for BAN ${responseObject.ban}: ${JSON.stringify(responseObject.errorpaymentProfiles)}`);
                    super.handleError(error, this.labels.unexpectedError, 'Payment Profiles', 'inline');

                }
                else if (responseObject.paymentProfiles.paymentProfileList) {

                    responseObject.paymentProfiles.paymentProfileList.forEach(profile => {

                        // Check if a related billing account has this profile as its default payment profile
                        let matchedBillingAccount = billingAccounts.find(billingAccount => billingAccount.Default_Payment_Profile__c === profile.profileName); 

                        // If no billing account matched this profile, add it to the list
                        if (!matchedBillingAccount) {
                            const row = BwcUtils.cloneObject(profile);

                            row.label = BwcUtils.buildPaymentMethodLabel(row);

                            // Enrich row data
                            row.paymentMethodTypeLabel = BwcConstants.PaymentMethodType[profile.paymentMethodType].label;
                            row.accountType = responseObject.accountType;
                            row.ban = responseObject.ban;
                            row.lastName = responseObject.lastName;
                            row.firstName = responseObject.firstName;
                            row.autoPayResponseCode = responseObject.autopay?.responseCode;
                            if (responseObject.individualId) {
                                row.individualId = responseObject.individualId;
                            }

                            if (profile.paymentMethodType === BwcConstants.PaymentMethodType.CARD.value) {

                                // Expiration date
                                row.expiration = profile.card.expireMonth + '/' + profile.card.expireYear;

                                // Expiration status
                                if (profile.card.expired) {
                                    row.expirationClass = 'slds-text-color_error';
                                    row.expirationIcon = 'utility:error';
                                    row.expirationVariant = 'error';
                                    row.expirationAlternativeText = 'Expired';
                                }
                                else if (profile.card.aboutToExpire) {
                                    row.expirationIcon = 'utility:warning';
                                    row.expirationVariant = 'warning';
                                    row.expirationAlternativeText = 'About to Expire';
                                }
                                else {
                                    row.expirationClass = '';
                                    row.expirationIcon = '';
                                    row.expirationVariant = '';
                                }

                            }

                            // Last Used?
                            if (row.paymentMethodType === BwcConstants.PaymentMethodType.CARD.value && lastPaymentMethods?.lastPaymentMethodCard) {

                                const lastCard = lastPaymentMethods.lastPaymentMethodCard.card;

                                if (row.card.cardType === lastCard.cardType &&
                                    row.card.cardNumber === lastCard.cardNumber) {

                                    row.isLastUsed = true;

                                }

                            }
                            if (row.paymentMethodType === BwcConstants.PaymentMethodType.BANKACCOUNT.value && lastPaymentMethods?.lastPaymentMethodBankAccount) {

                                const lastBankAccount = lastPaymentMethods.lastPaymentMethodBankAccount.bankAccount;

                                if (row.bankAccount.accountType === lastBankAccount.accountType &&
                                    row.bankAccount.routingNumber === lastBankAccount.routingNumber &&
                                    row.bankAccount.bankAccountNumber === lastBankAccount.bankAccountNumber) {

                                    row.isLastUsed = true;

                                }

                            }

                            this.tableData.push(row);
                        }

                    });

                }

            });

            // Sort by descending profileCreatedTime
            this.tableData.sort((a, b) => (b.profileCreatedTime < a.profileCreatedTime ? -1 : b.profileCreatedTime > a.profileCreatedTime ? 1 : 0));

        }
        finally {

            if (this.dataTable) {
                this.dataTable.data = this.tableData;
            }
            this.isLoading = false;

        }
 
    }

    async handleRefresh() {

        try {

            await this.refresh();

        }
        catch (e) {
            super.handleError(e, this.labels.unexpectedError, 'Payment Profiles', 'inline');
        }
       
    }

    handleAddNew() {

        try {

            this.notifications.clearNotifications();

            // One and done solution / interaction activity        
            bwcInteractActivityPublisher.publishMessage(this.recordId,BwcConstants.InteractionActivityValueMapping.AddPaymentMethod.action,JSON.stringify({data:'toDo'}),null);

            this.template.querySelector('c-bwc-payment-profile-add-edit').open(this.recordId, null, this.isBSSeCustomer);

        }
        catch (e) {
            super.handleError(e, this.labels.unexpectedError, 'Payment Profiles', 'inline');
        }

    }

    handleRowAction(event) {

        try {

            this.notifications.clearNotifications();
            
            switch (event.detail.action.name) {

                case 'editProfile':
                    this.template.querySelector('c-bwc-payment-profile-add-edit').open(this.recordId, event.detail.row, this.isBSSeCustomer);
                    break;

                case 'deleteProfile':
                    this.confirmDeleteProfile(event.detail.row);
                    break;

                default:
                    throw new Error('Unexpected action: ' + event.detail.action.name);

            }

        }
        catch (e) {
            super.handleError(e, this.labels.unexpectedError, 'Payment Profiles', 'inline');
        }

    }

    confirmDeleteProfile(profile) {

        BwcUtils.log(`Profile to delete: ${JSON.stringify(profile)}`);

        let message = '';
        if (profile.card != null) {
            message = `Debit/Credit Card ending in ${profile.card.cardNumber.replaceAll('X', '')}`;
        } else if (profile.bankAccount != null) {
            message = `Bank Account ending in ${profile.bankAccount.bankAccountNumber.replaceAll('X', '')}`;
        }

        // Build confirmation options
        const confirmOptions = {
            title: 'Delete Payment Profile',
            message: this.labels.deletePaymentProfileConfirmation.replace('{0}', message),
            okLabel: 'Confirm Delete',
            okCallback: async () => {
                await this.deleteProfile(profile)
            },
            cancelLabel: 'Cancel',
            isReadMessage: true
        };

        // Show confirmation modal
        this.template.querySelector('c-bwc-confirm').open(confirmOptions);

    }

    async deleteProfile(profile) {

        // Build the profile info for delete
        let paymentProfile = {};
        if (profile.ban) {

            paymentProfile = {
                accountType: profile.accountType,
                lastName: profile.lastName,
                firstName: profile.firstName,
                accountId: profile.ban,
                profileName: profile.profileName
            }

        } else {

            paymentProfile = {
                individualId: profile.individualId,
                profileName: profile.profileName,
                paySource: {
                    sourceSystem: BwcPayments.PaymentProfilePaySource.BSSE_CUSTOMERS.SOURCE_SYSTEM,
                    sourceLocation: BwcPayments.PaymentProfilePaySource.BSSE_CUSTOMERS.SOURCE_LOCATION
                }
            };

        }

        await BwcPaymentServices.postPaymentProfile(paymentProfile, BwcPaymentServices.PostPaymentProfileMode.DELETE);

        this.dispatchEvent(new ShowToastEvent({
            message: this.labels.deleteSuccess.replace('{0}', profile.profileName),
            variant: 'success'
        }));

        await this.refresh();

    }

}