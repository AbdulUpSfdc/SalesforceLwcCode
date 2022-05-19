import * as BwcUtils from 'c/bwcUtils';
import getCustomerInfoForBillingAccountCont from '@salesforce/apexContinuation/BWC_CustomerAccountController.getCustomerInfoForBillingAccountCont';
import putBillingInfoApex from '@salesforce/apex/BWC_CustomerAccountController.putBillingInfo';
import updateAccountPasscodeApex from '@salesforce/apex/BWC_CustomerAccountController.updateAccountPasscode';

export const getAccountDetailsForBillingAccountRecord =  async (recordId,interactionId) => {

     BwcUtils.log(`call getCustomerInforForBilling, recordId: ${recordId}, interactionId: ${interactionId}`);
 
     const responseWrapperJson = await getCustomerInfoForBillingAccountCont({recordId: recordId,InteractionId: interactionId});

     const responseWrapper = JSON.parse(responseWrapperJson);
     
     BwcUtils.log('response getCustomerInforForBillingAccount: ' + responseWrapperJson);

     return responseWrapper.account;
 
     
 }

export const putBillingInfo = async (ban, accountType, billingInfo) => {

    const billingInfoJson = JSON.stringify(billingInfo);

    BwcUtils.log('call putBillingInfo: ' + billingInfoJson);

    const putBillingInfoResultJson = await putBillingInfoApex({ban: ban, accountType: accountType, billingInfoJson: billingInfoJson});

    BwcUtils.log('result putBillingInfo: ' + putBillingInfoResultJson);

    const putBillingInfoResult = JSON.parse(putBillingInfoResultJson);
    if (!putBillingInfoResult.success) {
        throw new Error('Failed to put billing info: ' + putBillingInfoResult.message);
    }

    return putBillingInfoResult.response;

};

export const updateAccountPasscode = async (ban, accountType, passcodeInfo) => {

    const passcodeInfoJson = JSON.stringify(passcodeInfo);

    BwcUtils.log('call updateAccountPasscode: ' + passcodeInfoJson);

    const updatePasscodeInfoResultJson = await updateAccountPasscodeApex({ban: ban, accountType: accountType, passcodeInfoJson: passcodeInfoJson});

    BwcUtils.log('result updatePasscodeInfo: ' + updatePasscodeInfoResultJson);

    const updatePasscodeInfoResult = JSON.parse(updatePasscodeInfoResultJson);
    if (!updatePasscodeInfoResult.success) {
        throw new Error('Failed to update account passcode: ' + updatePasscodeInfoResult.message);
    }

    return updatePasscodeInfoResult.response;

};