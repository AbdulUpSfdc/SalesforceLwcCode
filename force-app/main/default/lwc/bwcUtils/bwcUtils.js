/*
    Helper methods for javascript.
*/
import * as BwcConstants from 'c/bwcConstants';
import { createMessageContext, releaseMessageContext, publish } from 'lightning/messageService';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import OPENSUBTABMC from '@salesforce/messageChannel/BWC_OpenSubTab__c';
import hasDebugPermission from '@salesforce/customPermission/BWC_Debug';


/*
    Wraps console.log to control context in which logging is allowed.
*/
export const log = (...args) => {

    if (hasDebugPermission) {
        console.log(...args);
    }

}

/*
    Wraps console.error to control behavior of error logging.
*/
export const error = (...args) => {

    console.error(...args);

}

/*
    Wraps console.warn to control behavior of warn logging.
*/
export const warn = (...args) => {

    console.warn(...args);

}

/*
    Deep-clone the object and return the clone.
*/
export const cloneObject = (source, clonedObjects) => {

    let target;

    if (clonedObjects === undefined) {
        clonedObjects = [];
    }

    //Return value types
    if (source === undefined || source === null || (!Array.isArray(source) && typeof(source) !== 'object')) {
        //Value type, just set.
        target = source;
    }
    else if (Array.isArray(source)) {
        //Recurse to array elements
        target = [];
        source.forEach(sourceItem => {target.push(cloneObject(sourceItem, clonedObjects));});
    }
    else {

        //It's an object

        //Handle reference loops by detecting already cloned object
        for (let i = 0; i < clonedObjects.length; i++) {
            if (clonedObjects[i].source === source) {
                target = clonedObjects[i].target;
                break;
            }
        }

        //Reference not found, clone
        if (target === undefined) {

            target = {};

            //Push now so self-reference is detected below.
            clonedObjects.push({source: source, target: target});

            for (let key in source) {

                if (Object.prototype.hasOwnProperty.call(source, key)) {
                    //Recurse for each property.
                    target[key] = cloneObject(source[key], clonedObjects);
                }
        
            }

        }

    }

    return target;

};

/*
    Use to wait for event loop to complete so rendering can occur before further processing.
    This is just Promise.resolve() but "nextTick" makes it easier to understand in context of use.
*/
export const nextTick = () => {
    return Promise.resolve();
}

/*
    Makes it slightly easier to show toast from a component.
*/
export const showToast = (component, args) => {

    component.dispatchEvent(new ShowToastEvent(args));

}

/*
    Report validity of all inputs in a template
*/
export const reportValidity = (template, additionalInputTypes) => {

    const inputTypes = 'lightning-input, lightning-combobox, lightning-radio-group' + (additionalInputTypes ? ', ' + additionalInputTypes : '');

    // Validate all inputs
    let isValid = true;
    template.querySelectorAll(inputTypes).forEach(input => {
        if (!input.reportValidity()) {
            isValid = false;
        }
    });

    return isValid;

}

/*
    Check validity of all inputs in a template
*/
export const checkValidity = (template, additionalInputTypes) => {

    const inputTypes = 'lightning-input, lightning-combobox, lightning-radio-group' + (additionalInputTypes ? ', ' + additionalInputTypes : '');

    // Validate all inputs
    let isValid = true;
    template.querySelectorAll(inputTypes).forEach(input => {
        if (!input.checkValidity()) {
            isValid = false;
        }
    });

    return isValid;

}

/*
    Resets validity reporting on controls that are now disabled.
    This fixes odd-looking situation where a newly disabled control retains an error message such as for required fields.
*/
export const resetDisabledValidity = (template, additionalInputTypes) => {

    const inputTypes = 'lightning-input, lightning-combobox, lightning-radio-group' + (additionalInputTypes ? ', ' + additionalInputTypes : '');

    // Validate all inputs
    template.querySelectorAll(inputTypes).forEach(input => {
        if (input.disabled) {
            input.reportValidity();
        }
    });

}

