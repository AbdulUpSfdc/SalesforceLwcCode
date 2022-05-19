import * as BwcUtils from 'c/bwcUtils';
import createChargeApex from '@salesforce/apex/BWC_ChargesController.createCharge';

export const createCharge = async (recordId, request) => {

    BwcUtils.log('call createCharge', request);

    const requestJson = JSON.stringify(request);

    const responseJson = await createChargeApex({ recordId, requestJson });

    const response = JSON.parse(responseJson);

    BwcUtils.log(`response createCharge`, response);

    return response;
}