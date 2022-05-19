import BwcPageElementBase from "c/bwcPageElementBase";

/*
    Base component for custom modals built in LWC. This works in conjunction with Aura component BWCPageHelper,
    which is a hidden component that must be on the flexipage where the modal is to be shown.

    Component that extends this class provides the body of the modal, plus data for the header and buttons.
*/
export default class BwcModalBase extends BwcPageElementBase {
    // Local copy of footer button data.
    _footerButtons;

    /*
        Get latest button data from modal body (LWC which extends bwcModalBase).
    */
    getButtonData(buttonName) {
        this._footerButtons = this.getFooterButtons();
        const buttonData = this._footerButtons.find((button) => button.name === buttonName);
        if (buttonData) {
            return buttonData;
        }
        throw new Error(`Button not found for button name '${buttonName}'.`);
    }

    /*
        Tell BWCModalFooter to refresh buttons.
    */
    updateButtons() {
        this.dispatchEvent(new CustomEvent("updatebuttons", { detail: { buttons: this._footerButtons } }));
    }

    //#region Extending component calls these to control the modal header, buttons, and closing.

    /*
        Set/update the modal header.
    */
    setHeaderRichText(headerRichText) {
        this.dispatchEvent(new CustomEvent("updateheaderrichtext", { detail: { headerRichText: headerRichText } }));
    }

    /*
        Enable a button. Also allows disable by setting enabled to false.
        This allows the single method to be used in case where a boolean variable is used to tell whether to enable or disable.
    */
    enableButton(buttonName, enabled) {
        // Enable unless explicit false enabled.
        this.getButtonData(buttonName).disabled = enabled === false;
        this.updateButtons();
    }

    /*
        Disable a button.
    */
    disableButton(buttonName) {
        this.getButtonData(buttonName).disabled = true;
        this.updateButtons();
    }

    /*
        Show a button. Also allows hide by setting shown to false.
        This allows the single method to be used in case where a boolean variable is used to tell whether to show or hide.
    */
    showButton(buttonName, shown) {
        // Enable unless explicit false shown.
        this.getButtonData(buttonName).disabled = shown === false;
        this.updateButtons();
    }

    /*
        Hide a button.
    */
    hideButton(buttonName) {
        this.getButtonData(buttonName).hidden = true;
        this.updateButtons();
    }

    /*
        Close the modal, optionally return a response to the caller.
    */
    closeModal(response) {
        this.dispatchEvent(new CustomEvent("close", { detail: response }));
    }

    //#endregion
}