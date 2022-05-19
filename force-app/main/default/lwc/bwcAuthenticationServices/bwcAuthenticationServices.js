import * as BwcUtils from 'c/bwcUtils';
import generatePinCont from '@salesforce/apexContinuation/BWC_AuthenticationController.generatePinCont';
import validatePinCont from '@salesforce/apexContinuation/BWC_AuthenticationController.validatePinCont';
import validateCredentialsCont from '@salesforce/apexContinuation/BWC_AuthenticationController.validateCredentialsCont';
import bypassAuthenticationApex from '@salesforce/apex/BWC_AuthenticationController.bypassAuthentication';

export const generatePin = async (interactionId, billingAccountId, deliveryMethods) => {

    const deliveryMethodsJson = JSON.stringify(deliveryMethods);

    BwcUtils.log(`call generatePin: interactionId: ${interactionId} billingAccountId: ${billingAccountId} credentials: ${deliveryMethodsJson}`);

    const responseJson = await generatePinCont({interactionId, billingAccountId, deliveryMethodsJson});

    BwcUtils.log('result generatePin: ' + responseJson);
    const response = JSON.parse(responseJson);

    return response;

};

export const validatePin = async (interactionId, billingAccountId, securityCode, identificationType, otpContactMethod) => {

    BwcUtils.log(`call validatePin: interactionId: ${interactionId} billingAccountId: ${billingAccountId} securityCode: ${securityCode} identificationType: ${identificationType}`);

    const responseJson = await validatePinCont({interactionId, billingAccountId, securityCode, identificationType, otpContactMethod});

    BwcUtils.log('result validatePin: ' + responseJson);
    const response = JSON.parse(responseJson);

    return response;

};

export const validateCredentials = async (interactionId, billingAccountId, accountCredentials) => {

    const accountCredentialsJson = JSON.stringify(accountCredentials);

    BwcUtils.log(`call validateCredentials: interactionId: ${interactionId} billingAccountId: ${billingAccountId} credentials: ${accountCredentialsJson}`);

    const responseJson = await validateCredentialsCont({interactionId, billingAccountId, accountCredentialsJson});

    BwcUtils.log('result validateCredentials: ' + responseJson);
    const response = JSON.parse(responseJson);

    return response;

};

export const bypassAuthentication = async (interactionId, billingAccountId) => {

    BwcUtils.log(`call bypassAuthentication: interactionId: ${interactionId}, billingAccountId: ${billingAccountId}`);

    await bypassAuthenticationApex({interactionId, billingAccountId});

    BwcUtils.log('result bypassAuthentication ');

};