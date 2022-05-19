import {  api } from 'lwc';
import BwcPageElementBase from 'c/bwcPageElementBase';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import * as BwcConstants from 'c/bwcConstants';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcInteractionServices from 'c/bwcInteractionServices';
import * as BwcAuthorizationServices from 'c/bwcAuthorizationServices';
import * as BwcLICPublisher from 'c/bwcMsgToLICPublisher';
import * as BwcOrder from 'c/bwcOrder';
import * as BwcOrderServices from 'c/bwcOrderServices';

/*
    This flows through the following steps, some of which are optional depending upon context:
        - Authorized User Selection -- Wireless only
        - Authorization -- Checks for L0/L1 authorization levels for each BAN for the customer. Also gets step-up authentication methods for those bans not authenticated.
        - Authentication -- Authenticates via passcode or one time pin, if authentication did not take place through IVR
        - CPNI Consent -- Depending upon setting on the billing account
*/
export default class BwcAuthorize extends BwcPageElementBase {

    @api recordId;
    interaction;
    billingAccountId;
    isOffline;
    isBypass;
    isRendered;
    isBusy;

    // LIC
    doLic;
    get showLicButton() {
        return super.hasErrorNotifications;
    }

    // 1. Authorization / Reauthorization (after authenticating)
    isAuthorizing;
    isReauthorizing;
    isAuthorized;

    // 2. Authentication
    isAuthenticating;

    // 3. CPNI Consent
    mustCheckCpni;
    isShowingCpni;

    // 4. Is Authenticating in Legacy System
    isAuthLegacySystem;
    get showLegacyAuthScreen() {
        return this.isAuthLegacySystem && !this.isShowingCpni && !this.isAuthenticating;
    }

    // Get title from step
    get title() {

        if (this.isAuthorizing) {
            if (this.isReauthorizing) {
                return 'Customer Authenticated, Reauthorizing...';
            }
            return 'Authorizing...';
        }
        else if (this.isAuthenticating) {
            return 'Authenticate the Customer';
        }
        else if (this.isShowingCpni) {
            return 'CPNI Consent';
        }

        return '';

    }

    async renderedCallback() {

        // Do on first render
        if (!this.isRendered) {

            this.isRendered = true;

            try {

                this.doLic = false;
                this.isBypass = false;

                // Get interaction values
                this.interaction = await BwcInteractionServices.getInteraction(this.recordId);
                this.billingAccountId = this.interaction.Billing_Account__c;
                this.isOffline = this.interaction.RecordType.DeveloperName === 'Offline';

                // First step is check the status of authorization
                await this.checkAuthorizationStatus();

            }
            catch (error) {
                super.handleError(error, 'An unexpected error occurred.', 'Authorization');
            }
            finally {
                this.isBusy = false;
            }

        }

    }

    /*
        Get authorizations for the selected billing account.
    */
    async checkAuthorizationStatus() {

        try {

            this.isAuthorizing = true;
            this.isBusy = true;
            this.isAuthLegacySystem = false;

            // Get the authorization data from the API
            const response = await BwcAuthorizationServices.checkAuthorizationStatus(this.recordId, this.billingAccountId);
            this.isAuthorized = response.isAuthorized;

            this.isAuthorizing = false;

            // Next step is check authentication and do manually if needed
            await this.checkAuthentication();

        }
        catch (error) {
            let action = {
                name: 'authErrorRefresh',
                message: 'Refresh'
            }
            super.handleError(error, 'An unexpected error occurred. ', 'Authorization', null, action);
        }
        finally {

            this.isBusy = false;

        }

    }

