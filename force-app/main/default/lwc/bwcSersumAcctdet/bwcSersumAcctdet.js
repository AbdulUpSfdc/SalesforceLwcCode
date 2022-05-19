import { LightningElement,wire ,track,api } from 'lwc';
import getServiceDetails from '@salesforce/apex/BWC_ServiceSummary.getServiceDetails';

// Import custom labels
import header_firstnet from '@salesforce/label/c.BWC_FirstNet_Header';
import message_firstnet from '@salesforce/label/c.BWC_FirstNet_Message';
import header_businessCustomer from '@salesforce/label/c.BWC_BusinessCustomer_Header';
import message_businessCustomer from '@salesforce/label/c.BWC_BusinessCustomer_Message';

const columns = [
    { label: 'LOB', fieldName: 'lob', type: 'text',hideDefaultActions: true,cellAttributes : {class : { fieldName : 'redfont'}} },
    { label: 'Service Start', fieldName: 'serstart', type: 'text',hideDefaultActions: true,cellAttributes : {class : { fieldName : 'redfont'}} },
    { label: 'Account Status', fieldName: 'acctStatus', type: 'text',hideDefaultActions: true,cellAttributes : {class : { fieldName : 'redfont'}} },
];

export default class BwcSersumAcctdet extends LightningElement {
    isLoading1 = true;
    data = [];
    columns = columns;
    @track acctSerSumDetails;
    @track error;
    globalId;
    @api recordId;
    @api objectApiName;
    fields = ['AccountId', 'Name', 'Global_ID__c', 'BillingAddress', 'ShippingAddress','Account_Type__c','CPNI_Indicator__c'];

    showModal 
    modalHeader
    modalMessage

    label_firstnet = {
        header_firstnet,
        message_firstnet,
    };

    label_businessCustomer = {
        header_businessCustomer,
        message_businessCustomer,
    };

    connectedCallback(){  

        this.isLoading1=false;
        getServiceDetails({recordId:this.recordId})
            .then(result => {    
                let response = JSON.parse(result);
                this.acctSerSumDetails = response.services;
                this.data = this.acctSerSumDetails;
                this.isLoading=false;
                console.log({response});
                console.log('%cBwcSersumAcctdet',"color:green");

                if(response.isFirstNet){
                    this.showModal = true;
                    this.modalHeader = header_firstnet;
                    this.modalMessage = message_firstnet;
                } else if(response.isBusinessCustomer) {
                    this.showModal = true;
                    this.modalHeader = header_businessCustomer;
                    this.modalMessage = message_businessCustomer;
                }
            })
            .catch(error => {
                console.log('%cBwcSersumAcctdet',"color:red");
                console.log(error);
                this.error = error;
            });
    }

    
}