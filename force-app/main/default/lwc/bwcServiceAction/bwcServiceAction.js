/* ================================================
* @class name: BwcServiceAction
* @author: Salesforce Inc.
* @purpose: this is a reusable action cmp for billing account. we wrap this with an AURA wrapper
* @created date (mm/dd/yyyy) :  03/20/2021
================================================*/
import { LightningElement, api, wire , track} from 'lwc';
import * as bwcInteractActivityPublisher from 'c/bwcInteractActivityPublisher';
import * as bwcLICPublisher from 'c/bwcMsgToLICPublisher';
import * as bwcBAActionPublisher from 'c/bwcBillingAccountActionPublisher';
import * as bwcTSRMLauncher from 'c/bwcTSRMLauncher';
import * as bwcOpenNewBrowserTabPublisher from 'c/bwcOpenNewBrowserTabPublisher';
import * as BwcConstants from 'c/bwcConstants';
import DeviceURL from '@salesforce/label/c.Device_Support_Index_URL';
import {CurrentPageReference } from "lightning/navigation";
import getComboboxOptions from '@salesforce/apex/BWC_ServiceAction_Controller.getComboboxOptions';
import getDeviceData from '@salesforce/apex/BWC_ServiceAction_Controller.getDeviceData';
import getData from '@salesforce/apex/BWC_ServiceAction_Controller.getData';
import { MessageContext} from 'lightning/messageService';
export default class BwcServiceAction extends LightningElement {
    serviceActionFeature;
    subscription = null;
    interactionId;
    @api serviceAction;

    @api recordId;

    @wire (getData, { billingAccountId: '$recordId' })
    payload;
    @wire(MessageContext)
    messageContext;
    @wire(CurrentPageReference)
    pageRef;
    //we grab dependent picklist values here
    @wire(getComboboxOptions, { controlValue: '$serviceAction' })
    comboOptions;

    @wire(getDeviceData, { baId: '$recordId' })
    deviceList;