/*
    Creates an error with custom details property.
*/
export const errorWithDetails = (message, details) => {
    const theError = new Error(message);
    theError.details = details;
    return theError;
}

/*
    Convert from string or float to number with 2 decimals.
*/
export const toCurrency = (value) => {

    if (!value) {
        return 0;
    }

    let numberValue = (typeof value === 'number') ? value : parseFloat(value);

    return parseFloat(numberValue.toFixed(2));

}

/*
    Format number as currency.
*/
export const formatCurrency = (value) => {
    return new Intl.NumberFormat('en-EN', { style: 'currency', currency: 'USD' }).format(value ? value : 0);
}

/*
    Pads to width using leading zeros
*/
export const padInteger = (value, width) => {

    let result = value.toString();
    result = '0'.repeat(width - result.length) + result;
    return result;

}

/*
    Return date-only as ISO date string, i.e. '2020-05-25'
*/
export const toIsoDate = (dateTimeValue) => {

    if (!dateTimeValue || !(dateTimeValue instanceof Date)) {
        return undefined;
    }
    
    try {
    return dateTimeValue.getFullYear() + '-' + padInteger(dateTimeValue.getMonth() + 1, 2) + '-' + padInteger(dateTimeValue.getDate(), 2);
    }
    catch (e) {
        return undefined;
    }
    
}

/*
    Take ISO date-only string like '2020-05-25' and return as Date.
*/
export const parseIsoDateString = (dateString) => {
    return dateString ? Date.parse(dateString + 'T00:00:00') : undefined;
}

/*
    Format a Date value to string like "Jun 14, 2020".
*/
export const formatDate = (value) => {
    return new Intl.DateTimeFormat('en-US', {year: 'numeric', month: 'short', day: 'numeric' }).format(value);
}

/*
    Format a Date to string like "11/01/2001".
*/
export const formatDateShort = (value) => {
    let options = {
        year: "numeric",
        month: "2-digit",
        day: "2-digit",
    };

    if (value instanceof Date) {
        return new Intl.DateTimeFormat('en-US', options).format(value);
    }
    if (isNaN(value)) {
        value = parseIsoDateString(value);
    }
    const theDate = new Date();
    theDate.setTime(value);
    return new Intl.DateTimeFormat('en-US', options).format(theDate);
}

/*
    Return <length> characters from right of string.
*/
export const rightstring = (value, length) => {
    if (!value) {
        return value;
    }
    return value.substring(value.length - length);
}

/*
    Format a phone number string.
*/
export const formatPhone = (value) => {

    if (!value) {
        return '';
    }

    // remove all characters except numbers
    value = value.replace(/[^0-9]+/g, '');

    if (value.length === 10) {
        return `(${value.substring(0, 3)}) ${value.substring(3, 6)}-${value.substring(6)}`;
    }

    return value;

}

/*
    Strip everything from string but digits.
*/
export const parsePhoneToDigits = (value) => {

    if (!value) {
        return undefined;
    }

    return value.replace(/[^0-9]+/g, '');

}

/*
    Get a GUID.
*/
export function generateUUID() { // Public Domain/MIT
    var d = new Date().getTime();//Timestamp
    var d2 = (performance && performance.now && (performance.now()*1000)) || 0;//Time in microseconds since page-load or 0 if unsupported
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        var r = Math.random() * 16;//random number between 0 and 16
        if(d > 0){//Use timestamp until depleted
            r = (d + r)%16 | 0;
            d = Math.floor(d/16);
        } else {//Use microseconds since page-load if supported
            r = (d2 + r)%16 | 0;
            d2 = Math.floor(d2/16);
        }
        return (c === 'x' ? r : (r & 0x3 | 0x8)).toString(16);
    });
}

/*
    Open console workspace subtab.
    Works with hidden BWCOpenSubTab Aura component which must be on page.

    Message format: {
        pageReference: {},
        url: '<url>',
        recordId: '<recordId>',
        label: 'Tab Label',
        icon: 'my:icon'
    }

    Only provide pageReference OR url OR recordId.
*/
export const openSubTab = (message) => {

    // Publish the message for BWCOpenSubTab to consume and open the subtab
    const messageContext = createMessageContext();
    publish(messageContext, OPENSUBTABMC, message);
    releaseMessageContext(messageContext);

}

