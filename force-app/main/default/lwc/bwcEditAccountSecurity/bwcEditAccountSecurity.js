import { api, track, wire } from 'lwc';
import { MessageContext } from 'lightning/messageService';
import { updateRecord } from 'lightning/uiRecordApi';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcAccountServices from 'c/bwcAccountServices';
import * as BwcCustomerAccountServices from 'c/bwcCustomerAccountServices';
import BwcModalBase from 'c/bwcModalBase';

// Labels
import passcode_success from '@salesforce/label/c.BWC_Security_Passcode_Update_Success';
import passcode_error from '@salesforce/label/c.BWC_Security_Passcode_Update_Error';
import question_success from '@salesforce/label/c.BWC_Security_Question_Update_Success';
import question_error from '@salesforce/label/c.BWC_Security_Question_Update_Error';

export default class BwcEditAccountSecurity extends BwcModalBase {

    // Needed to send refresh message
    @wire(MessageContext)
    messageContext;

    label = {
        passcode_success: passcode_success,
        passcode_error: passcode_error,
        question_success: question_success,
        question_error: question_error
    };

    @api recordId;
    billingAccountRecord = {};
    get securityQuestion() {return this.billingAccountRecord ? this.billingAccountRecord.Security_Question__c : '';}

    @api isFullPage;
    get modalSectionClass() {return this.isFullPage ? 'slds-modal_small full-page' : 'slds-modal slds-modal_small slds-fade-in-open';}

    @track oldValues = {};
    @track newValues = {};

    isOpen = false;             // Show modal
    isBusy = false;             // Show spinner
    get errorReport() {return this.template.querySelector('c-bwc-error-report');}

    /**
     * Modal
     */
    @api getHeaderRichText() {
        return 'Account Security';
    }

    @api getFooterButtons() {
        return [
            {
                name: 'close',
                label: 'Cancel',
                position: 'right',
                click: this.close.bind(this)
            },
            {
                name: 'updateClose',
                label: 'Update & Close',
                position: 'right',
                variant: 'brand',
                disabled: true,
                click: this.handleUpdateAndClose.bind(this)
            }
        ];
    }
    
    renderedCallback() {
        if (!this.isRendered) {
            // Perform actions on first render, that way error report component is rendered and available to show error
            this.isRendered = true;

            this.loadInfo(this.recordId);
        }
    }

    @api async loadInfo(recordId) {
        this.isOpen = true;

        // Allow render
        await BwcUtils.nextTick();

        try {

            this.errorReport.clearError();
            this.isBusy = true;

            // Get record for current security question]
            this.billingAccountRecord = await BwcAccountServices.getBillingAccountForId(recordId);

        }
        catch(error) {
            this.errorReport.reportError(error);
        }
        finally {
            this.isBusy = false;
        }
    }
  
