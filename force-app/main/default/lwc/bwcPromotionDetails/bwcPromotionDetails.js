import { LightningElement, api, wire } from 'lwc';
import {CurrentPageReference} from "lightning/navigation";
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
//Apex
import * as BwcConstants from 'c/bwcConstants';
import * as bwcDispatchEscalationCase from 'c/bwcDispatchEscalationCase';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcPromotionDetailsService from 'c/bwcPromotionDetailsService';

//Lightning Message Service
import {
    subscribe,
    unsubscribe,
    MessageContext
} from 'lightning/messageService';
import COMPLETIONMC from '@salesforce/messageChannel/BWC_Completion__c';

//Custom Permission
import HAS_URGENT_PERMISSION from '@salesforce/customPermission/Urgent_Billing_Inquiries';

// Import custom labels
import noexistingpromotions from '@salesforce/label/c.BWC_PromotionDetails_NoExistingPromotions';
import noexpiredpromotions from '@salesforce/label/c.BWC_PromotionDetails_NoExpiredPromotions';

//Billing account fields
import BAN_FIELD from '@salesforce/schema/Billing_Account__c.Billing_Account_Number__c';
import ACCOUNT_TYPE_FIELD from '@salesforce/schema/Billing_Account__c.Account_Type__c';

const BILLING_ACCOUNT_FIELDS = [BAN_FIELD, ACCOUNT_TYPE_FIELD];

export default class BWCPromotionDetails extends LightningElement {

    promotionWirelessColumns = [
        { label: 'Description', fieldName: 'promotionName', type: 'text', hideDefaultActions: true, cellAttributes: {wrapText: true}, sortable:true},
        { label: 'Promo ID', fieldName: 'promotionID', type: 'button', cellAttributes: {wrapText: true}, hideDefaultActions: true, sortable:true, typeAttributes:{label: {fieldName: 'promotionID'}, disabled: false, variant: 'base', name: 'openPromotionModal', title: 'openPromotionModal'} },
        { label: 'Product Type', fieldName: 'productType', type: 'text', cellAttributes: {wrapText: true}, hideDefaultActions: true, initialWidth :100, sortable:true },
        { label: 'Start Date', fieldName: 'promotionStartDate', type: 'date-local', typeAttributes: {month: '2-digit', day: '2-digit'}, hideDefaultActions: true, initialWidth:125, sortable:true },
        { label: 'End Date', fieldName: 'contractEndDate', type: 'date-local', typeAttributes: {month: '2-digit', day: '2-digit'}, hideDefaultActions: true, initialWidth:100, sortable:true },
        { label: 'Discount', fieldName: 'promotionAmount', type: 'currency', cellAttributes: {alignment: 'left', wrapText: true}, hideDefaultActions: true, sortable:true },
        { label: 'Phone #', fieldName: 'wirelessSubscriberNumber', type: 'phone', hideDefaultActions: true, cellAttributes: {wrapText: true}, sortable:true},
        { label: 'Applied To', fieldName: 'level', type: 'text', cellAttributes: {wrapText: true}, hideDefaultActions: true, sortable:true },
        { type: 'action', typeAttributes: { rowActions: this.getRowActions.bind(this) }},
    ];

    promotionUverseColumns = [
        { label: 'Description', fieldName: 'promotionName', type: 'text', hideDefaultActions: true, cellAttributes: {wrapText: true}, initialWidth :150, sortable:true},
        { label: 'Promo ID', fieldName: 'promotionID', type: 'button', cellAttributes: {wrapText: true}, hideDefaultActions: true, sortable:true, typeAttributes:{label: {fieldName: 'promotionID'}, disabled: false, variant: 'base', name: 'openPromotionModal', title: 'openPromotionModal'} },
        { label: 'Product Type', fieldName: 'productType', type: 'text', cellAttributes: {wrapText: true}, hideDefaultActions: true, initialWidth :100, sortable:true },
        { label: 'Start Date', fieldName: 'promotionStartDate', type: 'date-local', typeAttributes: {month: '2-digit', day: '2-digit'}, hideDefaultActions: true, initialWidth:125, sortable:true },
        { label: 'End Date', fieldName: 'promotionEndDate', type: 'date-local', typeAttributes: {month: '2-digit', day: '2-digit'}, hideDefaultActions: true, initialWidth:100, sortable:true,
        "cellAttributes": {
            "class": {
                "fieldName": "showClass"
            },
            "iconName": {
                "fieldName": "displayIconName"
            },
            iconPosition: 'right'
        } },
        { label: 'Discount', fieldName: 'promotionAmount', type: 'currency', cellAttributes: {alignment: 'left', wrapText: true}, hideDefaultActions: true, sortable:true },
        { type: 'action', typeAttributes: { rowActions: this.getRowActions.bind(this) }},
    ];

