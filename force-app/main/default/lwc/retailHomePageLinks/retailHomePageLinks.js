import { LightningElement, wire, api, track } from 'lwc';
import getLoggedInUsrInfo from '@salesforce/apex/RetailHomePageController.getLoggedInUserInfo';
import gotoMyStoreURL from '@salesforce/apex/LeadForm.getMyStoreUrlLink';
import { NavigationMixin } from 'lightning/navigation';
import SubmitUSHSupportTicket from '@salesforce/label/c.Submit_USH_Support_Ticket';////Sid Changes on Submit USH Support Ticket

export default class RetailHomePageLinks extends NavigationMixin(LightningElement) {
    @track userInfo ={};
    @track isARSM = false;
    @track myStoreLink;
    @track submitUSHSupportTicket=SubmitUSHSupportTicket;//Sid Changes on Submit USH Support Ticket
    @track issubmitUSHSupportTicket=false;//Sid Changes on Submit USH Support Ticket
    @track isARChannel=true;//SPTSLSATT-1236
	@track classRep='slds-modal slds-fade-in-open slds-backdrop';
	@track openModal = false;
    showModal() {
        this.openModal = true;
    }
    showsubmitUSHModal() {//Sid Changes on Submit USH Support Ticket
        this.openModal = true;
        this.issubmitUSHSupportTicket=true;
    }
    closeModal() {
        this.openModal = false;
        this.issubmitUSHSupportTicket=false;//Sid Changes on Submit USH Support Ticket
    }
	
	
    connectedCallback(){
            getLoggedInUsrInfo()
            .then(data => {
                console.log(data);
                this.userInfo = data; 
                //  SPTSLSATT-1236
                if(data && data.channel && data.channel =='Authorized Retail'){
                   this.isARChannel=true; 
                }
                else{
                    this.isARChannel=false; 
                }
                if(data && (data.profileName =='Retail ARSM' ||data.profileName =='Retail AVP' || data.profileName =='Retail DOS' || data.profileName =='KM Pilot Retail ARSM')){
                    this.isARSM = true;
                    this.classRep='slds-modal slds-fade-in-open slds-backdrop';  
                }
                else if(data && (data.profileName =='Retail RSC Rep')){
                    this.classRep='slds-modal slds-fade-in-open slds-backdrop classRep';

                }
                console.log(data);
                console.log('User Info loaded');
            }).catch(error => {
                console.log('error');
                console.log(error);
            });
			gotoMyStoreURL()
            .then(result => {
                if (result) {
                   this.myStoreLink = result;
                }  

            });
            
    }

    gotoLeadForm(){
        this.navigateToWebPage('/lightning/n/LeadForm');
    }
	
	
    
    navigateToWebPage(url) {
        this[NavigationMixin.Navigate]({
            "type": "standard__webPage",
            "attributes": {
                "url": url
            }
        });
    }
   
}