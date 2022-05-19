import { api } from 'lwc';
import * as BwcConstants from 'c/bwcConstants';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcAccountServices from 'c/bwcAccountServices';
import * as BwcAuthorizationServices from 'c/bwcAuthorizationServices';
import BwcPageElementBase from 'c/bwcPageElementBase';

/*
    Modal supports step-up authentication from L0 to L1, or to OTP when required.
*/
export default class BwcStepUp extends BwcPageElementBase {

    isOtpOnly;
    interactionId;
    ban;
    billingAccountId;
    billingAccounts = [];
    billingAccount;
    authenticatedCallback;

    isOpen;
    isLoading;
    isAuthenticating;
    isAuthorizing;
    isStepUpAuthRequired;

    get errorReports() {return this.template.querySelector('c-bwc-error-reports');}
    get authenticateComponent() {return this.template.querySelector('c-bwc-authenticate');}
    isDisabledConfirm = true;
    get disableConfirm() {return this.isDisabledConfirm || this.isAuthorizing;}

    get title() {return this.isOtpOnly ? 'OTP Authentication Required' : 'Authenticate the Customer';}
    
    /*
        Start step-up authentication for the specific interaction and ban.
    */
    @api async open(interactionId, ban, accountType, unifiedBan, authenticatedCallback) {

        try {

            this.isOtpOnly = false;
            this.interactionId = interactionId;
            this.ban = ban;
            this.authenticatedCallback = authenticatedCallback;
            this.billingAccountId = undefined;
            this.billingAccounts = [];
            this.billingAccount = undefined;
            this.isAuthenticating = true;
            this.isOpen = true;
            this.isStepUpAuthRequired = true;

            // Allow render
            await BwcUtils.nextTick();

            // Resolve billing account
            await this.getBillingAccount();

            this.authenticateComponent.initialize(interactionId, this.billingAccountId);

        }
        catch (error) {

            this.errorReports.addError(error);

        }

    }

    /*
        Check BAN, if it's already authorized L1 using OTP, then just call authenticatedCallback.
        Otherwise, show UI to allow step up using OTP-only.
    */
    @api async openForOtp(interactionId, billingAccountId, authenticatedCallback, disableBanSelection) {

        this.isOtpOnly = true;
        this.interactionId = interactionId;
        this.billingAccountId = billingAccountId;
        this.billingAccounts = [];
        this.billingAccount = undefined;
        this.authenticatedCallback = authenticatedCallback;
        this.isAuthenticating = false;

        try {

            // Check if already OTP
            const isAuthenticatedWithOtp = await BwcAuthorizationServices.isAuthenticatedWithOtp(interactionId, billingAccountId);

            // Find entry for BAN
            if (isAuthenticatedWithOtp) {

                // Ban is already L1 authenticated using OTP, we're finished
                this.close();
                this.authenticatedCallback();
                return;

            }

            // Not OTP authorized yet:
            this.isOpen = true;
            this.isLoading = true;
            this.isLoading = false;
            this.isAuthenticating = true;

            await BwcUtils.nextTick();

            this.authenticateComponent.initialize(interactionId, this.billingAccountId, disableBanSelection, BwcConstants.AuthenticationMethod.OTP.value);

        }
        catch(error) {
            this.errorReports.addError(error);

        }
        finally {
            this.isLoading = false;
        }

    }

    /*
        Retrieve all billing accounts for the interaction, and find the one being stepped up.
    */
    async getBillingAccount() {

        this.billingAccounts = await BwcAccountServices.getBillingAccounts(this.interactionId);
        if (this.billingAccountId) {
            this.billingAccount = this.billingAccounts.find(billingAccount => billingAccount.Id === this.billingAccountId);
            if (!this.billingAccount) {
                throw new Error('Billing account record not found.');
            }
        }
        else if (this.ban) {
            this.billingAccount = this.billingAccounts.find(billingAccount => billingAccount.Billing_Account_Number__c === this.ban);
            if (!this.billingAccount) {
                throw new Error('Billing account record not found.');
            }
        }

        this.billingAccountId = this.billingAccount?.Id;        
        this.ban = this.billingAccount?.Billing_Account_Number__c;
        this.accountType = this.billingAccount?.Account_Type__c;
        this.unifiedBan = this.billingAccount?.Wireless_BAN__c;

    }

    /*
        Close the modal.
    */
    close() {
        this.isOpen = false;
    }

    handleConfirmDisabled(event) {
        this.isDisabledConfirm = event.detail.disabled;
    }

    handleConfirm() {
        this.authenticateComponent.handleConfirm();
    }

    /*
        The bwcAuthenticate component is telling us authentication was successful.
    */
    async handleAuthenticated(event) {

        // Get authorizations
        this.isAuthenticating = false;

        try {

            this.isAuthorizing = true;

            // Tell service to now recheck authorization for the billing account, will update the authorization level
            const checkAuthResponse = await BwcAuthorizationServices.checkAuthorizationStatus(this.interactionId, event.detail.billingAccountId);
            const steppedUpBans = checkAuthResponse.updatedAccounts.map(account => account.accountBan);

            // send general refresh message from bwcPageElementBase only if it was step up authentication
            if (this.isStepUpAuthRequired) {
                super.sendLmsRefresh(this.interactionId);
            }

            // Done
            this.close();

            // Callback
            this.authenticatedCallback(steppedUpBans);

        }
        catch(error) {

            this.errorReports.addError(new Error('Error retrieving authorization status.'), error);

            // Go back to authenticate
            this.isAuthenticating = true;
        
        }
        finally {
            this.isAuthorizing = false;
        }

    }

    handleClose() {
        this.close();
    }

    /*
        Handle some keypresses for entire modal.
    */
    handleModalKeydown(event) {

        switch(event.key) {

            case 'Enter':
                this.handleSave();
                break;

            case 'Escape':
                this.close();
                break;

            default:
                break;

        }

    }

    /*
        Capture tabbing so it cycles within the modal.
    */
    handleButtonKeydown(event) {

        //If tabbing forward and this is last button, override and circle back to X button
        if (event.target.dataset.name === 'confirmButton' && event.key === "Tab" && !event.shiftKey) {

            event.preventDefault();
            let closeButton = this.template.querySelector('lightning-button-icon[data-name="closeButton"');
            if (closeButton) {
                closeButton.focus();
            }

        }
        else if (event.target.dataset.name === 'closeButton' && event.key === "Tab" && event.shiftKey) {
            event.preventDefault();
            let rightButton = this.template.querySelector('lightning-button[data-name="confirmButton"');
            if (rightButton) {
                rightButton.focus();
            }
        }

    }

}