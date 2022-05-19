import { LightningElement, api, track } from 'lwc';
import * as BwcUtils from 'c/bwcUtils';

/*
    Displays error information.
*/

const ERROR_CODES = ['400', '404', '500'];
export default class BwcErrorReport extends LightningElement {

    @api variant = 'toast';  // 'toast', 'icon'
    @api get error() {
        return this.internalError;
    }
    set error(value) {
        this.internalError = value;
        if (value) {
            console.error('Error reporter: ' + value + ': ' + value.stack + ': ' + JSON.stringify(value));
        }
    }

    @track internalError;
    dismissable = false;
    isDismissed = true;

    get isToast() {return this.internalError && this.variant === 'toast';}
    get isIcon() {return this.internalError && this.variant === 'icon';}

    /*
        Called by host to display error.
    */
    @api reportError(error, dismissable) {

        this.dismissable = dismissable;
        this.internalError = error;
        this.isDismissed = false;

        console.error('Error reporter: ' + error.stack + ': ' + JSON.stringify(error));

    }

    /*
        Clear any current error.
    */
    @api clearError() {
        
        this.internalError = undefined;
        this.isDismissed = true;

    }

    get errorMessage() {

        let message = '';
        if (this.internalError) {

            if (this.internalError.message) {
                message = this.error.message;
            }

            BwcUtils.log('Error Message: ' + message);

            // Check if RAISR error message payload has a nested json response
            // If yes, then convert string response to JSON and extract the error code to match against ERROR_CODES array
            // If not, then look for error code in the response
            if(message.includes("{") && message.includes("Raisr")){

                // Get first and last index of open and closed brackets
                let indexOfFirstBracket = message.indexOf("{");
                let indexOfLastBracket = message.length;

                // Use those indexes to make a substring of just the relevant JSON data
                let stringJSONErrorObject = message.substring(indexOfFirstBracket, indexOfLastBracket);

                // Parse that string JSON data into actual JSON and extract the value for the "code" key
                let errorStatusCode = JSON.parse(stringJSONErrorObject)["code"].toString();

                // Determine if value from "code" key is in the ERROR_CODES array and designate right error message for agent to view
                message = (ERROR_CODES.includes(errorStatusCode) ? "An unexpected error occurred. Try closing the subtab or resubmitting your payment." : this.error.message);

            } else if (message.includes('400') || message.includes('404') || message.includes('500')) {
                message = "An unexpected error occurred. Try closing the subtab or resubmitting your payment.";
            }

        } 
        else {
            message = 'No error was provided';
        }

       BwcUtils.error('Error Message: ' + message);

        return message;

    }

    handleClose() {
        this.isDismissed = true;
    }

}