/*
    Shared components for adjustments functionality.
*/
import * as BwcConstants from 'c/bwcConstants';

/* Message Channels */
import OPENSUBTABMC from "@salesforce/messageChannel/BWC_OpenSubTab__c";

/* Labels */
import * as BwcLabelServices from 'c/bwcLabelServices';
import label_noAdjustmentHistory from '@salesforce/label/c.BWC_AdjustmentHistory_NoAdjustmentData';
import label_failedToCreateCharge from '@salesforce/label/c.BWC_CreateChargeWizard_Failed_To_Create_Charge';
import label_noBillingMarketCharges from '@salesforce/label/c.BWC_CreateChargeWizard_No_Billing_Market_Charges';
import label_positiveChargeAmount from '@salesforce/label/c.BWC_CreateChargeWizard_Positive_Charge_Amount';
import label_cdeRecommendationsError from '@salesforce/label/c.BWC_MakeAdjustmentWizard_CDE_Recommendations_Error';
import label_discardAdjustment from '@salesforce/label/c.BWC_MakeAdjustmentWizard_Discard_Adjustment';
import label_discardAdjustments from '@salesforce/label/c.BWC_MakeAdjustmentWizard_Discard_Adjustments';
import label_escalateAdjustmentsError from '@salesforce/label/c.BWC_MakeAdjustmentWizard_Escalate_Adjustments_Error';
import label_postAdjustmentsError from '@salesforce/label/c.BWC_MakeAdjustmentWizard_Post_Adjustments_Error';
import label_postAdjustmentsSuccess from '@salesforce/label/c.BWC_MakeAdjustmentWizard_Post_Adjustments_Success';
import label_noPendingAdjustments from '@salesforce/label/c.BWC_PendingChargesCredits_NoData';
import label_reverseAdjustmentError from '@salesforce/label/c.BWC_ReverseAdjustmentWizard_ReverseAdjustmentError';

export const labels = {
    /* General */
    account: BwcLabelServices.labels.account,
    noBillingAccountWithAuthorization: BwcLabelServices.labels.noBillingAccountWithAuthorization,
    unexpectedError: BwcLabelServices.labels.unexpectedError,
    /* Adjustment History */
    noAdjustmentHistory: label_noAdjustmentHistory,
    /* Create Charge Wizard */
    failedToCreateCharge: label_failedToCreateCharge,
    noBillingMarketCharges: label_noBillingMarketCharges,
    positiveChargeAmount: label_positiveChargeAmount,
    /* Make Adjustment Wizard */
    cdeRecommendationsError: label_cdeRecommendationsError,
    discardAdjustment: label_discardAdjustment,
    discardAdjustments: label_discardAdjustments,
    escalateAdjustmentsError: label_escalateAdjustmentsError,
    postAdjustmentsError: label_postAdjustmentsError,
    postAdjustmentsSuccess: label_postAdjustmentsSuccess,
    /* Pending Charges and Credits */
    noPendingAdjustments: label_noPendingAdjustments,
    /* Reverse Adjustment Wizard */
    reverseAdjustmentError: label_reverseAdjustmentError
}

// Agent Decision Statuses for CDE Recommendations
export const AgentDecisionStatus = {
    ACCEPTED: 'Accepted',
    OVERRIDDEN: 'Overridden',
    DISCARDED: 'Discarded'
}

// Final Action for Making Adjustments
export const FinalAction = {
    POST_ADJUSTMENT:'PostAdjustment',
    MANAGER_APPROVAL:'ManagerApproval',
}

// Hard Cap on Adjustments
export const MaxAdjustment = {
    label: '$100,000',
    value: 100_000
}

// Service product types 
export const ServiceProduct = {
    WIRELESS: 'Wireless',
    WIRELINE: 'Wireline',
    getValueFromType(serviceType) {
        
        const BillingAccountType = BwcConstants.BillingAccountType;

        switch(serviceType) {

            case BillingAccountType.WIRELESS.value:
            case BillingAccountType.WIRELESS.label:
                return this.WIRELESS;

            default:
                return this.WIRELINE;
        }
    }
}

/*
    Open View All Adjustments to view the full adjustment history.
*/
export const openViewAllAdjustments = (
    pageComponent,
    interactionId,
    interactionName,
    interactionName__c
) => {

    const pageReference = {
        type: 'standard__component',
        attributes: {
            componentName: 'c__BWCAdjustmentHistoryViewAllPage'
        },
        state: {
            c__recordId: interactionId
        }
    };

    const title = interactionName + ' - ' + interactionName__c;

    pageComponent.openSubtab( pageReference, title, 'custom:custom18' );

}

/*
    Open View All Pending Charges & Credits to view the full list of pending charges & credits.
*/
export const openViewAllPendingChargesCredits = (
    pageComponent,
    interactionId,
    interactionName,
    interactionName__c
) => {

    const pageReference = {
        type: 'standard__component',
        attributes: {
            componentName: 'c__bwcPendingChargesCreditsViewAllPage'
        },
        state: {
            c__recordId: interactionId
        }
    };

    const title = interactionName + ' - ' + interactionName__c;

    pageComponent.openSubtab( pageReference, title, 'custom:custom18' );

}

