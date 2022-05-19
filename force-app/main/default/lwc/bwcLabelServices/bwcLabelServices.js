import label_account from '@salesforce/label/c.BWC_Account_Label';
import label_agreeToTerms from '@salesforce/label/c.BWC_PaymentAgreeToTerms';
import label_attlogin_help from '@salesforce/label/c.BWC_CustomerSearchHelp_ATTLogin';
import label_authRemaining from '@salesforce/label/c.BWC_NotesHistory_AuthRemaining';
import label_ban_help from '@salesforce/label/c.BWC_CustomerSearchHelp_Ban';
import label_billingAdjustmentsIncorrectCreation from "@salesforce/label/c.BWC_BillingAdjustments_IncorrectCreation";
import label_cancelAutoPayNotAvailableBsse from "@salesforce/label/c.BWC_Cancel_Autopay_NotAvailable_BSSe";
import label_dueDateHelp from '@salesforce/label/c.BWC_PaymentDueDateHelp';
import label_enrollmentConfirmationEmailMessage from '@salesforce/label/c.BWC_Auto_Pay_ConfirmationEmailMessage';
import label_enrollmentSuccessMessage from '@salesforce/label/c.BWC_Auto_Pay_EnrollmentSuccess';
import label_enrollPaperlessMessage from '@salesforce/label/c.BWC_Billing_Enroll_Paperless_Message';
import label_enrollPaperlessMessageCustomer from '@salesforce/label/c.BWC_Billing_Enroll_Paperless_Message_Customer';
import label_enrollPaperlessTitle from '@salesforce/label/c.BWC_Billing_Enroll_Paperless_Title';
import label_enrollPaperMessage from '@salesforce/label/c.BWC_Billing_Enroll_Paper_Message';
import label_enrollPaperMessageCustomer from '@salesforce/label/c.BWC_Billing_Enroll_Paper_Message_Customer';
import label_enrollPaperTitle from '@salesforce/label/c.BWC_Billing_Enroll_Paper_Title';
import label_enroll_autopay from '@salesforce/label/c.BWC_Enroll_AutoPay';
import label_epaAutopayInformation from '@salesforce/label/c.BWC_EPA_AutopayInformation';
import label_fullRejectUnauthorizedMessage from "@salesforce/label/c.FullRejectUnauthorizedMessage";
import label_header from '@salesforce/label/c.BWC_CustomerSearch_Header';
import label_noAuthenticationOptionsMessage from '@salesforce/label/c.BWC_No_Authentication_Options';
import label_noBillingAccountWithAuthorization from '@salesforce/label/c.BWC_No_Billing_Account_With_Authorization';
import label_nohistorydata from '@salesforce/label/c.BWC_OrderHistory_NoOrderData';
import label_nopaymentdata from '@salesforce/label/c.BWC_BillAndPayment_NoPaymentData';
import label_noRecFound from '@salesforce/label/c.BWC_CustomerSearchError_NoRecFound';
import label_paymentAgreementVerify from '@salesforce/label/c.BWC_PaymentAgreementVerify';
import label_paymentConfirmationEmailMessage from '@salesforce/label/c.BWC_PaymentConfirmationEmailMessage';
import label_phone_help from '@salesforce/label/c.BWC_CustomerSearchHelp_Phone';
import label_storeThisProfile from '@salesforce/label/c.BWC_PaymentStoreThisProfile';
import label_takeOwnershipFailure from "@salesforce/label/c.bwc_Take_Ownership_failure";
import label_takeOwnershipSuccess from "@salesforce/label/c.bwc_Take_Ownership_sucess";
import label_templateDeleted from '@salesforce/label/c.BWC_Template_Is_Deleted_For_the_Associated_Communication_Record';
import label_templateUpdated from '@salesforce/label/c.BWC_Communication_Record_Is_Associated_With_the_Template';
import label_unexpectedError from '@salesforce/label/c.BWC_UnexpectedError_RefreshSection';
import label_update_autopay from '@salesforce/label/c.BWC_Update_AutoPay';
import label_deleteConfirmation from '@salesforce/label/c.BWC_ProfileConfirmDelete';
import label_deletePaymentProfileConfirmation from '@salesforce/label/c.BWC_ProfileConfirmReadMsgDelete';
import label_deleteSuccess from '@salesforce/label/c.BWC_ProfileDeleteSuccess';
import label_smartfields_info_disable from '@salesforce/label/c.BWC_Smart_Fields_Info_Disable';
import label_smartfields_disable_reason from '@salesforce/label/c.BWC_Smart_Fields_Disable_Reason';
import label_smartfields_disabled from '@salesforce/label/c.BWC_Smart_Fields_Disabled';
import label_delegateChangeSOAError from '@salesforce/label/c.BWC_Delegate_Change_SOA_Error';
import label_NoSOAError from '@salesforce/label/c.BWC_No_SOA_Error';
import label_NoEmployee_Record from '@salesforce/label/c.BWC_No_Employee_Record';

// Custom Labels Object
export const labels = {
    account: label_account,
    agreeToTerms: label_agreeToTerms,
    attlogin_help: label_attlogin_help,
    authRemaining: label_authRemaining,
    ban_help: label_ban_help,
    billingAdjustmentsIncorrectCreation: label_billingAdjustmentsIncorrectCreation,
    cancelAutoPayNotAvailableBsse: label_cancelAutoPayNotAvailableBsse,
    deleteConfirmation: label_deleteConfirmation,
    deletePaymentProfileConfirmation: label_deletePaymentProfileConfirmation,
    deleteSuccess: label_deleteSuccess,
    dueDateHelp: label_dueDateHelp,
    enrollAutoPay: label_enroll_autopay,
    enrollmentConfirmationEmailMessage: label_enrollmentConfirmationEmailMessage,
    enrollmentSuccessMessage: label_enrollmentSuccessMessage,
    enrollPaperlessMessage: label_enrollPaperlessMessage,
    enrollPaperlessMessageCustomer: label_enrollPaperlessMessageCustomer,
    enrollPaperlessTitle: label_enrollPaperlessTitle,
    enrollPaperMessage: label_enrollPaperMessage,
    enrollPaperMessageCustomer: label_enrollPaperMessageCustomer,
    enrollPaperTitle: label_enrollPaperTitle,
    epaAutopayInformation: label_epaAutopayInformation,
    fullRejectUnauthorizedMessage: label_fullRejectUnauthorizedMessage,
    header: label_header,
    noAuthenticationOptionsMessage: label_noAuthenticationOptionsMessage,
    noBillingAccountWithAuthorization: label_noBillingAccountWithAuthorization,
    nohistorydata: label_nohistorydata,
    nopayment: label_nopaymentdata,
    noRecFound: label_noRecFound,
    paymentAgreementVerify: label_paymentAgreementVerify,
    paymentConfirmationEmailMessage: label_paymentConfirmationEmailMessage,
    phone_help: label_phone_help,
    smartfields_disabled: label_smartfields_disabled,
    smartfields_info_disable: label_smartfields_info_disable,
    smartfields_info_disable_reason: label_smartfields_disable_reason,
    storeThisProfile: label_storeThisProfile,
    takeOwnershipFailure: label_takeOwnershipFailure,
    takeOwnershipSuccess: label_takeOwnershipSuccess,
    templateDeleted: label_templateDeleted,
    templateUpdated: label_templateUpdated,
    unexpectedError: label_unexpectedError,
    updateAutoPay: label_update_autopay,
    delegateChangeSOAError: label_delegateChangeSOAError,
	NoSOAError: label_NoSOAError,
	NoEmployeeRecordError: label_NoEmployee_Record
}