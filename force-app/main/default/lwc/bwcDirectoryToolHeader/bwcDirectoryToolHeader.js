import { LightningElement,track,api } from 'lwc';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcDirectoryToolServices from 'c/bwcDirectoryToolServices';
import BwcPageElementBase from 'c/bwcPageElementBase';
import adminHyperlink from '@salesforce/label/c.BWC_DirectoryTool_AdminHyperlink';

export default class BwcDirectoryToolHeader extends BwcPageElementBase {
    isLoading = false;
    isLoadingQuickList = false;
    isLoadingFeedbackModal = false;
    showDT = true;
    @api feedBackDisabled = false;
    enableFeedbackPopup = false;
    enableCancelPopup = false;
    attid;
    defaultChannel;
    defaultRole;
    state;
    location;
    locationName
    locationId;
    channelId;
    channelName;
    userName;
    isEditSettings = false;
    @api contactId;
    @api contactname;

    stateSelected;
    stateOptions = [];
    locationSelected;
    locationOptions = [];
    dqlSelected;
    defaultQuickListOptions = [];
    restrict = false;
    feedback;

    channelOptions;
    defaultChannelOption;
    
    errorLabel = 'An unexpected error occurred.Please contact your System Administrator.';  
    
    get stateOptions(){
        return this.stateOptions;
    }

    handleStateChange(event){
        try{
            this.stateSelected = String(event.detail.value);
            BwcUtils.log('--state--' + this.stateSelected);
            this.buildLocationOptions(this.editSettingsResponse,this.stateSelected,false);
        }catch(e){
            this.handleError(e,true,null);
        }

    }

    handleLocationChange(event){
        try{
            this.locationSelected = String(event.target.value);
            this.dqlSelected = '';
            this.buildDefaultQuickListOptions(this.editSettingsResponse,this.locationSelected,false);
        }catch(e){
            this.handleError(e,true,null);
        }
    }

    handledqlChange(event){
        try{
            this.dqlSelected = event.detail.value;
        }catch(e){
            this.handleError(e,true,null);
        }
    }

    async toggleFeedBack(){
        try{
            this.isLoading = true;
            const responseWrapper = await BwcDirectoryToolServices.getFeedback(this.contactId, this.contactname);
            if(responseWrapper){                    
                this.locationName = responseWrapper.locationname;
                this.locationId = responseWrapper.locationid;
                this.channelId = responseWrapper.channelid;
                this.channelName = responseWrapper.channelname;
                this.enableFeedbackPopup = true;                
            }
        }
        catch(e){
            this.handleError(e, true, 
                'An unexpected error occured while getting feedback details.');
        }
        finally {
            this.isLoading = false;
        }
    }

    cancelFeedback() {
        try{
            this.enableFeedbackPopup = false;
            this.enableCancelPopup = true;
        }catch(e){
            this.handleError(null, true, null);
        }
    }

    closeFeedbackPopup() {
        try{
            this.enableCancelPopup = false;
            this.feedback = '';
        }catch(e){
            this.handleError(null, true, null);
        }
    }

    openFeedBackPopup() {
        try{
            this.enableFeedbackPopup = true;
            this.enableCancelPopup = false;

        }catch(e){
            this.handleError(null, true, null);
        }
    }

    async saveFeedback(){
        try{
            this.isLoadingFeedbackModal = true;            
            if(!this.feedback){                
                const toastArgs = {
                    title:'Error',
                    message: 'Feedback is required',
                    variant:'error',
                    duration : '5000'
                }
                BwcUtils.showToast(this, toastArgs);                
            }else{
                const responseWrapper = await BwcDirectoryToolServices.addFeedback(
                    this.feedback, this.contactname, this.contactId, this.locationName, this.locationId);
                if(responseWrapper){                    
                    this.enableFeedbackPopup = false;
                    this.feedback = null;
                    const toastArgs = {
                        title:'Success',
                        message: 'Feedback added',
                        variant:'success',
                        duration : '5000'
                    }
                    BwcUtils.showToast(this, toastArgs);                        
                }
            }        
        }catch(e){
            this.handleError(e, true, 
                'An unexpected error occured while adding feedback.');
        }
        finally{
            this.isLoadingFeedbackModal = false;
        }
    }

    feedbackHandler(event){
        try{
            this.feedback = event.target.value;
        }catch(e){
            this.handleError(null, true, null);
        }
    }

    toggleEditSettings(){
        if(!this.isEditSettings){
            this.getEditSettings(false);
        }else{
            this.isEditSettings =  false;
        }
    }

    buildEditSettings(response){
        this.buildstateOptions(response);   
    }

    buildstateOptions(response){
        this.stateOptions = [];
        let parent = this;
        response.state.forEach(state=>{
            let stateLabel = state.statename;
            let stateValue = String(state.stateid);
            parent.stateOptions.push({label : stateLabel,value : stateValue});
        });
        this.stateSelected = String(response.defaultstateid);
        BwcUtils.log('State Options--' + JSON.stringify(this.stateOptions));
        this.buildLocationOptions(response,this.stateSelected,true);
    }