/*
    Parses out the Interaction__c value from the browser URL in the service console.
    For retrieving the interaction ID from Billing Account or other subtab in cases where the value is needed in LWC.
*/
export const getInteractionIdFromUrl = () => {

    const pattern = /Interaction__c%2F([a-zA-Z0-9]{18})/;
    const matchResult = pattern.exec(window.location.search);
    if (matchResult) {
        log ('Interaction__c = ' + matchResult[1]);
        return matchResult[1];
    }
    log('Unable to retrieve Interaction__c from URL ' + window.location);
    return undefined;

}

/*
    Return last x of string.
*/
export const right = (value, length) => {

    if (!value) {
        return '';
    }
    if (value.length <= length) {
        return value;
    }
    return value.substring(value.length - length);

}

/*
    Construct name for payment profile.
*/
export const buildPaymentMethodName = (paymentMethod) => {

    if (!paymentMethod) {
        return undefined;
    }

    // Build Profile Name
    switch(paymentMethod.paymentMethodType ? paymentMethod.paymentMethodType : paymentMethod.type) {

        case BwcConstants.PaymentMethodType.CARD.value:
            {
                const cardType = paymentMethod.card.cardType;
                const cardLabel = cardType ? `${BwcConstants.CardType[cardType].label} ...` : '';
                const cardNumber = paymentMethod.card.cardNumber;

                return cardLabel + rightstring(cardNumber, 4);
            }

        case BwcConstants.PaymentMethodType.BANKACCOUNT.value:
            {
                const accountType = paymentMethod.bankAccount.accountType;
                const accountLabel = accountType ? `${BwcConstants.BankAccountType[accountType].label} ...` : '';
                const accountNumber = paymentMethod.bankAccount.bankAccountNumber;

                return accountLabel + rightstring(accountNumber, 4);
            }

        default:
            return '';

    }

}

/*
    Construct label for payment profile.
*/
export const buildPaymentMethodLabel = (paymentMethod) => {

    if (!paymentMethod) {
        return undefined;
    }

    // Build Profile Name
    switch(paymentMethod.paymentMethodType ? paymentMethod.paymentMethodType : paymentMethod.type) {

        case BwcConstants.PaymentMethodType.CARD.value:
            {
                const cardType = paymentMethod.card.cardType;
                const cardLabel = cardType ? `${BwcConstants.CardType[cardType].label} ending in ` : '';
                const cardNumber = paymentMethod.card.cardNumber;

                return cardLabel + rightstring(cardNumber, 4);
            }

        case BwcConstants.PaymentMethodType.BANKACCOUNT.value:
            {
                const accountType = paymentMethod.bankAccount.accountType;
                const accountLabel = accountType ? `${BwcConstants.BankAccountType[accountType.toUpperCase()].label} ending in ` : '';
                const accountNumber = paymentMethod.bankAccount.bankAccountNumber;

                return accountLabel + rightstring(accountNumber, 4);
            }

        default:
            return '';

    }

}

// Sequential numbers that are not allowed for a phone number.
const DISALLOWED_PHONE_PATTERNS = ['1234567890', '0123456789', '9876543210', '0987654321'];

// Repeat of same digit not allowed for phone number
const REPEATING_DIGITS_PATTERN = /([0-9])\1{9}/;

// Labels
import label_invalidPhoneLength from '@salesforce/label/c.BWC_Invalid_Phone_Length';
import label_invalidPhoneSequential from '@salesforce/label/c.BWC_Invalid_Phone_Sequential';
import label_invalidPhoneRepeating from '@salesforce/label/c.BWC_Invalid_Phone_Repeating';

