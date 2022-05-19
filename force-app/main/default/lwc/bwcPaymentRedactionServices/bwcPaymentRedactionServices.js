import * as BwcUtils from 'c/bwcUtils';
import paymentInfoEnteredApex from '@salesforce/apex/BWC_RedactionController.paymentInfoEntered';
import startEmailSecureXchangeApex from '@salesforce/apex/BWC_RedactionController.startEmailSecureXchange';
import startEmailSecureXchangeAuxApex from '@salesforce/apex/BWC_RedactionController.startEmailSecureXchangeAux';
import startSMSSecureXchangeApex from '@salesforce/apex/BWC_RedactionController.startSMSSecureXchange';
import startSMSSecureXchangeAuxApex from '@salesforce/apex/BWC_RedactionController.startSMSSecureXchangeAux';
import verifyOTPApex from '@salesforce/apex/BWC_RedactionController.verifyOTP';

export const paymentInfoEntered = async sobjId => {

    BwcUtils.log(`call paymentInfoEntered: ${sobjId}`);

    const responseJson = await paymentInfoEnteredApex({sobjId});

    BwcUtils.log('result paymentInfoEntered: ' + responseJson);

    return JSON.parse(responseJson);

};

export const startEmailSecureXchange = async (sobjId, email, language, capabilities) => {

    BwcUtils.log(`call startEmailSecureXchange: ${sobjId}, ${email}, ${language}, ${capabilities ? JSON.stringify(capabilities) : ''}`);

    const response = await startEmailSecureXchangeApex({sobjId, email, language, capabilities});

    BwcUtils.log('result startEmailSecureXchange: ' + response);

    return response;

};

export const startEmailSecureXchangeAux = async req => {

    BwcUtils.log(`call startEmailSecureXchangeAux: ${req ? JSON.stringify(req) : ''}`);

    const response = await startEmailSecureXchangeAuxApex({req});

    BwcUtils.log('result startEmailSecureXchangeAux: ' + response);

    return response;

};

export const startSMSSecureXchange = async (sobjId, phone, language, capabilities) => {

    BwcUtils.log(`call startSMSSecureXchange: ${sobjId}, ${phone}, ${language}, ${capabilities ? JSON.stringify(capabilities) : ''}`);

    const response = await startSMSSecureXchangeApex({sobjId, phone, language, capabilities});

    BwcUtils.log('result startSMSSecureXchange: ' + response);

    return response;

};

export const startSMSSecureXchangeAux = async req => {

    BwcUtils.log(`call startSMSSecureXchangeAux: ${req ? JSON.stringify(req) : ''}`);

    const response = await startSMSSecureXchangeAuxApex({req});

    BwcUtils.log('result startSMSSecureXchange: ' + response);

    return response;

};

export const verifyOTP = async (sobjId, otp) => {

    BwcUtils.log(`call verifyOTP: ${sobjId}, ${otp}`);

    const responseJson = await verifyOTPApex({sobjId, otp});

    BwcUtils.log('result verifyOTP: ' + responseJson);

    return JSON.parse(responseJson);

};