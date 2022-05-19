import { LightningElement, api, track, wire } from 'lwc';
import { subscribe, unsubscribe, MessageContext, APPLICATION_SCOPE } from 'lightning/messageService';
import * as BwcConstants from 'c/bwcConstants';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcAccountServices from 'c/bwcAccountServices';
import * as BwcCustomerAccountServices from 'c/bwcCustomerAccountServices';

import BwcPageElementBase from 'c/bwcPageElementBase';
import * as BwcPageHelpers from 'c/bwcPageHelpers';

// Labels
import level2LockDetails from '@salesforce/label/c.BWC_Level2_Lock_Details';

// Message channels
import REFRESHMC from '@salesforce/messageChannel/BWC_Refresh__c';

//Custom Permission 
import HAS_ACCOUNT_SECURITY_PERMISSION from '@salesforce/customPermission/Manage_Customer_Account_Access';  
import HAS_CONTACT_PERMISSION from '@salesforce/customPermission/Manage_Customer_Contact_Info'; 

export default class BwcBillingAccountCustomerInfo extends BwcPageElementBase {

    label = {
        level2LockDetails
    };

    @api recordId;
    isRendered = false;
    get errorReport() {return this.template.querySelector('c-bwc-error-report');}

    // Needed to subscribe to refresh message
    @wire(MessageContext)
    messageContext;    
    subscription; // Message channel subscription

    // Billing account to get account type
    billingAccountRecord;

    // Only wireless or uverse are valid
    get isValidAccountType() {
        const productName360 = this.billingAccountRecord ? this.billingAccountRecord.Product_Name_360__c : undefined;
        return productName360 === BwcConstants.BillingAccountType.WIRELESS.value || productName360 === BwcConstants.BillingAccountType.UVERSE.value;
    }
    get showNotValid() {return this.billingAccountRecord && !this.isValidAccountType;}
    get showValid() {return this.billingAccountRecord && this.isValidAccountType;}

    // Retrieved from API
    accountDetails;

    // Account Contact & Security section:

    isBusyAccountContact = false;
    @track contactInformation = {};

    // Customer MyAT&T Login & Security secton:

    isInitializedLogins = false;
    isBusyLogins = false;
    @track logins = [];
    get showNoLogins() {return this.isInitializedLogins && this.logins.length === 0;}
    get showLogins() {return this.isInitializedLogins && this.logins.length > 0;}

    connectedCallback() {

        // Subscribe to refresh message channel
        this.subscription = subscribe(
            this.messageContext,
            REFRESHMC, (message) => {

                if (message.scope === 'accountContact' &&
                    (!message.recordId || message.recordId === this.recordId)) {
                    this.refreshAccountContact();
                }

            },
            { scope: APPLICATION_SCOPE });

    }

    disconnectedCallback() {

        // Unsubscribe from message channel
        unsubscribe(this.subscription);
        this.subscription = null;

    }

    /*
        Do on first render.
    */
    async renderedCallback() {

        if (!this.isRendered) {

            this.isRendered = true;

            this.billingAccountRecord = await BwcAccountServices.getBillingAccountForId(this.recordId);

            if (this.isValidAccountType) {
                this.isBusyLogins = true;
                await this.refreshAccountContact();
                this.refreshLogins(false);
            }

        }

    }

    /*
        Refresh Account Contact & Security section.
    */
    async refreshAccountContact(){

        try {

            this.errorReport.clearError();
            this.isBusyAccountContact = true;
            const interactionId = BwcUtils.getInteractionIdFromUrl();
            this.accountDetails = await BwcCustomerAccountServices.getAccountDetailsForBillingAccountRecord(this.recordId,interactionId);
            this.contactInformation = {};
            this.accountDetails.details.contactInfo.contacts.forEach(contactInfo => {

                switch (contactInfo.contactType) {

                    case 'phone':
                        if (contactInfo.isPrimary) {
                            this.contactInformation.primaryPhoneNumber = BwcUtils.formatPhone(contactInfo.contactValue);
                        }
                        else {
                            this.contactInformation.alternatePhoneNumber = BwcUtils.formatPhone(contactInfo.contactValue);
                        }
                        break;

                    case 'email':
                        this.contactInformation.emailAddress = contactInfo.contactValue;
                        break;

                    default:
                        BwcUtils.error(`Unknown contactType "${contactInfo.contactType}"`);
                        break;

                }

            });

        }
        catch(error) {
            this.errorReport.reportError(error);
        }
        finally {
            this.isBusyAccountContact = false;
        }
    
    }