    close() {
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

    passcodeSet = false;
    handleNewPasscodeChange(event) {
        const newPasscodeInput = event.target;

        // Check if passcode contains non-digit characters
        if(/\D/.test(newPasscodeInput.value)) {
            newPasscodeInput.setCustomValidity("4-8 digits only");
            newPasscodeInput.reportValidity();
        } else {
            newPasscodeInput.setCustomValidity("");
            newPasscodeInput.reportValidity();
        }

        // Enable/disable reenter new passcode input when starting to update passcode
        const reEnterNewPasscodeInput = this.template.querySelector(`lightning-input[data-name="reEnterNewPasscode"]`);
        if (newPasscodeInput.value.length > 0) {
            reEnterNewPasscodeInput.disabled = false;
        } else {
            reEnterNewPasscodeInput.value = '';
            reEnterNewPasscodeInput.disabled = true;
        }

        // Track if passcode has been set properly to evaluate later when update event is triggered
        if (!(/\D/.test(newPasscodeInput.value)) && newPasscodeInput.value.length >= 4) {
            this.passcodeSet = true;
        } else {
            this.passcodeSet = false;
        }
    }

    reEnterPasscodeIsValid = false;
    handleReEnterNewPasscodeChange(event) {
        const reEnterNewPasscodeInput = event.target;
        const newPasscodeInput = this.template.querySelector(`lightning-input[data-name="newPasscode"]`);

        if (reEnterNewPasscodeInput.value == newPasscodeInput.value && reEnterNewPasscodeInput.value.length == newPasscodeInput.value.length) {
            reEnterNewPasscodeInput.setCustomValidity("");
            reEnterNewPasscodeInput.reportValidity();
            this.reEnterPasscodeIsValid = true;
        } else {
            if (reEnterNewPasscodeInput.value.length >= newPasscodeInput.value.length) {
                reEnterNewPasscodeInput.setCustomValidity("Passcode does not match, please try again");
                reEnterNewPasscodeInput.reportValidity();
            }
            this.reEnterPasscodeIsValid = false;
        }

        this.setUpdateButtonsDisabled();
    }

    setUpdateButtonsDisabled() {
        let buttonStatus = this.passcodeSet && this.reEnterPasscodeIsValid && !this.isBusy;
        this.enableButton('updateClose', buttonStatus);
    }

    handleUpdate() {
        this.handlePasscodeUpdate(false);
    }

    handleUpdateAndClose() {
        this.handlePasscodeUpdate(true);
    }

    /*
        Attempt the update
    */
    async handlePasscodeUpdate(updateAndClose) {

        try {

            this.errorReport.clearError();
            this.isBusy = true;

            // Validate all inputs
            let isValid = BwcUtils.reportValidity(this.template);

            // Custom validate must have at least one method selected
            if (this.passcodeSet && !this.reEnterPasscodeIsValid) {
                isValid = false;
            } 

            let updatePasscode = this.passcodeSet && this.reEnterPasscodeIsValid;

            if (!isValid) {
                throw new Error();
            }

            // Construct request
            if (updatePasscode) {
                const newPasscode = this.template.querySelector(`lightning-input[data-name="newPasscode"]`);
                const putRequest = {
                    account: {
                        profile: {
                            accountPasscode: newPasscode.value
                        }
                    }
                };

                // Call API
                const updatePasscodeResult = await BwcCustomerAccountServices.updateAccountPasscode(this.billingAccountRecord.Billing_Account_Number__c, this.billingAccountRecord.Account_Type__c, putRequest);

                if (updatePasscodeResult.error) {
                    throw new Error(JSON.stringify(updatePasscodeResult.error));
                }

                // Update Billing Account record
                const fields = {
                    Id: this.billingAccountRecord.Id,
                    Passcode__c: newPasscode.value
                };

                await updateRecord({fields});

                this.clearPasscodeFields();
                this.setUpdateButtonsDisabled();
                BwcUtils.showToast(this, {message: this.label.passcode_success, variant: 'success'});

                if (updateAndClose) {
                    BwcUtils.showToast(this, {message: this.label.passcode_success, variant: 'success'});
                    this.close(); 
                }

            }

        }
        catch(error) {
            let errorResult = {
                "message" : this.label.passcode_error
            }
            this.reportError(errorResult);
        }
        finally {
            this.isBusy = false;
        }

    }

    clearPasscodeFields() {
        const newPasscode = this.template.querySelector(`lightning-input[data-name="newPasscode"]`);
        newPasscode.value = '';
        const reEnterNewPasscode = this.template.querySelector(`lightning-input[data-name="reEnterNewPasscode"]`);
        reEnterNewPasscode.value = '';
        reEnterNewPasscode.disabled = true;
        this.passcodeSet = false;
        this.reEnterPasscodeIsValid = false;
    }

    /*
        Handle some keypresses for entire modal.
    */
    handleModalKeydown(event) {

        switch(event.key) {

            case 'Enter':
                this.handleUpdateAndClose();
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