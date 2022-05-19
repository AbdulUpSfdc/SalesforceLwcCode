import { LightningElement, api, track } from 'lwc';
import * as BwcConstants from 'c/bwcConstants';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcCustomerProfileServices from 'c/bwcCustomerProfileServices';
import * as BwcInteractActivityPublisher from 'c/bwcInteractActivityPublisher';

// Custom labels
import label_subheading from '@salesforce/label/c.BWC_Security_Reset_Subheading';
import label_subheadingBoth from '@salesforce/label/c.BWC_Security_Reset_Subheading_Both';
import label_success from '@salesforce/label/c.BWC_Security_Reset_Success';
import label_successBoth from '@salesforce/label/c.BWC_Security_Reset_Success_Both';

export default class BwcSecurityReset extends LightningElement {

    isOpen = false;             // Show modal
    isBusy = false;             // Show spinner
    get errorReport() {return this.template.querySelector('c-bwc-error-report');}

    billingAccountRecord = {};
    @track user = {};
    resetBoth;
    get heading() {return this.resetBoth ? 'Reset MyAT&T Login Password and Security Q&A' : 'Reset MyAT&T Login Password';}
    get subheading() {return this.resetBoth ? label_subheadingBoth : label_subheading;}

    @track contactMethods = [];
    selectedContactMethod;

    @api async open(billingAccountRecord, user, resetBoth) {

        this.billingAccountRecord = billingAccountRecord;
        this.user = user;
        this.resetBoth = resetBoth;
        this.contactMethods = [];
        this.isOpen = true;

        // Allow render
        await BwcUtils.nextTick();

        try {

            this.errorReport.clearError();
            this.isBusy = true;

            if (user.contactInfo.error) {
                throw new Error(JSON.stringify(user.contactInfo.error));
            }

            user.contactInfo.contacts.filter(contact => !contact.error && contact.isEligible).forEach(contact => {

                switch(contact.contactType) {
                
                    case 'phone':
                        this.contactMethods.push(
                            {
                                label: 'Phone Number',
                                value: BwcUtils.formatPhone(contact.contactValue),
                                type: 'phone',
                                key: this.contactMethods.length.toString()
                            }
                        );
                        break;

                    case 'email':
                        this.contactMethods.push(
                            {
                                label: 'Email',
                                value: contact.contactValue,
                                type: 'email',
                                key: this.contactMethods.length.toString()
                            }
                        );
                        break;

                    default:
                        BwcUtils.error(`Unknown contact type "${contact.type}"`);
                        break;

                }

            });

            this.selectedContactMethod = this.contactMethods[0];
            this.contactMethods[0].selected = true;

        }
        catch(error) {
            this.errorReport.reportError(error);
        }
        finally {
            this.isBusy = false;
        }

    }
 
    close() {

        this.isOpen = false;

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

    /*
        Set selected contact method.
    */
    handleContactMethodChange(event) {

        this.contactMethods.forEach(contactMethod => {
            if (contactMethod.key === event.target.dataset.key) {
                this.selectedContactMethod = contactMethod;
                contactMethod.selected = true;
            }
            else {
                contactMethod.selected = false;
            }
        });

    }

    /*
        Call the password reset API to reset password or password + security question.
    */
    async handleSendLink() {

        try {

            this.errorReport.clearError();
            this.isBusy = true;
 
            // S for SMS or E for Email
            const deliveryMethodType = this.selectedContactMethod.type === 'phone' ? 'S' : 'E';

            // Build password reset request
            const request = {
                handle: this.user.slid,
                deliveryMethod: {
                    deliveryMethodType: deliveryMethodType,
                    methodSMS: deliveryMethodType === 'S'
                        ? {valueSMS: BwcUtils.parsePhoneToDigits(this.selectedContactMethod.value)}
                        : undefined,
                    methodEmail: deliveryMethodType === 'E'
                        ? {valueEmail: this.selectedContactMethod.value}
                        : undefined,
                    clearOnlineQA: this.resetBoth
                }
            };

            //// Dummy response for testing
            //const response = {"transactionName": "ResetUserPassword", "appStatusMsg": "SUCCESS", "appStatusCode": "0"};

            const response = await BwcCustomerProfileServices.resetPassword(request);

            if (response.appStatusCode === '0') {
                
                // Choose custom label
                const label = this.resetBoth ? label_successBoth : label_success;

                // Success, show toast
                BwcUtils.showToast(this, {
                    title: label.replace('{0}', this.billingAccountRecord.First_Name__c + ' ' + this.billingAccountRecord.Last_Name__c),
                    variant: 'success'
                });

                this.createInteractionActivity();

                this.close();

            }
            else {

                BwcUtils.error(JSON.stringify(response));
                throw new Error(response.appStatusMsg);

            }

        }
        catch(error) {
            this.errorReport.reportError(error);
        }
        finally {
            this.isBusy = false;
        }

    }

    /*
        Send messages to create interaction activity.
    */
    createInteractionActivity() {

        const recordDetail = {
            service: this.billingAccountRecord.Account_Type__c,
            serviceName: this.billingAccountRecord.Service_Name__c,
            ban: this.billingAccountRecord.Billing_Account_Number__c,
            myattUserId: this.user.aaid
        };

        let action;
        if (this.user.userLockLevel) {

            // It's being unlocked
            action = BwcConstants.InteractionActivityValueMapping.ProfileManagementMyATTUnlock.action;

        }
        else if (this.resetBoth) {

            // Resetting password and question/answer
            action = BwcConstants.InteractionActivityValueMapping.ProfileManagementMyATTResetPwdQA.action;

        }
        else {

            // Resettting just password
            action = BwcConstants.InteractionActivityValueMapping.ProfileManagementMyATTResetPwd.action;

        }

        BwcInteractActivityPublisher.publishMessage(this.billingAccountRecord.Id, action, JSON.stringify(recordDetail));

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
        if (event.target.dataset.name === 'sendLinkButton' && event.key === "Tab" && !event.shiftKey) {

            event.preventDefault();
            const closeButton = this.template.querySelector('lightning-button-icon[data-name="closeButton"');
            if (closeButton) {
                closeButton.focus();
            }

        }
        else if (event.target.dataset.name === 'closeButton' && event.key === "Tab" && event.shiftKey) {
            event.preventDefault();
            const rightButton = this.template.querySelector('lightning-button[data-name="sendLinkButton"');
            if (rightButton) {
                rightButton.focus();
            }
        }

    }

}