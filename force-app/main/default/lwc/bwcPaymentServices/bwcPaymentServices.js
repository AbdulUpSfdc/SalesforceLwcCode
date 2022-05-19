import * as BwcUtils from 'c/bwcUtils';
import getBillingAndPaymentsDataApex from '@salesforce/apex/BWC_BillingAndPaymentsController.getBillingAndPaymentsData';
import getPaymentDetailsCont from '@salesforce/apexContinuation/BWC_PaymentDetailsController.getPaymentDetailsCont';
import getTermsAndConditionsApex from '@salesforce/apex/BWC_TermAndConditionController.getTermsAndConditions';
import postPaymentProfileApex from '@salesforce/apex/BWC_PaymentProfileController.postPaymentProfile';
import postPaymentProfileRaisrApex from '@salesforce/apex/BWC_PaymentProfileController.postPaymentProfileRaisr'
import makePaymentApex from '@salesforce/apex/BWC_MakePaymentController.makePayment';
import makePaymentRaisrApex from '@salesforce/apex/BWC_MakePaymentController.makePaymentRaisr';
import updatePaymentApex from '@salesforce/apex/BWC_MakePaymentController.updatePayment';
import updatePaymentRaisrApex from '@salesforce/apex/BWC_MakePaymentController.updatePaymentRaisr';
import deletePaymentApex from '@salesforce/apex/BWC_MakePaymentController.deletePayment';
import postAutoPayProfileApex from '@salesforce/apex/BWC_AutoPayProfilesController.postAutoPayProfile';
import postAutoPayProfileRaisrApex from '@salesforce/apex/BWC_AutoPayProfilesController.postAutoPayProfileRaisr';
import epaEnrollApex from '@salesforce/apex/BWC_MakePaymentController.epaEnroll';
import epaEnrollRaisrApex from '@salesforce/apex/BWC_MakePaymentController.epaEnrollRaisr';

export const getBillingAndPaymentsData = async recordId => {

    BwcUtils.log('call getBillingAndPaymentsData: recordId: ' + recordId);

    const billingDatasResult = await getBillingAndPaymentsDataApex({recordId: recordId});

    BwcUtils.log('result getBillingAndPaymentsData: ' + JSON.stringify(billingDatasResult));

    if (!billingDatasResult.success) {
        throw new Error('Failed to retrieve billing data: ' + billingDatasResult.message);
    }

    return billingDatasResult.billingData;

};

export const getPaymentDetails = async args => {

    BwcUtils.log('call getPaymentDetails: ' + JSON.stringify(args));

    const paymentDetailsResultJson = await getPaymentDetailsCont(args);

    BwcUtils.log('result getPaymentDetails: ' + paymentDetailsResultJson);

    const paymentDetailsResult = JSON.parse(paymentDetailsResultJson);

    return paymentDetailsResult.responses;

};

export const getTermsAndConditions = async paymentEventType => {

    BwcUtils.log('call getTermsAndConditions: ' + paymentEventType);

    const responseWrapperJson = await getTermsAndConditionsApex({paymentEventTypes: [paymentEventType]});
    
    BwcUtils.log('result getTermsAndConditions: ' + responseWrapperJson);

    const responseWrapper = JSON.parse(responseWrapperJson);
    if (responseWrapper.success) {

        if (responseWrapper.termsAndConditions.length > 0) {
            return responseWrapper.termsAndConditions[0];
        }
        throw new Error(`No Terms and Conditions found for paymentEventType ${paymentEventType}`);

    }

    throw new Error(`Unable to retrieve Terms and Conditions verbiage for paymentEventType ${paymentEventType}: ${responseWrapper.message}`);

};

export const PostPaymentProfileMode = {
    ADD: 'add',
    UPDATE: 'update',
    DELETE: 'delete'
};

export const postPaymentProfile = async (paymentProfile, mode) => {

    const paymentProfileJson = JSON.stringify(paymentProfile) + ' ' + mode;

    BwcUtils.log('call postPaymentProfile: ' + paymentProfileJson);

    const responseWrapperJson = await postPaymentProfileApex({paymentProfileJson: paymentProfileJson, mode: mode});

    BwcUtils.log('result postPaymentProfile: ' + responseWrapperJson);

    const responseWrapper = JSON.parse(responseWrapperJson);
    if (responseWrapper.success) {

        if (responseWrapper.error) {
            throw new Error(`Error posting payment profile: ${responseWrapper.error.message}`);
        }

        return responseWrapper.response;

    }

    throw new Error(`Unable to post payment profile: ${responseWrapper.message}`);

};

export const postPaymentProfileRaisr = async (paymentProfile, mode, spiData) => {

    const paymentProfileJson = JSON.stringify(paymentProfile) + ' ' + mode;

    BwcUtils.log('call postPaymentProfileRaisr: ' + paymentProfileJson + ' ' + JSON.stringify(spiData));

    const responseWrapperJson = await postPaymentProfileRaisrApex({paymentProfileJson: paymentProfileJson, mode: mode, spiDataJson: JSON.stringify(spiData)});

    BwcUtils.log('result postPaymentProfileRaisr: ' + responseWrapperJson);

    const responseWrapper = JSON.parse(responseWrapperJson);
    if (responseWrapper.success) {

        if (responseWrapper.error) {
            throw new Error(`Error posting payment profile: ${responseWrapper.error.message}`);
        }

        return responseWrapper.response;

    }

    throw new Error(`Unable to post payment profile: ${responseWrapper.message}`);

};

