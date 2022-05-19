import logActivityApex from "@salesforce/apex/BWC_InteractionActivityController.logActivity";
import * as BwcUtils from 'c/bwcUtils';
/**
 * @param  {} interactionId Self-explain. Use bwcUtils.getInteractionIdFromUrl() if called from other than an interaction tab
 * @param  {} actionType Object from InteractionActivityValueMapping. This object already contains the action and type values
 * @param  {} detailRecord Additional payload
 * @param  {} additionalParams Object containing additional values for the activity. This can only include the following: billingAccountId, planId, assetId. Any other value will be ignored in apex
 * @example
 *
 * import { createActivity, InteractionActivityValueMapping } from 'c/bwcInteractionActivityService'
 *
 * let interactionId = this.recordId;
 * let detailRecord = {
 *      success: true,
 *      adjustmentAmount: 1000,
 *      effectiveDate: new Date()
 *  }
 *
 * //Simple interaction activity creation
 * createActivity(InteractionId, InteractionActivityValueMapping.PaymentAdjustmentSuspendedAccount, detailRecord);
 *
 *
 * let additionalParams = {
 *      billingAccountId: 'someBillingAccountId',
 *      planId: 'somePlanId',
 *      assetId: 'someAssetId'
 *  }
 *
 * //This will create an interaction activity and will link it with the given billing account, asset and plan records
 * createActivity(InteractionId, InteractionActivityValueMapping.PaymentAdjustmentSuspendedAccount, detailRecord, additionalParams);
 *
 */
export const createActivity = async (interactionId, actionType, detailRecord, additionalParams) => {

    const {action, type} = actionType;
    const activityObj = {
        interactionId,
        action,
        type,
    };

    if(additionalParams){

        const entries = Object.entries(additionalParams);

        for(const entry of entries){
          const [field, value] = entry;
          activityObj[field]=value;
        }

    }

    const activityJson = JSON.stringify(activityObj);
    const detailRecordJson = JSON.stringify(detailRecord);

    BwcUtils.log(activityJson);

    try{
        await logActivityApex({activityJson, detailRecordJson});
    } catch(error){
        BwcUtils.error(error);
    }

}

