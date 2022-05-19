import { LightningElement,api, track, wire } from 'lwc';
import {CurrentPageReference} from "lightning/navigation";
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

//Custom Permission
import HAS_URGENT_PERMISSION from '@salesforce/customPermission/Urgent_Billing_Inquiries';

//Apex
import getEquipmentDetails from '@salesforce/apex/BWC_EquipmentDetailController.getEquipmentDetails';
import getSOCCode from '@salesforce/apexContinuation/BWC_ProductSearchController.getSOCCodeCont';

//Other components
import * as bwcLICPublisher from 'c/bwcMsgToLICPublisher';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcConstants from 'c/bwcConstants';
import * as bwcDispatchEscalationCase from 'c/bwcDispatchEscalationCase';

//Lightning Message Service
import {
    subscribe,
    unsubscribe,
    MessageContext
} from 'lightning/messageService';
import COMPLETIONMC from '@salesforce/messageChannel/BWC_Completion__c';

//Custom labels
import label_noEquipmentsFound from '@salesforce/label/c.BWC_EquipmentDetails_NoEquipmentsFound';

//Billing account fields
import BAN_FIELD from '@salesforce/schema/Billing_Account__c.Billing_Account_Number__c';
import ACCOUNT_TYPE_FIELD from '@salesforce/schema/Billing_Account__c.Account_Type__c';

const CANCELED_STATUS = 'Canceled';
const UVERSE_TYPE = 'uverse';
const DIRECTV_TYPE = 'directv';
const GROUP_BY_DTV_RECORDS = 'description';
const BILLING_ACCOUNT_FIELDS = [BAN_FIELD, ACCOUNT_TYPE_FIELD];

const ESCALATION_BUTTONS_MAP = {
    escalateDeviceIssue: 'Device_Inquiry',
    escalateDeviceReturn: 'Device_Return_Inquiry'
}

export default class Bwc_EquipmentDetails extends LightningElement {
    @api recordId;
    @track recordDetails;
    @track receiverModelData;
    showLoading;
    showNoRows;
    error;
    escalationType;
    interactionId;
    completionSubscription
    selectedRecord;
    isExpanded=true;

    @wire(CurrentPageReference)
    pageRef;

    @wire(getRecord, {recordId: '$recordId', fields: BILLING_ACCOUNT_FIELDS})
    billingAccount;

    @wire(MessageContext)
    messageContext;

    label = {
        noEquipmentsFound: label_noEquipmentsFound
    };

    // 11-16-2020
    isDisplaySOCCodeOpen = false;
    socCodes = [];
    socCodeColumns = [
        { label: 'Service Type', fieldName: 'serviceType', type: 'text', hideDefaultActions: true, cellAttributes: {wrapText: true} },
        { label: 'Product Id', fieldName: 'productId', type: 'text', hideDefaultActions: true, cellAttributes: {wrapText: true} },
        { label: 'Product Name', fieldName: 'productName', type: 'text', hideDefaultActions: true, cellAttributes: {wrapText: true} },
        { label: 'Product Description', fieldName: 'productDescription', type: 'text', hideDefaultActions: true, cellAttributes: {wrapText: true} },
    ];
    mapBANToRawData = [];



