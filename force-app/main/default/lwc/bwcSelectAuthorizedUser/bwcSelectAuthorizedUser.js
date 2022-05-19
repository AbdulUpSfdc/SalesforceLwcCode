import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import * as BwcConstants from 'c/bwcConstants';
import * as BwcAccountServices from 'c/bwcAccountServices';
import * as BwcLabelServices from 'c/bwcLabelServices';

export default class BwcSelectAuthorizedUser extends LightningElement {

    // Labels
    labels = BwcLabelServices.labels;

    @api recordId;      // The record ID of the Billing Account

    isRendered;
    isBusy;
    isLoaded;

    @track userTableColumns = [
        {
            label: 'Name',
            fieldName: 'name',
            hideDefaultActions: true
        },
        {
            label: 'LOB',
            fieldName: 'accountType',
            hideDefaultActions: true,
            cellAttributes: {wrapText: true}
        },
        {
            label: this.labels.account,
            fieldName: 'accountId',
            hideDefaultActions: true,
            cellAttributes: {wrapText: true}
        },
        {
            label: 'User Type',
            fieldName: 'associationType',
            hideDefaultActions: true,
            cellAttributes: {wrapText: true}
        },
        {
            label: 'Action',
            type: 'actionLink',
            fieldName: 'action',
            hideDefaultActions: true,
            fixedWidth: 70,
            typeAttributes: {
                label: 'Select',
                onactionclick: this.handleUserSelect.bind(this)
            }
        }
    ];

    billingAccountRecordId;
    billingAccountRecord;

    get errorReports() {return this.template.querySelector('c-bwc-error-reports');}

    async renderedCallback() {

        if (!this.isRendered && this.recordId) {

            this.isRendered = true;

            // On first render, cause the wire service to get the billing account and subsquently get authorized users.
            this.billingAccountRecordId = this.recordId;

        }
        
    }

    /*
        Retrieve billing account record then get the authorized users.
    */
    @wire(getRecord, {recordId: '$billingAccountRecordId', 
        fields: ['Billing_Account__c.Billing_Account_Number__c', 'Billing_Account__c.Account_Type__c', 'Billing_Account__c.First_Name__c', 'Billing_Account__c.Last_Name__c']})
    async getBillingAccountRecord({error, data}) {

        if (!this.billingAccountRecordId) {
            return;
        }

        if (error) {
            this.errorReports.addError(new Error('Error reading Billing Account record.'), error);
        }
        else {

            this.billingAccountRecord = data;

            // Now that we have record we can call api to get users
            await this.getAuthorizedUsers();
 
        }

    }

    /*
        Retrieve authorized users for the billing account.
    */
    async getAuthorizedUsers() {

        try {

            this.errorReports.clearErrors();

            // Get ban and account type from the billing account record
            const ban = getFieldValue(this.billingAccountRecord, 'Billing_Account__c.Billing_Account_Number__c');
            const accountType = getFieldValue(this.billingAccountRecord, 'Billing_Account__c.Account_Type__c');

            // Make call to get authorized users
            this.isBusy = true;
            const responses = await BwcAccountServices.getUserAssociationsForBan(ban, accountType);

            // Call succeeded, process results
            this.isLoaded = true;
            this.userTableRows = [];
            responses.forEach(response => {

                if (response.record.users) {

                    response.record.users.forEach(user => {

                        this.userTableRows.push({

                            user: user,
                            name: this.buildUserName(user),
                            accountType: BwcConstants.BillingAccountType.getLabelForValue(response.accountType),
                            accountId: response.accountId,
                            associationType: user.associationType,
                            slid: user.slid,
                            iconName: user.associationType === 'OWNER' ? 'utility:record' : undefined,
                            iconAlternativeText: user.associationType === 'OWNER' ? 'Owner' : undefined,
                            action: user.slid
    
                        });

                    });

                }
                else {

                    // Error getting users -- use the primary account holder from the billing account record
                    console.error(`Error retrieving authorized users for BAN ${response.accountId}. Using primary account holder from Billing Account record. Error details follow.`);
                    console.error( response.record.errorPayload ? JSON.stringify(response.record.errorPayload) : 'No error details were returned by the API service.')

                    const user = {
                        firstName: getFieldValue(this.billingAccountRecord, 'Billing_Account__c.First_Name__c'),
                        lastName: getFieldValue(this.billingAccountRecord, 'Billing_Account__c.Last_Name__c'),
                        associationType: 'OWNER'
                    };

                    this.userTableRows.push({

                        user: user,
                        name: this.buildUserName(user),
                        accountType: BwcConstants.BillingAccountType.getLabelForValue(accountType),
                        accountId: ban,
                        associationType: user.associationType,
                        slid: user.slid,
                        iconName: 'utility:record',
                        iconAlternativeText: 'Owner',
                        action: user.slid

                    });

                }
            });
            
        }
        catch (error) {
            this.errorReports.addError(error);

        }
        finally {
            this.isBusy = false;
        }

    }

    /*
        Construct name with proper spaces if first or last is missing.
    */
    buildUserName(user) {

        if (user.firstName && user.lastName) {
            return user.firstName + ' ' + user.lastName;
        }
        else if (user.firstName) {
            return user.firstName;
        }
        return user.lastName;

    }

    /*
        Handle click on Select
    */
    async handleUserSelect(event) {

        try {

            this.isBusy = true;

            // Find the whole row
            const selectedUser = this.userTableRows.find(row => row.slid === event.detail.value).user;
            this.dispatchEvent(new CustomEvent('userselected', {detail: {selectedUser: selectedUser}}));

        }
        catch (error) {
            this.errorReports.addError(error);
        }
        finally {
          this.isBusy = false;
        }

    }

}