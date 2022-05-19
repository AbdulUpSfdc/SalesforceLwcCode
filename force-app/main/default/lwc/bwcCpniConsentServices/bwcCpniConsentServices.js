import * as BwcUtils from 'c/bwcUtils';
import * as BwcAccountServices from 'c/bwcAccountServices';
import updateCpniConsentApex from '@salesforce/apex/BWC_CpniConsentController.updateCpniConsent';

export const updateCpniConsent = async (request, ban) => {
    const requestJson = JSON.stringify(request);
    BwcUtils.log('call update ConsentPreferences: ' + requestJson + ' BAN: ' + ban);

    const billingAccount = await BwcAccountServices.getBillingAccountForBan(ban);

    const responseWrapperJson = await updateCpniConsentApex({requestJson: requestJson, ban: billingAccount.Billing_Account_Number__c, accountType: billingAccount.Account_Type__c});

    BwcUtils.log('result updateCpniConsent: ' + responseWrapperJson);

    const responseWrapper = JSON.parse(responseWrapperJson);
    if (!responseWrapper.success) {
        throw BwcUtils.errorWithDetails('Call to updateCpniConsent failed', responseWrapper.message);
    }

    return responseWrapper.response;
}