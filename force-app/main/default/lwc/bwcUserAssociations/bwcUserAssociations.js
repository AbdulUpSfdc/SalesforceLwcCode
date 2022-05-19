import { api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// LWC
import BwcPageElementBase from 'c/bwcPageElementBase';
import * as BwcConstants from 'c/bwcConstants';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcAccountServices from 'c/bwcAccountServices';
import * as BwcInteractActivityPublisher from 'c/bwcInteractActivityPublisher';

// Field references
import BAN_FIELD from '@salesforce/schema/Billing_Account__c.Billing_Account_Number__c';
import ACCOUNT_TYPE_FIELD from '@salesforce/schema/Billing_Account__c.Account_Type__c';
import SERVICE_NAME_FIELD from '@salesforce/schema/Billing_Account__c.Service_Name__c';

// Custom labels
import label_title from '@salesforce/label/c.BWC_UserAssociations_Title';
import label_noUsersFound from '@salesforce/label/c.BWC_UserAssociations_NoUsersFound';
import label_deleteConfirmation from '@salesforce/label/c.BWC_AuthorizedUserConfirmDelete';
import label_deleteSuccess from '@salesforce/label/c.BWC_AuthorizedUserDeleteSuccess';
import label_mulesoftErrorCode from '@salesforce/label/c.BWC_UnexpectedError_RefreshSection';

// Maximum number allowed before adding is not allowed
const MAX_USERS_ALLOWED = 10;

const COMPONENT_UI_NAME = 'Wireless Authorized Users';

/*
    Displays table of associated users for a billing account.
*/
export default class BwcUserAssociations extends BwcPageElementBase {

    label = {
        title: label_title,
        noUsersFound: label_noUsersFound
    };

    @api recordId;
    @track tableData;
    @track error;
    hasUsers=false;
    isLoading;

    subscription; // Message channel subscription

    // Get billing account to get BAN
    @wire(getRecord, { recordId: '$recordId', fields: [BAN_FIELD, ACCOUNT_TYPE_FIELD, SERVICE_NAME_FIELD] })
    billingAccount;

    get ban() {return getFieldValue(this.billingAccount.data, BAN_FIELD);}
    get accountType() {return getFieldValue(this.billingAccount.data, ACCOUNT_TYPE_FIELD);}
    get serviceName() {return getFieldValue(this.billingAccount.data, SERVICE_NAME_FIELD);}

    get showTable() {return !this.error && !this.isLoading && this.tableData && this.tableData.length !== 0;}
    get showEmpty() {return !this.error && !this.isLoading && this.tableData && this.tableData.length === 0;}

    get isDisabledAddNew() {return !this.tableData || this.tableData.length >= MAX_USERS_ALLOWED;}

    // Table columns
    columns = [
        {
            label: 'Name',
            fieldName: 'name',
            hideDefaultActions: true,
            cellAttributes: {
                iconName: {fieldName: 'iconName'},
                iconAlternativeText: {fieldName: 'iconAlternativeText'}
            }
        },
        {
            label: 'Type',
            fieldName: 'type',
            hideDefaultActions: true
        },
        {
            type: 'action', 
            typeAttributes: { rowActions: this.getRowActions}
        }

    ];

    isRendered = false;

    async renderedCallback() {

        if (!this.isRendered) {

            // Refresh on first render
            this.isRendered = true;

            // Work around boxcarring by waiting so this component doesn't block other API calls
            this.isLoading = true;
            await BwcUtils.wait(BwcConstants.BOXCAR_WAIT);
            this.refresh();

        }

    }

    handleLmsRefresh(scope, recordId) {

        if ((scope === 'authorizedUsers' || !scope) && (!recordId || recordId === this.recordId)) {
            this.refresh();
        }

    }

    getRowActions(row, doneCallback) {

        const actions = [
            {label: 'Delete Authorized User', name: 'delete'}
        ];

        doneCallback(actions);

    }

    async refresh(){

        try {

            super.clearNotifications();

            this.error = undefined;
            this.isLoading = true;

            // Call API
            const interactionId = BwcUtils.getInteractionIdFromUrl();
            const responseWrapper = await BwcAccountServices.getUserAssociationsForBillingAccount(this.recordId,interactionId);
           

            const responses = responseWrapper.responses;

            // Get users array
            const users = responses?.[0]?.record?.users;

            // Check for error in the response
            const msError = responseWrapper.rawResponse?.[0]?.record?.error;

            // There's no error in the response
            this.hasUsers = msError === undefined;

            // Error in the response
            if( msError && msError.code != BwcConstants.ERROR_CODE_404){

                const error = new Error(JSON.stringify(msError));
                super.handleError(error, label_mulesoftErrorCode, COMPONENT_UI_NAME, 'inline');
                this.hasUsers = false;
                return;

            }else if(msError?.code == BwcConstants.ERROR_CODE_404  || !users){

                // Show empty results message
                super.addInlineNotification(label_noUsersFound, 'info');
                this.hasUsers = false;

                // Empty
                this.tableData = [];

                return;
            }

            // Generate table rows
            this.tableData = users.map(user => ({

                name: user.firstName + (user.middleName ? ' ' + user.middleName : '') + ' ' + user.lastName + (user.suffix ? ' ' + user.suffix : ''),
                type: user.authUserType ? user.authUserType[0].toUpperCase() + user.authUserType.substring(1) : '', //Convert first letter to upper case
                slid: user.slid,
                iconName: user.associationType === 'OWNER' ? 'utility:record' : undefined,
                iconAlternativeText: user.associationType === 'OWNER' ? 'Owner' : undefined,
                user: user

            }));

        }
        catch (error) {

            super.handleError(error, label_mulesoftErrorCode, COMPONENT_UI_NAME, 'inline');

        }
        finally {

            this.isLoading = false;

        }
    }

    confirmDeleteUser(userRow) {

        // Build confirmation options
        const confirmOptions = {
            title: 'Confirm Delete',
            message: label_deleteConfirmation,
            okLabel: 'Delete',
            okCallback: async () => {
                await this.deleteUser(userRow)
            },
            cancelLabel: 'Cancel'
        };

        // Show confirmation modal
        this.template.querySelector('c-bwc-confirm').open(confirmOptions);

    }

    async deleteUser(userRow) {

        // Build the profile info for delete
        const userAssociation = {
            id: "1",
            accountId: this.ban,
            accountType: this.accountType,
            userType: 'retail',
            firstName: userRow.user.firstName,
            lastName: userRow.user.lastName,
            middleName: userRow.user.middleName,
            suffix: userRow.user.suffix
        };

        try {

            const deleteResponses = await BwcAccountServices.deleteUserAssociations([userAssociation]);

            if (deleteResponses[0] && deleteResponses[0].result && deleteResponses[0].result.status === 'SUCCESS') {

                // Success

                this.dispatchEvent(new ShowToastEvent({
                    message: label_deleteSuccess.replace('{0}', userRow.name),
                    variant: 'success'
                }));

                // Create interaction activity
                const activityRecordDetail = {
                    ban: this.ban,
                    service: this.accountType,
                    serviceName: this.serviceName,
                    authorizedUser: userAssociation
                };
                BwcInteractActivityPublisher.publishMessage(
                    BwcUtils.getInteractionIdFromUrl(), 
                    BwcConstants.InteractionActivityValueMapping.ProfileManagementAuthorizedusersDelete.action,
                    JSON.stringify(activityRecordDetail)
                );

                this.refresh();

            }
            else {

                // Failure
                BwcUtils.error(JSON.stringify(deleteResponses));
                this.dispatchEvent(new ShowToastEvent({
                    message: 'Unexpected error, Authorized User was NOT deleted.',
                    variant: 'error',
                    mode: 'sticky'
                }));

            }

        }
        catch(error) {

            BwcUtils.error(error);
            this.dispatchEvent(new ShowToastEvent({
                message: 'Unexpected error, Authorized User was NOT deleted.',
                variant: 'error',
                mode: 'sticky'
            }));            

        }

    }

    handleRowAction(event) {

        switch (event.detail.action.name) {

            case "delete":

                // OTP required
                this.template.querySelector('c-bwc-step-up').openForOtp(BwcUtils.getInteractionIdFromUrl(), 
                this.recordId, () => {this.confirmDeleteUser(event.detail.row);});
                break;

            default:
                BwcUtils.error('Unknown action: ' + event.detail.action.name);
                break;

        }

    }

    handleRefresh(){
        this.refresh();
    }

    handleAddNew() {

        try {

            this.error = undefined;

            // Open modal to add new user, pass it BAN and account type
            // OTP Required
            this.template.querySelector('c-bwc-step-up').openForOtp(BwcUtils.getInteractionIdFromUrl(), 
                this.recordId, () => {this.template.querySelector('c-bwc-user-association-add').open(this.billingAccount);});

        }
        catch (error) {

            this.error = error;

        }

    }

    get cardTitle(){
        return this.hasUsers ? label_title : `${label_title} (0)`;
    }

}