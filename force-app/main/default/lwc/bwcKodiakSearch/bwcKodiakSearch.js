import { LightningElement,track,api } from 'lwc';
import * as BwcUtils from 'c/bwcUtils';
import KodiakSearchContinuation from '@salesforce/apexContinuation/BWC_KodiakController.KodiakSearchContinuation';
import { NavigationMixin } from 'lightning/navigation';
import  checkUserAccess  from '@salesforce/apex/BWC_KodiakController.hasRecordAccess';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import KODIAKErrorMessage from '@salesforce/label/c.BWC_KodiakErrorMessage';
import KodiakTitle from '@salesforce/label/c.BWC_Kodiak_Title';
export default class BwcKodiakSearch extends NavigationMixin(LightningElement) {

    connectedCallback(){
        this.checkUserAccess();
    }

    async checkUserAccess(){
        const response = await checkUserAccess({
            title : KodiakTitle
        });
        if(response === true) {
           this.handleSearch();
         } else {
             const event = new ShowToastEvent({
                 title: 'Access Error',
                 message: KODIAKErrorMessage,
                 variant: 'error',
                 mode: 'dismissable'
             });
             this.dispatchEvent(event);
         }


    }
   async handleSearch(){
    this.isLoading = true;
    try{
        const options = {  weekday: 'short', year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: false, timeZone: 'America/Chicago' };
        const chicago_datetime_str = new Date().toLocaleString("en-US", options);
        const chicagoDate = new Date(chicago_datetime_str);
        const year = chicagoDate.getFullYear();
        const month = chicagoDate.toLocaleString('default', { month: 'short' });
        const date = ("0" + chicagoDate.getDate()).slice(-2);
        const hours = chicagoDate.getHours();
        const minutes = chicagoDate.getMinutes();
        const seconds = chicagoDate.getSeconds();
        const day = chicago_datetime_str.split(',')[0];
        const strDateTimeFormatted = `${day} ${month} ${date} ${hours}:${minutes}:${seconds} CST ${year}`;
        BwcUtils.log('Date--' , strDateTimeFormatted);
        const responseWrapperJson = await KodiakSearchContinuation({
              localTime : strDateTimeFormatted
        });
        
        const responseWrapper = JSON.parse(responseWrapperJson);
        BwcUtils.log(responseWrapperJson);
        if (!responseWrapper.success) {
            const toastArgs = {
                title:'Error',
                message:responseWrapper.message,
                variant:'error',
                duration : '5000'
            }
            BwcUtils.showToast(this, toastArgs);
        }else if(responseWrapper.response.message != 'Success'){
            const toastArgs = {
                title:'Error',
                message:responseWrapper.response.description,
                variant:'error',
                duration : '5000'
            }
            BwcUtils.showToast(this, toastArgs);

        }else{
            const redirectURL = responseWrapper.response.redirectLink;
            this[NavigationMixin.Navigate]({
                "type": "standard__webPage",
                "attributes": {
                    "url": redirectURL
                }
            });
        }
    }catch (error) {
        const toastArgs = {
            title:'Error',
            message:JSON.stringify(error),
            variant:'error',
            duration : '5000'
        }
        BwcUtils.showToast(this, toastArgs);
        BwcUtils.log(error);
    }
    finally {
        this.isLoading = false;
        const passNavigation = new CustomEvent('redirected',{
                detail:{isRedirected:true} 
            });
        this.dispatchEvent(passNavigation);
    }
    
}

addErrors(msg){
    this.showErrors = true;
    this.errorMessage += msg;
}

handleButtonChange(){ 
    let close = true;
        const closeclickedevt = new CustomEvent('closeclicked', {
            detail: { close },
        });

         // Fire the custom event
         this.dispatchEvent(closeclickedevt); 
    }
}