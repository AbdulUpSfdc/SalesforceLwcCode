import getBillingAccountSummaryApex from '@salesforce/apex/BWC_BillingAccountController.getBillingAccountSummary';

export const getBillingAccountSummary = async (interactionId) => {

    const responseJson = await getBillingAccountSummaryApex({interactionId});
    return JSON.parse(responseJson);

}