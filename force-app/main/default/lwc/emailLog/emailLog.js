import { LightningElement, track, api, wire } from "lwc";
import { getPicklistValuesByRecordType } from "lightning/uiObjectInfoApi";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Lead_OBJECT from "@salesforce/schema/Lead";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import getDefaultRT from "@salesforce/apex/LogACallController.getDefaultRT";

import EmailResult from "@salesforce/label/c.EmailResult";
import FollowUpDateMessage from "@salesforce/label/c.Follow_Up_Date_Message";
import emailLogIE11 from "./emailLogIE11.html";
import emailLog from "./emailLog.html";
import FORM_FACTOR from '@salesforce/client/formFactor';

import FIRSTNAME_FIELD from "@salesforce/schema/Lead.FirstName";
import LASTNAME_FIELD from "@salesforce/schema/Lead.LastName";
import NAME_FIELD from "@salesforce/schema/Lead.Name";
import EMAIL_FIELD from "@salesforce/schema/Lead.Email";
import EMAILNOTES_FIELD from "@salesforce/schema/Lead.LatestEmailNotes__c";
//import LEADSTRENGTH_FIELD from "@salesforce/schema/Lead.Rating";
import CREATEDDATE_FIELD from "@salesforce/schema/Lead.CreatedDate";
import EXPIRATION_FIELD from "@salesforce/schema/Lead.LeadExpirationDate__c";
import createCallLogActivity from "@salesforce/apex/LogACallController.createCallLogActivity";
import { NavigationMixin } from "lightning/navigation";
import ComplianceMessage from '@salesforce/label/c.Compliance_Message';

const FIELDS = [FIRSTNAME_FIELD, LASTNAME_FIELD, NAME_FIELD, EMAIL_FIELD, EMAILNOTES_FIELD, CREATEDDATE_FIELD, EXPIRATION_FIELD];
export default class CallLog extends NavigationMixin(LightningElement) {

  label = {
    ComplianceMessage
  }

  @api recordId;
  @api objectApiName;
  @track calldate;

  recTypeId;
  @track record;
  @track name;
  @track email;
  @track notes;
  //@track leadStrength;
  @track emailresults;
  @track emailResultValue;
  @track isLightning=false;
  @track displayCustomToastInSmallDevices = false;
  @track displayCFdateErrorMessage = false;
  @track displayRequiredInputsErrorMessage = false;
 
  @wire(getPicklistValuesByRecordType, {
    objectApiName: Lead_OBJECT,
    recordTypeId: "$recTypeId"
  })
  TaskPicklistFieldsValues({ error, data }) {
    if (data) {
      //this.callresults = data.picklistFieldValues.ReasonforClosingLead__c.values;
      //this.calltypes = data.picklistFieldValues.CallType__c.values;
      let emailResultOptions = [];
      EmailResult.split(",").forEach((option) => {
        let options = {};
        options.label = options.value = option;
        emailResultOptions.push(options);
      });
      this.emailresults = emailResultOptions;
    } else if (error) {
    }
  }
  
  @wire(getRecord, { recordId: "$recordId", fields: FIELDS })
  leadRecord({ error, data }) {   
    if (data) {
       this.record = data;
       console.log('wired data is' + JSON.stringify(data));
       this.name = getFieldValue(this.record, NAME_FIELD);
       this.email = getFieldValue(this.record, EMAIL_FIELD);      
       this.notes = getFieldValue(this.record, EMAILNOTES_FIELD);
       //this.leadStrength = getFieldValue(this.record, LEADSTRENGTH_FIELD);
    } else if (error) {
       console.log('error in lead..' + error);
    }
  }

 /* get name() {
    let fname = getFieldValue(this.lead.data, FIRSTNAME_FIELD);
    let lname = getFieldValue(this.lead.data, LASTNAME_FIELD);
    let name = fname + " " + lname;
    return name;
  }

  get phone() {
    return this.formatPhoneNumber(getFieldValue(this.lead.data, PHONE_FIELD));
  }

  get notes() {
    return getFieldValue(this.lead.data, NOTES_FIELD);
  }

  get leadStrength(){
    return getFieldValue(this.lead.data, LEADSTRENGTH_FIELD); 
  } */

