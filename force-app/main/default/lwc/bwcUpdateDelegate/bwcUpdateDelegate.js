import { api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import NAME_FIELD from '@salesforce/schema/Employee__c.Name';
import DELEGATE1_FIELD from '@salesforce/schema/Employee__c.Delegate_1__c';
import DELEGATE2_FIELD from '@salesforce/schema/Employee__c.Delegate_2__c';
import BwcPageElementBase from 'c/bwcPageElementBase';
import currentUserid from '@salesforce/user/Id';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcLabelServices from 'c/bwcLabelServices';
import * as BwcEmployeeServices from 'c/bwcEmployeeServices';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class BwcUpdateDelegate extends BwcPageElementBase {
    labels = BwcLabelServices.labels;

    @api recordId;
    @api objectApiName;
    delegate1Value;
    delegate2Value;
    disabledelegates1btn = true;
    disabledelegates2btn = true;
    currentUserSOAData;
    initialState = true;
    
    @wire(getRecord, { recordId: '$recordId', fields: [NAME_FIELD, DELEGATE1_FIELD, DELEGATE2_FIELD] })
    currentEmployee;

    //ConnectedCallback to fetch logged in User's Employee SOA Amount
    async connectedCallback() {
            const result = await BwcEmployeeServices.fetchEmployeeDetails(currentUserid);
            this.currentUserSOAData = result[currentUserid].SOA_Level__r.Authorization_Amount__c;
        }
        //changeHandler to fetch Delegate 1 Id and to fetch Delegate 1's Employee SOA Amount
    async deletegate1ChangeHandler(event) {
        try {

            this.delegate1Value = event.detail.value[0];
            this.delegate2Value = this.template.querySelector('.delegate2').value;
            if (this.delegate1Value) {
                this.initialState = false;
                const result1 = await BwcEmployeeServices.fetchEmployeeDetails(this.delegate1Value);
                if (Object.keys(result1).length !== 0) {
                    if (result1[this.delegate1Value].SOA_Level__c) {
                        if (result1[this.delegate1Value].SOA_Level__r.Authorization_Amount__c < this.currentUserSOAData) {
                            this.initialState = true;
                            this.disabledelegates1btn = true;
                            this.showToast('', this.labels.delegateChangeSOAError, 'error', 'sticky');
                        } else {
                            this.disabledelegates1btn = false;
                            if (this.delegate2Value) {
                                const result2 = await BwcEmployeeServices.fetchEmployeeDetails(this.delegate2Value);
                                if (Object.keys(result2).length !== 0 && result2[this.delegate2Value].SOA_Level__c && result2[this.delegate2Value].SOA_Level__r.Authorization_Amount__c >= this.currentUserSOAData) {
                                    this.disabledelegates2btn = false;
                                } else {
                                    this.initialState = true;
                                }
                            } else {
                                this.disabledelegates2btn = false;
                            }
                        }
                    } else {
                        this.disabledelegates1btn = true;
                        this.initialState = true;
                        this.showToast('', this.labels.NoSOAError, 'error', 'sticky');
                    }
                } else {
                    this.disabledelegates1btn = true;
                    this.initialState = true;
                    this.showToast('', this.labels.NoEmployeeRecordError, 'error', 'sticky');
                }
            } else {
                this.disabledelegates1btn = false;
                if (this.delegate2Value) {
                    const result2 = await BwcEmployeeServices.fetchEmployeeDetails(this.delegate2Value);
                    if (result2[this.delegate2Value].SOA_Level__c && result2[this.delegate2Value].SOA_Level__r.Authorization_Amount__c >= this.currentUserSOAData) {
                        this.disabledelegates2btn = false;
                    }
                }
            }
            if (!this.delegate1Value && !this.delegate2Value) {
                this.disabledelegates1btn = true;
                this.disabledelegates2btn = true;
            }
        } catch (e) {
            BwcUtils.error('Update Delegate 1', e);
            throw new Error(this.labels.unexpectedError);
        }
    }

    //changeHandler to fetch Delegate 1 Id and to fetch Delegate 1's Employee SOA Amount
    async deletegate2ChangeHandler(event) {
        try {
            this.delegate2Value = event.detail.value[0];
            this.delegate1Value = this.template.querySelector('.delegate1').value;
            if (this.delegate2Value) {
                this.initialState = false;
                const result1 = await BwcEmployeeServices.fetchEmployeeDetails(this.delegate2Value);
                if (Object.keys(result1).length !== 0) {
                    if (result1[this.delegate2Value].SOA_Level__c) {
                        if (result1[this.delegate2Value].SOA_Level__r.Authorization_Amount__c < this.currentUserSOAData) {
                            this.initialState = true;
                            this.disabledelegates2btn = true;
                            this.showToast('', this.labels.delegateChangeSOAError, 'error', 'sticky');

                        } else {
                            this.disabledelegates2btn = false;
                            if (this.delegate1Value) {
                                const result2 = await BwcEmployeeServices.fetchEmployeeDetails(this.delegate1Value);
                                if (Object.keys(result2).length !== 0 && result2[this.delegate1Value].SOA_Level__c && result2[this.delegate1Value].SOA_Level__r.Authorization_Amount__c >= this.currentUserSOAData) {
                                    this.disabledelegates1btn = false;
                                } else {
                                    this.initialState = true;
                                }
                            } else {
                                this.disabledelegates1btn = false;
                            }

                        }
                    } else {
                        this.disabledelegates2btn = true;
                        this.initialState = true;
                        this.showToast('', this.labels.NoSOAError, 'error', 'sticky');

                    }
                } else {
                    this.disabledelegates2btn = true;
                    this.initialState = true;
                    this.showToast('', this.labels.NoEmployeeRecordError, 'error', 'sticky');

                }
            } else {
                this.disabledelegates2btn = false;
                if (this.delegate1Value) {
                    const result2 = await BwcEmployeeServices.fetchEmployeeDetails(this.delegate1Value);
                    if (result2[this.delegate1Value].SOA_Level__c && result2[this.delegate1Value].SOA_Level__r.Authorization_Amount__c >= this.currentUserSOAData) {
                        this.disabledelegates1btn = false;
                    }
                }
            }
            if (!this.delegate1Value && !this.delegate2Value) {
                this.disabledelegates1btn = true;
                this.disabledelegates2btn = true;
            }
        } catch (e) {
            BwcUtils.error('Updating Delegate 2', e);
            throw new Error(this.labels.unexpectedError);
        }
    }

    // getter method to retrieve the boolean value to disable/Enable save button Based on Delegate's selection
    get isDisabled() {
        return (this.initialState && (this.disabledelegates1btn || this.disabledelegates2btn))
    }


    // Handle cancel to close the Model window
    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async handleSave(event) {
        let response = await BwcEmployeeServices.saveEmployeeData(this.delegate1Value, this.delegate2Value, this.recordId);
        if (response) {
            this.dispatchEvent(new CloseActionScreenEvent());
            this.showToast('Success', 'Employee Delegates Updated!', 'Success', '');
            refreshApex(this.currentEmployee);
        } else {
            this.showToast('Error', response.message, 'Error', '');
        }


    }
}