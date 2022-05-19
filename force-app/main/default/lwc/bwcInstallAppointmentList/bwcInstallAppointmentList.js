import BwcPageElementBase from 'c/bwcPageElementBase';
import { wire } from 'lwc';
import { CurrentPageReference } from "lightning/navigation";
import * as BwcAppointmentsService from 'c/bwcAppointmentsService';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcConstants from 'c/bwcConstants';
import * as BwcAccountServices from 'c/bwcAccountServices';
import { InteractionActivityValueMapping } from 'c/bwcInteractionActivityService';
import label_mulesoftErrorCode from '@salesforce/label/c.BWC_UnexpectedError_RefreshSection';

const COMPONENT_UI_NAME = 'Install Appointments List';

export default class BwcInstallAppointmentList extends BwcPageElementBase {
    authorizedBans = [];
    authorizedUverseBANCount = 0;
    billingAccount;
    columns = BwcAppointmentsService.COLUMNS;
    deafultSortDirection = 'desc';
    installAppointmentsDataForTable = [];
    interactionId;
    sortBy = 'date';
    sortDirection;
    selectedBillingAccountNumber;
    showSpinner = false;
    uverseBANFound = false;

    @wire(CurrentPageReference)
    pageRef;

    async connectedCallback() {
        this.interactionId = this.pageRef.state.c__recordId;
        await this.getAppointments();
    }

    //collects authorized bans from interaction
    async getAppointments() {
        try {
            this.showSpinner = true;
            const BILLING_ACCOUNT_TYPES = [
                BwcConstants.BillingAccountType.UVERSE.value
            ];

            // Build selection list of billing accounts
            const billingAccounts = await BwcAccountServices.getBillingAccounts(this.interactionId, true, false, BILLING_ACCOUNT_TYPES);
            BwcUtils.log(' bwcInstallAppointments >> billingAccounts : ' + JSON.stringify(billingAccounts));
            this.authorizedBans =
                billingAccounts.filter(billingAccount => (billingAccount.Billing_Account_Number__c !== null && billingAccount.Billing_Account_Number__c !== ""))
                    .map(billingAccount => billingAccount.Billing_Account_Number__c);
            BwcUtils.log(' bwcInstallAppointments >> Authorized BANs : ' + this.authorizedBans);
            if (this.authorizedBans.length > 0) {
                this.uverseBANFound = true;
                this.installAppointmentsDataForTable = await BwcAppointmentsService.getByDefaultSortedAppointments(this.interactionId, this.authorizedBans, BwcAppointmentsService.APPOINTMENT_TYPE_INSTALL, this.sortBy, this.sortDirection);
                BwcUtils.log('installAppointmentsDataForTable' + installAppointmentsDataForTable);
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

    //Checks if user is having broadband techcare agent custom permission
    get isUserBroadbandTechCareAgent() {
        return BwcAppointmentsService.isBroadbandTechCareAgentPermission;
    }

    //Handling sorting event on data table columns for Install Appointments
    handleSortAppointmentsData(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortAppointmentsData(event.detail.fieldName, event.detail.sortDirection);
    }

    // Method to sort appointments
    sortAppointmentsData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.installAppointmentsDataForTable));
        let sortedData = BwcAppointmentsService.getSortedAppointments(parseData, fieldname, direction);
        this.installAppointmentsDataForTable = sortedData;
    }

    //Handles WFE tech Support button Click
    handleWFETechSupportButtonClick() {
        this.template.querySelector('c-bwc-launch-w-f-e').open(InteractionActivityValueMapping.ManageInstallAppointments, undefined, undefined, undefined, this.interactionId);
    }
}