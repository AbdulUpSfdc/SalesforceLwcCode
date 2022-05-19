import { LightningElement, wire } from "lwc";
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";
import { MessageContext, subscribe, unsubscribe, publish, APPLICATION_SCOPE } from "lightning/messageService";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import FORM_FACTOR from "@salesforce/client/formFactor";
import * as BwcUtils from "c/bwcUtils";
import * as BwcPageHelpers from "c/bwcPageHelpers";

// Message channels

import REFRESHMC from "@salesforce/messageChannel/BWC_Refresh__c";

// Custom permissions
import hasMobileOnDesktopPermission from "@salesforce/customPermission/BWC_Mobile_On_Desktop";

/*
    Base component for "top level" LWC components, i.e. those that are placed on a flexipage.
*/
export default class BWCPageElementBase extends NavigationMixin(LightningElement) {
    @wire(CurrentPageReference)
    currentPageReference;

    @wire(MessageContext)
    messageContext;

    // Form factor helpers
    get formFactor() {
        return hasMobileOnDesktopPermission ? "Small" : FORM_FACTOR;
    }
    get isFormFactorLarge() {
        return this.formFactor === "Large";
    }
    get isFormFactorMedium() {
        return this.formFactor === "Medium";
    }
    get isFormFactorSmall() {
        return this.formFactor === "Small";
    }

    subscriptions = []; // Manage subscriptions to auto-release on disconnect

    /*
        Derived class should call super.connectedCallback if it overrides this.
    */
    connectedCallback() {
        // By default, subscribe to refresh since most components should act on a refresh.
        // Derived class can just override handleLmsRefresh.
        this.subscribeToMessage(
            REFRESHMC,
            (message) => {
                this.handleLmsRefresh(message.scope, message.recordId);
            },
            true
        );
    }

    /*
        Derived class should call super.disconnectedCallback if it overrides this.
    */
    disconnectedCallback() {
        // Unsubscribe from any LMS subscriptions.
        this.subscriptions.forEach((subscription) => {
            unsubscribe(subscription);
        });
    }

    /*
        Subscribe to an LMS message channel.
    */
    subscribeToMessage(messageChannel, callback, isApplicationScope) {
        const subscription = subscribe(
            this.messageContext,
            messageChannel,
            callback,
            isApplicationScope ? { scope: APPLICATION_SCOPE } : undefined
        );
        this.subscriptions.push(subscription);
    }

    /*
        Unsubscribe from an LMS message channel subscription.
    */
    unsubscribeFromMessage(subscription) {
        unsubscribe(subscription);
        const index = this.subscriptions.findIndex((sub) => sub === subscription);
        if (index !== -1) {
            this.subscriptions.splice(index, 1);
        }
    }

    /*
        Publish a message to an LMS message channel.
    */
    publishMessage(messageChannel, message) {
        publish(this.messageContext, messageChannel, message);
    }

    /*
        Easily send a refresh message for other components to handle.
    */
    sendLmsRefresh(recordId, scope) {
        this.publishMessage(REFRESHMC, { scope, recordId });
    }

    /*
        Derived class overrides this to handle refresh message.
    */
    // eslint-disable-next-line no-unused-vars
    handleLmsRefresh(scope, recordId) {}

    /*
        Use navigate service to navigate to specified page reference.
    */
    navigate(pageReference) {
        this[NavigationMixin.Navigate](pageReference);
    }

    /*
        Open the specified page reference in a subtab, if on desktop. Otherwise navigate to the page.
    */
    openSubtab(pageReference, label, icon) {
        if (this.isFormFactorLarge) {
            BwcPageHelpers.openSubtab(pageReference, label, icon);
        } else {
            // We are not on desktop, so no sub-tab, just navigate to page reference
            this.navigate(pageReference);
        }
    }

    /*
        Open specified page in a new browser tab.
    */
    openNewTab(url) {
        // Just open new tab
        window.open(url, "_blank");
    }

    /*
        Close the focused console tab. If one mobile, navigate to homepage instead.
    */
    closeFocusedTab() {
        if (this.isFormFactorLarge) {
            BwcPageHelpers.closeFocusedTab();
        } else {
            // Not in console, just navigate to home.
            this.navigate({
                type: "standard__namedPage",
                attributes: {
                    pageName: "home"
                }
            });
        }
    }

    /*
        Fire event to show toast.
    */
    showToast(title, message, variant, mode) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant, mode }));
    }

    /*
        Add any notification, page template must include c-bwc-notifications component.
    */
    addNotification(type, message, variant, action, texture, theme) {
        const notificationsComponent = this.template.querySelector("c-bwc-notifications");
        if (notificationsComponent) {
            notificationsComponent.addNotification(type, message, variant, null, action, texture, theme);
        } else {
            BwcUtils.warn("No bwc-notifications component found, notification could not be displayed.");
        }
    }

    /*
        Add a scoped notification, page template must include c-bwc-notifications component.
    */
    addScopedNotification(message, variant, texture, theme ) {
        this.addNotification("scoped", message, variant, undefined, texture, theme);
    }

    /*
        Add an inline notification, page template must include c-bwc-notifications component.
    */
    addInlineNotification(message, variant) {
        this.addNotification("inline", message, variant);
    }

    /*
        Remove all notifications from c-bwc-notifications component.
    */
    clearNotifications() {
        const notificationsComponent = this.template.querySelector("c-bwc-notifications");
        if (notificationsComponent) {
            notificationsComponent.clearNotifications();
        }
    }

    /*
        Returns true if there is at least one notification with variant == error.
    */
    get hasErrorNotifications() {
        const notificationsComponent = this.template.querySelector("c-bwc-notifications");
        if (notificationsComponent) {
            return notificationsComponent.hasErrorNotifications;
        }
        return false;
    }

    /*
        Use notifications component on component to display error to user.
    */
    handleError(error, message, context, notificationType, action) {

        let errorToLog;
        if (error?.body?.message && error.body.message.startsWith('{')) {
            try {
                errorToLog = JSON.parse(error.body.message);
            }
            catch(e) {                
                errorToLog = error;
            }
        }
        else {
            errorToLog = error;
        }

        // Always show in console.
        if (context) {
            BwcUtils.error('Error in ' + context, errorToLog);
        }
        else {
            BwcUtils.error(errorToLog);
        }

        let finalMessage;
        if (message) {
            finalMessage = message;
        }
        else if (error.message) {
            finalMessage = error.message;
        }
        else if (error.body) {
            finalMessage = error.body.message;
        }
        else {
            finalMessage = "An unexpected error occurred and no message is available.";
        }

        this.addNotification(notificationType ? notificationType : "scoped", finalMessage, "error", action);
    }
}