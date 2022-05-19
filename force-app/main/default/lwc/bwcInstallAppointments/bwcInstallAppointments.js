import BwcPageElementBase from 'c/bwcPageElementBase';
import { track, api } from 'lwc';
import * as BwcUtils from 'c/bwcUtils';
import { InteractionActivityValueMapping } from 'c/bwcInteractionActivityService';
import * as BwcAppointmentsService from 'c/bwcAppointmentsService';
import * as BwcAccountServices from 'c/bwcAccountServices';
import * as BwcConstants from 'c/bwcConstants';
import label_mulesoftErrorCode from '@salesforce/label/c.BWC_UnexpectedError_RefreshSection';

const COMPONENT_UI_NAME = 'Install Appointments';

export default class BwcInstallAppointments extends BwcPageElementBase {
    NO_DATA_FOUND = 'No appointments exist.';                          // Message to show when no Appointments found for autheniticated BAN
    NO_APP_FORAUTH_ACC = 'No Appointments for Authenticated Accounts.';// Message to show when no authenticated uverse BAN found
    columns = BwcAppointmentsService.COLUMNS;
    @api recordId;
    @track installAppointmentsData = [];
    sortBy;
    sortDirection;
    showSpinner = false;
    defaultSortDirection = 'desc';
    defaultSortBy = 'date';
    disableWFEButton = true;
    showSATable = false;
    showViewAll = false;
    showNoSAExistMessage = false;
    noAppointmentsForAccount = false;
    uverseBANFound = false;
    uverseBAN = '';
    isRendered;
    authorizedBans = [];
    billingAccount;

    async renderedCallback() {
        if (!this.isRendered) {
            this.isRendered = true;
            // Work around boxcarring by waiting so this component doesn't block product search from completion
            await BwcUtils.wait(BwcConstants.BOXCAR_WAIT);
            await this.getAppointments();
        }
    }

    //Collects authorized bans from interaction
    async getAppointments() {
        try {
            this.showSpinner = true;
            //const interactionRecord = await BwcInteractionServices.getInteraction(this.recordId);
            const BILLING_ACCOUNT_TYPES = [
                BwcConstants.BillingAccountType.UVERSE.value
            ];

            // Build selection list of billing accounts
            const billingAccounts = await BwcAccountServices.getBillingAccounts(this.recordId, true, false, BILLING_ACCOUNT_TYPES);
            BwcUtils.log(' bwcInstallAppointments >> billingAccounts : ' + JSON.stringify(billingAccounts));
            this.authorizedBans =
                billingAccounts.filter(billingAccount => (billingAccount.Billing_Account_Number__c !== null && billingAccount.Billing_Account_Number__c !== ""))
                    .map(billingAccount => billingAccount.Billing_Account_Number__c);
            BwcUtils.log(' bwcInstallAppointments >> Authorized BANs : ' + this.authorizedBans);

            if (this.authorizedBans.length > 0) {
                this.uverseBANFound = true;
                let sortedData = await BwcAppointmentsService.getByDefaultSortedAppointments(this.recordId, this.authorizedBans, BwcAppointmentsService.APPOINTMENT_TYPE_INSTALL, this.defaultSortBy, this.defaultSortDirection);
                this.installAppointmentsData = sortedData.slice(0, 5);
                if (this.installAppointmentsData.length > 0) {
                    this.showSATable = true;
                    this.disableWFEButton = false;
                    if (sortedData.length > 5) {
                        this.showViewAll = true;
                    }
                } else {
                    this.showNoSAExistMessage = true;
                }
            } else {
                this.noAppointmentsForAccount = true;
            }
        } catch (error) {
            super.handleError(error, label_mulesoftErrorCode, COMPONENT_UI_NAME, 'inline');
        }
        finally {
            this.showSpinner = false;
        }
    }

    //Handles refresh click
    handleRefreshAppointments() {
        this.showSATable = false;
        this.uverseBANFound = false;
        this.noAppointmentsForAccount = false;
        this.showViewAll = false;
        this.showNoSAExistMessage = false;
        this.disableWFEButton = true;
        this.installAppointmentsData = [];
        this.installAppointmentsData = [];
        this.authorizedBans = [];
        this.payload = [];
        this.getAppointments();
    }

    //Checks if user is having broadband techcare agent custom permission
    get isUserBroadbandTechCareAgent() {
        return BwcAppointmentsService.isBroadbandTechCareAgentPermission;
    }

    //Handle sorting of columns
    handleSortAppointmentsData(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortAppointmentsData(event.detail.fieldName, event.detail.sortDirection);
    }

    //Helper to support column sorting
    sortAppointmentsData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.installAppointmentsData));
        let sortedData = BwcAppointmentsService.getSortedAppointments(parseData, fieldname, direction);
        this.installAppointmentsData = sortedData;
    }

    //Navigating to BWCInstallAppointmentListWrapper component on click of View All
    handleNavigate(event) {
        const pageReference = {
            type: 'standard__component',
            attributes: {
                componentName: 'c__BWCInstallAppointmentListWrapper'
            },
            state: {
                c__recordId: this.recordId
            }
        };
        super.openSubtab(pageReference, 'Install Appointments', 'custom:custom40');
    }

    //Handles WFE tech Support button Click
    handleWFETechSupportButtonClick() {
        this.template.querySelector('c-bwc-launch-w-f-e').open(InteractionActivityValueMapping.ManageInstallAppointments, undefined, undefined, undefined, this.recordId);
    }
}