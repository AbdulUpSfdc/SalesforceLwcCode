import * as BwcUtils from 'c/bwcUtils';
import resetPasswordApex from '@salesforce/apex/BWC_CustomerProfileController.resetPassword';

export const resetPassword = async request => {

    const requestJson = JSON.stringify(request);

    BwcUtils.log('call resetPassword: ' + requestJson);

    const responseWrapperJson = await resetPasswordApex({requestJson: requestJson});

    BwcUtils.log('result resetPassword: ' + responseWrapperJson);

    const responseWrapper = JSON.parse(responseWrapperJson);

    if (!responseWrapper.success) {
        throw new Error('Failed to resetPassword: ' + responseWrapper.message);
    }

    return responseWrapper.response;

};