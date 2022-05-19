import * as BwcUtils from 'c/bwcUtils';
import getInteractionApex from '@salesforce/apex/BWC_InteractionController.getInteraction';
import checkPrefetchStatusApex from '@salesforce/apex/BWC_InteractionController.checkPrefetchStatus';
import autoSearchInteractionForCustomerCont from '@salesforce/apexContinuation/BWC_InteractionController.autoSearchInteractionForCustomerCont';
import checkCpniConsentApex from '@salesforce/apex/BWC_InteractionController.checkCpniConsent';
import setCpniConsentApex from '@salesforce/apex/BWC_InteractionController.setCpniConsent';
import getInteractionNotificationsCont from '@salesforce/apexContinuation/BWC_InteractionController.getInteractionNotificationsCont';

/*
    Retrieve interaction by record id.
*/
export const getInteraction = async interactionId => {

    BwcUtils.log('call getInteraction: interactionId: ' + interactionId);

    const interactionJson = await getInteractionApex({interactionId: interactionId});

    BwcUtils.log('result getInteraction: ' + interactionJson);

    return JSON.parse(interactionJson);

};

/*
    Retrieve interaction by record id.
*/
export const checkPrefetchStatus = async ctiCallIdentifier => {

    BwcUtils.log('call checkPrefetchStatus: ctiCallIdentifier: ' + ctiCallIdentifier);

    const resultJson = await checkPrefetchStatusApex({ctiCallIdentifier: ctiCallIdentifier});

    BwcUtils.log('result checkPrefetchStatus: ' + resultJson);

    return JSON.parse(resultJson);

};

/*
*/
export const autoSearchInteractionForCustomer = async interactionId => {

    BwcUtils.log('call autoSearchInteractionForCustomer: interactionId: ' + interactionId);

    const resultJson = await autoSearchInteractionForCustomerCont({interactionId: interactionId});

    BwcUtils.log('result autoSearchInteractionForCustomer: ' + resultJson);

    const result = JSON.parse(resultJson);

    if (!result.success) {
        throw new Error('Failed to autoSearchInteractionForCustomer: ' + result.message);
    }

    return result.accounts;

};

export const checkCpniConsent = async interactionId => {

    BwcUtils.log('call checkCpniConsent: interactionId: ' + interactionId);

    const result = await checkCpniConsentApex({interactionId: interactionId});

    BwcUtils.log('result checkCpniConsent: ' + result);

    return result;

};

export const setCpniConsent = async (interactionId, cpniConsent, billingAccountId) => {

    BwcUtils.log(`call setCpniConsent: interactionId: ${interactionId}, cpniConsent: ${cpniConsent}, billingAccountId: ${billingAccountId}`);

    await setCpniConsentApex({interactionId, cpniConsent, billingAccountId});

    BwcUtils.log('result setCpniConsent');

};

export const getInteractionNotifications = async interactionId => {

    BwcUtils.log(`call getInteractionNotifications: interactionId: ${interactionId}`);

    const resultJson = await getInteractionNotificationsCont({interactionId});

    BwcUtils.log('result getInteractionNotifications: ' + resultJson);

    return JSON.parse(resultJson);

};