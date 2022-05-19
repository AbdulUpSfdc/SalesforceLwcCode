import { api, track, wire } from 'lwc';
import { getRecord } from "lightning/uiRecordApi";
import { refreshApex } from '@salesforce/apex';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcCommunicationTemplateServices from 'c/bwcCommunicationTemplateServices';
import * as BwcLabelServices from 'c/bwcLabelServices';
import BwcPageElementBase from 'c/bwcPageElementBase';
import EMAIL_TEMPLATE_ID_FIELD from '@salesforce/schema/Communication_Template_Mapping__c.Email_Template_Id__c';
import EMAILTEMPLATE_FIELD from '@salesforce/schema/Communication_Template_Mapping__c.EmailTemplate__c';
import SMS_TEMPLATE_ID_FIELD from '@salesforce/schema/Communication_Template_Mapping__c.SMS_Template_Id__c';
import SMS_TEMPLATE_FIELD from '@salesforce/schema/Communication_Template_Mapping__c.SMS_Template__c';

export default class CustomLookup extends BwcPageElementBase {
    labels = BwcLabelServices.labels;

    @api recordId;
    @api objName;
    @api iconName;
    @api placeholder;
    @api displayFields;
    @api fields;
    @api labelName;
    @api selectedCommRec = {};
    @api currentRecordId;
    @api isVisible;
    @track templateName;
    @track templateId;
    @track selectedRecord;
    isLoading = false;
    
    @wire(getRecord, {recordId: '$recordId', fields: [EMAIL_TEMPLATE_ID_FIELD, EMAILTEMPLATE_FIELD,SMS_TEMPLATE_ID_FIELD,SMS_TEMPLATE_FIELD]})
    currentTemplate;

    connectedCallback() {
        if(this.objName === "EmailTemplate" || this.objName === "MessagingTemplate"){
            this.getCommunicationRecord();
        }
    }

    async handleLookup(event){
        this.isLoading = true;
        BwcUtils.log( 'In handleLookup'+JSON.stringify (event.detail.data.record));
        try{
            this.selectedRecord = event.detail.data.record;
            if(this.selectedRecord){
                this.templateId = this.selectedRecord.Id;
                switch(this.objName){
                case "EmailTemplate":
                    this.templateName = this.selectedRecord.Name;
                    break;
                case "MessagingTemplate":
                    this.templateName = this.selectedRecord.MasterLabel;
                    break;
                }
                let response = await BwcCommunicationTemplateServices.updateCommunicationData(this.templateId,this.templateName,this.recordId);
                if(response.success){
                    this.showToast('Success',this.labels.templateUpdated,'Success','');
                    refreshApex(this.currentTemplate);
                }
            }
        }
        catch (e) {
            BwcUtils.error('Exception loading data', e);
            throw new Error(this.labels.unexpectedError);
        }
        finally {
            this.isLoading = false;
         }
    }

    async handleClose(){
    this.isLoading = true;
       try{
            if(this.selectedRecord){
                this.templateId = this.selectedRecord.Id;
                BwcUtils.log('this.templateId'+this.templateId);
                switch(this.objName){
                    case "EmailTemplate":
                        this.templateName = this.selectedRecord.Name;
                        break;
                    case "MessagingTemplate":
                        this.templateName  = this.selectedRecord.MasterLabel;
                        break;
                    }
                let response = await BwcCommunicationTemplateServices.deleteCommunicationData(this.templateId,this.templateName,this.recordId);
                if(response.success){
                    this.showToast('Success',this.labels.templateDeleted,'Success','');
                    refreshApex(this.currentTemplate);
                }
            }
        }
        catch (e) {
            BwcUtils.error('Exceptiion closing', e);
            throw new Error(this.labels.unexpectedError);
        }
        finally {
            this.isLoading = false;
         }
        
    }

     //This function is used to set the selected Email Template & Messaging Template on load
     async getCommunicationRecord(){
        this.isLoading = true;
        let recordSelected={};
        try{
            let response = await BwcCommunicationTemplateServices.communicationTemplateData(this.recordId);
            let CommRecord = response[0];
            switch(this.objName){
                case "EmailTemplate":
                    recordSelected = {Id:CommRecord.Email_Template_Id__c,Name:CommRecord.EmailTemplate__c,showField:CommRecord.EmailTemplate__c};
                    BwcUtils.log('recordSelected for EmailTemplate'+JSON.stringify(recordSelected));
                    break;
                case "MessagingTemplate":
                    recordSelected = {Id:CommRecord.SMS_Template_Id__c,MasterLabel:CommRecord.SMS_Template__c,showField:CommRecord.SMS_Template__c};
                    BwcUtils.log('recordSelected for MessagingTemplate'+JSON.stringify(recordSelected));
                    break;
            }
            if(recordSelected.Id !== undefined && (recordSelected.Name !== undefined|| recordSelected.MasterLabel !== undefined)){
                this.selectedRecord = recordSelected;
                this.dispatchEvent(new CustomEvent('lookup', {
                        bubbles: true,
                        composed: true,
                        cancelable: true,
                        detail: {
                            data: {
                                record: recordSelected,
                                recordId: recordSelected.Id,
                                currentRecordId: this.currentRecordId
                            }
                        }
                    }));
                }
        }
        catch (e) {
            BwcUtils.error('Exception loading data', e);
            throw new Error(this.labels.unexpectedError);
        }
        finally {
            this.isLoading = false;
         }
    }
    
}