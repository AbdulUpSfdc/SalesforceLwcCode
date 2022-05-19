import { LightningElement,track,api } from 'lwc';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcConstants from 'c/bwcConstants';
import IMEISearch from '@salesforce/apex/BWC_IMEISearchController.IMEISearch';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ImeiValidation from '@salesforce/label/c.ImeiValidation';
import ImeiErrorMessage from '@salesforce/label/c.BWC_IMEI_Access_Error_Message';
import  checkUserAccess  from '@salesforce/apex/BWC_IMEISearchController.hasRecordAccess';
import IMEITitle from '@salesforce/label/c.BWC_IMEI_Search_Title';

export default class BwcSearchTest extends LightningElement {
    imei='';
    searchedImei;
    isLoading = false;
    showTable = false;
    lteIcon;
    lteLabel;
    showCheckToolTip = false;
    showCloseToolTip = false;
    showHelpToolTip = false;
    checkToolTipMessage = false;
    closeToolTipMessage=false;
    helpToolTipMessage=false;
    buttonFlag=true;
    toolTipClass = "slds-popover slds-popover_tooltip slds-nubbin_left toolTip slds-hide";
    response;
    hasUserAccess;
    @track showIMEIScreen = false;

    connectedCallback(){
        this.checkUserAccess();
    }

    checkUserAccess(){
        checkUserAccess({
            title : IMEITitle
        }).then((result) => {
            
            BwcUtils.log(' Access response: ' + result);
            this.hasUserAccess = result;
            if(result === true) {
                this.showIMEIScreen = true;
            } else {
                const event = new ShowToastEvent({
                    title: 'Access Error',
                    message: ImeiErrorMessage,
                    variant: 'error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(event);
            }
        })
    }

    get errorReports() {return this.template.querySelector('c-bwc-error-reports');}


    handleInputChange(event){
        this.imei = event.target.value;
    }

    addErrors(msg){
        this.showErrors = true;
        this.errorMessage += msg;
    }

    async handleSearch(){
        this.showTable = false;
        this.searchedImei = this.imei;
        BwcUtils.log('Handled Search');
        let regex=/^[0-9]+$/;
        if(this.imei.length!=15 || !this.imei.match(regex)){
            const toastArgs = {
                    title:'Error',
                    message:ImeiValidation,
                    variant:'error'
                }
                BwcUtils.showToast(this, toastArgs);
                BwcUtils.error(error);
                return;
        }
        this.isLoading = true;
        try{
            const responseWrapperJson = await IMEISearch({Imei : this.imei});
            BwcUtils.log('result imei Search: ' + responseWrapperJson);
            
            const responseWrapper = JSON.parse(responseWrapperJson);
            if (!responseWrapper.success) {
                const toastArgs = {
                    title:'Error',
                    message:responseWrapper.message,
                    variant:'error',
                    duration : '5000'
                }
                BwcUtils.showToast(this, toastArgs);
                BwcUtils.error(error);
            }else{
                this.showTable = true;
                this.response = responseWrapper.response;
                if(this.response.networkCompatibilityIndicator==="GREEN"){
                    BwcUtils.log('Entered GREEN');
                    this.hideAllVisuals();
                    this.showCheckToolTip=true;  
                }

                if(this.response.networkCompatibilityIndicator==="RED"){
                    BwcUtils.log('Entered RED');
                    this.hideAllVisuals();
                    this.showCloseToolTip=true;
                }

                if(this.response.networkCompatibilityIndicator==="YELLOW"){
                    BwcUtils.log('Entered YELLOW');
                    this.hideAllVisuals();
                    this.showHelpToolTip=true;
                }
            }
        }catch(error) {
            this.errorReports.addError(error);
        }
        finally {
            this.isLoading = false;
        }
        
    }

    handleClear(){
        BwcUtils.log('Handled Clear');
        this.imei='';
        this.showTable = false;
        this.buttonFlag=true;
        this.hideToolTip();
    }


    hideToolTip(){
        this.toolTipClass = "slds-popover slds-popover_tooltip slds-nubbin_left toolTip slds-hide";
    }

    showToolTip(){
        this.toolTipClass = "slds-popover slds-popover_tooltip slds-nubbin_left toolTip"
    }
    

    hideAllVisuals(){
        this.showCheckToolTip=false;
        this.showCloseToolTip=false;
        this.showHelpToolTip=false;
    }
}