  handleSubmit(event) {  
    event.preventDefault();
    event.stopPropagation();
    this.emailResultValue = this.template.querySelector(
      "[data-id='emailResult']"
    ).value;   
    let emailDate = this.template.querySelector("[data-id='emailDate']").value;
    let followUpDate = this.template.querySelector("[data-id='followupDate']")
      .value;
    let emailNotes = this.template.querySelector("[data-id='emailNotes']").value;

    let emailLog = { sobjectType: "Task" };
    emailLog.CallType__c = "Email";    
    emailLog.CallResult__c = this.emailResultValue; 
    emailLog.CustomerRequestedFollowUpDate__c = followUpDate;
    emailLog.CallDate__c = emailDate;
    emailLog.CallNotes__c = emailNotes;
    emailLog.Lead__c = this.recordId;
    emailLog.Subject = this.emailResultValue;
  //  emailLog.TaskSubtype = "Email";
    emailLog.WhoId = this.recordId;
    //emailLog.Priority = this.leadStrength;
    emailLog.Status = "Completed";
    emailLog.What = this.recordId;
    
    if (!this.validateForm() && FORM_FACTOR === 'Large') {
      this.displayCustomToastInSmallDevices = false;
      this.displayRequiredInputsErrorMessage = false;
      this.dispatchEvent(
        new ShowToastEvent({
            title: "Error in Validation",
            message: "Please provide required inputs",
            variant: 'error'
        })
    );
    return;
    }else if(!this.validateForm() && (FORM_FACTOR === 'Small' || FORM_FACTOR === 'Medium')){
      this.displayCustomToastInSmallDevices = true;
      this.displayRequiredInputsErrorMessage = true;
      setTimeout(() => {
        this.displayCustomToastInSmallDevices = false;
        this.displayRequiredInputsErrorMessage = false;
      }, 5000);
      return;
    }
    else {
      let futureDate = this.record.fields.LeadExpirationDate__c.value;//YYYY-MM-DDTHH:MM:SS.zzz
      let date = new Date();
      //let today = date.toISOString().split('T')[0];
      //updated date format as part of SPTSFDCSLS-3509
      let today = date.getFullYear() +'-'+(date.getMonth() < 9 ? '0': '')+(date.getMonth()+1)+'-'+(date.getDate()<9 ? '0': '')+(date.getDate());
      if(followUpDate != '' && ((followUpDate < today) || (followUpDate > futureDate)) && (FORM_FACTOR === 'Small' || FORM_FACTOR === 'Medium')) {
        this.displayCustomToastInSmallDevices = true;
        this.displayCFdateErrorMessage = true;
        setTimeout(() => {
          this.displayCustomToastInSmallDevices = false;
          this.displayCFdateErrorMessage = false;
        }, 5000);
        return;
      } else if(followUpDate != '' && ((followUpDate < today) || (followUpDate > futureDate)) && (FORM_FACTOR === 'Large')){
        this.displayCustomToastInSmallDevices = false;
        this.displayCFdateErrorMessage = false;
        this.dispatchEvent(
          new ShowToastEvent({
              title: "Error in Validation",
              message: FollowUpDateMessage,
              variant: 'error'
          })
        );
        return;
      }
      let activity = JSON.stringify(emailLog);  
      console.log('Email Log Object -->' + activity);
      createCallLogActivity({
        newRecord: activity
      })
        .then((response) => {
          if (response) {
            if(FORM_FACTOR === 'Small' || FORM_FACTOR === 'Medium')                
                this.navigateToDetailMobile();
            else
              this.navigateToDetail();
          }
        })
        .catch((error) => {
          let message =
            "Error received: code " +
            error.errorCode +
            ", " +
            "message " +
            error.body.message;        
        });
    }
  }
  get FollowUpDateMessage(){
    return FollowUpDateMessage;
  }
  closeCustomToast(){
    this.displayCustomToastInSmallDevices = false;
  }
  addDays(date, days) {
    var result = new Date(date);
    result.setDate(result.getDate() + days);
    return result;
  }
  navigateToDetail() {
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: this.recordId,
        objectApiName: "Lead",
        actionName: "view"
      }
    });
  }

  navigateToDetailMobile(){   
    const submitClickedEvent = new CustomEvent('submitclicked');
    // Fire the custom event to aura
    this.dispatchEvent(submitClickedEvent);
  }  

  handleCancel(event) {
    if(FORM_FACTOR === 'Small' || FORM_FACTOR === 'Medium') {
      const cancelClickedEvent = new CustomEvent('cancelclicked');      
      this.dispatchEvent(cancelClickedEvent);
    }  
    else    
      window.history.back();
  }

 
  handleEmailResultChange(event) {
    this.emailResultValue = event.detail.value;
  }

  connectedCallback() {
    var newDate = new Date();
    this.emaildate = newDate.toISOString();
    let time = newDate.getTime();
    getDefaultRT({
      ObjName: "LEAD"
    })
      .then((res) => {
        this.recTypeId = res;
      })
      .catch((err) => {});   
  }

  renderedCallback() {
    console.log('record..' + JSON.stringify(this.record));
    this.name = getFieldValue(this.record, NAME_FIELD);
    this.email = getFieldValue(this.record, EMAIL_FIELD);
    this.notes = getFieldValue(this.record, EMAILNOTES_FIELD);
    //this.leadStrength = getFieldValue(this.record, LEADSTRENGTH_FIELD);
  }

  render() {
    if (this.isIE()) {
      return emailLogIE11;
    } else {
      return emailLog;
    }
  }
  formatPhoneNumber(strPhone) {
    if (strPhone != null) {
      if(strPhone.includes('+1')){
        strPhone = strPhone.replace('+1','');
      }
      let match = strPhone.match(/^(\d{3})(\d{3})(\d{4})$/);

      if (match) {
        return "(" + match[1] + ") " + match[2] + "-" + match[3];
      }
    } else return strPhone;
  }
  isIE() {
    var ua = window.navigator.userAgent;
    if (
      ua.indexOf("MSIE") > -1 ||
      ua.indexOf("Trident") > -1 ||
      ua.indexOf("IE11") > -1
    )
      return true;
    else return false;
  }

  validateForm() {
    let isFormValid = true;
  
    if (this.emailResultValue == null)
      isFormValid = false;

      return isFormValid;
  }

}