import { LightningElement, api, wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import { getFieldValue } from 'lightning/uiRecordApi';
import * as BwcConstants from 'c/bwcConstants';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcAccountServices from 'c/bwcAccountServices';
import * as BwcInteractActivityPublisher from 'c/bwcInteractActivityPublisher';

// Field references
import BAN_FIELD from '@salesforce/schema/Billing_Account__c.Billing_Account_Number__c';
import ACCOUNT_TYPE_FIELD from '@salesforce/schema/Billing_Account__c.Account_Type__c';
import SERVICE_NAME_FIELD from '@salesforce/schema/Billing_Account__c.Service_Name__c';

// Message channels
import REFRESHMC from '@salesforce/messageChannel/BWC_Refresh__c';

export default class BwcUserAssociationAdd extends LightningElement {

    isOpen = false;             // Show modal
    isBusy = false;             // Show spinner
    error;

    billingAccount;
    get ban() {return getFieldValue(this.billingAccount.data, BAN_FIELD);}
    get accountType() {return getFieldValue(this.billingAccount.data, ACCOUNT_TYPE_FIELD);}
    get serviceName() {return getFieldValue(this.billingAccount.data, SERVICE_NAME_FIELD);}
    
    // User association to add
    userAssociation = {};

    // Needed to send refresh message
    @wire(MessageContext)
    messageContext;

    // Valid suffixes
    get suffixOptions() {return BwcConstants.NameSuffixes.map(suffix => ({label: suffix, value: suffix}));}

    @api async open(billingAccount) {

        this.isBusy = false;
        this.error = undefined;
        this.isOpen = true;
        this.billingAccount = billingAccount;
        this.userAssociation = {
            id: "1",
            userType: 'retail',
            accountId: this.ban,
            accountType: this.accountType
        };

        // Focus first input
        await BwcUtils.nextTick();
        this.template.querySelector('lightning-input[data-name="firstName"]').focus();

    }

    close() {
        this.isOpen = false;
    }

    /*
        Display error to user.
    */
    @api reportError(error) {

        this.error = error;

        // If there's no error message, then the error is due to field validation failures, which are already shown on the page.
        // So if there's no message, do nothing.
        if (error.message || error.body) {

            const errorReport = this.template.querySelector('c-bwc-error-report');
            errorReport.reportError(error, false);

        }

    }

    /*
        Clear any displayed error.
    */
    @api clearError() {
        const errorReport = this.template.querySelector('c-bwc-error-report');
        errorReport.clearError();
        this.error = undefined;
    }

    handleInputCommit(event) {

        this.userAssociation[event.target.name] = event.target.value;

    }

    async handleSave() {

        this.clearError();

        try {

            // Validate all inputs
            if (!BwcUtils.reportValidity(this.template.querySelector('div[data-name="inputPanel"]'))) {
                throw new Error();
            }

            this.isBusy = true;

            // Attempt the add
            const addResponses = await BwcAccountServices.addUserAssociations([this.userAssociation]);

            if (addResponses[0] && addResponses[0].result && addResponses[0].result.status === 'SUCCESS') {

                // Success
                
                // Refresh Wireless Authorized Users table
                publish(this.messageContext, REFRESHMC, {scope: 'authorizedUsers'});

                // Create interaction activity
                const activityRecordDetail = {
                    ban: this.ban,
                    service: this.accountType,
                    serviceName: this.serviceName,
                    authorizedUser: this.userAssociation
                };
                BwcInteractActivityPublisher.publishMessage(
                    BwcUtils.getInteractionIdFromUrl(),
                    BwcConstants.InteractionActivityValueMapping.ProfileManagementAuthorizedusersAdd.action,
                    JSON.stringify(activityRecordDetail)
                );

            }
            else {

                // Failure
                BwcUtils.error(JSON.stringify(addResponses));
                throw new Error('Unexpected error, Authorized User was NOT added.');

            }

            this.close();

        }

        catch (e) {

            this.reportError(e);

        }
        finally {

            this.isBusy = false;

        }

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
        if (event.target.dataset.name === 'saveButton' && event.key === "Tab" && !event.shiftKey) {

            event.preventDefault();
            const closeButton = this.template.querySelector('lightning-button-icon[data-name="closeButton"');
            if (closeButton) {
                closeButton.focus();
            }

        }
        else if (event.target.dataset.name === 'closeButton' && event.key === "Tab" && event.shiftKey) {
            event.preventDefault();
            const rightButton = this.template.querySelector('lightning-button[data-name="saveButton"');
            if (rightButton) {
                rightButton.focus();
            }
        }

    }

}