    promotionElseColumns = [
        { label: 'Description', fieldName: 'promotionName', type: 'text', hideDefaultActions: true, cellAttributes: {wrapText: true}, sortable:true},
        { label: 'Promo ID', fieldName: 'promotionID', type: 'button', cellAttributes: {wrapText: true}, hideDefaultActions: true, sortable:true, typeAttributes:{label: {fieldName: 'promotionID'}, disabled: false, variant: 'base', name: 'openPromotionModal', title: 'openPromotionModal'} },
        { label: 'Product Type', fieldName: 'productId', type: 'text', cellAttributes: {wrapText: true}, hideDefaultActions: true, sortable:true },
        { label: 'Start Date', fieldName: 'promotionStartDate', type: 'date-local', typeAttributes: {month: '2-digit', day: '2-digit'}, hideDefaultActions: true, initialWidth:105, sortable:true },
        { label: 'End Date', fieldName: 'promotionEndDate', type: 'date-local', typeAttributes: {month: '2-digit', day: '2-digit'}, hideDefaultActions: true, initialWidth:130, sortable:true,
        "cellAttributes": {
            "class": {
                "fieldName": "showClass"
            },
            "iconName": {
                "fieldName": "displayIconName"
            }
        } },
        { label: 'Discount', fieldName: 'promotionAmount', type: 'currency', cellAttributes: {alignment: 'left', wrapText: true}, hideDefaultActions: true,initialWidth:80, sortable:true },
        { type: 'action', typeAttributes: { rowActions: this.getRowActions.bind(this)}},
    ];

    // The Salesforce Person Account Record Id
    @api recordId;

    @wire(CurrentPageReference)
    pageRef;

    @wire(getRecord, {recordId: '$recordId', fields: BILLING_ACCOUNT_FIELDS})
    billingAccount;

    @wire(MessageContext)
    messageContext;

    error = '';

    existingPromotions;
    expiredPromotions;
    interactionId;
    completionSubscription;

    //Sorting variables
    defaultSortDirection= 'asc';
    sortDirection = 'asc';
    sortedBy;
    selectedPromotion;

    onHandleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.existingPromotions];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.existingPromotions = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    sortBy(field, reverse, primer) {
        const key = primer
            ? function(x) {
                  return primer(x[field]);
              }
            : function(x) {
                  return x[field];
              };

        return function(a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }
 
    // Used to show spiiner as the promotions are being loaded.
    isLoading = true;

    // Used to do operation once upon first render
    isRendered = false;
    
    label = {
        noexistingpromotions: noexistingpromotions,
        noexpiredpromotions: noexpiredpromotions
    };
    showExistingPromotions = false;
    showEmptyExistingPromotions = false;
    showExpiredPromotions = false;
    showEmptyExpiredPromotions = false;

  

    // The LWC framework calls this method when the LWC is loaded.
    renderedCallback() { 

        if (this.isRendered) {
            return;
        }
        this.isRendered = true;

        // call billing api
        this.callGetPromotionDetails();
        this.getInteractionId();
    }

    // refresh the promotion data
    handleRefresh() {
        this.callGetPromotionDetails();
    }

    // get promotion data
    async callGetPromotionDetails() {

        // hide table
        this.showExistingPromotions = false;
        this.showExpiredPromotions = false;

        // hide empty message
        this.showEmptyExistingPromotions = false;
        this.showEmptyExpiredPromotions = false;

        // show spinner
        this.isLoading = true;

        this.error = null;

        try{
            const interactionIdData = BwcUtils.getInteractionIdFromUrl();
            const responseWrapper = await BwcPromotionDetailsService.getPromotionDetailsForBillingAccount(this.recordId, interactionIdData);
            
            var promoDets = responseWrapper;
            this.existingPromotions = [];
            this.expiredPromotions = [];
            if( promoDets.length > 0 ){
                promoDets.forEach(promoDetail=>{
                    console.log({promoDetail});
                    if(promoDetail.error && promoDetail.error.code =='404'){
                        this.showEmptyExistingPromotions=true;   
                        return; 
                    }

                    if (promoDetail.promotions != null && promoDetail.promotions.length > 0) {
                        let promotions = promoDetail.promotions;
                        promotions.forEach(promotion => {
                            promotion.with60Days = false;
                            console.log(`promoDetail.accountType ${promoDetail.accountType}`);
                            if(promoDetail.accountType == BwcConstants.BillingAccountType.WIRELESS.value){
                                this.promotionColumns =  this.promotionWirelessColumns;
                                if(promotion.promotionCode != '')
                                    promotion.promotionCode = promotion.promotionCode;
                                if(promotion.promotionAmount != '')
                                    promotion.promotionAmount = promotion.promotionAmount;				
                                if(promotion.wirelessPromotionLevel == 'groupLevel') {	
                                    promotion.level = 'Group Level';
                                } else if(promotion.promotionPlanLevel == 'C'){
                                    promotion.level = 'Subscriber level promotion';
                                } else if(promotion.promotionPlanLevel == 'B'){
                                    promotion.level = 'ban level promotion';
                                } else if(promotion.promotionPlanLevel == 'P'){
                                    promotion.level = 'product level';
                                } else if(promotion.promotionPlanLevel == 'G'){
                                    promotion.level = 'Group level';
                                } else {
                                    promotion.level = promotion.promotionPlanLevel;
                                }
                                if(promotion.promotionStartDate != ''){
                                    let year = promotion.promotionStartDate.substring(0, 4);
                                    let month = promotion.promotionStartDate.substring(4, 6);
                                    let day = promotion.promotionStartDate.substring(6, 8);
                                    promotion.promotionStartDate = year + '-' + month + '-' + day;
                                }
                                if(promotion.contractEndDate != undefined && promotion.contractEndDate != ''){
                                    //let year = promotion.contractEndDate.substring(0, 4);
                                    //let month = promotion.contractEndDate.substring(4, 6);
                                    //let day = promotion.contractEndDate.substring(6, 8);
                                    //promotion.contractEndDate = year + '-' + month + '-' + day;
                                    promotion.contractEndDate = promotion.contractEndDate;
                                    if(this.checkDatewith60Days(promotion.contractEndDate)){
                                        promotion.with60Days = true;
                                    }
                                }							
                                if(!promotion.promotionName){
                                    promotion.promotionName = promotion.promotionCode;
                                }
                                if(!promotion.level){
                                    promotion.level = promotion.wirelessPromotionLevel;
                                }
                            } else if(promoDetail.accountType ==  BwcConstants.BillingAccountType.DTVNOW.value){
                                this.promotionColumns =  this.promotionElseColumns;
                                if(promotion.promotionStartDate != ''){
                                    let year = promotion.promotionStartDate.substring(0, 4);
                                    let month = promotion.promotionStartDate.substring(5, 7);
                                    let day = promotion.promotionStartDate.substring(8, 10);
                                    promotion.promotionStartDate = year + '-' + month + '-' + day;
                                }
                                if(promotion.promotionEndDate != undefined && promotion.promotionEndDate != ''){
                                    let year = promotion.promotionEndDate.substring(0, 4);
                                    let month = promotion.promotionEndDate.substring(5, 7);
                                    let day = promotion.promotionEndDate.substring(8, 10);
                                    promotion.promotionEndDate = year + '-' + month + '-' + day;
                                    
                                    if(this.checkDatewith60Days(promotion.promotionEndDate)){
                                        promotion.with60Days = true;
                                    }
                                }

                                if( Array.isArray(promotion.productId) && promotion.productId.length>0){
                                    promotion.productId = promotion.productId[0];
                                }

                            } else if(promoDetail.accountType ==  BwcConstants.BillingAccountType.UVERSE.value){
                                // request for expired promotions to all have the same columns.
                                this.promotionColumns =  this.isExpired(promotion) ? this.promotionElseColumns : this.promotionUverseColumns;

                                promotion.promotionAmount = Math.abs(promotion.promotionAmount);
                                if(promotion.promotionEndDate != undefined && this.checkDatewith60Days(promotion.promotionEndDate)){
                                    promotion.with60Days = true;
                                }
                            } else {
                                promotion.productId = promotion.productId;  //ProductId is being received in the form of a String.
                                promotion.promotionAmount = promotion.promotionAmount[0];
                                this.promotionColumns =  this.promotionElseColumns;
                                if(promotion.promotionEndDate != undefined && this.checkDatewith60Days(promotion.promotionEndDate)){
                                    promotion.with60Days = true;
                                }
                            }
                            if(promotion.with60Days){
                                //promotion.showClass = 'slds-text-color_destructive';
                                promotion.showClass = 'slds-text-color_destructive';
                                promotion.displayIconName = 'utility:warning'; 
                            }                      
                            
                            if ( !this.isExpired(promotion) ) {
                                this.existingPromotions.push(promotion);
                            }
                            else {
                                this.expiredPromotions.push(promotion);                    
                            }

                        }); 
                    }
                });
            }
            /*
            if (mypromo[0].promotions != null && mypromo.length > 0) {
                promotions.forEach(promotion => {
                    promotion.promotionCode1 = promotion.promotionCode[0];
                    if(promotion.promotionStartDate != ''){
                        let year = promotion.promotionStartDate.substring(0, 4);
                        let month = promotion.promotionStartDate.substring(4, 6);
                        let day = promotion.promotionStartDate.substring(6, 8);
                        promotion.promotionStartDate = year + '-' + month + '-' + day;
                    }
                    
                    if (promotion.promotionStatus == undefined) {
                        this.existingPromotions.push(promotion);
                    }
                    else {
                        this.expiredPromotions.push(promotion);                    
                    }
                });
            } */
            
            if(this.existingPromotions.length > 0) {
                this.showExistingPromotions = true;
            } else { 
                this.showEmptyExistingPromotions = true;
            }
            
            if(this.expiredPromotions.length > 0) {
                this.showExpiredPromotions = true;
            } else { 
                this.showEmptyExpiredPromotions = true;
            }

            // Stop spinner.
            this.isLoading = false;
        }
        catch(error){
            this.error = error;
            this.isLoading = false;
        }
        
    }
  
    checkDatewith60Days(curDate){
        var currDate = new Date(curDate);
        var todate = new Date();
        // To calculate the time difference of two dates 
        var Difference_In_Time = currDate.getTime() - todate.getTime(); 
        
        // To calculate the no. of days between two dates 
        var Difference_In_Days = Difference_In_Time / (1000 * 3600 * 24); 
        console.log('Difference_In_Time : Difference_In_Days'+Difference_In_Days)
        if(Difference_In_Days < 60) {
            return true;
        } else {
            return false;
        }
    }

    getRowActions(row, doneCallback){

        const actions =[];

        actions.push(
            {
                label: 'Escalate Promotion',
                name: 'escalate',
                disabled:!this.showEscalateButton
            }
        );

        doneCallback(actions);
    }

    handleRowAction(event){

        const actionName = event.detail.action.name;
        const row = event.detail.row;

        switch(actionName){
            case'openPromotionModal':
                this.selectedPromotion = JSON.parse(JSON.stringify(row));
                setTimeout(()=>
                {
                    this.template.querySelector('c-bwc-promotion-details-expand').openModal();
                },200);
            break;
            case'escalate':
                this.onEscalate();
                break;

        }
    }

    escalationComplete(){
        unsubscribe(this.completionSubscription);
        this.completionSubscription=null;
        this.isLoading = false;
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

    isExpired(promotion) {
        if(promotion.promotionStatus == undefined || promotion.promotionStatus == 'Active') return false;

        return true;
    }

    onEscalate(){

        this.isLoading = true;

        this.completionSubscription = subscribe(
            this.messageContext,
            COMPLETIONMC, (message) => {
                this.escalationComplete(message);
            }
        );

        let ecType = BwcConstants.HighLevelCaseType.Account_Services_Promotions.type;
        let ecFeature = BwcConstants.HighLevelCaseType.Account_Services_Promotions.feature;

        bwcDispatchEscalationCase.publishEscalationCaseMessage(
            this.interactionId,
            ecType,
            ecFeature,
            JSON.stringify(
                {
                    ban: this.billingAccount.data.fields.Billing_Account_Number__c.value,
                    // caseAction: CASE_ACTION_PROMOTIONS,
                }
            )
        );
        this.template.querySelector('div').click();
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

}