import * as BwcUtils from 'c/bwcUtils';
import customerSearchCont from '@salesforce/apexContinuation/BWC_UnifiedSearchController.customerSearchCont';
import linkInteractionWithAccountApex from '@salesforce/apex/BWC_UnifiedSearchController.linkInteractionWithAccount';
import accountDetailsCont from '@salesforce/apexContinuation/BWC_AccountDetailsController.accountDetailsCont';
import label_noAddressFound from '@salesforce/label/c.BWC_UnifiedSearch_NoAddressFound';
import label_noServiceAddress from '@salesforce/label/c.BWC_UnifiedSearch_NoServiceAddress';

import label_header from '@salesforce/label/c.BWC_CustomerSearch_Header';
import label_ban_help from '@salesforce/label/c.BWC_CustomerSearchHelp_Ban';
import label_phone_help from '@salesforce/label/c.BWC_CustomerSearchHelp_Phone';
import label_attlogin_help from '@salesforce/label/c.BWC_CustomerSearchHelp_ATTLogin';
import label_noRecFound from '@salesforce/label/c.BWC_CustomerSearchError_NoRecFound';
import label_zipAStMand from '@salesforce/label/c.BWC_CustomerSearchError_ZipAStMand';
import label_plsPopBan from '@salesforce/label/c.BWC_CustomerSearchError_PlsPopBan';
import label_manualSearch from '@salesforce/label/c.BWC_Interaction_ManualSearchRequired';
import label_errWhilSear from '@salesforce/label/c.BWC_CustomerSearchError_ErrWhilSear';
import label_BanNotInOrder from '@salesforce/label/c.BWC_CustomerSearchError_BANNotInOrder';
import label_selectValidState from '@salesforce/label/c.BWC_UnifiedSearch_SelectValidState';
import label_plsSelAcctTyp from '@salesforce/label/c.BWC_CustomerSearchError_PlsSelAcctTyp';

export const labels = {
    noAddressFound: label_noAddressFound,
    noServiceAddress: label_noServiceAddress,
    header: label_header,
    ban_help: label_ban_help,
    phone_help: label_phone_help,
    attlogin_help: label_attlogin_help,
    noRecFound: label_noRecFound,
    zipASTMand: label_zipAStMand,
    plsPopBan: label_plsPopBan,
    manualSearch: label_manualSearch,
    errorWhileSearch: label_errWhilSear,
    banNotInOrder: label_BanNotInOrder,
    selectValidState: label_selectValidState,
    selectAcctType: label_plsSelAcctTyp,
}

export const customerSearch = async (recordId, requestJson) => {

    BwcUtils.log(`Calling customerSearch. recordId: ${recordId}, requestJson: ${requestJson}`);
    const responseJson = await customerSearchCont({recordId, requestJson});

    BwcUtils.log('Response customerSearch: ', {responseJson});

    return JSON.parse(responseJson);
}

export const linkInteractionWithAccount = async (interactionId, accountId, hasUverseAccount) => {

    BwcUtils.log(`Calling linkInteractionWithAccount.
        interactionId: ${interactionId},
        accountId: ${accountId},
        hasUverseAccount: ${hasUverseAccount}`);

    await linkInteractionWithAccountApex({interactionId, accountId, hasUverseAccount});
}

export const accountDetails = async (recordId, billingAccountIdsJson, individualId) => {

    BwcUtils.log(`Calling accountDetails. recordId: ${recordId}, billingAccountIdsJson: ${billingAccountIdsJson}, individualId: ${individualId}`);
    const responseJson = await accountDetailsCont({recordId, billingAccountIdsJson, individualId});

    BwcUtils.log(`Response accountDetails: ${responseJson}`);

    return JSON.parse(responseJson);
}