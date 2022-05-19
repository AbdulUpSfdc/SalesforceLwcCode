import { LightningElement, api, track } from 'lwc';
import * as BwcUtils from 'c/bwcUtils';

const DEFAULT_MIN_HEIGHT = 240;      // Pixels, min height of a panel, needed to manage scrolling behavior
const MODAL_CONTENT_MARGINS = 32;    // Pixels, need for calculation in conjunction with min height

export default class BwcWizard extends LightningElement {
    
    @api defaultTitle = 'Loading'; // Default title to show if steps are not loaded yet

    // Client specifies the step data.
    @api get steps() {
        return this.stepData;
    }
    set steps(value) {

        // Clone so we can change the step data
        this.stepData = BwcUtils.cloneObject(value);

        // Build map of step name to index
        this.stepData.forEach((stepData, index) => {

            this.stepNameToIndexMap[stepData.name] = index;

            // Remove any markup from title so it can display in non-rich contexts
            if (stepData.title) {
                stepData.titlePlain = stepData.title.replace(/<[^>]+>/ig, '');
            }

        });

    }

    @api isQuickAction;
    @api isFullPage;

    get modalSectionClass() {return this.isFullPage ? 'full-page' : 'slds-modal slds-fade-in-open';}

    @track stepData = [];       // Internal copy of step data
    stepNameToIndexMap = {};    // Maps step name to corresponding index in stepData

    isOpen = false;             // Show modal
    isBusy = false;             // Show spinner
    isOpening = false;          // Used to handle error during opening process
    @track error;               // Error being displayed

    @api get currentStep() {
        return this.isOpening || !this.stepData[this.currentStepIndex]
            ? {name: 'internalLoading', title: this.defaultTitle}
            : this.stepData[this.currentStepIndex];
    }
    currentStepIndex;

    // All steps not currently disabled
    get activeSteps() {return this.stepData.filter(step => !step.isDisabled);}

    get isDisabledLeftButton() {return this.isBusy || (this.currentStep.leftButton && this.currentStep.leftButton.isDisabled);}
    get isDisabledRightButton() {return this.isBusy || (this.currentStep.rightButton && this.currentStep.rightButton.isDisabled);}
    get isDisabledCancelButton() {return this.isBusy || (this.currentStep.cancelButton && this.currentStep.cancelButton.isDisabled);}
    get showLeftButton() {return this.currentStep.leftButton && !this.currentStep.leftButton.isHidden && (this.currentStep.leftButton.action || this.getPreviousEnabledStepIndex() !== undefined);}
    get showRightButton() {return this.currentStep.rightButton && !this.currentStep.rightButton.isHidden;}
    get showCancelButton() {return this.currentStep.cancelButton && !this.currentStep.cancelButton.isHidden && this.currentStep.cancelButton.action;}
    get showProgressIndicator() {return !this.isOpening && this.activeSteps && this.activeSteps.length > 1;}

    // Adjusts height attributes of modal content
    get modalContentStyle() {

        if (this.currentStep.minHeight) {

            // Overflow visible for combo box drop down
            return `min-height: ${this.currentStep.minHeight + 32}px; overflow: visible;`;

        }

        // Contents will scroll but drop-down will not be visible
        return `min-height: ${DEFAULT_MIN_HEIGHT + MODAL_CONTENT_MARGINS}; overflow: auto !important;`;

    }

    // Adjusts height attributes of panel
    get panelStyle() {
        const minHeight = (this.currentStep.minHeight ? this.currentStep.minHeight : DEFAULT_MIN_HEIGHT);
        return `min-height: ${minHeight}px;`;
    }

    /*
        Called from host component to open.
    */
    @api async open(initializeCallback) {

        this.currentStepIndex = undefined;
        this.error = undefined;

        // Allow dialog to display and show spinner
        this.isOpen = true;
        this.isOpening = true;
        this.isBusy = true;

        try {

            await BwcUtils.nextTick();

            // Hide all panels in case we're re-opening
            this.template.querySelectorAll(`div[data-panel]`).forEach(panel => {
                panel.classList.add('slds-hide');
            });

            await initializeCallback();
            this.isOpening = false;
            await this.gotoFirstEnabledStep();

        }
        catch (error) {
            this.reportError(error);
        }
        finally {
            this.isBusy = false;
        }

    }