    ctnActionList = ['Device Support','Device Issues','Service Issues'];
    // this returns a list of dependent picklist values
    get options(){
        let comboObj = [];
        let obj;
        let escalatableActionsMap = this.escalationActions;
        if(this.comboOptions.data){
         obj = JSON.parse(this.comboOptions.data);
            for(let i = 0; i < obj.length; i++){
                let tempObj;
                if(escalatableActionsMap.has(obj[i]) && escalatableActionsMap.get(obj[i]) == this.serviceAction){
                    tempObj =
                    {
                        label: obj[i] + ' **',
                        value: obj[i]
                    };
                }else{
                    tempObj =
                    {
                        label: obj[i],
                        value: obj[i]
                    };
                }
            comboObj.push(tempObj);
            }
        }
        return comboObj;
    }
    // this returns a list of dependent picklist values
    get ctnOptions(){
        let deviceList;
        let rowOptions= [];
        if(this.deviceList.data){
            deviceList = JSON.parse(this.deviceList.data);
            for(let i = 0; i < deviceList.length; i++){
                let labelParam = (deviceList[i].Phone_Number__c) ? deviceList[i].Phone_Number__c  : 'no data';
                labelParam = (deviceList[i].Manufacturer__c) ?  labelParam +' - '+ deviceList[i].Manufacturer__c  : labelParam;
                labelParam = (deviceList[i].Make_And_Model__c) ? labelParam +' - '+ deviceList[i].Make_And_Model__c  : labelParam;

                let valuePeram = (deviceList[i].Manufacturer__c) ? deviceList[i].Manufacturer__c + '/' : '';
                valuePeram = (deviceList[i].Make_And_Model__c) ? valuePeram  + deviceList[i].Make_And_Model__c : valuePeram;
                let valueData = {};

                valueData.manufacturer = (deviceList[i].Manufacturer__c) ? deviceList[i].Manufacturer__c  : '';
                valueData.makeAndModel =  (deviceList[i].Make_And_Model__c) ? deviceList[i].Make_And_Model__c : '';
                valueData.assetId =  (deviceList[i].Id) ? deviceList[i].Id : '';
                valueData.ctn = (deviceList[i].Phone_Number__c) ? deviceList[i].Phone_Number__c  : '';
                valueData.url = valuePeram;


                let tempObj = { label: labelParam, value: JSON.stringify(valueData)};


                // we have advanced filter business req
                switch(this.serviceAction){
                    case 'Device Support':
                        if(deviceList[i].Status === 'Active'||deviceList[i].Status === 'Suspended'){
                            rowOptions.push(tempObj);
                        }
                        break;
                    case 'Device Issues':
                        if(deviceList[i].Status === 'Active'||deviceList[i].Status === 'Suspended'){
                            rowOptions.push(tempObj);
                        }
                        break;
                    case 'Service Issues':
                        if(deviceList[i].Status === 'Active'||deviceList[i].Status === 'Suspended'){
                            rowOptions.push(tempObj);
                        }
                        break;

                }

            }

        }
        return rowOptions;
    }
    //tells html which template to render
    get isActionPicklist(){
        return (!this.ctnActionList.includes(this.serviceAction)) ? true : false ;

    }
    //tells html which template to render
    get isCTNList(){

        return (this.ctnActionList.includes(this.serviceAction)) ? true : false ;

    }
    get escalationActions(){
        let returnMap = new Map();
        if(this.payload.data){
        let recordList = JSON.parse(this.payload.data);
        for(let i = 0; i < recordList.metadataListForEscalations.length; i++){
            if(recordList.metadataListForEscalations[i].Allow_LIC_Escalation__c){
                returnMap.set(recordList.metadataListForEscalations[i].Action__c, recordList.metadataListForEscalations[i].Type__c);
            }
        }}
        return returnMap;
    }
    //self explanitory
    handleChange(event) {
        this.serviceActionFeature = event.target.value;
    }
    //we handle sumbit on diffrent situations with the switch statment
    handleSubmit(){
       let comboBox = this.template.querySelector('[data-id="combobox"]');
       let ctncomboBoxCMP = this.template.querySelector('[data-id="CTNCombobox"]');
       let data = JSON.parse(this.payload.data);
       let billAccount = {};
       billAccount.billingAccountId = this.recordId;
       billAccount.ban = data.ban;


       switch (this.serviceAction){

        case 'Device Support':
            if(!ctncomboBoxCMP.checkValidity() ){return; }

            this.handleDeviceSupport(JSON.parse(ctncomboBoxCMP.value),billAccount);

            break;
        case 'Device Issues':
            if(!ctncomboBoxCMP.checkValidity() ){ return; }
            this.handleDeviceIssues(JSON.parse(ctncomboBoxCMP.value),billAccount);

            break;
        case 'Service Issues':
            if(!ctncomboBoxCMP.checkValidity() ){ return; }
            //we launch to same system as device issues. Still TSRM
            this.handleDeviceIssues(JSON.parse(ctncomboBoxCMP.value),billAccount);

            break;

        //this is the action picklist
        default:
            if(!comboBox.checkValidity() ){
                return;
            }
            let msg = 'PostToOpus';
            const licObj = {};
            licObj.launchPoint = 'Launch Point';
            licObj.JsonData = {};
            bwcLICPublisher.publishMessage(msg,licObj,data.ban);
            bwcInteractActivityPublisher.publishMessage(this.interactionId,this.serviceActionFeature,JSON.stringify(billAccount),this.serviceAction);

       }



       bwcBAActionPublisher.publishMessage(this.serviceActionFeature,this.recordId,this.serviceAction);
       this.dispatchEvent(new CustomEvent('close'));
    }
    //self explanitory
    handleDeviceIssues(ctncomboBox,ban){
        let detailField = this.handleDetailField(ctncomboBox,ban);
        bwcTSRMLauncher.launchTSRM(this.interactionId,ctncomboBox.ctn,detailField.ban);
        bwcInteractActivityPublisher.publishMessage(this.interactionId,BwcConstants.InteractionActivityValueMapping.TroubleshootResolveDeviceIssues.action,JSON.stringify(ban),BwcConstants.InteractionActivityValueMapping.TroubleshootResolveDeviceIssues.action);

    }
    //self explanitory
    handleDeviceSupport(combobox,ba){
        //billAccount.ctn = ()?:'';
        ba = this.handleDetailField(combobox,ba);
        let URLParam = DeviceURL + combobox.manufacturer +'/'+ combobox.makeAndModel;
        bwcOpenNewBrowserTabPublisher.publishMessage(URLParam);
        bwcInteractActivityPublisher.publishMessage(this.interactionId,BwcConstants.InteractionActivityValueMapping.TroubleshootResolveDeviceSupport.action,JSON.stringify(ba),BwcConstants.InteractionActivityValueMapping.TroubleshootResolveDeviceSupport.action);


    }
    handleDetailField(dataObject,ban){
        ban.manufacturer = dataObject.manufacturer;
        ban.makeAndModel = dataObject.makeAndModel;
        ban.ctn = dataObject.ctn;
        return ban;
    }
    //self explanitory
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
    //self explanitory
    connectedCallback() {
        this.getInteractionId();
    }



}