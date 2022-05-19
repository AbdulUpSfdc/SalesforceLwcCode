import { LightningElement,api ,track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import * as closeTabPublisher from 'c/bwc_CloseFocusedTabPublisher';
import * as BWCDISABLECLOSETAB from 'c/bwcDisableCloseTabPublisher';
import getCaseDetails from '@salesforce/apex/CaseEscalationFieldsController.getCaseDetails';
import getCaseActionValues from '@salesforce/apex/CaseEscalationFieldsController.getCaseActionValues';
import getCaseRefundPaymentMethod from '@salesforce/apex/BWC_RedactionController.getRefundPaymentMethod';
import deleteCase from '@salesforce/apex/BWC_Case_Delete.deleteCase';
import { getRecord, getFieldValue  } from 'lightning/uiRecordApi';

//
import * as BwcUtils from 'c/bwcUtils';
import {
    subscribe,
    unsubscribe,
    APPLICATION_SCOPE,
    MessageContext
} from 'lightning/messageService';
import paymentMethodComplete from '@salesforce/messageChannel/BWC_Completion__c';

import * as BwcConstants from 'c/bwcConstants';
import * as bwcLICPublisher from 'c/bwcMsgToLICPublisher';
import * as bwcInteractActivityPublisher from 'c/bwcInteractActivityPublisher';
import * as bwcDispatchEscalationCase from 'c/bwcDispatchEscalationCase';
import * as BwcLabelServices from "c/bwcLabelServices";

//Case field
import SUBSCRIBER_CTN_CASE from '@salesforce/schema/Case.CTN__c';

const CASE_FIELDS = [SUBSCRIBER_CTN_CASE];
const CASE_TYPE_BILLING_INQUIRY = 'Billing | Inquiry';
const CASE_TYPE_BILLING_PAYMENT = 'Billing | Payment';
const CASE_TYPE_ORDER_ACTION_ONLINE_FALLOUT_WIRELESS = 'Order Action | Online fallout Wireless'; 		//SPTSFDCSPT-8366
const CASE_TYPE_BILLING_ADJUSTMENT = 'Billing | Adjustment';

const PAYMENT_TYPE_CASH = 'Cash';
const PAYMENT_TYPE_CREDIT_OR_DEBIT = 'Credit / ATM card';
const PAYMENT_TYPE_BANK_TRANS_OR_EFT = 'Bank Transfer / EFT';
const PAYMENT_PROFILE_PAYMENT_METHOD_TYPE_CARD = 'CARD';
const PAYMENT_PROFILE_PAYMENT_METHOD_TYPE_BANK_ACCOUNT = 'BANKACCOUNT';
const PAYMENT_METHOD_CARD_NUMBER = 'Card number';

const REFUND_TYPE_CHECK = 'Check';
const REFUND_TYPE_BANK_TRANSFER = 'Bank Transfer';
const REFUND_TYPE_CREDIT_ATM_CARD = 'Credit / ATM Card';
const REFUND_TYPE_BANK_TRANS_OR_EFT = 'Bank Transfer / EFT';
const REFUND_PROFILE_PAYMENT_METHOD_TYPE_BANK_ACCOUNT = 'BANKACCOUNT';



const CASE_ACTION_INCLUDES_AUTOPAY_TRANSACTION_ISSUES = 'autopay transaction issues';
const CASE_ACTION_INCLUDES_PAYMENT_INQUIRY = 'payment inquiry';
const CASE_ACTION_INCLUDES_DEPOSIT_REMOVAL = 'deposit removal';
const CASE_ACTION_INCLUDES_REFUND = 'refund';
const CASE_ACTION_INCLUDES_NSF_BLOCK_REMOVE = 'nsf - payment block remove';
const CASE_ACTION_INCLUDES_NSF_DISPUTE = 'nsf - nsf dispute';
const CASE_ACTION_INCLUDES_NSF_ORIGINAL_CHK_REQUEST = 'nsf - original nsf check request';
const CASE_ACTION_INCLUDES_NSF_OTHER = 'nsf - other nsf issues';
const CASE_ACTION_INCLUDES_SBP_TRANSACTION_ISSUES = 'sbp transaction issue';
const CASE_ACTION_REFUND_REQUEST_STATUS_STOP = 'refund request - refund status/stop payment request';
const CASE_ACTION_TRANS_PMT_OR_FUNDS = 'transfer payment or funds';
//SPTSFDCSPT-8366
const CASE_ACTION_WIRELESS_ORDER_FALLOUT_DF = 'Wireless order fallout | DF';						
const CASE_ACTION_WIRELESS_ORDER_FALLOUT_IN_STORE = 'Wireless order fallout | In Store';
const CASE_ACTION_WIRELESS_ORDER_FALLOUT_READY_TO_GO = 'Wireless order fallout | Ready to Go';

const LIGHTNING_INPUT_FIELD_SHOW = 'slds-form-element slds-show';
const LIGHTNING_INPUT_FIELD_HIDE = 'slds-form-element slds-hide';


const CaseAction2Capabilities = Object.freeze({
	'Autopay Transaction Issues - Overpayment' : ['CREDCARD', 'BANK_WITH_CHECK_NUM', 'REFUND_BANK_NOCHECK_CREDCARD'],

	'SBP Transaction Issue' : ['CREDCARD', 'BANK_WITH_CHECK_NUM', 'REFUND_BANK_NOCHECK_CREDCARD'],

	'Payment Inquiry - Duplicate Charges Service' : ['CREDCARD', 'BANK_WITH_CHECK_NUM', 'REFUND_BANK_NOCHECK_CREDCARD'],
	'Payment Inquiry - Duplicate Charges Equipment' : ['CREDCARD', 'BANK_WITH_CHECK_NUM', 'REFUND_BANK_NOCHECK_CREDCARD'],
	'Payment Inquiry - Hold Release Letter Request' : ['CREDCARD', 'BANK_WITH_CHECK_NUM', 'REFUND_BANK_NOCHECK_CREDCARD'],
	'Payment Inquiry - Posted for Incorrect Amount' : ['CREDCARD', 'BANK_WITH_CHECK_NUM', 'REFUND_BANK_NOCHECK_CREDCARD'],
	'Payment Inquiry - Unrecognized Payment' : ['CREDCARD', 'BANK_WITH_CHECK_NUM', 'REFUND_BANK_NOCHECK_CREDCARD'],
	'Payment Inquiry - Customer Does Not Recognize Charge' : ['CREDCARD', 'BANK_WITH_CHECK_NUM', 'REFUND_BANK_NOCHECK_CREDCARD'],

	'Deposits - Deposit Transfers' : ['BANK_WITH_CHECK_NUM', 'CREDCARD'],
	'Deposits - Deposit Removal / Waiver' : ['CREDCARD', 'BANK_WITH_CHECK_NUM', 'REFUND_BANK_NOCHECK_CREDCARD'],
	'Deposits - Misapplied Deposit Payment' : ['BANK_WITH_CHECK_NUM', 'CREDCARD'],

	'NSF - Payment block remove' : ['BANK_WITH_CHECK_NUM', 'CREDCARD'],

	'Refund Request - Bankruptcy Refund Request' : ['CREDCARD', 'BANK_WITH_CHECK_NUM', 'REFUND_BANK_NOCHECK_CREDCARD'],
	'Refund Request - Payment refund request' : ['CREDCARD', 'BANK_WITH_CHECK_NUM', 'REFUND_BANK_NOCHECK_CREDCARD'],
	'Refund Request - Check Not Made Out To AT&T Mobility' : ['CREDCARD', 'BANK_WITH_CHECK_NUM', 'REFUND_BANK_NOCHECK_CREDCARD'],
	'Refund Request - Refund Status/Stop Payment Request' : ['CREDCARD', 'BANK_WITH_CHECK_NUM', 'REFUND_BANK_NOCHECK_CREDCARD'],

	'Transfer Payment or Funds - Account # to Compass' : ['BANK_WITH_CHECK_NUM', 'CREDCARD'],
	'Transfer Payment or Funds - Account # to Misc GL' : ['BANK_WITH_CHECK_NUM', 'CREDCARD'],
	'Transfer Payment or Funds - Compass to Account #' : ['BANK_WITH_CHECK_NUM', 'CREDCARD'],
	'Transfer Payment or Funds - Non-Posted to Service' : ['BANK_WITH_CHECK_NUM', 'CREDCARD'],
	'Transfer Payment or Funds - Suspense to Account #' : ['BANK_WITH_CHECK_NUM', 'CREDCARD'],
	'Transfer Payment or Funds - Suspense to Invoice' : ['BANK_WITH_CHECK_NUM', 'CREDCARD']
});

const ASSET_FIELDS = [
    {apiName: 'Device_IMEI__c', label:'Device IMEI'},
    {apiName: 'Device_Make_Model__c', label:'Device Make & Model'},
    {apiName: 'Device_Manufacturer__c', label:'Device Manufacturer'},
    {apiName: 'Device_Type__c', label:'Device Type'},
    {apiName: 'Rate_Plan__c', label:'Rate Plan Name'},
    {apiName: 'Rate_Plan_Code__c', label:'Rate Plan Product Code'},
    {apiName: 'SIM_Smart_Chip__c', label:'SIM / Smart Chip'},
    {apiName: 'New_Device_Product_Code__c', label:'Device Product Code'},
    {apiName: 'Mobile_Status__c', label:'Subscriber Status'},
    {apiName: 'Sub_Market_Site__c', label:'SubMarket'},
    {apiName: 'User_Subscriber_Name__c', label:'Subscriber Name'},
]

const CASE_ACTION_HELP_TEXT = "Some case types are restricted (e.g. Urgent cases) - if no case action presented then none are available based on your permissions";

const TYPE_OF_CUSTOMER_TYPE = ['Apply to acct and Refund Remaining Balance',
'Stop Payment/Reissue',
'Stop Payment/Reapply to Customer Account'];

export default class CaseEscalationDynamicFields extends LightningElement {
    @api objectApiName='Case';
    @track showLoadingSpinner = false;
    @track lstOfModelCase;
    @api recordId;
    @api isdyDropDown=false;
    @track isOnLoad=true;
    @track caseDynamicFieldInfo;
    @track selectOpt = [];
    @track selectOptionsVal='';
    @track allOptionItems={};
    @track allDyFields=[];
    @track isShowAllItems=false;
    @track mapOfAssetIds={};
    @track caseActionOptions = [];
	@track CaseAction='';
    @track caseType='';
    // @track contactId;
    @track hasContact=false;
	disabledButton = false;

	showPaymentMethod = false;
	isChecked = false;
	isSuccess = false;
	isCashPmtDisabled = false;
	showRefund = false;
	subscription = null;
	pymtType = undefined;
	nameAttachedToPymt = undefined;
	showTypeCustRfndFld = false;
	showIssueType = false;
	//initialPymtType = undefined;

    currentCTN;
    caseActionHelpText=CASE_ACTION_HELP_TEXT;
	paymentTypeCash = false;
	capabilities = [];

    // Labels
    labels = BwcLabelServices.labels;

    @wire(getRecord, { recordId: '$recordId', fields: CASE_FIELDS})
    wiredCase({error, data}){
        if(data){
            BwcUtils.log("%cCaseEscalationDynamicFields, wiredCase", "color:green");
            BwcUtils.log({data});
            this.currentCTN = getFieldValue(data, SUBSCRIBER_CTN_CASE);
        } else if(error){
            BwcUtils.error("CaseEscalationDynamicFields, wiredCase", error);
        }
    }

    onCaseType(event){
        // Show toast message if Billing | Adjustment is selected
        if (event.target.value === CASE_TYPE_BILLING_ADJUSTMENT) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Error",
                    message: this.labels.billingAdjustmentsIncorrectCreation,
                    variant: "error",
                    mode: "sticky"
                })
            );
            this.disabledButton = true;
        } else {
            this.disabledButton = false;
        }

        this.allDyFields = [];
        this.isShowAllItems = false;
        this.caseType = event.target.value;
        this.CaseAction = "";
        BwcUtils.log("Select type=", event.target.value);
        this.fillAllActionsItems();
        this.callGetActionValues();
        this.pymtType = event.target.value;
    }

    onCaseAction(event){
		
		
		BwcUtils.log('### ENTERED onCaseAction ', event);
		let pymtReq = undefined;
        this.allDyFields=[];
		this.capabilities = [];
        this.isShowAllItems=false;
        this.CaseAction=event.target.value;
        this.fillAllActionsItems();
		let action = event.target.value.toLocaleLowerCase();
		this.showTypeCustRfndFld = action.includes(CASE_ACTION_REFUND_REQUEST_STATUS_STOP)
		 ? true : false;		
		 
		/*
		this.showPaymentMethod = this.caseType.includes(CASE_TYPE_BILLING_PAYMENT) &&
		!action.includes(CASE_ACTION_INCLUDES_NSF_DISPUTE.toLocaleLowerCase()) &&
		!action.includes(CASE_ACTION_INCLUDES_NSF_ORIGINAL_CHK_REQUEST.toLocaleLowerCase()) &&
		!action.includes(CASE_ACTION_INCLUDES_NSF_OTHER.toLocaleLowerCase()) ? true : false;
		//BwcUtils.log('### CAPABILITIES', this.capabilities);
		this.showRefund = action.includes(CASE_ACTION_INCLUDES_AUTOPAY_TRANSACTION_ISSUES.toLocaleLowerCase()) ||
		action.includes(CASE_ACTION_INCLUDES_PAYMENT_INQUIRY.toLocaleLowerCase()) ||
		action.includes(CASE_ACTION_INCLUDES_DEPOSIT_REMOVAL.toLocaleLowerCase()) ||
		action.includes(CASE_ACTION_INCLUDES_SBP_TRANSACTION_ISSUES.toLocaleLowerCase()) ||
		action.includes(CASE_ACTION_INCLUDES_REFUND.toLocaleLowerCase())
		? true : false;
		*/
		for (const [key, value] of Object.entries(CaseAction2Capabilities)) {
			if(event.target.value === key){
			this.capabilities = value;
			}/**/
		}
		
		pymtReq = this.template.querySelector('c-bwc-payment-request');
		if(pymtReq){
			pymtReq.handleShowRefundChange(this.showRefund);
			pymtReq.handleCapabilitiesChange(this.capabilities);
		}

    }
    onSelectItem(event){
		
        this.allDyFields=[];
        this.selectOptionsVal=event.target.value;
        this.isShowAllItems=false;
		
        if(event.target.value!=''){
            this.allDyFields=this.allOptionItems[event.target.value];
            this.isShowAllItems=true;
			console.log('alldyfields are ',this.alldyfields);
        }
    }

    onloadEditForm (event) {
        if(this.isOnLoad){
            //this.CaseAction=event.detail.records[this.recordId].fields['CaseAction__c'].displayValue;
            this.caseType=event.detail.records[this.recordId].fields['Type'].displayValue;
            //BwcUtils.log("######@@@Onload",JSON.stringify(event.detail.records[this.recordId]));
            this.fillAllActionsItems();
            this.callGetActionValues();
			this.isChecked = false;
            //BwcUtils.log("### CaseAction",JSON.stringify(this.CaseAction));
			this.showPaymentMethod = this.CaseAction && this.caseType.includes(CASE_TYPE_BILLING_PAYMENT) ? true : false;
			
			//BwcUtils.log('### cashPmtToggle ', this.template.querySelector('cashPmtToggle').value);
			//this.showPaymentMethod = false;
        }
    }

    callGetActionValues(){
        getCaseActionValues({caseType: this.caseType})
        .then((result)=>{

            let parsedResult = JSON.parse(result);
		
            //BwcUtils.log("### parsedResult result--- ",parsedResult);
            this.caseActionOptions = parsedResult.map((entry)=>{

                let newEntry = {
                    label: entry.label,
                    value: entry.value
                }

                return newEntry
            })
        })
        .catch(error=>{
            BwcUtils.error('Error on getCaseActionValues', error);
        });
    }

    fillAllActionsItems(){
		//BwcUtils.log('ENTERED fillAllActionsItems ');
        this.isShowAllItems=false;
        this.isdyDropDown=false;

        if(this.CaseAction!='' && this.caseType!=''){

            this.selectOpt=[];
            this.allOptionItems={};
            this.showLoadingSpinner=true;
            this.allDyFields=[];
            this.isShowAllItems=false;
            this.mapOfAssetIds={};
            getCaseDetails({selAction:this.CaseAction,caseType:this.caseType,caseRecId:this.recordId}).then(result => {
                BwcUtils.log("### getCaseDetails result--- ",JSON.stringify(result));
                this.isOnLoad=false;
                this.lstOfModelCase = result.lstOfModelCase;
				
				//SPTSFDCSPT-8396_START
				this.lstOfModelCase.forEach(element => {
					if (element.apiName == 'Order_ID__c') {element.showHyperlink = true} else {element.showHyperlink = false}
				});
				//SPTSFDCSPT-8396_END
                this.showLoadingSpinner=false;
                this.caseDynamicFieldInfo=result.caseDynamicFieldInfo;
                //BwcUtils.log("### caseDynamicFieldInfo--- ",JSON.stringify(this.caseDynamicFieldInfo));
                if(this.caseDynamicFieldInfo == null || this.caseDynamicFieldInfo == undefined) return;

                var allCaseItems=this.caseDynamicFieldInfo;
                var allKeys=Object.keys(this.caseDynamicFieldInfo)+'';
                //BwcUtils.log("### allKeys--- ",JSON.stringify(allKeys));
				if(allKeys){
					var res = allKeys.split(",");

					for(var i=0;i<res.length;i++){

						var objItems=allCaseItems[res[i]];
						var allKeyItems=Object.keys(objItems)+'';
						const option = {
							label: allKeyItems+'',
							value: allKeyItems+''
						};

						this.allOptionItems[allKeyItems]=objItems[allKeyItems];
						this.selectOpt = [ ...this.selectOpt,option ];

						this.mapOfAssetIds[allKeyItems]=res[i];
						// if(i==0){
						//     this.allDyFields=[];
						//     this.selectOptionsVal = this.currentCTN;
						//     this.allDyFields=this.allOptionItems[this.selectOptionsVal];
						//     this.isShowAllItems=true;
						//     BwcUtils.log("Default!!!",this.allDyFields);
						//     BwcUtils.log("DefaultallKeyItems!!!",allKeyItems);

						// }

					}
				}
                if(this.currentCTN!='' && this.currentCTN != undefined && this.currentCTN != null){
                    this.allDyFields=[];
                    this.selectOptionsVal = this.currentCTN;
                    this.allDyFields=this.allOptionItems[this.selectOptionsVal];
                    this.isShowAllItems=true;
                }

                //BwcUtils.log('### this.allOptionItems', JSON.stringify(this.allOptionItems));

                if(this.allOptionItems){
                    this.isdyDropDown=true;
                }

            })
            .catch(error => {
                BwcUtils.log({error});
                this.showLoadingSpinner=false;
                this.isOnLoad=false;
            });

        }else{
            BwcUtils.log("Else");
            this.lstOfModelCase=null;
        }
    }

    onSubmitHandler(event){
        BwcUtils.log("### ENTERED onSubmitHandler");
        const inputFields = event.detail.fields;
        BwcUtils.log("### inputFields", inputFields);
        BwcUtils.log("### this.isdyDropDown", this.isdyDropDown);
        BwcUtils.log("### this.selectOptionsVal", this.selectOptionsVal);
        if(this.isdyDropDown==true && this.selectOptionsVal!=''){
            inputFields['AssetId']=this.mapOfAssetIds[this.selectOptionsVal];
            //BwcUtils.log("finalitsWork");
        }

        //Adding caseAction from custom picklist
        let caseActionField = 'CaseAction__c';
        inputFields[caseActionField] = this.CaseAction;
        BwcUtils.log('### inputFields[caseActionField]: ', inputFields[caseActionField]);
        console.log('fields are', inputFields[caseActionField]);
        let ctnField = 'CTN__c';
        inputFields[ctnField] = this.selectOptionsVal;

        //Adding fields from Asset based on the selected CTN
        for(let assetField of ASSET_FIELDS){
            let info = this.allDyFields.find(field=> field.fieldLabel === assetField.label);
            if(info){
                inputFields[assetField.apiName] = info.fieldVal;
            }
        }

        this.showLoadingSpinner=true;
        this.template.querySelector('lightning-record-edit-form').submit(inputFields);
    }

    handleSuccess(event){
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success!!',
            message: 'Successfully Updated!!.',
            variant: 'success'
        }));
        this.showLoadingSpinner=false;
        BWCDISABLECLOSETAB.publishMessage(false);
    }

    handlError(event){
        BwcUtils.log("###Err",JSON.stringify(event));
        this.showLoadingSpinner=false;

        var errDetails='';
        if(event.detail!=undefined && event.detail.detail!=undefined  ){
            errDetails+=event.detail.detail;
        }else if(event.message!=undefined){
            errDetails+=event.message;
        }

        this.dispatchEvent(new ShowToastEvent({
            title: 'Error!!',
            message: errDetails,
            variant: 'error'
        }));
    }
    cancelCase(){
        this.showLoadingSpinner = true;
        deleteCase({caseId:this.recordId})
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Case Cancelled',
                    message: 'Case Cancelled',
                    variant: 'info'
                })
            );
            closeTabPublisher.publishMessage();
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error  cancelling Case',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        });
    }

    connectedCallback() {
        this.disableCloseCase();
		this.subscribeToMessageChannel();
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    disableCloseCase(){
        BWCDISABLECLOSETAB.publishMessage(true);
    }

    get isBillingInquiry(){
        return this.caseType === CASE_TYPE_BILLING_INQUIRY;
    }

	/*-----------------------------------------------------------------------------------------------------------------------*/
	
	renderedCallback() {
		if(this.CaseAction.toLowerCase() === CASE_ACTION_REFUND_REQUEST_STATUS_STOP){
			this.handleShowHideIssueType();
		}
    }

	handleShowHideIssueType(){
		//BwcUtils.log('### ENTERED handleShowHideIssueType ');
		const items = this.template.querySelectorAll('lightning-input-field');
		if (items) {
			items.forEach(item => {
				if(item.fieldName === 'IssueType__c'){
					item.className = this.showIssueType ? 
					LIGHTNING_INPUT_FIELD_SHOW : LIGHTNING_INPUT_FIELD_HIDE;
					item.value = item.className === LIGHTNING_INPUT_FIELD_HIDE ?
					 '' : item.value;
					//BwcUtils.log('### ISSUE TYPE CLASS NAME: ', item.className);
				}
			});
		}
	}

	handleCstmrRfndTypChng(event){
		BwcUtils.log('### ENTERED handleCstmrRfndTypChng');
		let cstmrRfndTyp = event.target.value;
		this.showIssueType = !cstmrRfndTyp ? false : true;
		this.handleShowHideIssueType();
	}

	handleCollectPaymentMethod(event){
		//BwcUtils.log('### ENTERED handleCollectPaymentMethod ', event.detail);
        this.startCollectPaymentMethod();
	}
	
	handleOpenSubTab(event){
		//BwcUtils.log('@@@ ENTERED handleOpenSubTab ', JSON.stringify(event.detail));
        BwcUtils.openSubTab(event.detail);        
	}
	/**/
	handleCashPaymentToggleChange(event){
		//BwcUtils.log('@@@ ENTERED handleCashPaymentToggleChange ', event.detail);
		this.isChecked = event.detail == true ? true : false;
		let pmtType = this.isChecked ? PAYMENT_TYPE_CASH : undefined;
		this.setPaymentType(pmtType);
		//BwcUtils.log('@@@ PAYMENT TYPE ', pmtType);
		this.setPaymentTypeCash(event.detail.checked)
	}

	setPaymentTypeCash(value) {
		this.paymentTypeCash = value;
		//BwcUtils.log('### Payment Type Is Cash: ', this.paymentTypeCash);
	}

	setPymtAccountName(aName) {
		const items = this.template.querySelectorAll('lightning-input-field');
		if (items) {
			items.forEach(item => {
				if(item.fieldName === 'NameTiedToPayment__c'){
					item.value = aName;
					this.nameAttachedToPymt = item.value;
				}
			});
		}
	}

	setRefundAccountName(aName) {
		const items = this.template.querySelectorAll('lightning-input-field');
		if (items) {
			items.forEach(item => {
				if(item.fieldName === 'NameTiedToRefund__c'){
					item.value = aName;
				}
			});
		}
	}

    @wire(MessageContext)
    messageContext;

    subscribeToMessageChannel() {
		//BwcUtils.log('### ENTERED subscribeToMessageChannel');
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                paymentMethodComplete,
                (message) => this.handleMessage(message),
                { scope: APPLICATION_SCOPE }
            );
        }
        //BwcUtils.log('### SUBSCRIPTION ', JSON.stringify(this.subscription));
    }

    unsubscribeToMessageChannel() {
		//BwcUtils.log('### ENTERED unsubscribeToMessageChannel');
        unsubscribe(this.subscription);
        this.subscription = null;
    }
	/*
	{"profileProcessTime":"2021-05-25","profileOwnerId":"NEWCONNECT-SF-Manual_20215251056_0vtsi5p","profileName":"Checking ...3401","profileCreatedTime":"2021-05-25","paySource":{"sourceUser":"kc434j","sourceSystem":"SFORCECC","sourceLocation":"CS"},"paymentMethodType":"BANKACCOUNT","bankAccount":{"routingNumber":"211170130","bankAccountNumber":"XXXXX3401","accountType":"CHECKING","accountHolderName":"Test Customer"}}
	*/
    handleMessage(message) {
		//BwcUtils.log('### ENTERED handleMessage');
		if(message && message.messageBody){
	        BwcUtils.log('### MESSAGE BODY ', message.messageBody);
			let cardHolderName = message.messageBody.card ? message.messageBody.card.cardHolderName : undefined;
			let acctHolderName = message.messageBody.bankAccount ? message.messageBody.bankAccount.accountHolderName : undefined;
			let bankAcctInfo = message.messageBody.bankAccount ? message.messageBody.bankAccount : undefined;
			let processDate = message.messageBody.profileProcessTime;
			let paymentMethodType = message.messageBody.paymentMethodType;
	        //BwcUtils.log('### CARDHOLDER NAME ', cardHolderName);
	        //BwcUtils.log('### ACCOUNTHOLDER NAME ', acctHolderName);
			if(cardHolderName){
				this.setPymtAccountName(cardHolderName);
			}else if(acctHolderName){
				this.setPymtAccountName(acctHolderName);
			}
			const inputs = this.template.querySelectorAll('lightning-input');
			if (inputs) {
				inputs.forEach(field => {
					if(field.name === 'pmtTypeCashToggle'){ 
						this.isCashPmtDisabled = true;	
					}
				});
			}
			this.isSuccess = true;
			if(this.isSuccess){
				this.setPaymentType(paymentMethodType);
				let refundMethodType;
				let obj;
				let refundCardHolderName;
				let refundAcctHolderName;
				//BwcUtils.log('### IS SUCCESS this.pymtType', this.pymtType);
				//BwcUtils.log('### IS SUCCESS this.showRefund', this.showRefund);
				getCaseRefundPaymentMethod({sobjId: this.recordId})
				.then((result)=>{
					//BwcUtils.log('### getCaseRefundPaymentMethod RESULT: ', JSON.stringify(result));
					if(result){
						obj = JSON.parse(result);
						//BwcUtils.log('### REFUND TYPE OBJECT ', obj);
						if(obj != null){
							if(obj.paymentMethodType){
								//BwcUtils.log('### OBJECT paymentMethodType ', obj.paymentMethodType);
								refundMethodType = obj.paymentMethodType;
							}else if (this.showRefund){
								refundMethodType = this.pymtType;
							}
							refundCardHolderName = obj.card ? obj.card.cardHolderName : undefined;
							refundAcctHolderName = obj.bankAccount ? obj.bankAccount.accountHolderName : undefined;
							if(refundCardHolderName){
								this.setRefundAccountName(refundCardHolderName);
							}else if(refundAcctHolderName){
								this.setRefundAccountName(refundAcctHolderName);
							}
						}else{
							refundMethodType = this.pymtType;
							this.setRefundAccountName(this.nameAttachedToPymt);
						}
						//BwcUtils.log('### REFUND TYPE ', refundMethodType);
						this.setRefundType(refundMethodType);
					}
				})
				.catch(error=>{
					BwcUtils.error('Error on getCaseRefundPaymentMethod ', error);
				});
			}
		}else{
			this.isSuccess = false;
		}
		let pymtReq = this.template.querySelector('c-bwc-payment-request');
		if(pymtReq){
			pymtReq.handleIsSuccessChange(this.isSuccess);
		}
    }
	    
	setPaymentType(pmtType) {
		const items = this.template.querySelectorAll('lightning-input-field');
		if (items) {
			items.forEach(item => {
				if(item.fieldName === 'PaymentType__c'){
					if(pmtType == PAYMENT_TYPE_CASH){
						item.value = PAYMENT_TYPE_CASH;
					}else
					if(pmtType == PAYMENT_PROFILE_PAYMENT_METHOD_TYPE_CARD){
						item.value = PAYMENT_TYPE_CREDIT_OR_DEBIT;
					}else 
					if(pmtType == PAYMENT_PROFILE_PAYMENT_METHOD_TYPE_BANK_ACCOUNT){
						item.value = PAYMENT_TYPE_BANK_TRANS_OR_EFT;
					}
					else{
						item.value = null;
					}
					/**/
					this.pymtType = item.value;
				}
			});
				BwcUtils.log('### setPaymentType this.pymtType', this.pymtType);
		}
	}
    
	setRefundType(refundType) {
		BwcUtils.log('### ENTERED setRefundType');
		BwcUtils.log('### setRefundType refundType', refundType);
		const items = this.template.querySelectorAll('lightning-input-field');
		if (items) {
			items.forEach(item => {
				if(item.fieldName === 'RefundType__c'){
					if(refundType == REFUND_TYPE_BANK_TRANS_OR_EFT || 
					refundType == REFUND_TYPE_BANK_TRANSFER|| 
					refundType == REFUND_PROFILE_PAYMENT_METHOD_TYPE_BANK_ACCOUNT){
						item.value = REFUND_TYPE_BANK_TRANSFER;
					}else
					if(refundType == REFUND_TYPE_CREDIT_ATM_CARD ||
					 refundType == PAYMENT_TYPE_CREDIT_OR_DEBIT ||
					 PAYMENT_PROFILE_PAYMENT_METHOD_TYPE_CARD){
						item.value = REFUND_TYPE_CREDIT_ATM_CARD;
					}
				}
			});
		}
	}

	submitButtonSetDisabled( isDisabled = true ) {
		const btn = this.template.querySelector( '.submit-button' );
		if ( !btn ) {
			console.error( 'Cannot find Submit Button to enable/disable!!!' );
		}
		else {
			btn.disabled = isDisabled;
		}
	}

	handleRedactionStarted() {
		this.submitButtonSetDisabled( true );
	}

	handleRedactionFinished() {
		this.submitButtonSetDisabled( false );
	}
	//SPTSFDCSPT-8366
	get isOrderHyperlinkVisible() {
		return (
			this.caseType === CASE_TYPE_ORDER_ACTION_ONLINE_FALLOUT_WIRELESS 
			&& 
			( 
				this.CaseAction === CASE_ACTION_WIRELESS_ORDER_FALLOUT_DF||
				this.CaseAction === CASE_ACTION_WIRELESS_ORDER_FALLOUT_IN_STORE ||
				this.CaseAction	=== CASE_ACTION_WIRELESS_ORDER_FALLOUT_READY_TO_GO
			)
		)
	}
}