    /*
        Close the modal.
    */
    @api async close() {

        this.isOpen = false;

        // Tells any hosting Aura component to close quick action
        this.dispatchEvent(new CustomEvent('close'));

    }

    /*
        Close X button.
    */
    handleClose() {

        this.close();

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

    /*
        Currently has an error displaying.
    */
    @api hasError() {
        return !!this.error;
    }

    /*
        Client uses to start/stop spinner.
    */
    @api setBusy(isBusy) {
        this.isBusy = isBusy;
    }

    /*
        Set the title shown in modal header for the step.
        Use to dynamically change title.
    */
    @api setStepTitle(stepName, title) {
        const stepData = this.stepData[this.stepNameToIndexMap[stepName]];
        stepData.title = title;
        if (title) {
            stepData.titlePlain = stepData.title.replace(/<[^>]+>/ig, '');
        }
    }

    /*
        Explicitly set the current step.
    */
    @api async setCurrentStep(stepName) {
        await this.setCurrentStepIndex(this.stepNameToIndexMap[stepName]);
    }

    /*
        Enable or disable a step.
    */
    @api enableStep(stepName, enable) {
        this.stepData[this.stepNameToIndexMap[stepName]].isDisabled = enable === false ? true : false;
    }

    /*
        Enable or disable a button. Value of button = 'left' or 'right'.
    */
    @api enableButton(stepName, button, enable) {
        this.stepData[this.stepNameToIndexMap[stepName]][button+'Button'].isDisabled = enable === false ? true : false;
    }

    /*
        Show or hide a button. Value of button = 'left' or 'right'.
    */
    @api showButton(stepName, button, show) {
        this.stepData[this.stepNameToIndexMap[stepName]][button+'Button'].isHidden = show === false ? true : false;
    }

    /*
        Change a button's label
    */
    @api setButtonLabel(stepName, button, label) {
        this.stepData[this.stepNameToIndexMap[stepName]][button+'Button'].label = label;
    }

    // Set the current step
    async setCurrentStepIndex(index) {

        if (index === undefined) {
            return undefined;
        }

        try {

            // Finish if needed
            if (this.currentStep.finishAction) {
                try {

                    this.isBusy = true;
                    await this.currentStep.finishAction();

                    if (!this.isOpen) {
                        // Wizard was closed by the action
                        return undefined;
                    }

                }
                finally {
                    this.isBusy = false;
                }
            }

            const oldPanelNumber = this.currentStep.panelNumber;

            this.currentStepIndex = index;

            // Wait for step panels to rerender
            await BwcUtils.nextTick();

            // Init if needed
            if (this.currentStep.initAction) {

                try {

                    this.isBusy = true;
                    await this.currentStep.initAction();

                    if (!this.isOpen) {
                        // Wizard was closed by the action
                        return undefined;
                    }

                }
                finally {
                    this.isBusy = false;
                }

            }

            // Find old and new panel divs
            const oldPanel = this.template.querySelector(`div[data-panel="${oldPanelNumber}"]`);
            const newPanel = this.template.querySelector(`div[data-panel="${this.currentStep.panelNumber}"]`);

            if (oldPanelNumber !== this.currentStep.panelNumber) {
                // Hide old, show new
                newPanel.classList.remove('slds-hide');
                if (oldPanel) {
                    oldPanel.classList.add('slds-hide');
                }
            }

            // Setup for fade-in
            newPanel.classList.remove('slds-transition-show');
            newPanel.classList.add('slds-transition-hide');

            // eslint-disable-next-line @lwc/lwc/no-async-operation
            window.setTimeout(
                () => {
                    // Complete fade-in
                    newPanel.classList.remove('slds-transition-hide');
                    newPanel.classList.add('slds-transition-show');
                }
            , 200);

        }
        catch(e) {
            this.reportError(e);
        }

        return undefined;

    }

    /*
        Find index of previous step that's not disabled.
        Returns undefined if no such step.
    */
    getPreviousEnabledStepIndex() {

        let newStepIndex = this.currentStepIndex - 1;
        while (newStepIndex >= 0 && this.stepData[newStepIndex].isDisabled) {
            newStepIndex--;
        }
        if (newStepIndex >= 0) {
            return newStepIndex;
        }
        return undefined;

    }

    /*
        Find index of next step that's not disabled.
        Returns undefined if no such step.
    */    
    getNextEnabledStepIndex() {

        let newStepIndex = this.currentStepIndex + 1;
        while (newStepIndex < this.stepData.length && this.stepData[newStepIndex].isDisabled) {
            newStepIndex++;
        }
        if (newStepIndex < this.stepData.length) {
            return newStepIndex;
        }

        return undefined;

    }

    async gotoFirstEnabledStep() {

        this.isOpening = false;

        let newStepIndex = 0;
        while (this.stepData[newStepIndex].isDisabled) {
            newStepIndex++;
        }
        await this.setCurrentStepIndex(newStepIndex);

    }

    @api async gotoPreviousEnabledStep() {
        await this.setCurrentStepIndex(this.getPreviousEnabledStepIndex());
    }

    @api async gotoNextEnabledStep() {
        await this.setCurrentStepIndex(this.getNextEnabledStepIndex());
    }

    async handleLeftButtonClick() {

        try {

            this.clearError();

            const startingStepIndex = this.currentStepIndex;

            if (this.currentStep.leftButton.action) {

                // There's an action, run it.
                this.isBusy = true;
                await this.currentStep.leftButton.action();

                if (!this.isOpen) {
                    // Wizard was closed by the action
                    return;
                }

            }

            if (this.currentStepIndex !== startingStepIndex) {

                // Action changed the step, go no further
                return;

            }

            if (this.getPreviousEnabledStepIndex() !== undefined) {

                // Move back
                await this.gotoPreviousEnabledStep();

            }
            else if (!this.currentStep.leftButton.action) {

                // We're on first step -- any Left button closes by default if no action
                // (If there's action, it's responsible for closing or doing whatever other action.)
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

    async handleRightButtonClick() {

        try {

            this.clearError();

            const startingStepIndex = this.currentStepIndex;

            if (this.currentStep.rightButton.action) {

                // There's an action, run it.
                this.isBusy = true;
                await this.currentStep.rightButton.action();

                if (!this.isOpen) {
                    // Wizard was closed by the action
                    return;
                }

            }

            if (this.currentStepIndex !== startingStepIndex) {

                // Action changed the step, go no further
                return;

            }

            if (this.getNextEnabledStepIndex() !== undefined) {

                // Move forward
                await this.gotoNextEnabledStep();

            }
            else if (!this.currentStep.rightButton.action) {

                // We're on last step -- Right button closes by default if no action.
                // (If there's action, it's responsible for closing or doing whatever other action.)
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

    async handleCancelButtonClick() {

        try {

            this.clearError();

            if (this.currentStep.cancelButton.action) {

                // There's an action, run it.
                this.isBusy = true;
                await this.currentStep.cancelButton.action();

                if (!this.isOpen) {
                    // Wizard was closed by the action
                    return;
                }

            }

        }
        catch (e) {
            this.reportError(e);
        }
        finally {
            this.isBusy = false;
        }

    }
    
    /*
        Capture tabbing so it cycles within the modal.
    */
    onButtonKeydown(event) {

        if (!this.isFullPage) {

            //If tabbing forward and this is last button, override and circle back to X button
            if (event.target.dataset.name === 'rightButton' && event.key === "Tab" && !event.shiftKey) {

                event.preventDefault();
                let closeButton = this.template.querySelector('lightning-button-icon[data-name="closeButton"');
                if (closeButton) {
                    closeButton.focus();
                }

            }
            else if (event.target.dataset.name === 'closeButton' && event.key === "Tab" && event.shiftKey) {
                event.preventDefault();
                let rightButton = this.template.querySelector('lightning-button[data-name="rightButton"');
                if (rightButton) {
                    rightButton.focus();
                }
            }

        }

    }

}