    connectedCallback(){
        this.showLoading = true;
        this.showNoRows = false;
        BwcUtils.log('Bwc_EquipmentDetails:connectedCallback '+this.recordId);
        getEquipmentDetails({recordId:this.recordId})
            .then(resultJson => {
                const result = JSON.parse(resultJson);
                this.recordDetails = result.recordDetails;
                BwcUtils.log('Bwc_EquipmentDetails:connectedCallback ',this.recordDetails);
                BwcUtils.log('Bwc_EquipmentDetails:connectedCallback ',result.success);
                if(!result.success){
                    // 10-05-2020 if error show error message.
                    this.error = result.message;
                }
                else {
                    // 10-05-2020 if no equipments found, show proper message
                    if (this.recordDetails == null || this.recordDetails.length === 0) {
                        this.showNoRows = true;
                    }
                    else {
                        // 11-17-2020
                        let strWireless = 'wireless';
                        this.recordDetails.forEach(rd => {
                            let accountType = rd.accountType == null?'':rd.accountType.toLowerCase();
                            rd.isWireless = strWireless === accountType;
                            rd.isCanceled = rd.status === CANCELED_STATUS;
                            rd.isLoading = false;
                            rd.title = `${rd.phone} - ${rd.device}`;
                        });
                        BwcUtils.log('this.recordDetails', this.recordDetails);
                        //get Uverse/DTV records
                        let dtvRecords = this.recordDetails.filter((rd)=> rd.accountType === UVERSE_TYPE || rd.accountType===DIRECTV_TYPE);
                        BwcUtils.log({dtvRecords});
                        //remove dtv records from main list
                        this.recordDetails = this.recordDetails.filter((rd)=> rd.accountType !== UVERSE_TYPE && rd.accountType!==DIRECTV_TYPE);
                        BwcUtils.log('this.recordDetails', this.recordDetails);

                        this.processDTVRecords(dtvRecords);
                    }
                }
                this.showLoading = false;
            })
            .catch(error => {
                BwcUtils.log('Bwc_EquipmentDetails:connectedCallback Failed');
                this.error = error;
                this.showNoRows = true;
                //this.data = mydata;
                this.showLoading = false;
            });

        this.getInteractionId();
    }

    handleActionMenuSelect(event) {
        const recordId = event.target.dataset.item;
        const recordDetail = this.recordDetails.find(rd => rd.recordId === recordId);
        this.selectedRecord = recordDetail;
        switch(event.detail.value) {

            case 'displayFeatureDetails':
                {
                    if (this.mapBANToRawData[recordDetail.ban] != null) {
                        this.showSOCCodes(this.mapBANToRawData[recordDetail.ban], recordDetail);
                    }
                    else {
                        this.getSOCCodesFromServer(recordDetail);
                    }
                }
                break;
            case 'escalateDeviceReturn':
            case 'escalateDeviceIssue':

                {
                let hlCaseTypeIndex = ESCALATION_BUTTONS_MAP[event.detail.value];
                let hlCaseType = BwcConstants.HighLevelCaseType[hlCaseTypeIndex];

                if(hlCaseType!=undefined && hlCaseType!=undefined){

                    let ecType = hlCaseType.type;
                    let ecFeature = hlCaseType.feature;

                    this.createEscalationCase(ecType, ecFeature, recordDetail);
                }
                }
                break;
            case 'changeEquipment':
            case 'changeProtectionPlan':

                this.postToLIC();

                break;
            default:
                break;
        }

    }

    getSOCCodesFromServer(rd) {
        this.showLoading = true;

        this.showSpecificSpinner(rd.recordId);

        BwcUtils.log('recordDetails: ', this.recordDetails);
        getSOCCode({interactionId: this.interactionId, billingAccountId: this.recordId})
        .then(result => {

            BwcUtils.log('result:' + JSON.stringify(result));
            if (result.success) {
                BwcUtils.log('in success:' + result.resultJSON);
                let rawData = JSON.parse(result.resultJSON);
                BwcUtils.log('in parse' + JSON.stringify(rawData));
                this.mapBANToRawData[rawData.accounts[0].ban] = rawData;
                this.showSOCCodes(rawData, rd);
            }
            else {
                this.error = result.message;
            }

            this.showLoading = false;
            BwcUtils.log('recordDetails: ', this.recordDetails);
            this.hideAllEquipmentSpinners();

            BwcUtils.log('recordDetails: ', this.recordDetails);
        })
        .catch(error => {
            BwcUtils.log('getSOCCode Failed');
            this.error = error;
            this.showLoading = false;
        });
    }

    showSOCCodes(rawData, rd) {
        this.socCodes = [];
        let account = rawData.accounts[0];
        if (account.plans != null) {
            let plan;
            for(plan of account.plans) {
                if (plan.subscribers != null) {
                    let subscriber;
                    for(subscriber of plan.subscribers) {
                        BwcUtils.log ('subscriber.subscriberId:' + subscriber.subscriberId + '; rd.phone:' + rd.phone);
                        if (subscriber.subscriberId === rd.phone) {
                            if (subscriber.features != null) {
                                this.socCodes = this.socCodes.concat(subscriber.features);
                            }
                        }
                    }
                }
            }
        }
        this.isDisplaySOCCodeOpen = true;
    }

