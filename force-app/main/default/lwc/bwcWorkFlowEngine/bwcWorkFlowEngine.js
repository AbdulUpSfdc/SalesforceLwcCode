import { api, wire } from 'lwc';
import BwcPageElementBase from 'c/bwcPageElementBase';
import { InteractionActivityValueMapping } from 'c/bwcInteractionActivityService';
import { CurrentPageReference } from 'lightning/navigation';
import * as BwcAccountServices from 'c/bwcAccountServices';
import * as BwcConstants from 'c/bwcConstants';
import { CloseActionScreenEvent } from 'lightning/actions';

import * as BwcUtils from 'c/bwcUtils';

export default class BwcWorkFlowEngine extends BwcPageElementBase {
    recordId;
    urlParamArray = [];
    retrievedRecordId = false;

    @wire(CurrentPageReference)
    currentPageReference;

    connectedCallback() {

        
        //Get the current record id and interaction Id from URL
        this.recordId = this.currentPageReference.state.recordId;
        // Get billing details
        const interactionId = BwcUtils.getInteractionIdFromUrl();
        this.createInteractionActivityOnWFELaunch(this.recordId,interactionId);
      
    }
    
    closeQuickAction() {
        BwcUtils.log('inside close');
        setTimeout(() => {
            this.dispatchEvent(new CloseActionScreenEvent());
        }, 5000);
    }

    //Create Interaction Activity on WFE Launch
    billingAccounts;
    async createInteractionActivityOnWFELaunch(billingAccountId,interactionId){
       try{
            if(interactionId){
                const BILLING_ACCOUNT_TYPES = [
                    BwcConstants.BillingAccountType.UVERSE.value
                ];
                    // Build selection list of billing accounts
                    if(this.billingAccounts === undefined){
                        this.billingAccounts = await BwcAccountServices.getBillingAccounts(interactionId, true, false, BILLING_ACCOUNT_TYPES)
                    }
                let isBANAuthenticated = false;
                let ban = '';
                let banId = '';
                this.billingAccountStatus = this.billingAccounts.forEach(billingAccount => {
                    if( billingAccount.Id === billingAccountId){
                        isBANAuthenticated = true;
                        ban = billingAccount.Billing_Account_Number__c;
                        banId = billingAccount.Id;
                    }
                });
                //Launch WFE
                this.launchWFE(interactionId,ban,isBANAuthenticated,banId);
                this.closeQuickAction();
            }
        }catch(error){
            BwcUtils.error(error);
        }     
    }
    launchWFE(interactionId,ban,isBANAuthenticated,billingAccNumberId){
        this.template.querySelector('c-bwc-launch-w-f-e').open(InteractionActivityValueMapping.WFEGeneralSupport,ban,billingAccNumberId,isBANAuthenticated,interactionId);
    }

}