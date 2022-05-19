import { LightningElement, api, track } from "lwc";

/*
    Provides different informational, warning, or error messages in a component.
*/
export default class BwcNotification extends LightningElement {
    _type; // inline, scoped, validation
    @api get type() {
        return this._type ? this._type : "scoped";
    }
    set type(value) {
        this._type = value;
    }

    _variant; // success, info, warning, error
    @api get variant() {
        return this._variant ? this._variant : "info";
    }
    set variant(value) {
        this._variant = value;
    }

    _theme; // light, dark
    @api get theme() {
        return this._theme ? this._theme : "dark";
    }
    set theme(value) {
        this._theme = value;
    }

    _texture; // alert
    @api get texture() {
        return this._texture;
    }
    set texture(value) {
        this._texture = value;
    }

    _alignment;
    @api get alignment() {
        return this._alignment;
    }
    set alignment(value) {
        this._alignment = value;
    }

    _message; // Notification text displayed
    @api get message() {
        return this._message;
    }
    set message(value) {
        this._message = value;
        this.refreshDisplayItems();
    }

    // Hyperlink action shown after the message. This is an object with properties:
    //    name:     Unique name for the action
    //    message:  Text to show for the hyperlink
    //    href:     HREF to navigate to
    //    icon:     Details to display icon
    //    context:  Can add any other properties needed to manage the activity, i.e. Interaction ID, Billing Account ID, etc
    _action;
    @api get action() {
        return this._action;
    }
    set action(value) {
        this._action = value;
        this.refreshDisplayItems();
    }

    // Allows muliple instances of a message and action to be specified -- so that one notification can contain multiple hyperlink actions
    _items;
    @api get items() {
        return this._items;
    }
    set items(value) {
        this._items = value;
        this.refreshDisplayItems();
    }

    // This is the final list of items displayed within the notification. Each one can be a message and optionally followed by a clickable action.
    @track displayItems = [];

    _closeButton = false; // true, false
    @api get closeButton() {
        return this._closeButton;
    }
    set closeButton(value) {
        this._closeButton = value;
    }

    // Use to provide standalone validity component
    _customValidity;

    // Don't show left icon
    @api hideIcon;

    get isTypeInline() {
        return this.type === "inline";
    }
    get isTypeScoped() {
        return this.type === "scoped";
    }
    get isTypeValidation() {
        return this.type === "validation";
    }
    get showTypeInline() {
        return (this.message || this._items) && this.isTypeInline;
    }
    get showTypeScoped() {
        return (this.message || this._items) && this.isTypeScoped;
    }
    get showTypeValidation() {
        return (this.message || this._items) && this.isTypeValidation;
    }
    get showCloseButton() {
        return this.closeButton;
    }

    // Get text color class for inline.
    get inlineClass() {
        switch (this.variant) {
            case "error":
                return "slds-text-color_error";
            default:
                return "slds-text-color_default";
        }
    }

    // Get theme class based on variant
    get themeClass() {
        switch (this.variant) {
            case "success":
                return "slds-theme_success";
            case "error":
                return "slds-theme_error";
            case "warning":
                return "slds-theme_warning";
            default:
                if (this.theme === 'light') {
                    return "slds-scoped-notification_light";
                }
                return "slds-theme_info";
        }
    }

    // Get texture class based on texture
    get textureClass() {
        switch (this.texture) {
            case "alert":
                return "slds-theme_alert-texture";

            default:
                return "";
        }
    }

    get alignmentClass() {
        switch (this.alignment) {
            case "right":
                return "slds-grid_align-end";
            default:
                return "slds-grid_align-start";
        }
    }

    // Get theme icon based on variant
    get iconName() {
        return `utility:${this.variant}`;
    }

    get iconVariant() {
        return this.theme === 'dark' ? 'inverse' : undefined;
    }

    // Class for scoped -- includes the theme
    get scopedClass() {
        return `slds-scoped-notification slds-media slds-media_center full-width slds-grid ${this.themeClass} ${this.textureClass}`;
    }

    get validationClass() {
        return `full-width slds-var-m-top_x-small slds-grid slds-grid_vertical-align-center ${this.alignmentClass}`;
    }

    /*
        Set the final list of items displayed within the notification.
    */
    refreshDisplayItems() {

        this.displayItems = [];

        // Include explicit message + action
        if (this.message) {
            this.displayItems.push(
                {
                    message: this.message,
                    action: this.action,
                    icon: this.icon,
                    index: "0"
                }
            );
        }

        // Include any specified items
        if (this._items) {
            this._items.forEach((item) => {

                this.displayItems.push({
                    message: item.message,
                    action: item.action,
                    index: this.displayItems.length + ""
                });

            });
        }

    }

    // Handle close notification
    showNotification = true;
    closeNotification() {
        this.showNotification = false;
    }

    /*
        User clicked on the optional hypertext action.
    */
    handleActionClick(event) {

        // Retrieve action based upon index
        const action = this.displayItems[event.target.dataset.index].action;
        this.dispatchEvent(new CustomEvent('actionclick', {detail: {action}}));

    }

    @api setCustomValidity(message) {
        this._customValidity = message;
        if (!message) {
            this._message = undefined;
        }
    }

    @api checkValidity() {
        return !this._customValidity;
    }

    @api reportValidity() {
        if (this._customValidity) {
            this._message = this._customValidity;
        }
        else {
            this._message = undefined;
        }
        return !this._customValidity;
    }

}