/*
    Validate phone number:
        10 digits
        Disallowed sequential runs such as 123-456-7890
        Disallowed repeating runs of same number such as 111-111-1111

    Strips all punctuation, performs validations, then formats as XXX-XXX-XXXX.
*/
export const validatePhone = input => {
    
    if (!input.value) {
        return;
    }

    // This will give just the digits, stripping all punctuation and non-numeric
    const rawDigits = parsePhoneToDigits(input.value);

    if (rawDigits.length !== 10) {
        input.setCustomValidity(label_invalidPhoneLength);
    }
    else if (DISALLOWED_PHONE_PATTERNS.includes(rawDigits)) {
        input.setCustomValidity(label_invalidPhoneSequential);
    }
    else if (REPEATING_DIGITS_PATTERN.test(rawDigits)) {
        // Pattern looks for sequence of 10 of the same digit.
        input.setCustomValidity(label_invalidPhoneRepeating);
    }
    else {

        // Valid
        input.setCustomValidity('');

        // Always reformat as (XXX) XXX-XXXX
        input.value = formatPhone(rawDigits);

    }

}
/**
     * Method that extract nested values from an object. Returns null if no property was found
     * @param  {} object Object that contains the property we want the extract values from
     * @param  {} path the name of the property we want to extract value from. If it is a nested
     * property, use dot notation
     * @example
     * //extract top level property from an object. Returns the value of name
     * getValueFromField(myObject,'name');
     *
     * //extract nested property from an object. Returns the value of modelNumber
     * getValueFromField(myObject,'tradeInDetails.expectedDetails.modelNumber');
     */
 export const getValueFromField = (object, path)=>{
    let localObject = {...object}
    let fields = path.split('.');
    let property

    let skipExecution = false;
    fields.forEach((field)=>{

        if(skipExecution){
            return
        }

        property = localObject[field];
        localObject = property;

        if(!localObject){
            skipExecution = true;
        }

    });

    return localObject;
}

/** Method used to extract and process error messages
 * @param  {} error. Thrown by apex, LDS, etc.
 */
export const processError = (error)=>{

    let result='';

    if(Array.isArray(error.body)){
        result = error.body.map(e => e.message).join(', ');
    }else{
        result = error.body.message || error.body;
    }

    // Duplicate values, invalid picklist values, etc.
    if(error.body?.output?.fieldErrors){

        let fieldNames = Object.keys(error.body.output.fieldErrors);
        let fieldErrors = error.body.output.fieldErrors;
        for(let field of fieldNames){
            for(let e of fieldErrors[field]){
                result+=' \n'+e.message;
            }
        }
    }

    // Validation rule errors, permissions errors, etc.
    if(error.body?.output?.errors){
        result += error.body?.output?.errors.map(e=>e.message).join(', ');
    }


    return result;
}

// Error Message Label
import label_invalidOrderId from '@salesforce/label/c.BWC_Invalid_Order_Id';

const ORDER_ID_PATTERN = /^[0-9]{2}-{1}[0-9]{15}$/;
const ORDER_ID_NUMBERS_PATTERN = /^[0-9]{17}$/;

/** Method used to validate the orderId input.
 *  @param  {} input. Where the user is entering the order Id
 */
export const validateOrderId = input => {

    if (!input.value) {
        return;
    }

    const inputValue = input.value;

    // User already formatted orderId
    if(ORDER_ID_PATTERN.test(inputValue)){
        input.setCustomValidity('');
        return true;

    } else if(ORDER_ID_NUMBERS_PATTERN.test(inputValue)){

        // User provided just numbers, formatted order Id is set to the input
        input.value = formatOrderId(inputValue);
        input.setCustomValidity('');
        return true;

    }else {

        input.setCustomValidity(label_invalidOrderId);
        return false;

    }

}

export const formatOrderId = orderId =>{
    return `${orderId.substring(0,2)}-${orderId.substring(2,orderId.length)}`;
}

/*
    Return promise that resolves when timeout is done. Allows "await" for length of time.
 */
export const wait = delay => {

    return new Promise((resolve) => {
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {resolve();}, delay);
    });

    return value;
}