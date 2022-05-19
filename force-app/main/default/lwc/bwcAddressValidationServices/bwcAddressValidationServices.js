import * as BwcUtils from 'c/bwcUtils';
import addressValidationCont from '@salesforce/apexContinuation/BWC_AddressValidationController.addressValidationCont';

export const addressValidation = async (recordId, requestJson) => {

    BwcUtils.log(`Calling addressValidation. recordId: ${recordId}, requestJson: ${requestJson}`);
    const responseJson = await addressValidationCont({recordId, requestJson});

    BwcUtils.log('Response addressValidation: ', {responseJson});

    return JSON.parse(responseJson);

}

export const ID_NOT_FOUND = 'NOT FOUND';