    buildLocationOptions(response,state,initialLoad){
        this.locationOptions = [];
        if(initialLoad){
            this.locationSelected = String(response.defaultlocationid);
        }else{
            this.locationSelected = '';
        }
        if(state !== null){
            let parent = this;
            response.location.forEach(location => {
                if(String(location.stateid) === state){
                    parent.locationOptions.push({label : location.locationname, value : String(location.locationid)});
                }
            });
        }
        this.buildDefaultQuickListOptions(response,this.locationSelected,initialLoad);
    }

    buildDefaultQuickListOptions(response,location,initialLoad){
        this.defaultQuickListOptions = [];
        if(initialLoad){
            this.dqlSelected = String(response.defaultqlid);
        }else{
            this.dqlSelected = '';
        }
        let parent = this;
        response.quicklinks.forEach(ql =>{
            if(String(ql.locationid) === location){
                parent.defaultQuickListOptions.push({label : ql.qlname, value : String(ql.qlid)});
            }
        });
    }

    async connectedCallback(){
        await this.initialize();
    }

    async initialize(){
        try{
            this.isLoading = true;
            const response = await BwcDirectoryToolServices.initialize();
            if(!response){
                BwcUtils.log('response is null--' + response);
            }else{
                this.channelOptions = response.channels.map(element => ({ label: element.Channel_Name__c, value: element.Channel_Id__c }));
                this.defaultChannelOption= this.channelOptions.find(({ value }) => value === response.employee.BWDefaultKMChannel__c);

                this.attid = response.employee.EmployeeId__c;
                this.userName = response.userRecord.Name;
                this.defaultChannel = this.defaultChannelOption?this.defaultChannelOption.label:'';
                this.state = response.employee.Work_State__c;
                this.location = response.employee.Work_City__c;
                BwcUtils.log('role is--' + response.userRecord.UserRole);
                if(response.userRecord.UserRole !== null && response.userRecord.UserRole !== undefined){
                    this.defaultRole = response.userRecord.UserRole.Name;
                }
              

                if(this.state === undefined || this.location === undefined){
                    this.getEditSettings(true);
                }
            }
        }catch(e){
            this.handleError(e,true,null);
        }finally{
            this.isLoading = false;
        }
    }


    async getEditSettings(onload){
        
        try{
            this.isLoading = true;
            const responseWrapper = await BwcDirectoryToolServices.getEditSettings();
            if(responseWrapper){
                this.editSettingsResponse = responseWrapper;
                this.buildEditSettings(this.editSettingsResponse);
                if(!this.editSettingsResponse.defaultstateid || !this.editSettingsResponse.defaultlocationid){
                    this.isEditSettings = true;
                }else{
                    if(onload){
                        this.stateSelected = String(this.editSettingsResponse.defaultstateid);
                        this.locationSelected = String(this.editSettingsResponse.defaultlocationid);
                        this.updateEmployeeRecord();
                    }else{
                        this.isEditSettings = true;
                    }
                }
                
            }else{
                const toastArgs = {
                    title:'Error',
                    message: 'Error Retreiving Edit Settings',
                    variant:'error',
                    duration : '5000'
                }
                BwcUtils.showToast(this, toastArgs);
            }
        }
        catch(e){
            this.handleError(e,true,'An unexpected error occurred while retreiving the settings.');
        }
        finally{
            this.isLoading = false;
        }
    }
    async SaveSettings(event){
        try{
            this.isLoading = true;
            let isValid = true;
            let inputFields = this.template.querySelectorAll('.validate');
            inputFields.forEach(inputField => {
                if(!inputField.checkValidity()) {
                    inputField.reportValidity();
                    isValid = false;
                }
                BwcUtils.log('inpField--' + inputField);
            });
            if(!isValid){
                return;
            }
            const responseWrapper = await BwcDirectoryToolServices.SaveEditSettings(this.locationSelected,this.dqlSelected,this.stateSelected);
            if(responseWrapper){
                if(responseWrapper.message === "Settings Saved"){
                    const toastArgs = {
                            title:'Success',
                            message: 'Settings Saved Successfully',
                            variant:'success',
                            duration : '5000'
                        }
                        BwcUtils.showToast(this, toastArgs);
                        this.toggleEditSettings();
                        this.updateEmployeeRecord();
                        this.notifySaveSettings();
                }
            }else{
                const toastArgs = {
                    title:'Error',
                    message:'Error Saving Settings',
                    variant:'error',
                    duration : '5000'
                }
                BwcUtils.showToast(this, toastArgs);
            }
        }catch(e){
            this.handleError(e,true,'An unexpected error occurred while Saving Setings.');
        }finally{
            this.isLoading = false;
        }
    }

    async updateEmployeeRecord(){
        try{
            this.isLoading = true;
            let state = this.stateOptions.find(element => element.value === this.stateSelected);
            let stateLabel = state === undefined ? '' : state.label;
            let location = this.locationOptions.find(element => element.value === this.locationSelected);
            let locationLabel = location === undefined ? '' : location.label;
            const response = await BwcDirectoryToolServices.updateEmployeeRecord(stateLabel,locationLabel,this.attid);
            if(response === 'Success'){
                this.initialize();
            }else{
                BwcUtils.error('--Failed to update Employee record--' + response);
            }
        }catch(e){
            this.handleError(e,false,null);
        }finally{
            this.isLoading = false;
        }
    }

    notifySaveSettings(){
        this.dispatchEvent(new CustomEvent('savesettings'));
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

    openAdminPage(){
        window.open(adminHyperlink,"_blank");
    }
}