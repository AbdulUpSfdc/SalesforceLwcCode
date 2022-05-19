import { LightningElement, api, track } from 'lwc';

export default class BwcErrorReports extends LightningElement {

    @track errors = [];

    /*
        Add an error to the list.
    */
    @api addError(error, details) {

        const newError = error instanceof Error ? error : new Error(JSON.stringify(error));

        let newDetails;
        if (details) {

            if (typeof details === 'string') {
                newDetails = details;
            }
            else if (details instanceof Error) {
                newDetails = details.stack;
                console.error(details);
            }
            else {
                newDetails = JSON.stringify(details);
            }

        }

        // Only set if there are some details, existing error might already have details attached.
        if (newDetails) {
            newError.details = newDetails;
        }

        newError.key = this.errors.length + '';
        this.errors.push(newError);

    }

    /*
        Remove all errors.
    */
    @api clearErrors() {
        this.errors = [];
    }

    @api get hasErrors() {
        return this.errors.length > 0;
    }

}