    handleAccountContactRefresh() {

        this.refreshAccountContact();

    }

    handleManageAccountContact() {

        try {

            // OTP Required
            this.template.querySelector('c-bwc-step-up').openForOtp(BwcUtils.getInteractionIdFromUrl(), 
                this.recordId, () => {

                    const message = {
                        pageReference: {
                            type: 'standard__component',
                            attributes: {
                                componentName: 'c__BWCManageAccountContactPage'
                            },
                            state: {
                                c__recordId: this.recordId
                            }                
                        },
                        label: `${this.billingAccountRecord.Billing_Account_Number__c}: Manage Account Contact`,
                        icon: 'custom:custom40'
                    };
            
                    BwcUtils.openSubTab(message);        

                }, true);

        }
        catch(error) {
            this.errorReport.reportError(error);
        }
        
    }

    /**
     * Permission 1: Allow agent to send link for My ATT login password
     * Allows agent to Edit Account Security 
     */
    get editAccountSecurity(){
        return HAS_ACCOUNT_SECURITY_PERMISSION;
    }

    /**
     * Permission 2:
     * Allows agent to Manage Contact Information
     */
    get manageContactInfo(){
        return HAS_CONTACT_PERMISSION;
    }
    
    /**
     * Evaluate if we are able to show Account Security Modal
     * based on account type: 
     * If it is wireless and it is unified, don't show it
     * else, show it (wireless NOT unified, uverse)
     */
    get showAccountSecurityTile() {
        if (this.billingAccountRecord) {
            if ((this.billingAccountRecord.Account_Type__c == BwcConstants.BillingAccountType.WIRELESS.value && !this.billingAccountRecord.Is_Unified__c) 
                || this.billingAccountRecord.Account_Type__c == BwcConstants.BillingAccountType.UVERSE.value) {
                return true;
            }
        }
        return false;
    }

    /**
     * Open Account Security Modal
     * OTP authentication required
     */
    async handleEditAccountSecurity() {

        try {

            // OTP Required
            this.template.querySelector('c-bwc-step-up').openForOtp(BwcUtils.getInteractionIdFromUrl(), 
                this.recordId, () => {

                    BwcPageHelpers.showModal('c:bwcEditAccountSecurity', {recordId: this.recordId}, null, true);

                }, true);

        }
        catch(error) {
            this.errorReport.reportError(error);
        }        
    }

    /*
        Refresh Customer MyAT&T Login & Security section.
    */
    async refreshLogins(requery) {

        try {

            this.errorReport.clearError();
            this.isBusyLogins = true;

            // If not requery, we use existing details that were already retrieved
            if (requery || !this.accountDetails) {
                const interactionId = BwcUtils.getInteractionIdFromUrl();
                this.accountDetails = await BwcCustomerAccountServices.getAccountDetailsForBillingAccountRecord(this.recordId,interactionId);
            }

            // Example locked items
            // this.logins.push({slid: 'L1LockExample', userLockLevel: '1'});
            // this.logins.push({slid: 'L2LockExample', userLockLevel: '2'});

            // Enrich with lock information
            this.logins.forEach(login => {

                if (login.userLockLevel === '1') {
                    login.isL1Locked = true;
                }
                else if (login.userLockLevel === '2') {
                    login.isL2Locked = true;
                    login.isResetDisabled = true;
                }

            });

        }
        catch(error) {
            this.errorReport.reportError(error);
        }
        finally {
            this.isInitializedLogins = true;
            this.isBusyLogins = false;
        }

    }

    handleLoginsRefresh() {
        this.refreshLogins(true);
    }

    handleSecurityReset(event) {

        try {

            const user = this.logins.find(login => login.slid === event.target.dataset.slid);
            const resetBoth = event.target.name !== 'resetPasswordOnly';

            // OTP Required
            this.template.querySelector('c-bwc-step-up').openForOtp(BwcUtils.getInteractionIdFromUrl(), 
                this.recordId, () => {this.template.querySelector('c-bwc-security-reset').open(this.billingAccountRecord, user, resetBoth);}, true);

        }
        catch(error) {
            this.errorReport.reportError(error);
        }
        
    }

    handleLevel2Mouseover(event) {
        this.template.querySelector('c-bwc-helptext[data-name="level2Popover"]').showPopover(event.target);
    }

    handleLevel2Mouseout() {
        this.template.querySelector('c-bwc-helptext[data-name="level2Popover"]').hidePopover();
    }

}