import {  api, wire } from 'lwc';
import {CurrentPageReference} from "lightning/navigation";
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

//Custom Permission
import HAS_URGENT_PERMISSION from '@salesforce/customPermission/Urgent_Billing_Inquiries';

//Other components
import BwcPageElementBase from 'c/bwcPageElementBase';
import * as BwcConstants from 'c/bwcConstants';
import * as BwcUtils from 'c/bwcUtils';
import * as bwcDispatchEscalationCase from 'c/bwcDispatchEscalationCase';
import * as BwcAddOnsServices from 'c/bwcAddOnsService';

//Lightning Message Service
import {
    subscribe,
    unsubscribe,
    MessageContext
} from 'lightning/messageService';
import COMPLETIONMC from '@salesforce/messageChannel/BWC_Completion__c';

//Billing account fields
import BAN_FIELD from '@salesforce/schema/Billing_Account__c.Billing_Account_Number__c';
import ACCOUNT_TYPE_FIELD from '@salesforce/schema/Billing_Account__c.Account_Type__c';

const BILLING_ACCOUNT_FIELDS = [BAN_FIELD, ACCOUNT_TYPE_FIELD];
const columns = [
    { label: 'Add-on Name', fieldName: 'title', type: 'text',hideDefaultActions: true },
    { label: 'Monthly cost', fieldName: 'monthlyCost', type: 'currency',hideDefaultActions: true },
    { label: 'User ID', fieldName: 'userId', type: 'text',hideDefaultActions: true },
];

const COMPONENT_UI_NAME = 'Add-Ons';

// Import custom labels
import label_title from '@salesforce/label/c.BWC_AddOns_Title';
import label_noAddOnsFound from '@salesforce/label/c.BWC_AddOns_NoReLstFoud';
import label_mulesoftErrorCode from '@salesforce/label/c.BWC_UnexpectedError_RefreshSection';

export default class BwcAddOns extends BwcPageElementBase {
    @api recordId;
    isLoading = true;
    data = [];
    columns = columns;
    showTable;
    showError;
    completionSubscription;

    @wire(CurrentPageReference)
    pageRef;

    @wire(getRecord, {recordId: '$recordId', fields: BILLING_ACCOUNT_FIELDS})
    billingAccount;

    @wire(MessageContext)
    messageContext;

    isRendered = false;

    async renderedCallback(){

        if (!this.isRendered) {

            this.isRendered = true;

            // Work around boxcarring by waiting so this component doesn't block other API calls
            this.isLoading = true;
            await BwcUtils.wait(BwcConstants.BOXCAR_WAIT);

            this.getAddOn();
            this.getInteractionId();

        }

    }

    onRefresh(){
        this.getAddOn();
    }

    async getAddOn(){

        try {

            this.isLoading = true;
            this.showTable = false;
            
            super.clearNotifications();

            const interactionId = BwcUtils.getInteractionIdFromUrl();
            const responseWrapper = await BwcAddOnsServices.getAddOnsForBillingAccount(this.recordId,interactionId);
            const result = responseWrapper;
            const msError = result.accounts?.[0].error;

            if(msError && msError.code !== BwcConstants.ERROR_CODE_404){

                const error = new Error(JSON.stringify(msError));
                super.handleError(error, label_mulesoftErrorCode, COMPONENT_UI_NAME, 'inline');
                return;

            }else if(msError?.code === BwcConstants.ERROR_CODE_404){

                BwcUtils.log({msError});
                super.addInlineNotification(label_noAddOnsFound, 'info');
                return;

            }

            this.showTable = true;
            this.data = result.accounts?.[0]?.addons;

        }
        catch (error) {
            super.handleError(error, label_mulesoftErrorCode, COMPONENT_UI_NAME, 'inline');
        }
        finally {
            this.isLoading = false;
        }

    }

    onEscalate(){
        this.isLoading=true;
        this.completionSubscription = subscribe(
            this.messageContext,
            COMPLETIONMC, (message) => {
                this.escalationComplete(message);
            }
        );

        let ecType = BwcConstants.HighLevelCaseType.Services_Inquiry.type;
        let ecFeature = BwcConstants.HighLevelCaseType.Services_Inquiry.feature;

        bwcDispatchEscalationCase.publishEscalationCaseMessage(
            this.interactionId,
            ecType,
            ecFeature,
            JSON.stringify(
                {
                    ban: this.billingAccount.data.fields.Billing_Account_Number__c.value
                }
            )
        );
        this.template.querySelector('div').click();
    }

    escalationComplete(){
        unsubscribe(this.completionSubscription);
        this.completionSubscription=null;
        this.isLoading=false;
    }

    getInteractionId(){
        if(this.pageRef.state.ws){
           let interactionIdData = this.pageRef.state.ws.split('/');
            for(let i = 0; i < interactionIdData.length; i++){
                if(interactionIdData[i] === 'Interaction__c'){
                    this.interactionId = interactionIdData[i+1];
                }
            }
        }
    }

    get isWirelessType(){
        return getFieldValue(this.billingAccount.data, ACCOUNT_TYPE_FIELD) === BwcConstants.BillingAccountType.WIRELESS.value;
    }

    get hasUrgentBillingPermission(){
        return HAS_URGENT_PERMISSION;
    }

    get showEscalateButton(){
        return this.hasUrgentBillingPermission && this.isWirelessType;
    }

    get cardTitle(){
        return this.data?.length>0 ? label_title : `${label_title} (0)`;
    }

}