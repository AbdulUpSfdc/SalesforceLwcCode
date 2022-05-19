import { LightningElement, api, track } from "lwc";
import * as BwcUtils from 'c/bwcUtils';

/*
    Manages a list of notifications (error, info, warnings, etc.) displayed on a page-level component.
*/
export default class BwcNotifications extends LightningElement {
    
    // List of notification data
    @track _notifications = [];

    // Allows setting full notification list directly.
    @api get notifications() {
        return this._notifications;
    }
    set notifications(value) {
        this._notifications = value;
        this.updateDisplayNotifications();
    }

    /*
        Add a notification. Variant defaults to error for scoped and info for inline.
    */
    @api addNotification(type, message, variant, allowDuplicates, action, texture, theme) {

        if (!allowDuplicates && this._notifications.some(notification => notification.type === type && notification.message === message && notification.variant === variant)) {
            // Don't add identical notification
            return;
        }

        // Add
        this._notifications.push({
            type: type,
            message: message,
            variant: variant ? variant : type === "scoped" ? "error" : "info",
            key: this._notifications.length + "",
            action: action,
            texture: texture,
            theme: theme
        });

        this.updateDisplayNotifications();

    }

    // This is final list that is actually displayed
    @track displayNotifications = [];

    /*
        Set final display list from _notifications.
    */
    updateDisplayNotifications() {

        this.displayNotifications = [];
        if (!this._notifications) {
            return;
        }

        this._notifications.forEach(notification => {
            const addedNotification = BwcUtils.cloneObject(notification);
            addedNotification.key = this.displayNotifications.length + "";
            this.displayNotifications.push(addedNotification);
        });

    }

    /*
        Clear all notifications.
    */
    @api clearNotifications() {
        this._notifications = [];
        this.updateDisplayNotifications();
    }

    /*
        Tells whether there are currently any error notifications.
    */
    @api get hasErrorNotifications() {
        return this._notifications.some(notification => notification.variant === 'error');
    }

    /*
        Handle click from individual notification.
    */
    handleActionClick(event) {
        this.dispatchEvent(new CustomEvent('actionclick', {detail: event.detail}));
    }

}