/*
    Open Add New Charge Wizard to create a new charge.
*/
export const openAddNewChargeWizard = (
    pageComponent,
    interactionId
) => {
    
    const pageReference = {
        type: 'standard__component',
        attributes: {
            componentName: 'c__bwcAddNewChargeWizardPage'
        },
        state: {
            c__recordId: interactionId
        }
    };
        
    pageComponent.openSubtab( pageReference, 'New Charge', 'custom:custom41' );
}

/*
    Open Reverse Adjustment Wizard to reverse an existing adjustment.
*/
export const openReverseAdjustmentWizard = (
    pageComponent,
    interactionId,
    interactionName,
    interactionName__c,
    ban,
    chargeCode,
    createdDate,
    adjustmentDescription,
    adjustmentAmount,
    entSeqNo,
    subscriberNo,
    nextBillDate
) => {

    const pageReference = {
        type: 'standard__component',
        attributes: {
            componentName: 'c__bwcReverseAdjustmentWizardPage'
        },
        state: {
            c__recordId: interactionId,
            c__ban: ban,
            c__chargeCode: chargeCode,
            c__createdDate: createdDate,
            c__adjustmentDescription: adjustmentDescription,
            c__adjustmentAmount: adjustmentAmount,
            c__entSeqNo: entSeqNo,
            c__subscriberNo: subscriberNo,
            c__nextBillDate: nextBillDate
        }
    };

    const title = interactionName + ' - ' + interactionName__c;
        
    pageComponent.openSubtab( pageReference, title, 'custom:custom41' );

}

/*
    Open Goodwill Adjustment Wizard to create a goodwill adjustment.
*/
export const openGoodwillAdjustmentWizard = (
    pageComponent, 
    interactionId,
    accountNumber,
    serviceType,
    customerName,
    billSequenceNumber,
    billStartDate,
    billEndDate,
    billingPeriod,
    billPaymentStatus,
    caseId,
    selectedStatementId
) => {

    const pageReference = {
        type: 'standard__component',
        attributes: {
            componentName: 'c__bwcMakeAdjustmentWizardPage'
        },
        state: {
            c__isGoodwill: true,
            c__recordId: interactionId,
            c__accountNumber: accountNumber,
            c__serviceType: serviceType,
            c__customerName: customerName,
            c__billSequenceNumber: billSequenceNumber,
            c__billStartDate: billStartDate,
            c__billEndDate: billEndDate,
            c__billingPeriod: billingPeriod,
            c__billPaymentStatus: billPaymentStatus,
            c__caseId: caseId,
            c__selectedStatementId: selectedStatementId
        }
    };

    const title = customerName + ' - ' + billingPeriod;

    pageComponent.openSubtab( pageReference, title, 'custom:custom41' );
}

/*
    Open Adjustment Wizard to make adjustments on charges.
*/
export const openAdjustmentWizard = (
    pageComponent, 
    interactionId,
    accountNumber,
    serviceType,
    customerName,
    selectedStatementId,
    billSequenceNumber,
    billStartDate,
    billEndDate,
    billingPeriod,
    billPaymentStatus,
    caseId
) => {

    const pageReference = {
        type: 'standard__component',
        attributes: {
            componentName: 'c__bwcMakeAdjustmentWizardPage'
        },
        state: {
            c__isGoodwill: false,
            c__recordId: interactionId,
            c__accountNumber: accountNumber,
            c__serviceType: serviceType,
            c__customerName: customerName,
            c__selectedStatementId: selectedStatementId,
            c__billSequenceNumber: billSequenceNumber,
            c__billStartDate: billStartDate,
            c__billEndDate: billEndDate,
            c__billingPeriod: billingPeriod,
            c__billPaymentStatus: billPaymentStatus,
            c__caseId: caseId
        }
    };

    const title = customerName + ' - ' + billingPeriod;

    pageComponent.openSubtab( pageReference, title, 'custom:custom41' );

}

/*
    Open the new escalation case when an agent escalates the adjustment to management.
*/
export const openEscalationCase = (
    pageComponent,
    caseId,
    interactionId,
    useMessageChannel
) => {

    const pageReference = {
        type: 'standard__recordPage',
        attributes: {
            recordId: caseId,
            objectApiName: 'Case',
            actionName: 'view'
        },
        state: {
            ws: `/lightning/r/Interaction__c/${interactionId}/view`
        }
    };

    useMessageChannel 
        ? pageComponent.publishMessage( OPENSUBTABMC, { pageReference, label: caseId, recordId: interactionId })
        : pageComponent.openSubtab( pageReference, caseId, 'custom:custom86' );
}

/*
    Sort Function used in Adjustments
    Will sort arrays of objects
    Can handle different field data types: Dates, Strings, Integers, Null
*/
export const sort = (data, sortedBy, sortDirection) => {

    const primer = function(field) {
        if(field == null || field === "") {
            return field;
        }

        if(!isNaN(field)) {
            return parseInt(field);
        }

        return field;
    };

    data.sort((a,b) => {

        const fieldA = primer(a[sortedBy]);
        const fieldB = primer(b[sortedBy]);

        return ((fieldA > fieldB) - (fieldB > fieldA)) * ((sortDirection === 'asc') ? 1 : -1);
    });

    return data;
}