import { api, track } from 'lwc';
import BwcPageElementBase from 'c/bwcPageElementBase';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcConstants from 'c/bwcConstants';
import * as BwcAccountServices from "c/bwcAccountServices";
import * as BwcBanUsageSummaryService from 'c/bwcViewBANUsageSummaryService';
import * as BwcInteractActivityPublisher from 'c/bwcInteractActivityPublisher';

// Labels
import usageSummaryError from '@salesforce/label/c.BWC_UsageSummary_ErrorRetrieving';
import usageSummaryNotReady from '@salesforce/label/c.BWC_UsageSummary_UsageNotReady';
import nonWirelessAccount from '@salesforce/label/c.BWC_UsageSummary_NonWirelessAccount';

export default class BwcViewBANUsageSummary extends BwcPageElementBase {

    // Public interface
    @api recordId;      // Always passed into component

    billingAccount;
    interactionRecord;
    @track usageSummary;
    billingCycleOptions = [];
    plans = [];
    selectedBillingCycle = undefined;
    dayOrDaysLabel;

    isLoading = false;
    usageRetrieved;
    banUsageSummaryRetrieved;

    get notifications() {return this.template.querySelector('c-bwc-notifications');}

    get ban() {return this.billingAccount ? this.billingAccount.Billing_Account_Number__c : '';}

    get daysRemainingInBillingCycle() { 
        if (!this.usageSummary) return null;

        let today = new Date();
        const billingEndDate = new Date(this.usageSummary.billingCycleEndDate);

        if (billingEndDate > today) {
            var differenceInTime = billingEndDate.getTime() - today.getTime();
            var daysRemaining = differenceInTime / (1000 * 3600 * 24);

            if (Math.trunc(daysRemaining) == 1) {
                this.dayOrDaysLabel = 'day';
            } else {
                this.dayOrDaysLabel = 'days';
            } 

            return Math.trunc(daysRemaining);

        } else {

            BwcUtils.log('not current billing cycle');
            return null;

        }
    }

    get showNoPlans() { this.plans ? this.plans.length === 0 : true }

    handleBillingCycleChange(event) {
        return event.target.value;
    }

    isRendered = false;
    renderedCallback() {
        if (!this.isRendered) {
            // Perform actions on first render, that way error report component is rendered and available to show error
            this.isRendered = true;
            this.loadUsageSummary();
        }
    }

    async loadUsageSummary() {

        this.isLoading = true;
        this.usageSummary = undefined;
        this.billingCycleOptions = [];
        this.plans = [];
        this.selectedBillingCycle = undefined;
        this.usageRetrieved = false;
        this.banUsageSummaryRetrieved = false;

        this.notifications.clearNotifications();

        this.billingAccount = await BwcAccountServices.getBillingAccountForId(this.recordId);

        if (this.billingAccount.Account_Type__c !== BwcConstants.BillingAccountType.WIRELESS.value) {
            this.isLoading = false;
            super.addScopedNotification(nonWirelessAccount, 'info');
            return;
        }

        let usageSummaryRequest = {
            AccountData: [
                {
                    AccountNumber: this.billingAccount.Billing_Account_Number__c
                }
            ]
        };

        try {
            this.isLoading = true;
            // Get usage data
            const result = await BwcBanUsageSummaryService.getUsageSummary(usageSummaryRequest, this.recordId);

            if (result) {

                this.usageSummary = result;

                // Init usage summary values
                this.initUsageSummary(this.usageSummary);

                // Create interaction activity 
                this.createInteractionActivity();

            } else {

                BwcUtils.log('no response');
                super.addScopedNotification(usageSummaryNotReady, 'info')

            }

        } catch(error) {

            BwcUtils.log('error loading usage summary: ' + JSON.stringify(error));
            // show error notification 
            super.handleError(error, usageSummaryError, 'Customer Usage Summary', 'scoped');

        } finally {

            this.isLoading = false;

        }
    }

    /*
        Initialize values for usage summary
    */
    initUsageSummary(usage) {

        // Set billing cycle dropdown options
        if (usage.billingCycleStartDate && usage.billingCycleEndDate) {
            // Format dates
            let startDate = this.adjustForTimezone(new Date(usage.billingCycleStartDate));
            let endDate = this.adjustForTimezone(new Date(usage.billingCycleEndDate));

            const label = startDate.toLocaleDateString() + ' - Present';
            const value = startDate.toLocaleDateString() + ' - ' + endDate.toLocaleDateString();
            this.billingCycleOptions.push({label: label, value: value});  

            // Set selected option
            this.selectedBillingCycle = value;
        }

        // Set each plan usage
        this.plans = usage.planUsage;

        this.usageRetrieved = true;

    }

    /*
        Create an InteractionActivity for each payment added or edited
    */
    async createInteractionActivity() {

        try {

            // Get interaction Id from URL
            const interactionId = BwcUtils.getInteractionIdFromUrl();
            BwcUtils.log(`createInteractionActivity - interactionId: ${interactionId}`);

            if (!interactionId) {
                // No interaction ID, do not log activity
                BwcUtils.error('Usage Summary', 'No interaction record found.');
                return;
            }

            // Get authorization for billing account from interaction
            let custAuthorization = await BwcBanUsageSummaryService.getInteractionAuthentication(interactionId, this.recordId);

            // Build out details
            const details = {
                recordId: interactionId,
                ban: this.ban,
                custAuthorization: custAuthorization
            };

            BwcUtils.log(`Usage Summary Interaction Activity details: ${JSON.stringify(details)}`);

            // Publish
            BwcInteractActivityPublisher.publishMessage(
                interactionId,
                BwcConstants.InteractionActivityValueMapping.ViewBANUsageSummary.action,
                JSON.stringify(details),
                null
            );

        }
        catch (error) {
            // Write any error to the log only
            BwcUtils.error('Usage Summary', 'Failed to create Interaction Activity: ' + error.message);
            BwcUtils.error('Usage Summary', error);
        }

    }

    /**
     * Adjust timezone for date
     */
    adjustForTimezone(date){
        var timeOffsetInMS = date.getTimezoneOffset() * 60000;
        date.setTime(date.getTime() + timeOffsetInMS);
        return date
    }

}