    /*
        Check if authenticated and move to next step depending upon whether authenticated or not.
    */
    async checkAuthentication() {

        // Are we authenticated?
        if (this.isAuthorized) {

            // Already authenticated
            this.isAuthenticating = false;
            this.isAuthLegacySystem = false;

            await this.checkCpniConsent();

        }
        else {

            // Account was not automatically authenticated, use the recommended step-ups to authenticate manually
            this.isAuthenticating = true;
            this.isAuthLegacySystem = false;
            await BwcUtils.nextTick();

            // Retrieve updated interaction to get primary ban
            // TODO get primaryBillingAccountId (not ban)
            this.template.querySelector('c-bwc-authenticate').initialize(this.recordId, this.interaction.Billing_Account__c);

            // Component will send authenticated event when completed, see handleAuthenticated()

        }

    }
    
    /*
        Authentication component fired event that authentication was successful.
    */
    async handleAuthenticated(event) {

        try {

            // Manual authentication was successful so now we have authentication method <> NONE
            this.isAuthenticating = false;
            this.isAuthLegacySystem = false;
            this.doLic = false;

            // Set new selected billing account
            this.billingAccountId = event.detail.billingAccountId;
            this.isBypass = event.detail.authenticationMethod === BwcConstants.AuthenticationMethod.BYPASS.value;

            // Now need to reauthorize to get the L0/L1 and step-up info
            this.isReauthorizing = true;
            await this.checkAuthorizationStatus();

        }
        catch (error) {
            super.handleError(error, 'An unexpected error occurred.', 'Authorization');
        }
        finally {
            this.isBusy = false;
        }

    }

    /*
        Authentication component fired event that user wants to do LIC.
    */
    async handleLic() {

        super.clearNotifications();

        this.isAuthorizing = false;
        this.isAuthenticating = false;
        this.doLic = true;
        this.isAuthLegacySystem = true;
        await this.checkCpniConsent();

    }

    /*
        Check if CPNI Consent needs to be obtained.
    */
    async checkCpniConsent() {
        
        this.mustCheckCpni = await BwcInteractionServices.checkCpniConsent(this.recordId);
        this.isShowingCpni = this.mustCheckCpni;

        if (!this.mustCheckCpni) {
            await this.refreshPage();
        }

    }

    async handleCpniConsentSubmitted(event) {

        try {

            // Done, currently no action to take, just continue to interaction
            this.isShowingCpni = false;

            this.isBusy = true;
            await BwcInteractionServices.setCpniConsent(this.recordId, event.detail.response, this.billingAccountId);
            await this.refreshPage();

        }
        catch (error) {
            super.handleError(error, 'An unexpected error occurred.', 'Authorization');
        }
        finally {
            this.isBusy = false;
        }

    }

    async refreshPage() {

        if (this.doLic) {
            await BwcAuthorizationServices.setNoAuthentication(this.recordId);
            BwcLICPublisher.publishMessage('PostToOpus', {launchPoint: 'Launch Point', JsonData: {}}, this.billingAccountId);
        }
        else if (this.interaction.User_Order_Num__c && this.interaction.User_Action_Object__c === 'Inquire-Order') {

            // If there's an order, open subtab
            try {

                // Test that we can open the order details
                await BwcOrderServices.getOrderDetail(this.interaction.Id, this.interaction.User_Order_Num__c);

                // Success -- open the subtab
                BwcOrder.openOrderDetails(this.interaction.Id, this.interaction.User_Order_Num__c);

            }
            catch (e) {
                // Order retrieval failed -- failure is silent, just don't try to open the subtab
                BwcUtils.warn(`Not opening order detail for ${this.interaction.User_Order_Num__c} due to error.`, e);
            }

        }

        // Force flexipage to recognize any update to interaction and recalculate conditional display of components
        getRecordNotifyChange([{recordId: this.recordId}]);

    }

    async handleActionClick() {
        super.clearNotifications();
        this.doLic = false;
        this.isBypass = false;

        // Start authorization process again
        await this.checkAuthorizationStatus();
    }

    async backToAuthentication() {
        this.isAuthLegacySystem = false;

        // Start authroization process again
        await this.checkAuthorizationStatus();
    }

}