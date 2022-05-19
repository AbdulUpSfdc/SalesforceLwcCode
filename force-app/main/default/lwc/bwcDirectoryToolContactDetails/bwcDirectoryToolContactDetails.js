import { track,api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcDirectoryToolServices from 'c/bwcDirectoryToolServices';
import BwcPageElementBase from 'c/bwcPageElementBase';



export default class BwcDirectoryToolContactDetails extends BwcPageElementBase {
    isLoading = false;
    @api codeName;
    @api response;
    @api contactName;
    searchResponse;
    contactDetailsResponse;
    showContactDetails = false;
    statusUpdateTime;
    @track customerTypes = [];
    isRendered = false;
    specificHoursList
    
    currentPageReference = null; 
    urlStateParameters = null;

    get isNoHours(){
        return this.contactDetailsResponse.normalhours?this.contactDetailsResponse.normalhours==="N":false;
    }
    get isRegHours(){
        return this.contactDetailsResponse.normalhours?this.contactDetailsResponse.normalhours==="T":false;
    }
    get isSpecificHours(){
        return this.contactDetailsResponse.normalhours?this.contactDetailsResponse.normalhours==="S":false;
    }
    get isCustomerTypes() {
        return this.customerTypes?.length > 0
    }
    

    renderedCallback(){
        if(!this.isRendered){
            this.isRendered = true;
            this.searchResponse = JSON.parse(this.response);
            this.callContactDetailsAPI();
        }
    }

    async callContactDetailsAPI(){
        try {
            this.isLoading = true;
            const responseWrapper = await BwcDirectoryToolServices.getContactDetails(this.codeName);
            if(responseWrapper){
                if(responseWrapper.message === 'Success'){
                    this.showContactDetails = true;
                    BwcUtils.log('responseWrapper--' + JSON.stringify(responseWrapper));
                    this.contactDetailsResponse = responseWrapper;
                    this.buildExtensions();
                    let updatedate = BwcDirectoryToolServices.formatDate(this.contactDetailsResponse.updatedate);
                    let createdate = BwcDirectoryToolServices.formatDate(this.contactDetailsResponse.createdate);
                    this.contactDetailsResponse.updatedate = updatedate ? updatedate:this.contactDetailsResponse.updatedate;
                    this.contactDetailsResponse.createdate = createdate ? createdate:this.contactDetailsResponse.createdate;
                    let statusUpdate= BwcDirectoryToolServices.formatDate(new Date().toUTCString());
                    this.statusUpdateTime = statusUpdate ? statusUpdate : new Date().toLocaleString();
                    this.contactDetailsResponse.isMainInternal = this.contactDetailsResponse.maininternal&&this.contactDetailsResponse.maininternal ===1;
                    this.contactDetailsResponse.isAddInternal = this.contactDetailsResponse.adlinternal&&this.contactDetailsResponse.adlinternal ===1;
                    this.contactDetailsResponse.isAddInternal2 = this.contactDetailsResponse.adlinternal2&&this.contactDetailsResponse.adlinternal2 ===1;
                    this.contactDetailsResponse.isAddInternal3 = this.contactDetailsResponse.adlinternal3&&this.contactDetailsResponse.adlinternal3 ===1;
                    this.contactDetailsResponse.isAddInternal4 = this.contactDetailsResponse.adlinternal4&&this.contactDetailsResponse.adlinternal4 ===1;
                    this.contactDetailsResponse.isAddInternal5 = this.contactDetailsResponse.adlinternal5&&this.contactDetailsResponse.adlinternal5 ===1;
                    this.contactDetailsResponse.isWebsiteInternal = this.contactDetailsResponse.websiteinternal&&this.contactDetailsResponse.websiteinternal ===1;
                    this.contactDetailsResponse.isEmailInternal = this.contactDetailsResponse.emailinternal&&this.contactDetailsResponse.emailinternal ===1;
                    this.buildHours(this.contactDetailsResponse?.contactdaytime);
                } else{
                    BwcUtils.error('Error in Directory Tool Contact Details API ');
                    this.handleError(e,true,'An unexpected error occurred while getting contact details.');
                }
            }
           
        } catch (e) {
            this.handleError(e,true,'An unexpected error occurred while getting contact details.');
        } finally {
            this.isLoading = false;
        }
    }

    buildExtensions(){
        try{
            this.isLoading = true;
            this.customerTypes=[];
            if(this.searchResponse){
                const speedDials = this.searchResponse.speeddial?this.searchResponse.speeddial:[];
                speedDials.forEach(sd =>{
                    let customerTypeInfo ={};
                    customerTypeInfo.customerType =  sd.customerType;
                    let languages = sd.languages?sd.languages:{};
                    let speedDialsArr =[];
                    for (const [key, value] of Object.entries(languages)) {
                        let speedDialsObj ={};
                        speedDialsObj.language=key;
                        speedDialsObj.number=value;
                        speedDialsArr.push(speedDialsObj);
                    }
                    customerTypeInfo.speedDials= speedDialsArr;
                    this.customerTypes.push(customerTypeInfo);
                });
            }
        }catch(e){
            this.handleError(e,true,null);
        }finally{
            this.isLoading = false;
        }
    }

    buildHours(contactdaytime){
        try{
            let hours = [];
            if(contactdaytime && contactdaytime.length > 0){
                const specificHours = contactdaytime[0].specifichours;
                if(specificHours && specificHours.length > 0){
                    specificHours.forEach(h =>{
                        for(const [key,value] of Object.entries(h)){
                            let hour = {};
                            hour.key = key;
                            hour.value = value;
                            hours.push(hour);
                        }
                    });
                }
            }
            const order = ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"];
            let sortedHours = hours.sort((a, b) => {
                return (
                    order.indexOf(a.key) - order.indexOf(b.key)
                );
            });
            this.specificHoursList = sortedHours;
        }catch(e){
            this.handleError(e,true,null);
        }
    }

    handleContactDetailsRefresh(){
        this.callContactDetailsAPI();
    }
    handleNavigateToURL(){
        try{
        const redirectURL = this.contactDetailsResponse?.website;
        if(redirectURL){
            this[NavigationMixin.Navigate]({
                "type": "standard__webPage",
                "attributes": {
                    "url": redirectURL
                }
            });
        }
        }catch(e){
            this.handleError(e,true,null);
        }

    }
    handleError(e,showToast,message){
        super.handleError(e,null,'Directory Tool');
        if(showToast){
            this.unexpectedError(message);
        }
    }

    unexpectedError(message){
        message = message ? message : this.errorLabel;
        const toastArgs = {
            title:'Error',
            message:message,
            variant:'error',
            duration : '5000'
        }
        BwcUtils.showToast(this, toastArgs);
    }
}