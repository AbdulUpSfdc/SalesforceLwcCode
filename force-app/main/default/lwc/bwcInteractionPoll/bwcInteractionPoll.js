/* eslint-disable @lwc/lwc/no-async-operation */
import { api } from 'lwc';
import BwcPageElementBase from 'c/bwcPageElementBase';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import * as BwcUtils from 'c/bwcUtils';
import getBwcSettings from '@salesforce/apex/BWC_Settings.getBwcSettings';
import * as BwcInteractionServices from 'c/bwcInteractionServices';

// Labels
import label_polling from '@salesforce/label/c.BWC_Interaction_PollingForPrefetch';

/*
    Periodically calls out to try to find matching customer for the Interaction record.
*/
export default class BwcInteractionPoll extends BwcPageElementBase {

    @api recordId;              // Interaction Id
    interactionRecord;
    isTimedOut = false;         // Timed out waiting for status, shift to autosearch
    pollingTimout;
    pollingInterval;
    pollingMaxIterations;
    pollingIteration;
    isAutoSearching = false;
    autoSearchTicks;            // Increment once a second while auto-searching, to allow update of progress indicator

    heading = label_polling;

    get pollingProgressPercent() {

        // While polling for status, move up to no more than 80% -- other 20% will represent auto-search if needed
        let result = Math.floor(80 * this.pollingIteration / this.pollingMaxIterations);

        if (!this.isTimedOut) {

            return result;

        }

        // Autosearching -- start where polling ended but show progressively slower since we don't know how long it will actually take
        result = result + (100 - result - 1) * (1 - 1 / (this.autoSearchTicks));

        console.log('percent ' + result)

        return result;

    }

    async connectedCallback() {

        try {

            // Get the interaction
            this.interactionRecord = await BwcInteractionServices.getInteraction(this.recordId);

            // Get config settings for intervals
            const bwcSettings = await getBwcSettings();

            this.pollingTimout = bwcSettings.Prefetch_Status_Polling_Timeout__c;
            this.pollingInterval = bwcSettings.Prefetch_Status_Polling_Interval__c;
            this.pollingMaxIterations = Math.ceil(this.pollingTimout / this.pollingInterval);
            this.pollingIteration = 0;

            BwcUtils.log(`Poll every ${this.pollingInterval} milliseconds for ${this.pollingTimout} milliseconds.`);

            // Do first poll
            this.poll();

        }
        catch (error) {

            this.handleError(error);

        }
    }

    /*
        Search once for prefetched customer data, and if found set Interaction Customer.
    */
    async poll() {

        try {

            this.pollingIteration++;

            console.log(`Polling ${this.pollingIteration} of ${this.pollingMaxIterations}`)

            if (this.pollingIteration > this.pollingMaxIterations) {

                //Timed out:
                BwcUtils.log('Customer Data polling timed out.');
                this.isTimedOut = true;

                // Try autosearch
                await this.autoSearch();

                return;
            
            }

            const prefetchStatusResult = await BwcInteractionServices.checkPrefetchStatus(this.interactionRecord.CTI_Call_Identifier__c);

            switch(prefetchStatusResult.prefetchStatus) {

                case 'In Process':

                    // In process, poll again after interval
                    window.setTimeout(() => {
                        this.poll();
                    }, this.pollingInterval);
                    break;

                case 'Success':

                    // Customer was found, force page to recognize update to interaction so it refreshes
                    super.sendLmsRefresh(this.recordId, 'customerSearch');
                    await getRecordNotifyChange([{recordId: this.recordId}]);
                    break;

                default:

                    // Failed or never started, go to auto-search
                    this.isTimedOut = true;
                    await this.autoSearch();
                    break;

            }

        }
        catch (error) {
            this.handleError(error);
        }

    }

    /*
        Perform automatic search for customer based upon interaction field values.
    */
    async autoSearch() {

        try {

            BwcUtils.log('AutoSearching');
            this.autoSearchClock(true);
            await BwcInteractionServices.autoSearchInteractionForCustomer(this.recordId);

        }
        catch(error) {
            this.handleError(error);
        }
        finally {

            this.isAutoSearching = false;

            // Force page to recognize any update to interaction
            await getRecordNotifyChange([{recordId: this.recordId}]);

        }

    }

    /*
        Allows updated of progress bar.
    */
    autoSearchClock(start) {

        if (start) {
            this.isAutoSearching = true;
            this.autoSearchTicks = 0;
        }
        else if (!this.isAutoSearching) {
            return;
        }

        BwcUtils.log('Autosearching ' + this.autoSearchTicks);

        this.autoSearchTicks++;

        window.setTimeout(() => {
            this.autoSearchClock();
        }, 1000);

    }

    async handleError(error) {

        // Write error to console
        BwcUtils.error(error);

        // Force page to recognize any update to interaction
        await getRecordNotifyChange([{recordId: this.recordId}]);

    }

}