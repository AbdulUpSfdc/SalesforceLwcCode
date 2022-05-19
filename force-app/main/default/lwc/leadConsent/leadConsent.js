import { LightningElement, wire, api, track } from 'lwc';
import ATT_LOGO from '@salesforce/resourceUrl/ATTlogo';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updateLeadConsent from '@salesforce/apex/LeadConsent.updateLeadConsent';
import getLeadConsent from '@salesforce/apex/LeadConsent.getLeadConsent';
import updateLeadConsentCancelled from '@salesforce/apex/LeadConsent.updateLeadConsentCancelled';
import CustomerConsent from '@salesforce/label/c.CustomerConsent';
import ConsentMessage from '@salesforce/label/c.ConsentMessage';
//Spanish Labels
import CustomerConsentSpanish from '@salesforce/label/c.CustomerConsentSpanish';
import ConsentMessageSpanish from '@salesforce/label/c.ConsentMessageSpanish'
import MobilePhoneSpanish from '@salesforce/label/c.MobilePhoneSpanish'
import EmailSpanish from '@salesforce/label/c.EmailSpanish'
import FirstNameSpanish from '@salesforce/label/c.FirstNameSpanish'
import LastNameSpanish from '@salesforce/label/c.LastNameSpanish'
import AcceptSpanish from '@salesforce/label/c.AcceptSpanish'
import CancelSpanish from '@salesforce/label/c.CancelSpanish'


export default class LeadConsent extends LightningElement {
    @track hashId;
    @track showConsent =false;
    @track isSpanish =false;
    @track LeadConsent ={};
    @track Message='';
    @track combovalue='English';
    @track isModalOpen = false;
    AttLogoUrl = ATT_LOGO;

    label = {
        CustomerConsent,
        CustomerConsentSpanish,
        ConsentMessage,
        ConsentMessageSpanish,
        MobilePhoneSpanish,
        EmailSpanish,
        FirstNameSpanish,
        LastNameSpanish,
        AcceptSpanish,
        CancelSpanish
    };
    connectedCallback(){
        this.hashId = ((new URL(window.location.href)).searchParams.get("id")); 
        console.log(this.hashId);
        if(this.hashId){
            getLeadConsent({
                idHash: this.hashId
            })
            .then(data => {
                this.showConsent = true;
                this.LeadConsent = data;  
            }).catch(error => {
                console.log('error '+error);
                this.Message ='This link is no longer valid.';
                console.log("Error thrown in getLeadConsent" + JSON.stringify(error));
                this.showConsent = false; 
             });

        }else{
            this.Message ='This link is invalid.'; 
        }
    }

    get options() {
        return [
            { label: 'English', value: 'English' },
            { label: 'Spanish', value: 'Spanish' },
        ];
    }

    handleComboChange(event) {
        this.combovalue = event.detail.value;
        this.isSpanish = this.combovalue == 'English' ? false : true;
    }

    handleAccept(event){
        updateLeadConsent({
            idHash: this.hashId
        })
        .then(data => {
            this.Message ='Thank you! Your consent has been registered successfully';
            this.showConsent = false;
            this.dispatchEvent( 
                new ShowToastEvent({
                title: 'Success',
                message: 'Thank you! Your consent has been registered successfully',
                variant: 'success'
               })  
            );
        }).catch(error => {
            this.Message ='This link is no longer valid.';
            this.showConsent = false; 
            console.log("Error thrown in updateLeadConsent" + JSON.stringify(error));
         });
    }

    handleCancel(event){
        this.isModalOpen = true;
    }

    closeModal() {
        // to close modal set isModalOpen tarck value as false
        this.isModalOpen = false;
    }
    submitDetails() {
        this.isModalOpen = false;
        updateLeadConsentCancelled({
            idHash: this.hashId
        })
        .then(data => {
            this.Message ='Thank you! have a nice day.'; 
            this.showConsent = false; 
        }).catch(error => {
            this.Message ='This link is no longer valid.';
            this.showConsent = false; 
            console.log("Error thrown in updateLeadConsentCancelled" + JSON.stringify(error));
         });
    }
}