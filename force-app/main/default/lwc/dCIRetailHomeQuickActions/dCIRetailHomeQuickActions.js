import { LightningElement, api, track } from 'lwc';
import postToOPUS from '@salesforce/apex/OPUSLaunchHelper.postToOPUS';
import gotoMyStoreURL from '@salesforce/apex/LeadForm.getMyStoreUrlLink';
import DCIcheckIfBusywithCustomer from '@salesforce/apex/DCIController.DCIcheckIfBusywithCustomer';
import getRetailCustomSettings from '@salesforce/apex/OPUSLaunchHelper.getRetailCustomSettings';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class DCIRetailHomeQuickActions extends NavigationMixin(LightningElement) {

    @track redirectURL = '';
    @track myStoreLink;
    @track openModal = false;
    hideQuckAction;
    isLoading =  false;//Lakshmi


    showModal() {
        this.openModal = true;
    }
    closeModal() {
        this.openModal = false;
    }

    gotoLeadForm(){
        this.navigateToWebPage('/lightning/n/LeadForm');
    }

    connectedCallback(){
            gotoMyStoreURL()
            .then(result => {
                if (result) {
                   this.myStoreLink = result;
                }  
            });
    }

   gotoPayABillForm(){
    this.isLoading = true;//Lakshmi
            postToOPUS({
                recordId: null,
                launchIntent: "Bill Pay-Unverified"
            })
            .then(result => {
                this.isLoading = false;//Lakshmi
                if(result!='isEngaged'){
                    this.redirectURL = result;
                    this.navigateToWebPage(encodeURI(this.redirectURL));
                }
                else{
                    const event = new ShowToastEvent({
                        variant: 'error',
                        title: 'Error !',
                        message: ' You are already helping a customer. Please finish your current engagement before helping next customer.',
                    });
                    this.dispatchEvent(event);
                }
            }); 
    }

    gotoBuyaccessoryForm(){
        this.isLoading = true;//Lakshmi
        postToOPUS({
            recordId: null,
            launchIntent: "Sell Item"
        })
        .then(result => {
            this.isLoading = false;//Lakshmi
            if(result!='isEngaged'){
                this.redirectURL = result;
                this.navigateToWebPage(encodeURI(this.redirectURL));
            }
            else{
                const event = new ShowToastEvent({
                    variant: 'error',
                    title: 'Error !',
                    message: ' You are already helping a customer. Please finish your current engagement before helping next customer.',
                });
                this.dispatchEvent(event);
            }
            
        }); 
    }
	alreadyHelpingToast(){        
		const event = new ShowToastEvent({
			variant: 'error',
            title: 'Error!',
            message: 'You are already helping a customer. Please finish your current customer before starting a new one.',
        });
        this.dispatchEvent(event);
    }
    navigateToWebPage(url) {
        this[NavigationMixin.Navigate]({
            "type": "standard__webPage",
            "attributes": {
                "url": url
            }
        });
    }
    refreshPage(){
        window.location.reload();
    } 
 
}