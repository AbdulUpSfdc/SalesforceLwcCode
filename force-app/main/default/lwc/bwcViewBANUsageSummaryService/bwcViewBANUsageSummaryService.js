import * as BwcUtils from 'c/bwcUtils';
import getUsageSummaryApex from '@salesforce/apex/BWC_BanUsageSummaryController.getUsageSummary';
import getInteractionAuthenticationApex from '@salesforce/apex/BWC_BanUsageSummaryController.getInteractionAuthentication';

export const getUsageSummary = async (request, recordId) => {

    const requestJson = JSON.stringify(request);

    BwcUtils.log('call getPlanUsageSummaryForBan: ' + requestJson);

    const getUsageSummaryResultJson = await getUsageSummaryApex({requestJson, recordId});

    BwcUtils.log('result getPlanUsageSummaryForBan: ' + getUsageSummaryResultJson);

    const responseWrapper = JSON.parse(getUsageSummaryResultJson);

    if (!responseWrapper.success) {
        throw new Error('Failed to get Usage Summary: ' + responseWrapper.message);
    }

    return responseWrapper.response;

};

export const getInteractionAuthentication = async (interactionId, billingAccountId) => {

    BwcUtils.log('call getInteractionAuthentication: ' + interactionId);

    const authenticationResultJson = await getInteractionAuthenticationApex({interactionId: interactionId, billingAccountId: billingAccountId});

    BwcUtils.log('result getInteractionAuthentication: ' + authenticationResultJson);

    return authenticationResultJson;

};