export const makePayment = async request => {

    const requestJson = JSON.stringify(request);

    BwcUtils.log('call makePayment: ' + requestJson);

    const responseWrapperJson = await makePaymentApex({requestJson: requestJson});

    BwcUtils.log('result makePayment: ' + responseWrapperJson);

    const responseWrapper = JSON.parse(responseWrapperJson);

    if (!responseWrapper.success) {
        throw new Error('Failed to make payment: ' + responseWrapper.message);
    }

    return responseWrapper.response;

};

export const updatePayment = async request => {

    const requestJson = JSON.stringify(request);

    BwcUtils.log('call updatePayment: ' + requestJson);

    const responseWrapperJson = await updatePaymentApex({requestJson: requestJson});

    BwcUtils.log('result updatePayment: ' + responseWrapperJson);

    const responseWrapper = JSON.parse(responseWrapperJson);

    if (!responseWrapper.success) {
        throw new Error('Failed to update payment: ' + responseWrapper.message);
    }

    return responseWrapper.response;

};

export const deletePayment = async request => {

    const requestJson = JSON.stringify(request);

    BwcUtils.log('call deletePayment: ' + requestJson);

    const responseWrapperJson = await deletePaymentApex({requestJson: requestJson});

    BwcUtils.log('result deletePayment: ' + responseWrapperJson);

    const responseWrapper = JSON.parse(responseWrapperJson);

    if (!responseWrapper.success) {
        throw new Error('Failed to delete payment: ' + responseWrapper.message);
    }

    return responseWrapper.response;

};

export const makePaymentRaisr = async (request, spiData) => {

    const requestJson = JSON.stringify(request);

    BwcUtils.log('call makePaymentRaisr: ' + requestJson + ' spiDataJson: ' + JSON.stringify(spiData));

    const responseWrapperJson = await makePaymentRaisrApex({requestJson: requestJson, spiDataJson: JSON.stringify(spiData)});

    BwcUtils.log('result makePaymentRaisr: ' + responseWrapperJson);

    const responseWrapper = JSON.parse(responseWrapperJson);

    if (!responseWrapper.success) {
        throw new Error('Failed to make payment Raisr: ' + responseWrapper.message);
    }

    return responseWrapper.response;

};

export const updatePaymentRaisr = async (request, spiData) => {

    const requestJson = JSON.stringify(request);

    BwcUtils.log('call updatePaymentRaisr: ' + requestJson + ' spiDataJson: ' + JSON.stringify(spiData));

    const responseWrapperJson = await updatePaymentRaisrApex({requestJson: requestJson, spiDataJson: JSON.stringify(spiData)});

    BwcUtils.log('result updatePaymentRaisr: ' + responseWrapperJson);

    const responseWrapper = JSON.parse(responseWrapperJson);

    if (!responseWrapper.success) {
        throw new Error('Failed to update payment: ' + responseWrapper.message);
    }

    return responseWrapper.response;

};

export const postAutoPayProfile = async (autoPayProfile, mode) => {

    const autoPayProfileJson = JSON.stringify(autoPayProfile);

    BwcUtils.log('call postAutoPayProfile: ' + mode + ' ' + autoPayProfileJson);

    const responseWrapperJson = await postAutoPayProfileApex({autoPayProfileJson: autoPayProfileJson, mode: mode});

    BwcUtils.log('result postAutoPayProfile: ' + responseWrapperJson);

    const responseWrapper = JSON.parse(responseWrapperJson);

    if (!responseWrapper.success) {
        throw new Error('Failed to postAutoPayProfile: ' + responseWrapper.message);
    }

    return responseWrapper.response;

};

export const postAutoPayProfileRaisr = async (autoPayProfile, mode, spiData) => {

    const autoPayProfileJson = JSON.stringify(autoPayProfile);

    BwcUtils.log('call postAutoPayProfile: ' + mode + ' ' + autoPayProfileJson + JSON.stringify(spiData));

    const responseWrapperJson = await postAutoPayProfileRaisrApex({autoPayProfileJson: autoPayProfileJson, mode: mode, spiDataJson: JSON.stringify(spiData)});

    BwcUtils.log('result postAutoPayProfile: ' + responseWrapperJson);

    const responseWrapper = JSON.parse(responseWrapperJson);

    if (!responseWrapper.success) {
        throw new Error('Failed to postAutoPayProfile: ' + responseWrapper.message);
    }

    return responseWrapper.response;

};

export const epaEnroll = async request => {

    const requestJson = JSON.stringify(request);

    BwcUtils.log('call epaEnroll: ' + requestJson);

    const responseWrapperJson = await epaEnrollApex({requestJson: requestJson});

    BwcUtils.log('result epaEnroll: ' + responseWrapperJson);

    const responseWrapper = JSON.parse(responseWrapperJson);

    if (!responseWrapper.success) {
        throw new Error('Failed to epaEnroll: ' + responseWrapper.message);
    }

    return responseWrapper.response;

};

export const epaEnrollRaisr = async (request, spiData) => {

    const requestJson = JSON.stringify(request);

    const spiDataJson = JSON.stringify(spiData);

    BwcUtils.log('call epaEnrollRaisr: ' + requestJson + ' ' + spiDataJson);

    const responseWrapperJson = await epaEnrollRaisrApex({requestJson: requestJson, spiDataJson: spiDataJson});

    BwcUtils.log('result epaEnrollRaisr: ' + responseWrapperJson);

    const responseWrapper = JSON.parse(responseWrapperJson);

    if (!responseWrapper.success) {
        throw new Error('Failed to epaEnroll: ' + responseWrapper.message);
    }

    return responseWrapper.response;

};