export const InteractionActivityValueMapping  = {

    Payment: {
        action: 'Onetime Payment',
        type: 'Billing | Payment',
    },
    BanInquiry: {
        action: 'Inquiry | Service',
        type: 'Inquiry',
    },
    BillingChangeCycleDate: {
        action: 'Change bill cycle date',
        type: 'Billing | Inquiry',
    },
    ViewPaymentHistory: {
        action:'View payment history',
        type: 'Inquiry',
    },
    BillingInquiryViewPaymentHistory: {
        action:'View payment history',
        type: 'Billing | Inquiry',
    },
    ViewBillPDF: {
        action:'Bill PDF',
        type: 'Billing | Inquiry',
    },
    InquiryViewBill:{
        action: 'Viewed Billing detail',
        type: 'Inquiry',
    },
    BillingInquiryViewBill:{
        action: 'Viewed Billing detail',
        type: 'Billing | Inquiry',
    },
    AddPaymentMethod:{
        action: 'Add payment method',
        type: 'Billing | Inquiry',
    },
    ChangeBillOwnership:{
        action:'Change billing ownership',
        type: 'Billing | Inquiry',
    },
    ViewChangeInstallments:{
        action: 'Installments',
        type: 'Billing | Inquiry',
    },
    MakeCollectionPayment:{
        action:'Collections',
        type: 'Billing | Payment',
    },
    BillingInquiryMakeCollectionPayment:{
        action:'Collections',
        type: 'Billing | Inquiry',
    },
    PaymentAdjustmentAddCharges:{
        action:'Payment or adjustment | Add charges',
        type: 'Billing | Inquiry',
    },
    PaymentAdjustmentAddGoodwillAdj:{
        action:'Payment or adjustment | Add goodwill adjustment',
        type: 'Billing | Inquiry',
    },
    PaymentAdjustmentAddBillAdj:{
        action:'Payment or adjustment | Add billing adjustment',
        type: 'Billing | Inquiry',
    },
    PaymentAdjustmentAddPendingChargeAdj:{
        action:'Payment or adjustment | Add pending charge adjustment',
        type: 'Billing | Inquiry',
    },
    PaymentAdjustmentSuspendedAccount:{
        action:'Payment or Adjustment | Suspended Account',
        type: 'Billing | Inquiry',
    },
    PaymentAdjustmentCancelledAccount:{
        action:'Payment or Adjustment | Cancelled Account',
        type: 'Billing | Inquiry',
    },
    ViewPromo:{
        action:'View promotions',
        type: 'Billing | Inquiry',
    },
    ProfileManagementAuthorizedusersAdd: {
        action: 'Authorized users | Add',
        type: 'Profile Management',
    },
    ProfileManagementAuthorizedusersDelete: {
        action: 'Authorized users | Delete',
        type: 'Profile Management',
    },
    ProfileManagementChangecontactinfoCBR: {
        action: 'Change contact info | CBR',
        type: 'Account Management',
    },
    ProfileManagementChangecontactinfoEmail	: {
        action: 'Change contact info | Email',
        type: 'Account Management',
    },
    ProfileManagementMyATTResetPwdQA: {
        action: 'MyAT&T Users | Reset Password & Security Q&A',
        type: 'Profile Management',
    },
    ProfileManagementMyATTResetPwd: {
        action: 'MyAT&T Users | Reset Password',
        type: 'Profile Management',
    },
    ProfileManagementMyATTUnlock: {
        action: 'MyAT&T Users | Unlock',
        type: 'Profile Management',
    },
    ProductServiceDeviceUpgrade: {
        action: 'Device | Upgrade',
        type: 'Product Service',
    },
    ProductServiceChangeServices: {
        action: 'Change Services',
        type: 'Product Service',
    },
    ProductServiceAddaline: {
        action: 'Add a line',
        type: 'Product Service',
    },
    TroubleshootResolveDeviceSupport: {
        action:'Device | Support',
        type: 'Troubleshoot & Resolve',
    },
    TroubleshootResolveDeviceIssues: {
        action:'Device | Issues',
        type: 'Troubleshoot & Resolve',
    },
    TroubleshootResolveServiceIssues: {
        action:'Service | Issues',
        type: 'Troubleshoot & Resolve',
    },
    InquiryAuthentication: {
        action:'Authentication',
        type: 'Inquiry',
    },
    InquiryNoAuthentication: {
        action:'No Authentication',
        type: 'Inquiry',
    },
    InquiryBypassAuthentication: {
        action:'Authentication Bypassed',
        type: 'Inquiry',
    },
    BillingPaymentImmediateOrFuture: {
        action: 'Immediate or Future dated',
        type: 'Billing | Payment',
    },
    BillingPaymentPromiseToPay: {
        action: 'Promise to pay',
        type: 'Billing | Payment',
    },
    BillingPaymentSplit: {
        action: 'Split payment',
        type: 'Billing | Payment',
    },
    BillingPaymentSecuredAdd: {
        action: 'Secured Payment - Add',
        type: 'Billing | Payment',
    },
    BillingPaymentSecuredEdit: {
        action: 'Secured Payment - Edit',
        type: 'Billing | Payment',
    },
    BillingPaymentSecuredCancel: {
        action: 'Secured Payment - Cancel',
        type: 'Billing | Payment',
    },
    BillingPaymentPromiseAdd: {
        action: 'Promise to Pay - Add',
        type: 'Billing | Payment',
    },
    BillingPaymentPromiseEdit: {
        action: 'Promise to Pay - Edit',
        type: 'Billing | Payment',
    },
    BillingPaymentPromiseCancel: {
        action: 'Promise to Pay - Cancel',
        type: 'Billing | Payment',
    },
    BillingPaymentEpaEnroll: {
        action: 'Epa Enroll',
        type: 'Billing | Payment',
    },
    BillingPaymentEpaView: {
        action: 'Epa View',
        type: 'Billing | Payment',
    },
    OrderDetailsReturns: {
        action: 'Order Details | Returns',
        type: 'Order Management',
    },
    ViewOrders: {
        action: 'View Order | Order Details',
        type: 'Order Management',
    },
    BillingAdjustmentsAdjustmentsReverseAdju: {
        action: 'Adjustments | Reverse Adjustment',
        type: 'Billing Adjustments',
    },
    BillingAdjustmentsAdjustmentsAddCharge: {
        action: 'Adjustments | Add Charge',
        type: 'Billing Adjustments',
    },
    CustomerCommunicationsResendEmail: {
        action: 'Customer Communications | Resend Email',
        type: 'Account Inquiry',
    },
    CustomerCommunicationsResendSMS: {
        action: 'Customer Communications | Resend SMS',
        type: 'Account Inquiry',
    },
    ViewBANUsageSummary: {
        action: 'Mobility Usage | View Summary',
        type: 'Profile Management',
    },
    CustomerSearch: {
        action: 'Inquiry | Customer Search',
        type: 'Inquiry',
    },
    CompleteInteraction: {
        action: 'Inquiry | Complete Interaction',
        type: 'Inquiry',
    },
    BillingAdjustmentWireless: {
        action: 'Adjustment Wireless | Billing Adjustment',
        type: 'Billing Adjustments'
    },
    ChangePlanUverse: {
        action: 'Change Uverse internet',
        type: 'Product Service'
    },
    ChangePlanWireless: {
        action: 'Change wireless',
        type: 'Product Service'
    },
    ChangePlanDTV: {
        action: 'Change DIRECTV',
        type: 'Product Service'
    },
    ChangePlanDTVStream: {
        action: 'Change DIRECTV STREAM',
        type: 'Product Service'
    },
    WFEGeneralSupport : {
        action : 'WFE | General Support',
        type : 'Tech Support'
    },
    ManageServiceAppointments: {
        action: 'Manage Appointments | Service',
        type: 'Tech Support'
    },
    ManageInstallAppointments: {
        action: 'Manage Appointments | Install',
        type: 'Tech Support'
    },
}