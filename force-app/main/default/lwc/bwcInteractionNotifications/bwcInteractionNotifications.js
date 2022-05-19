import { api, track } from 'lwc';
import BwcPageElementBase from 'c/bwcPageElementBase';
import * as BwcConstants from 'c/bwcConstants';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcInteractionServices from 'c/bwcInteractionServices';
import * as BwcPayments from 'c/bwcPayments';

/*
    Displays zero or more notifications at the top of the interaction flexipage.
*/
export default class BwcInteractionNotifications extends BwcPageElementBase {

    @api recordId;

    isRendered;
    isLoaded;
    @track notifications = [];

    /*
        Get notifications on first render.
    */
    async renderedCallback() {

        if (!this.isRendered) {
            this.isRendered = true;

            // Work around boxcarring by waiting so this component doesn't block product search from completion
            await BwcUtils.wait(BwcConstants.BOXCAR_WAIT);
            this.refresh();

        }

    }

    async refresh() {
        
        try {

            // Retrieve notifications for the Interaction
            const response = await BwcInteractionServices.getInteractionNotifications(this.recordId);
            this.notifications = response.notifications;

        }
        catch(error) {
            super.handleError(error, 'An unexpected error occurred.');
        }
        finally {
            this.isLoaded = true;
        }

    }

    /*
        A hyperlink within some notification was clicked.
    */
    handleActionClick(event) {

        switch (event.detail.action.name) {

            case "epaViewDetails":
                BwcPayments.epaOpenViewer(this, this.recordId, event.detail.action.billingAccountId);
                break;

            case "epaEnroll":
                BwcPayments.epaOpenWizard(this, this.recordId, event.detail.action.ban);
                break;

            default:
                throw new Error('Unrecognized action: ' + event.detail.action.name);

        }

    }

}