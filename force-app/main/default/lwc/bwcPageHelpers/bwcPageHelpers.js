import { createMessageContext, releaseMessageContext, publish, subscribe, unsubscribe } from "lightning/messageService";
import CONSOLEAPIMC from "@salesforce/messageChannel/BWC_ConsoleApi__c";
import SHOWMODALMC from "@salesforce/messageChannel/BWC_ShowModal__c";
import MODALRESPONSEMC from "@salesforce/messageChannel/BWC_ModalResponse__c";

/*
    Open the specified page reference in a subtab.
*/
export const openSubtab = (pageReference, label, icon) => {
    const messageContext = createMessageContext();

    publish(messageContext, CONSOLEAPIMC, { methodName: "openSubtab", arguments: { pageReference, label, icon }, pageUrl: window.location.href });

    releaseMessageContext(messageContext);
};

/*
    Close the focused console tab. If one mobile, navigate to homepage instead.
*/
export const closeFocusedTab = () => {
    const messageContext = createMessageContext();

    publish(messageContext, CONSOLEAPIMC, { methodName: "closeFocusedTab", pageUrl: window.location.href } );

    releaseMessageContext(messageContext);
};

/*
    Open a modal and return a promise which is resolved when the modal closes.
*/
export const showModal = async (bodyComponentName, bodyComponentArguments, cssClass, showCloseButton) => {
    const messageContext = createMessageContext();

    // Prepare and send the lightning message to show the modal. This message is received by BWCPageHelper aura component, which must be on the current flexipage.
    const showModalArgs = {
        bodyComponentName: bodyComponentName,
        bodyComponentArguments: bodyComponentArguments,
        cssClass,
        showCloseButton: showCloseButton !== false ? true : false,
        pageUrl: window.location.href
    };
    publish(messageContext, SHOWMODALMC, showModalArgs);

    // Return a promise that will resolve when response message is received.
    return new Promise((resolve, reject) => {
        let subscription;
        try {
            // Subscribe to the response channel and wait for response
            subscription = subscribe(messageContext, MODALRESPONSEMC, (message) => {
                // Match component name.
                if (message.bodyComponentName === bodyComponentName) {
                    // Release things
                    unsubscribe(subscription);
                    releaseMessageContext(messageContext);

                    // Resolve with modal response
                    resolve(message.response);
                }
            });
        } catch (error) {
            // Release things
            if (subscription) {
                unsubscribe(subscription);
            }
            releaseMessageContext(messageContext);

            // Reject with error
            reject(error);
        }
    });
};

/*
    Show a simple confirmation modal with specific title, message, and button labels.
*/
export const confirm = async (title, message, okButtonLabel, cancelButtonLabel) => {
    return showModal("c:bwcConfirmModal", { title, message, okButtonLabel, cancelButtonLabel });
};

export const consoleApiCall = ( methodName, args ) => {
    const ctxt = createMessageContext();

    const apiReq = {
        messageType: "method",
        methodName: methodName,
        arguments: args,
        pageUrl: window.location.href
    }
    publish( ctxt, CONSOLEAPIMC, apiReq );        

    return new Promise(( resolve, reject) => {
        let subscription;
        try {
            subscription = subscribe( 
                ctxt, 
                CONSOLEAPIMC, 
                (msg) => {
                    if ( msg.result ) {
                        unsubscribe(subscription);
                        releaseMessageContext( ctxt );
                        resolve( msg.result );
                    }
                }, 
    //             {scope: APPLICATION_SCOPE} 
            );
        }
        catch ( ex ) {
            if ( subscription ) {
                unsubscribe(subscription);
            }
            releaseMessageContext( ctxt );
            reject( ex );
        }    
    });
}