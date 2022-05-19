import * as BwcUtils from 'c/bwcUtils';
import getEscalationCasesByBillingAccountApex from '@salesforce/apex/BWC_EscalationCaseServiceController.getEscalationCasesByBillingAccount';

export const getEscalationCasesByBillingAccount = async (billingAccountNumber) => {

    BwcUtils.log('call getEscalationCasesByBillingAccount, billingAccountNumber: ' + billingAccountNumber);

    const response = await getEscalationCasesByBillingAccountApex({ billingAccountNumber });

    BwcUtils.log('response getEscalationCasesByBillingAccount', response);

    return response;
}