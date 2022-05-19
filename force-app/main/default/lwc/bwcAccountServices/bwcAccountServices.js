import * as BwcUtils from 'c/bwcUtils';
import * as BwcConstants from 'c/bwcConstants';
import getBillingAccountsApex from '@salesforce/apex/BWC_AccountServiceController.getBillingAccounts';
import getBillingAccountForBanApex from '@salesforce/apex/BWC_AccountServiceController.getBillingAccountForBan';
import getBillingAccountForIdApex from '@salesforce/apex/BWC_AccountServiceController.getBillingAccountForId';
import getInteractionBillingAccountApex from '@salesforce/apex/BWC_AccountServiceController.getInteractionBillingAccount';
import getUserAssociationsApex from '@salesforce/apex/BWC_UserAssociationsController.getUserAssociations';
import getUserAssociationsForBillingAccountApex from '@salesforce/apexContinuation/BWC_UserAssociationsController.getUserAssociationsForBillingAccountCont';
import getUserAssociationsForBanApex from '@salesforce/apex/BWC_UserAssociationsController.getUserAssociationsForBan';
import addUserAssociationsApex from '@salesforce/apex/BWC_UserAssociationsController.addUserAssociations';
import deleteUserAssociationsApex from '@salesforce/apex/BWC_UserAssociationsController.deleteUserAssociations';
import getSortedBillingAccountsApex from  '@salesforce/apex/BWC_AccountServiceController.getSortedBillingAccounts';
import getCustomerAccountApex from  '@salesforce/apex/BWC_AccountServiceController.getCustomerAccount';

const accountTypes = [
    BwcConstants.BillingAccountType.WIRELESS,
    BwcConstants.BillingAccountType.UVERSE,
    BwcConstants.BillingAccountType.DTVNOW,
    BwcConstants.BillingAccountType.DTVS,
    BwcConstants.BillingAccountType.WATCHTV,
    BwcConstants.BillingAccountType.DTV,
    BwcConstants.BillingAccountType.POTS
];

export const getBillingAccounts = async (recordId, onlyL1, excludeUnified, requestedTypes, requestedBans, maskUnauthorized) => {

    BwcUtils.log(`call getBillingAccounts recordId: ${recordId}, onlyL1: ${onlyL1}, excludeUnified: ${excludeUnified}, requestedTypes: ${requestedTypes}, requestedBans: ${requestedBans}`);

    const billingAccountsResponseJson = await getBillingAccountsApex({recordId, onlyL1, excludeUnified, requestedTypes, requestedBans, maskUnauthorized});

    BwcUtils.log('response getBillingAccounts: ' + billingAccountsResponseJson);

    const billingAccountsResponse = JSON.parse(billingAccountsResponseJson);
    if (!billingAccountsResponse.success) {
        throw BwcUtils.errorWithDetails('Call to getBillingAccounts failed', billingAccountsResponse.message);
    }

    return billingAccountsResponse.billingAccounts;

};

export const getBillingAccountForBan = async ban => {

    BwcUtils.log('call getBillingAccountForBan ban: ' + ban);

    const billingAccountResponseJson = await getBillingAccountForBanApex({ban: ban});

    BwcUtils.log('response getBillingAccountForBan: ' + billingAccountResponseJson);

    const billingAccountResponse = JSON.parse(billingAccountResponseJson);
    if (!billingAccountResponse.success) {
        throw BwcUtils.errorWithDetails('Call to getBillingAccountForBan failed', billingAccountResponse.message);
    }

    return billingAccountResponse.billingAccount;

};

export const getBillingAccountForId = async billingAccountId => {

    BwcUtils.log('call getBillingAccountForId billingAccountId: ' + billingAccountId);

    const billingAccountResponseJson = await getBillingAccountForIdApex({billingAccountId: billingAccountId});

    BwcUtils.log('response getBillingAccountForId: ' + billingAccountResponseJson);

    const billingAccountResponse = JSON.parse(billingAccountResponseJson);
    if (!billingAccountResponse.success) {
        throw BwcUtils.errorWithDetails('Call to getBillingAccountForId failed', billingAccountResponse.message);
    }

    return billingAccountResponse.billingAccount;

};


export const getInteractionBillingAccount = async (interactionId, billingAccountId) => {

    BwcUtils.log(`call getInteractionBillingAccount, interactionId: ${interactionId}, billingAccountId: ${billingAccountId}`);

    const billingAccountResponseJson = await getInteractionBillingAccountApex({interactionId, billingAccountId});

    BwcUtils.log('response getInteractionBillingAccount: ' + billingAccountResponseJson);

    const billingAccountResponse = JSON.parse(billingAccountResponseJson);

    return billingAccountResponse;

};

