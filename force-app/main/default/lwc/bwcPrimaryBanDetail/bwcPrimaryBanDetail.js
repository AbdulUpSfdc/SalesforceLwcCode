import { LightningElement,api } from 'lwc';
import getPrimaryBanDetails from '@salesforce/apex/BWC_PrimaryBanDetailController.getPrimaryBanDetails';


// Import custom labels
import header_firstnet from '@salesforce/label/c.BWC_FirstNet_Header';
import message_firstnet from '@salesforce/label/c.BWC_FirstNet_Message';

// Import custom labels
import header_businessCustomer from '@salesforce/label/c.BWC_BusinessCustomer_Header';
import message_businessCustomer from '@salesforce/label/c.BWC_BusinessCustomer_Message';


export default class BwcPrimaryBanDetail extends LightningElement {
    @api recordId
    prmBanDet
    isLoading1 = true;  
    bShowModal 
    modalHeader
    modalMessage

    // Expose the labels to use in the template.
    label_firstnet = {
        header_firstnet,
        message_firstnet,
    };

    label_businessCustomer = {
        header_businessCustomer,
        message_businessCustomer,
    };


    connectedCallback(){  
        this.bShowModal = false;
        this.whichModal = null;

        getPrimaryBanDetails({recordId:this.recordId})
            .then(resultJson => {
                const result = JSON.parse(resultJson);
                this.isLoading1=false;    
                this.prmBanDet = result.recordDetails;

                // if(this.prmBanDet.isFirstNet){
                //     this.bShowModal = true;
                //     this.modalHeader = header_firstnet;
                //     this.modalMessage = message_firstnet;
                // } else if(this.prmBanDet.isBusinessCustomer) {
                //     this.bShowModal = true;
                //     this.modalHeader = header_businessCustomer;
                //     this.modalMessage = message_businessCustomer;
                // }
                this.data = this.prmBanDet;
            })
            .catch(error => {
                this.error = error.message;
                this.isLoading1=false; 
            });
    }

    
}