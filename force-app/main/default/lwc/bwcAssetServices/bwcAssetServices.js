import * as BwcUtils from 'c/bwcUtils';
import getAssetsForBillingAccountsApex from '@salesforce/apex/BWC_AssetsController.getAssetsForBillingAccounts';

export const getAssetsForBillingAccounts = async (request) => {
    
    BwcUtils.log('call getAssetsForBillingAccounts', request);

    const requestJson = JSON.stringify(request);

    const response = await getAssetsForBillingAccountsApex({ requestJson });

    BwcUtils.log(`response getAssetsForBillingAccounts`, response);

    return response;
}