export const getUserAssociations = async recordId => {

    BwcUtils.log('call getUserAssociations recordId: ' + recordId);

    const responseWrapperJson = await getUserAssociationsApex({recordId: recordId});

    BwcUtils.log('response getUserAssociations: ' + responseWrapperJson);

    const responseWrapper = JSON.parse(responseWrapperJson);
    if (!responseWrapper.success) {
        throw BwcUtils.errorWithDetails('Call to getUserAssociations failed', responseWrapper.message);
    }

    return responseWrapper.responses;

}

export const getUserAssociationsForBillingAccount =  async (recordId,interactionId) => {

    
     BwcUtils.log(`call getUserAssociationsForBillingAccount, recordId: ${recordId}, interactionId: ${interactionId}`);
 
     const responseWrapperJson = await getUserAssociationsForBillingAccountApex({recordId: recordId,InteractionId: interactionId});
 
     BwcUtils.log('response getUserAssociationsForBillingAccount: ' + responseWrapperJson);
 
     const responseWrapper = JSON.parse(responseWrapperJson);
 
     return responseWrapper;
 
     
 }

export const getUserAssociationsForBan = async (ban, accountType) => {

    BwcUtils.log('call getUserAssociationsForBan billingAccountId: ' + ban + ', ' + accountType);

    const responseWrapperJson = await getUserAssociationsForBanApex({ban: ban, accountType: accountType});

    BwcUtils.log('response getUserAssociationsForBan: ' + responseWrapperJson);

    const responseWrapper = JSON.parse(responseWrapperJson);
    if (!responseWrapper.success) {
        throw BwcUtils.errorWithDetails('Call to getUserAssociationsForBan failed', responseWrapper.message);
    }

    return responseWrapper.responses;

}

export const addUserAssociations = async userAssociations => {

    const requestJson = JSON.stringify(userAssociations);

    BwcUtils.log('call addUserAssociations: ' + requestJson);

    const responseWrapperJson = await addUserAssociationsApex({userAssociationsJson: requestJson});

    BwcUtils.log('result addUserAssociations: ' + responseWrapperJson);

    const responseWrapper = JSON.parse(responseWrapperJson);

    if (!responseWrapper.success) {
        throw new Error('Failed to add user: ' + responseWrapper.message);
    }

    return responseWrapper.responses;

};

export const deleteUserAssociations = async userAssociations => {

    const requestJson = JSON.stringify(userAssociations);

    BwcUtils.log('call deleteUserAssociations: ' + requestJson);

    const responseWrapperJson = await deleteUserAssociationsApex({userAssociationsJson: requestJson});

    BwcUtils.log('result deleteUserAssociations: ' + responseWrapperJson);

    const responseWrapper = JSON.parse(responseWrapperJson);

    if (!responseWrapper.success) {
        throw new Error('Failed to delete user: ' + responseWrapper.message);
    }

    return responseWrapper.responses;

};

export const getAccountTypeLabel = value => {

    const accountType = accountTypes.find(accountType => accountType.value === value);

        if(accountType) return accountType.label;

        return '';
}

export const getSortedBillingAccounts = async (recordId, onlyL1, excludeUnified, requestedTypes, requestedBans, maskUnauthorized, customPermission) => {

    BwcUtils.log(`call getSortedBillingAccounts recordId: ${recordId}, onlyL1: ${onlyL1}, excludeUnified: ${excludeUnified}, requestedTypes: ${requestedTypes}, requestedBans: ${requestedBans}, customPermission ${customPermission}`);

    const billingAccountsResponseJson = await getSortedBillingAccountsApex({recordId, onlyL1, excludeUnified, requestedTypes, requestedBans, maskUnauthorized, customPermission});

    BwcUtils.log('response getSortedBillingAccounts: ' + billingAccountsResponseJson);

    const billingAccountsResponse = JSON.parse(billingAccountsResponseJson);
    if (!billingAccountsResponse.success) {
        throw BwcUtils.errorWithDetails('Call to getSortedBillingAccounts failed', billingAccountsResponse.message);
    }

    return billingAccountsResponse.billingAccounts;
}

export const getCustomerAccount = async (recordId) => {

    BwcUtils.log(`call getCustomerAccount interactionId: ${recordId}`);

    try {
        const customerAccountsResponseJson = await getCustomerAccountApex({recordId});

        BwcUtils.log('response getCustomerAccount: ' + customerAccountsResponseJson);

        return JSON.parse(customerAccountsResponseJson);
        
    } catch (error) {

        throw BwcUtils.errorWithDetails('Call to getCustomerAccount failed', error);

    }

};