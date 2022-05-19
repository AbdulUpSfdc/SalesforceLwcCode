import {LightningElement, api} from 'lwc';

const PAYMENT_REQUEST_HELP_TEXT = "Click to collect payment/refund method";
const PAYMENT_REQUEST_ALT_TEXT = "Payment Request";
const CASE_ACTION_BASED_REQUEST_HELP_TEXT = "Case Action Based Request";
const CASE_ACTION_BASED_REQUEST_ALT_TEXT = "Case Action Based Request";
const CASH_PAYMENT_LABEL_TEXT = "Cash Payment?";
const CASH_PAYMENT_BUTTON_LABEL_TEXT = "Original Payment Type is Cash";
const COLLECT_PAYMENT_REFUND_TEXT = "Collect Payment/Refund Method";
const COLLECT_PAYMENT_TEXT = "Collect Payment Method";
const PAYMENT_METHOD_REFUND_SUBMITTED_TEXT = "Payment Method/Refund Submitted";
const PAYMENT_METHOD_SUBMITTED_TEXT = "Payment Method Submitted";

export default class BwcPaymentRequest extends LightningElement {
	@api recordId;
	@api ban;
	@api isSuccess;
	@api showRefund;
	@api capabilities;

	paymentRequestHelpText = PAYMENT_REQUEST_HELP_TEXT;
	caseActionBasedRequestHelpText = CASE_ACTION_BASED_REQUEST_HELP_TEXT;
	paymentRequestAltText = PAYMENT_REQUEST_ALT_TEXT;
	caseActionBasedRequestAltText = CASE_ACTION_BASED_REQUEST_ALT_TEXT;
	cashPaymentLabelText = CASH_PAYMENT_LABEL_TEXT;
	cashPaymentButtonLabelText = CASH_PAYMENT_BUTTON_LABEL_TEXT;
	collectPaymentRefundText = COLLECT_PAYMENT_REFUND_TEXT;
	collectPaymentText = COLLECT_PAYMENT_TEXT;
	paymentMethodRefundSubmittedText = PAYMENT_METHOD_REFUND_SUBMITTED_TEXT;
	paymentMethodSubmittedText = PAYMENT_METHOD_SUBMITTED_TEXT;

	openTabComponentName = 'c__BWCCollectPaymentMethodPage';
	openTabType = 'standard__component';
	openTabLabel = 'Collect Payment Method';
	openTabIcon = 'custom:custom41';
	isChecked = false;
	isCashPmtDisabled = false;

	@api handleShowRefundChange(value){
		console.log('@@@ ENTERED handleShowRefundChange ', value);
		this.showRefund = value;
	}

	@api handleIsSuccessChange(value){
		console.log('@@@ ENTERED handleIsSuccessChange ', value);
		this.isSuccess = value;
		this.isCashPmtDisabled = this.isSuccess === true ? true : false;
	}

	@api handleCapabilitiesChange(value){
		console.log('@@@ ENTERED handleCapabilitiesChange ', value);
		this.capabilities = value;
	}

	handleToggleChange(event){
		console.log('@@@ ENTERED handleToggleChange ', event.detail);
		this.isChecked = event.detail.checked == true ? true : false;
		const checkedEvent = new CustomEvent("cashpaymentcheckedchange", {
			detail: event.detail.checked
			});
		this.dispatchEvent(checkedEvent);
	}

	handleCollectPaymentMethod(event){
		console.log('@@@ ENTERED handleCollectPaymentMethod ');
        this.startCollectPaymentMethod();
	}
    
	/*
        Set message to open sub tab for collect payment method.
    */
    startCollectPaymentMethod() {
		console.log('@@@ ENTERED startCollectPaymentMethod');
		//console.log('@@@ startCollectPaymentMethod - RECORD ID==>', this.recordId);
		//console.log('@@@ startCollectPaymentMethod - CAPABILITIES==>', this.capabilities);
		//console.log('@@@ startCollectPaymentMethod - BAN==>', this.ban);
        const message = {
            pageReference: {
                type: this.openTabType,
                attributes: {
                    componentName: this.openTabComponentName
                },
                state: {
                    c__recordId: this.recordId,
                    c__capabilities: this.capabilities.length > 0 ? JSON.stringify(this.capabilities) : undefined,
                    c__defaultBan: this.ban
                }                
            },
            label: this.openTabLabel,
            icon: this.openTabIcon
        };
		console.log('@@@ startCollectPaymentMethod - message', message);
		const openSubTabEvent = new CustomEvent("triggeropensubtab", {
			detail: message
			});
		this.dispatchEvent(openSubTabEvent);
    }

}