    postToLIC(){
        const msg = 'PostToOpus';
        const licObj = {};
        licObj.launchPoint = 'Launch Point';
        licObj.JsonData = {};
        bwcLICPublisher.publishMessage(msg, licObj, this.recordId);
    }

    processDTVRecords(dtvRecords){
        //group uverse/DTV records by receiver model
        let receiverModelMap = new Map();
        for(let rd of dtvRecords){
            if(!receiverModelMap.has(rd[GROUP_BY_DTV_RECORDS])){
                receiverModelMap.set(rd[GROUP_BY_DTV_RECORDS], []);
            }

            receiverModelMap.get(rd[GROUP_BY_DTV_RECORDS]).push(rd);
        }
        BwcUtils.log({receiverModelMap});

        //transform map to list so HTML can iterate through it
        let receiverModelData = []
        for(let [key, value] of receiverModelMap){
            let length = value.length;
            let title = `${key} - ${length}`;
            let isCanceled = value[0].isCanceled;
            let recordId = value[0].recordId;
            receiverModelData.push({value, key, length, title, isCanceled, recordId});
        }

        BwcUtils.log(receiverModelData);

        this.receiverModelData = receiverModelData;
    }

    createEscalationCase(ecType, ecFeature, recordDetail){

        let recordId = recordDetail.recordId;

        this.showSpecificSpinner(recordId);

        this.completionSubscription = subscribe(
            this.messageContext,
            COMPLETIONMC, (message) => {
                this.escalationComplete(message);
            }
        );

        bwcDispatchEscalationCase.publishEscalationCaseMessage(
            this.interactionId,
            ecType,
            ecFeature,
            JSON.stringify(
                {
                    ban: this.billingAccount.data.fields.Billing_Account_Number__c.value,
                    ctn: recordDetail.phone,
                }
            )
        );
        this.template.querySelector('div').click();
    }

    escalationComplete(){
        unsubscribe(this.completionSubscription);
        this.completionSubscription=null;
        this.hideAllEquipmentSpinners();
    }

    showSpecificSpinner(recordId){
        this.recordDetails = this.recordDetails.map((record) =>{
                if(record.recordId === recordId){
                    record.isLoading = true;
                }
                return record;
        });
    }

    hideAllEquipmentSpinners(){
        this.recordDetails = this.recordDetails.map((record) =>{
            record.isLoading = false;
            return record;
        });
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

    escalateFeature(){
        let hlCaseType = BwcConstants.HighLevelCaseType.Feature_Inquiry;

        let ecType = hlCaseType.type;
        let ecFeature = hlCaseType.feature;

        this.closeDisplaySOCCode();
        this.createEscalationCase(ecType, ecFeature, this.selectedRecord);
    }

    // hide the soc code modal
    closeDisplaySOCCode() {
        this.isDisplaySOCCodeOpen = false;
    }

    handleExpandClick(){

        this.isExpanded = !this.isExpanded;

        let expandableSections = [...this.template.querySelectorAll('c-bwc-expandable-section')];
        expandableSections.forEach(section=>{
            section.expandCollapseSection(this.isExpanded);
        });

    }

    handleExpandEvent(event){
        event.stopPropagation();

        const expandableSections = [...this.template.querySelectorAll("c-bwc-expandable-section")];
        const sectionsCounter = {
            expanded: 0,
            closed:0
        };
        expandableSections.forEach((section)=>{
            const key = section.isExpanded ? 'expanded' : 'closed';
            sectionsCounter[key]++;
        });

        this.isExpanded = sectionsCounter.expanded === expandableSections.length;
    }

    get showExpandButton(){
        return this.recordDetails?.length > 0 || this.receiverModelData?.length > 0;
    }

    get hasData(){
        return this.recordDetails.length > 0;
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

    get expandCollapseLabel(){
        return this.isExpanded ? 'Collapse All' : 'Expand All';
    }

}