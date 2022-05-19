import { LightningElement, api, track, wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import { updateRecord } from 'lightning/uiRecordApi';
import * as BwcConstants from 'c/bwcConstants';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcAccountServices from 'c/bwcAccountServices';
import * as BwcCustomerAccountServices from 'c/bwcCustomerAccountServices';
import * as BwcInteractActivityPublisher from 'c/bwcInteractActivityPublisher';

// Message channels
import REFRESHMC from '@salesforce/messageChannel/BWC_Refresh__c';

// Labels
import label_agentScript from '@salesforce/label/c.BWC_Manage_Account_Contact_AgentScript';
import label_phoneAuth from '@salesforce/label/c.BWC_Manage_Account_Contact_Phone_Auth';
import label_emailNotify from '@salesforce/label/c.BWC_Manage_Account_Contact_Email_Notify';
import label_success from '@salesforce/label/c.BWC_Manage_Account_Contact_Success';
import label_alternatePhoneMissing from '@salesforce/label/c.BWC_Manage_Account_Contact_AltPhone';
import label_emailMissing from '@salesforce/label/c.BWC_Manage_Account_Contact_Email';
import label_methodOfContactRequired from '@salesforce/label/c.BWC_Manage_Account_Contact_Method_Required';
import label_phoneHelp from '@salesforce/label/c.BWC_Manage_Account_Contact_Phone_Help';

export default class BwcManageAccountContact extends LightningElement {

    // Needed to send refresh message
    @wire(MessageContext)
    messageContext;

    label = {
        agentScript: label_agentScript,
        phoneAuth: label_phoneAuth,
        emailNotify: label_emailNotify,
        alternatePhoneMissing: label_alternatePhoneMissing,
        emailMissing: label_emailMissing,
        phoneHelp: label_phoneHelp
    };

    @api recordId;
    billingAccountRecord = {};
    get ban() {return this.billingAccountRecord ? this.billingAccountRecord.Billing_Account_Number__c : '';}
    get accountType() {return this.billingAccountRecord ? this.billingAccountRecord.Account_Type__c : '';}
    get serviceName() {return this.billingAccountRecord ? this.billingAccountRecord.Service_Name__c : '';}
    get customerName() {return this.billingAccountRecord ? this.billingAccountRecord.First_Name__c + ' ' + this.billingAccountRecord.Last_Name__c : '';}
    get billingAddress() {return this.billingAccountRecord ? this.billingAccountRecord.Billing_Address__c : '';}

    @api isFullPage;
    get modalSectionClass() {return this.isFullPage ? 'slds-modal_small full-page' : 'slds-modal slds-modal_small slds-fade-in-open';}

    @track oldValues = {};
    @track newValues = {};
    isAlternatePhoneRequired;
    isEmailRequired;
    isEmailVerified;
    isInvalidPrimaryPhoneNumber;
    isInvalidAlternatePhoneNumber;
    isPrimaryPhoneAuthChecked;
    isAlternatePhoneAuthChecked;
    primaryMethodError;
    alternateMethodError;
    get isDisabledPrimaryMethods() {return this.isInvalidPrimaryPhoneNumber || !this.isPrimaryPhoneAuthChecked;}
    get isDisabledAlternateMethods() {return this.isInvalidAlternatePhoneNumber || !this.isAlternatePhoneAuthChecked;}

    isOpen = false;             // Show modal
    isBusy = false;             // Show spinner
    get errorReport() {return this.template.querySelector('c-bwc-error-report');}

    isRendered = false;

    renderedCallback() {

        if (!this.isRendered) {

            // Perform actions on first render, that way error report component is rendered and available to show error
            this.isRendered = true;

            if (this.isFullPage) {
                // Calling from quick action modal -- open immediately
                this.open(this.recordId);
            }
    
        }

    }

    @api async open(recordId) {

        this.isOpen = true;

        // Reset all values
        this.oldValues = {};
        this.newValues = {};
        this.isValidPrimaryPhoneNumber = false;
        this.isInvalidPrimaryPhoneNumber = true;
        this.isInvalidAlternatePhoneNumber = true;

        // Allow render
        await BwcUtils.nextTick();

        try {

            this.errorReport.clearError();
            this.isBusy = true;

            // Get record for name and address
            this.billingAccountRecord = await BwcAccountServices.getBillingAccountForId(recordId);

            // Get billing details
            const interactionId = BwcUtils.getInteractionIdFromUrl();
            const accountDetails = await BwcCustomerAccountServices.getAccountDetailsForBillingAccountRecord(this.recordId,interactionId);

            // Pull phones and email
            accountDetails.details.contactInfo.contacts.forEach(contactInfo => {

                switch (contactInfo.contactType) {

                    case 'phone':
                        if (contactInfo.isPrimary) {
                            this.oldValues.primaryPhoneNumber = BwcUtils.formatPhone(contactInfo.contactValue);
                            this.isInvalidPrimaryPhoneNumber = false;
                        }
                        else {
                            this.oldValues.alternatePhoneNumber = BwcUtils.formatPhone(contactInfo.contactValue);
                            this.isInvalidAlternatePhoneNumber = false;
                        }
                        break;

                    case 'email':
                        if (contactInfo.isPrimary) {
                            this.oldValues.emailAddress = contactInfo.contactValue;
                            this.isEmailVerified = contactInfo.isVerified;
                        }
                        break;

                    default:
                        BwcUtils.error(`Unknown contactType "${contactInfo.contactType}"`);
                        break;

                }

            });

            this.isAlternatePhoneRequired = !!this.oldValues.alternatePhoneNumber;
            this.isEmailRequired = false; // May change later

            // Pull contact preferences -- they have type of SERVICEALERTS
            if (accountDetails.notifPreferences.preferences) {
                accountDetails.notifPreferences.preferences.filter(pref => pref.notificationType === 'SERVICEALERTS').forEach(pref => {

                    if (pref.phoneNumberType === 'primary' && pref.notificationPhoneNumber === this.oldValues.primaryPhoneNumber) {
                        // Found alert for primary phone, set contact methods
                        this.oldValues.primaryPhoneNumberCall = pref.notifyByPhone;
                        this.oldValues.primaryPhoneNumberSms = pref.notifyBySMS;

                    }
                    else if (pref.phoneNumberType === 'secondary' && pref.notificationPhoneNumber === this.oldValues.alternatePhoneNumber) {
                        // Found alert for alternate phone, set contact methods
                        this.oldValues.alternatePhoneNumberCall = pref.notifyByPhone;
                        this.oldValues.alternatePhoneNumberSms = pref.notifyBySMS;
                    }

                });
            }

            // If there are already contact methods, then consent is initialized to checked
            if (this.oldValues.primaryPhoneNumberCall || this.oldValues.primaryPhoneNumberSms) {
                this.isPrimaryPhoneAuthChecked = true;
            }
            if (this.oldValues.alternatePhoneNumberCall || this.oldValues.alternatePhoneNumberSms) {
                this.isAlternatePhoneAuthChecked = true;
            }

            this.newValues = BwcUtils.cloneObject(this.oldValues);

        }
        catch(error) {
            this.errorReport.reportError(error);
        }
        finally {
            this.isBusy = false;
        }

    }
 
    close() {

        //this.isOpen = false;
        this.dispatchEvent(new CustomEvent("close"));

    }

    /*
        Display error to user.
    */
    reportError(error) {

        this.error = error;

        // If there's no error message, then the error is due to field validation failures, which are already shown on the page.
        // So if there's no message, do nothing.
        if (error.message || error.body) {

            const errorReport = this.template.querySelector('c-bwc-error-report');
            errorReport.reportError(error, false);

        }

    }

    handleInputCommit(event) {

        // Do custom validations
        switch(event.target.name) {

            case 'primaryPhoneNumber':
                BwcUtils.validatePhone(event.target);
                this.isInvalidPrimaryPhoneNumber = !event.target.checkValidity();
                break;

            case 'alternatePhoneNumber':
                BwcUtils.validatePhone(event.target);
                this.isInvalidAlternatePhoneNumber = !event.target.checkValidity();
                break;

            default:
                break;

        }

        // Check validity and don't proceed if not valid.
        if (!event.target.checkValidity()) {
            return;
        }

        // Process updates
        switch(event.target.name) {

            case 'primaryPhoneNumber':
                this.newValues.primaryPhoneNumber = event.target.value;
                break;

            case 'alternatePhoneNumber':
                this.newValues.alternatePhoneNumber = event.target.value;
                break;

            case 'emailAddress':
                this.newValues.emailAddress = event.target.value;
                break;

            default:
                break;

        }

    }

    /*
        Click of an authorization checkbox.
    */
    handleAuthChange(event) {
        
        switch (event.target.dataset.name) {

            case 'primaryPhoneAuth':
                this.setPrimaryPhoneAuth();
                break;

            case 'alternatePhoneAuth':
                this.setAlternatePhoneAuth();
                break;

            default:
                break;


        }
    }

    /*
        Handle clicking on checkbox label, because "for" attribute with separate label doesn't work with lightning-input.
    */
    handleLabelClick(event) {

        const forName = event.target.dataset.for;
        const checkbox = this.template.querySelector(`lightning-input[data-name="${forName}"]`);

        switch (forName) {

            case 'primaryPhoneAuth':

                if (!this.isInvalidPrimaryPhoneNumber) {
                    checkbox.checked = !checkbox.checked;
                    checkbox.focus();
                    this.setPrimaryPhoneAuth();
                }
                break;

            case 'alternatePhoneAuth':

                if (!this.isInvalidAlternatePhoneNumber) {
                    checkbox.checked = !checkbox.checked;
                    checkbox.focus();
                    this.setAlternatePhoneAuth();
                }
                break;

            default:
                break;

        }

    }

    handleMethodOfContactChange(event) {

        switch (event.target.name) {

            case 'primaryPhoneNumberCall':
                this.newValues.primaryPhoneNumberCall = event.target.checked;
                if (!this.newValues.primaryPhoneNumberCall) {
                    this.newValues.primaryPhoneNumberSms = true;
                }
                break;

            case 'primaryPhoneNumberSms':
                this.newValues.primaryPhoneNumberSms = event.target.checked;
                if (!this.newValues.primaryPhoneNumberSms) {
                    this.newValues.primaryPhoneNumberCall = true;
                }
                break;

            case 'alternatePhoneNumberCall':
                this.newValues.alternatePhoneNumberCall = event.target.checked;
                if (!this.newValues.alternatePhoneNumberCall) {
                    this.newValues.alternatePhoneNumberSms = true;
                }
                break;

            case 'alternatePhoneNumberSms':
                this.newValues.alternatePhoneNumberSms = event.target.checked;
                if (!this.newValues.alternatePhoneNumberSms) {
                    this.newValues.alternatePhoneNumberCall = true;
                }
                break;

            default:
                break;
            
        }
        
    }

    setPrimaryPhoneAuth() {
     
        const input = this.template.querySelector('lightning-input[data-name="primaryPhoneAuth"]');
        this.isPrimaryPhoneAuthChecked = input.checked;
        this.primaryMethodError = undefined;
        if (!this.isPrimaryPhoneAuthChecked) {
            // Consent is not checked -- clear methods
            this.newValues.primaryPhoneNumberCall = false;
            this.newValues.primaryPhoneNumberSms = false;
        }

    }

    setAlternatePhoneAuth() {
     
        const input = this.template.querySelector('lightning-input[data-name="alternatePhoneAuth"]');
        this.isAlternatePhoneAuthChecked = input.checked;
        this.alternateMethodError = undefined;
        if (!this.isAlternatePhoneAuthChecked) {
            // Consent is not checked -- clear methods
            this.newValues.alternatePhoneNumberCall = false;
            this.newValues.alternatePhoneNumberSms = false;
        }

    }

    /*
        Attempt the update
    */
    async handleUpdate() {

        try {

            this.errorReport.clearError();
            this.isBusy = true;

            // Validate all inputs
            let isValid = BwcUtils.reportValidity(this.template);

            // Custom validate must have at least one method selected
            if (this.isPrimaryPhoneAuthChecked && !this.newValues.primaryPhoneNumberCall && !this.newValues.primaryPhoneNumberSms) {
                this.primaryMethodError = label_methodOfContactRequired;
                isValid = false;
            }
            else {
                this.primaryMethodError = undefined;
            }
            if (this.isAlternatePhoneAuthChecked && !this.newValues.alternatePhoneNumberCall && !this.newValues.alternatePhoneNumberSms) {
                this.alternateMethodError = label_methodOfContactRequired;
                isValid = false;
            }
            else {
                this.alternateMethodError = undefined;
            }

            if (!isValid) {
                throw new Error();
            }

            // Construct request
            const putRequest = {
                account: {
                    details: {
                        contactInfo: [
                            {
                                contactType: 'phone',
                                contactValue: BwcUtils.parsePhoneToDigits(this.newValues.primaryPhoneNumber),
                                isPrimary: true
                            },
                            {
                                contactType: 'email',
                                contactValue: this.newValues.emailAddress,
                                isPrimary: true
                            }
                        ]
                    },             
                    notifPreferences: {
                        preferences: [
                            {
                                notificationType: 'SERVICEALERTS',
                                phoneNumberType: 'primary',
                                notifyByPhone: !!this.newValues.primaryPhoneNumberCall,
                                notifyBySMS: !!this.newValues.primaryPhoneNumberSms
                            }
                        ]
                    }
                }
            };

            if (this.newValues.alternatePhoneNumber) {

                putRequest.account.details.contactInfo.push({
                    contactType: 'phone',
                    contactValue: BwcUtils.parsePhoneToDigits(this.newValues.alternatePhoneNumber),
                    isPrimary: false
                });

                putRequest.account.notifPreferences.preferences.push({
                    notificationType: 'SERVICEALERTS',
                    phoneNumberType: 'secondary',
                    notifyByPhone: this.isAlternatePhoneAuthChecked && !!this.newValues.alternatePhoneNumberCall,
                    notifyBySMS: this.isAlternatePhoneAuthChecked && !!this.newValues.alternatePhoneNumberSms
                });

            }

            // Call API
            const putBillingInfoResult = await BwcCustomerAccountServices.putBillingInfo(this.ban, this.accountType, putRequest);

            if (putBillingInfoResult.error) {
                throw new Error(JSON.stringify(putBillingInfoResult.error));
            }

            // Generate interaction activities for changes
            this.createInteractionActivities();

            // Update Billing Account record
            const fields = {
                Id: this.billingAccountRecord.Id,
                Contact_Number__c: this.newValues.primaryPhoneNumber,
                Alternate_Phone_Number__c: this.newValues.alternatePhoneNumber,
                Email__c: this.newValues.emailAddress
            };

            await updateRecord({fields});

            if (putBillingInfoResult.preferencesUpdateResult.error) {

                // Partial success, show toast
                BwcUtils.error(JSON.stringify(putBillingInfoResult.preferencesUpdateResult.error));
                const label_partialSuccess = 'Updates to phone numbers and email address for {0} were saved but any Method of Contact changes were NOT saved.';
                BwcUtils.showToast(this, {
                    title: label_partialSuccess.replace('{0}', this.customerName),
                    variant: 'warning',
                    mode: 'sticky'
                });                

            }
            else {

                // Full success, show toast
                BwcUtils.showToast(this, {
                    title: label_success.replace('{0}', this.customerName),
                    variant: 'success'
                });

            }

            // Tell all to refresh
            publish(this.messageContext, REFRESHMC, {scope: 'accountContact', recordId: this.recordId});

            this.close();

        }
        catch(error) {
            this.reportError(error);
        }
        finally {
            this.isBusy = false;
        }

    }

    /*
        Send messages to create interaction activities.
    */
    createInteractionActivities() {

        if (this.oldValues.primaryPhoneNumber !== this.newValues.primaryPhoneNumber ||
            this.oldValues.alternatePhoneNumber !== this.newValues.alternatePhoneNumber) {

            // CBR Phone number changed

            const recordDetail = {
                service: this.accountType,
                serviceName: this.serviceName,
                ban: this.ban
            };

            if (this.oldValues.primaryPhoneNumber !== this.newValues.primaryPhoneNumber) {
                recordDetail.primaryPhoneNumber = {
                    currentValue: !this.newValues.primaryPhoneNumber ? '' : this.newValues.primaryPhoneNumber,
                    oldValue: !this.oldValues.primaryPhoneNumber ? '' : this.oldValues.primaryPhoneNumber
                };
            }

            if (this.oldValues.alternatePhoneNumber !== this.newValues.alternatePhoneNumber) {
                recordDetail.secondaryPhoneNumber = {
                    currentValue: !this.newValues.alternatePhoneNumber ? '' : this.newValues.alternatePhoneNumber,
                    oldValue: !this.oldValues.alternatePhoneNumber ? '' : this.oldValues.alternatePhoneNumber
                };
            }

            BwcInteractActivityPublisher.publishMessage(
                this.billingAccountRecord.Id,
                BwcConstants.InteractionActivityValueMapping.ProfileManagementChangecontactinfoCBR.action,
                JSON.stringify(recordDetail)
            );

        }

        if (this.oldValues.emailAddress !== this.newValues.emailAddress) {

            // Email Address Changed

            const recordDetail = {
                service: this.accountType,
                serviceName: this.serviceName,
                ban: this.ban,
                emailAddress: {
                    currentValue: this.newValues.emailAddress,
                    oldValue: this.oldValues.emailAddress
                }
            };

            BwcInteractActivityPublisher.publishMessage(
                this.billingAccountRecord.Id,
                BwcConstants.InteractionActivityValueMapping.ProfileManagementChangecontactinfoEmail.action,
                JSON.stringify(recordDetail)
            );

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
        if (event.target.dataset.name === 'updateButton' && event.key === "Tab" && !event.shiftKey) {

            event.preventDefault();
            const closeButton = this.template.querySelector('lightning-button-icon[data-name="closeButton"');
            if (closeButton) {
                closeButton.focus();
            }

        }
        else if (event.target.dataset.name === 'closeButton' && event.key === "Tab" && event.shiftKey) {
            event.preventDefault();
            const rightButton = this.template.querySelector('lightning-button[data-name="updateButton"');
            if (rightButton) {
                rightButton.focus();
            }
        }

    }
    
}