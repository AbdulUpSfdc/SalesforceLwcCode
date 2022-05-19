import * as BwcUtils from 'c/bwcUtils';
import * as BwcConstants from 'c/bwcConstants';
import getBillingAndPaymentsDataApex from '@salesforce/apex/BWC_BillingAndPaymentsController.getBillingAndPaymentsData';
import getBillingStatementsApex from '@salesforce/apexContinuation/BWC_BillingStatementController.getBillingStatementsCont';
import getBillingDetailsApex from '@salesforce/apex/BWC_BillingDetailsController.getBillingDetails';
import getEligibleForAdjustmentLineItemsApex from '@salesforce/apex/BWC_BillingDetailsController.getEligibleForAdjustmentLineItems';
import getBillPdfApex from '@salesforce/apex/BWC_BillingDetailsController.getBillPdf';

export const getBillingSummaries = async recordId => {

    BwcUtils.log('call getBillingSummaries: ' + recordId);

    const getBillingSummariesResult = await getBillingAndPaymentsDataApex({recordId: recordId});

    BwcUtils.log('result getBillingSummaries: ' + JSON.stringify(getBillingSummariesResult));

    if (!getBillingSummariesResult.success) {
        throw new Error('Failed to get billing summaries: ' + getBillingSummariesResult.message);
    }

    return getBillingSummariesResult.billingData;

};

export const getBillingStatements =  async (recordId, InteractionId) => {

     BwcUtils.log(`call getBillingStatements, recordId: ${recordId}, interactionId: ${InteractionId}`);
 
     const responseWrapperJson = await getBillingStatementsApex({recordId: recordId, InteractionId: InteractionId});
 
     BwcUtils.log('response getBillingStatements: ' + responseWrapperJson);
 
     const responseWrapper = JSON.parse(responseWrapperJson);
 
     return responseWrapper;
 }

// These are all different properties that can be returned with charges on statement
export const BillingDetailsChargeNodeTypes = [
    'acctChrgs', 'uverseTvChrgs', 'direcTvChrgs', 'combinedDtvChrgsList', 'hsiaChrgs', 'voipChrgs', 'wllVoiceChrgs', 'wllIntrntChrgs', 'wirelessChrgs'
];

export const getBillingDetails = async (product, statementId) => {

    BwcUtils.log('call getBillingDetails: ' + product + ', ' + statementId);

    const billingDetailsResultJson = await getBillingDetailsApex({product: product, statementId: statementId});

    BwcUtils.log('result getBillingDetails: ' + billingDetailsResultJson);

    const billingDetailsResult = JSON.parse(billingDetailsResultJson);
    if (!billingDetailsResult.success) {
        throw new Error('Failed to get billing details: ' + billingDetailsResult.message);
    }

    return billingDetailsResult.response;

};

export const getEligibleForAdjustmentLineItems = async (product, statementId, ban) => {

    BwcUtils.log('call getEligibleForAdjustmentLineItems: ' + product + ', ' + statementId + ', ' + ban);

    const billingDetailsResultJson = await getEligibleForAdjustmentLineItemsApex({product: product, statementId: statementId, ban: ban});

    BwcUtils.log('result getEligibleForAdjustmentLineItems: ' + billingDetailsResultJson);

    const billingDetailsResult = JSON.parse(billingDetailsResultJson);
    if (!billingDetailsResult.success) {
        throw new Error('Failed to get billing details: ' + billingDetailsResult.message);
    }

    return billingDetailsResult.response;

};

export const getBillPdf = async (product, statementId) => {

    BwcUtils.log('call getBillPdf: ' + product + ', ' + statementId);

    const billingDetailsResultJson = await getBillPdfApex({product: product, statementId: statementId});
    //console.log('result getBillPdf: ' + billingDetailsResultJson);

    const billingDetailsResult = JSON.parse(billingDetailsResultJson);

    if (!billingDetailsResult.success) {
        throw new Error('Failed to get bill pdf: ' + billingDetailsResult.message);
    }

    BwcUtils.log('getBillPdf: pdfReturned: ' + billingDetailsResult.response.content.pdfReturned);

    return billingDetailsResult.response;

};

/*
    Get amount detecting undefined object and credit indicator
*/
export const getAmount = (amountObject) => {
    if (amountObject === undefined) {
        return undefined;
    }

    if (amountObject.amtInd === 'CR') {

        // Credit
        return -1 * BwcUtils.toCurrency(amountObject.amt);

    }
    return BwcUtils.toCurrency(amountObject.amt);
}

/*
    Check if line item is eligible for adjustment
*/
export const isEligibleForAdjustment = (charge) => {
    if ((charge.type === BwcConstants.CHARGES.TYPES.TAXES || charge.type === BwcConstants.CHARGES.TYPES.SURCHARGES  || charge.type === BwcConstants.CHARGES.TYPES.PLAN_CHANGES) ||
        (charge.type === BwcConstants.CHARGES.TYPES.MONTHLY_CHARGES_DETAILS && charge.amtInd === BwcConstants.CHARGES.AMTIND.CR)) {
            return false;
    }
    return true;
}