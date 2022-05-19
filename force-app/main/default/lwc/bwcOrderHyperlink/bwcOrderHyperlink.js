import { LightningElement, api, wire } from 'lwc';
import { getFieldValue, getRecord } from 'lightning/uiRecordApi';

//LWC
import * as BwcUtils from 'c/bwcUtils';

//Case fields
import BILLING_ACCOUNT from '@salesforce/schema/Case.Billing_Account__c';
import ORDER_ID  from '@salesforce/schema/Case.Order_ID__c';

const CASE_FIELDS = [
    BILLING_ACCOUNT,
    ORDER_ID
];



export default class BwcOrderHyperlink extends LightningElement {

    banId;
    orderId;
    //interactionId;
    //billingAccountNumber;
    //authBANMap;
    @api recordId;


    /*strCaseAction;
    @api get caseAction() {
        return this.strCaseAction;
    }
    set caseAction(ca) {
        this.strCaseAction = ca;
        //this.initState();
    }*/


    /*@api 
    get interactionId() {
        return this.interactionId;
    }
    set interactionId(strInteractionId) {
        this.interactionId = strInteractionId;
    }*/

    //Get information from current case
    @wire(getRecord, {recordId: '$recordId', fields: CASE_FIELDS})
    wiredCase({error, data}){

        if(data){
            this.banId = getFieldValue(data, BILLING_ACCOUNT);
            this.orderId = getFieldValue(data, ORDER_ID);
        }
        if(error){
            BwcUtils.log(error);
        }
    }
    /**
     * Method that opens a subtab on the console.
     * It sends the order information as params
     * User must be L1 authenticated in order to access order detail information
     */
    handleOnClick(){
        //get Order from Map
        /*BwcUtils.log('***billingAccountNumber', this.billingAccountNumber);

        let authBan = this.authBANMap.get(this.billingAccountNumber);

        if(!authBan || !BwcConstants.AuthenticationLevel.isL1Privileged(authBan)){
            return;
        }

        let banId = this.banMap[this.billingAccountNumber];  //Figure out whether we can directly pass the account number or not
        */
        console.log('__Record-Id='+this.recordId);
        console.log('__BANId='+this.banId);
        console.log('__OrderId='+this.orderId);
        if(this.orderId){
            const message = {
                label: `Order ${this.orderId}`,
                icon: 'custom:custom93',
                pageReference: {
                    type: 'standard__component',
                    attributes: {
                        componentName: 'c__BWCOrderDetailsPage'
                    },
                    state:{
                        c__ban: this.banId,                 //'a2b7c000001h5xiAAA',                                    //banId,
                        c__orderId: this.orderId,       //this.orderId,           //'23-299505437143753',                              //this.orderId, // 
                        c__recordId: this.recordId                       //'a3C7c000000kOtFEAU'  //'5007c00000CzIVfAAN'//'5007c00000CzIMNAA3'                         //this.interactionId // Case Id - Check-a3C7c000000kOtFEAU
                    }
                },
            };
            BwcUtils.openSubTab(message);
        }
        
    }
}