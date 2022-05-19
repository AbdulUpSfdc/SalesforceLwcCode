import {LightningElement, api, wire} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getFieldValue, getRecord } from 'lightning/uiRecordApi';

// Other components
import * as BwcUtils from 'c/bwcUtils';
import * as BwcConstants from 'c/bwcConstants';
import * as BwcInteractActivityPublisher from 'c/bwcInteractActivityPublisher';

// Apex
import requestResend from '@salesforce/apex/BWC_CommunicationHistoryController.requestResend';

// Fields
import resendFlag__c from '@salesforce/schema/Communication_History__c.resendFlag__c';
import uniqueId__c from '@salesforce/schema/Communication_History__c.uniqueId__c';
import category__c from '@salesforce/schema/Communication_History__c.category__c';
import subCategory__c from '@salesforce/schema/Communication_History__c.subCategory__c';
import mode__c from '@salesforce/schema/Communication_History__c.mode__c';
import recipientAddress__c from '@salesforce/schema/Communication_History__c.recipientAddress__c';

const FIELDS = [
	"Communication_History__x.resendFlag__c",
	"Communication_History__x.uniqueId__c",
	"Communication_History__x.category__c",
	"Communication_History__x.subCategory__c",
	"Communication_History__x.recipientAddress__c",
	"Communication_History__x.mode__c",
];

const EMAIL_TYPE = 'email';
const SMS_TEXT_TYPE = 'sms';
const ERROR_VARIANT_TOAST = 'error';
const SUCCESS_VARIANT_TOAST = 'success';
const RESEND_FLAG = 'Y';

export default class BwcCommunicationResend extends LightningElement {

    @api recordId;

	interactionId;
	commHistory={};
	resendResponse;
	isRendered;

	@wire(getRecord, {recordId: '$recordId', fields: FIELDS})
	wiredRecord({error, data}){
		if(data){
			this.commHistory.data= data;
			this.resendCommunication();
		}

		if(error){
			BwcUtils.error(error);
			this.handleComplete();
		}
	}

	async resendCommunication(){

		this.populateInteractionId();

		try{

			if(this.resendFlag && this.resendFlag === RESEND_FLAG){

				// call Mulesoft API to request a Resend of Communication to CBUS
				await this.handleRequestResend();

			} else {

				this.handleNotResendableCommunication();

			}
		}catch(error){

            BwcUtils.error('Error calling handleRequestResend.', error);

			const toastArgs = {
				title: 'Error',
				message: 'Error resending the communication history record.',
				variant: ERROR_VARIANT_TOAST,
			}

			BwcUtils.showToast(this, toastArgs);

		}finally{
			this.handleComplete();
		}
	}

	async handleRequestResend(){


		let success;

		try {

			let toastMessage = '';
			let toastVariant = '';

			let result = await requestResend({objId: this.uniqueId, category: this.category});
			let resendResp = JSON.parse(result);

			if(resendResp && resendResp.statusCode === '200'){

				toastVariant = SUCCESS_VARIANT_TOAST;
				toastMessage = this.successToastMessage;
				success = true;

			} else {

				BwcUtils.error('Communication Resend Failed', resendResp);
				toastMessage = `Communication Resend Failed: ${resendResp.message}`;
				toastVariant = ERROR_VARIANT_TOAST;
				success = false;

			}

			const toastArgs = {
				title: success ? 'Success' : 'Error',
				message: toastMessage,
				variant: toastVariant,
			}

			BwcUtils.showToast(this, toastArgs);

		} catch (error) {

            BwcUtils.error('### Error MESSAGE: ',error);

			success = false;

			const toastArgs = {
				title: 'Error',
				message: 'Communication resend failed.',
				variant: ERROR_VARIANT_TOAST,
			}

			BwcUtils.showToast(this, toastArgs);
		} finally{
			let action = this.interactionActivityAction;
			if(action){
				this.createInteractionActivity(action, success);
			}
		}
	}

	handleNotResendableCommunication(){

		const toastArgs = {
            title: 'Error',
            message: this.notResendableToastMessage,
            variant: ERROR_VARIANT_TOAST,
        }

        BwcUtils.showToast(this, toastArgs);

	}

	handleComplete() {

		const completeEvent = new CustomEvent("processcomplete",
			{
				detail: 'COMPLETE'
			}
		);

		this.dispatchEvent(completeEvent);

    }

	createInteractionActivity(action, success){

        let intActPayload = {
            recordId: this.interactionId,
			uniqueId: this.uniqueId,
			category: this.category,
			subCategory: this.subCategory,
			success: success ? 'true' : 'false',
        }

        BwcInteractActivityPublisher.publishMessage(this.interactionId, action, JSON.stringify(intActPayload));
        BwcUtils.log('interaction activity event fired');
    }

	populateInteractionId(){
		this.interactionId = BwcUtils.getInteractionIdFromUrl();
	}

	get interactionActivityAction(){

		if(this.isEmailType){

			return BwcConstants.InteractionActivityValueMapping.CustomerCommunicationsResendEmail.action;

		} else if(this.isSmsType){

			return BwcConstants.InteractionActivityValueMapping.CustomerCommunicationsResendSMS.action;
		}

	}



	get successToastMessage(){

		if(this.isEmailType){

			return `Email resend: ${ this.recipientAddress || '' } - Email successfully sent.`;

		} else if(this.isSmsType){

			return `SMS resend: ${ this.recipientAddress || '' } - SMS successfully sent.`;

		}else{

			return 'This communication was sent.';
		}

	}

	get notResendableToastMessage(){

		if(this.isEmailType){

			return `Email Resend: ${ this.recipientAddress || '' }   - This email cannot be resent.`;

		}else if(this.isSmsType){

			return `SMS Resend: ${ this.recipientAddress || '' }  - This SMS cannot be resent.`;

		}else{

			return 'This Communication cannot be resent.';
		}

	}

	get uniqueId(){
		return getFieldValue(this.commHistory.data, uniqueId__c);
	}

	get category(){
		return getFieldValue(this.commHistory.data, category__c);
	}

	get subCategory(){
		return getFieldValue(this.commHistory.data, subCategory__c);
	}

	get resendFlag(){
		return getFieldValue(this.commHistory.data, resendFlag__c);
	}

	get type(){
		return getFieldValue(this.commHistory.data, mode__c);
	}

	get recipientAddress(){
		return getFieldValue(this.commHistory.data, recipientAddress__c);
	}

	get isEmailType(){
		return this.type?.toLowerCase() === EMAIL_TYPE;
	}

	get isSmsType(){
		return this.type?.toLowerCase() === SMS_TEXT_TYPE;
	}
 }