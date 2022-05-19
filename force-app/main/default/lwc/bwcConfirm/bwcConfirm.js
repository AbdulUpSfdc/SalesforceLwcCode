import { LightningElement, api, track } from 'lwc';
import * as BwcUtils from 'c/bwcUtils';

export default class BwcConfirm extends LightningElement {

    @track options = {
        title: '',
        okButtonLabel: 'Ok',
        okButtonCallback: undefined,
        cancelButtonLabel: 'Cancel',
        cancelButtonCallback: undefined,
        message: undefined,
        isReadMessage: undefined
    };

    isOpen = false;             // Show modal
    isBusy = false;             // Show spinner
    error;                      // Error being displayed

    @api async open(options) {

        this.options = options;

        this.isBusy = false;
        this.error = undefined;
        this.isOpen = true;

        // Wait for render then focus so tab is captured.
        await BwcUtils.nextTick();
        this.template.querySelector('section').focus();

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
        if (error.message) {

            const errorReport = this.template.querySelector('c-bwc-error-report');
            errorReport.reportError(error, true);

        }

    }

    /*
        Clear any displayed error.
    */
    clearError() {
        const errorReport = this.template.querySelector('c-bwc-error-report');
        errorReport.clearError();
        this.error = undefined;
    }

    async handleOk() {

        this.clearError();

        try {
            if (this.options.okCallback) {

                this.isBusy = true;
                await this.options.okCallback();
                this.close();

            }
            else {
                this.close();
            }
        }
        catch (e) {
            this.reportError(e);
        }
        finally {
            this.isBusy = false;
        }

    }

    async handleCancel() {

        this.clearError();

        try {
            if (this.options.cancelCallback) {

                this.isBusy = true;
                await this.options.cancelCallback();
                this.close();

            }
            else {
                this.close();
            }
        }
        catch (e) {
            this.reportError(e);
        }
        finally {
            this.isBusy = false;
        }

    }

    handleClose() {
        this.close();
    }

    /*
        Capture tabbing so it cycles within the modal.
    */
    onButtonKeydown(event) {

        const targetName = event.target.dataset.name;

        //If tabbing forward and this is last button, override and circle back to X button
        if ((targetName === 'okButton' || (targetName === 'cancelButton' && !this.options.okLabel))  && event.key === "Tab" && !event.shiftKey) {

            event.preventDefault();
            let closeButton = this.template.querySelector('lightning-button-icon[data-name="closeButton"');
            if (closeButton) {
                closeButton.focus();
            }

        }
        else if (targetName === 'closeButton' && event.key === "Tab" && event.shiftKey) {
            event.preventDefault();
            const rightButtonName = this.options.okLabel ? 'okButton' : 'cancelButton';
            const rightButton = this.template.querySelector(`lightning-button[data-name="${rightButtonName}"`);
            if (rightButton) {
                rightButton.focus();
            }
        }

    }

    /*
        Handle some keypresses for entire modal.
    */
    handleModalKeydown(event) {

        switch(event.key) {

            case 'Enter':
                this.handleOk();
                break;

            case 'Escape':
                this.close();
                break;

            default:
                break;

        }

    }

}