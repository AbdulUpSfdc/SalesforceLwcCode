import { LightningElement,track,api } from 'lwc';
import * as BwcUtils from 'c/bwcUtils';
import * as BwcConstants from 'c/bwcConstants';
import * as BwcDirectoryToolServices from 'c/bwcDirectoryToolServices';
import BwcPageElementBase from 'c/bwcPageElementBase';
import channelErrMsgLabel from '@salesforce/label/c.BWC_Directory_Tool_Channel_Access_Err_Msg';


export default class BwcDirectoryTool extends BwcPageElementBase {

    isLoading = false;
    isLoadingQuickList = false;
    showDT = false;
    feedBackDisabled = true;
    quickList = [];
    selectedQuickList;
    channelSelected = '-1';
    ChannelOptions;
    searchKey;
    searchKeyFinal;
    searchType;
    restrict = false;
    hasQuickLists = false;
    showResults = false;
    statusUpdateTime;
    isRendered = false;
    @api recId;

    errorLabel = 'An unexpected error occurred.Please contact your System Administrator.';   
    get ChannelOptions(){
        return this.ChannelOptions;
    }

    async checkUserAccess(){
        try{
            const response = await BwcDirectoryToolServices.checkUserAccess(this.recId);
            if(response) {            
                this.showDT = true;
                await this.initialize();
                await this.getQuickLinks();  
            } else {
                this.unexpectedError(channelErrMsgLabel);
            }
        }catch(e){
            this.handleError(e,true,null);
        }
    }

    handleSearchChange(event){
        try{
            this.searchKey = event.target.value;
            BwcUtils.log('searck key--' + this.searchKey);
        }catch(e){
            this.handleError(e,true,null);
        }
        
    }
    handleChannelChange(event){
        try{
            this.channelSelected = event.detail.value;
            BwcUtils.log('channelSelected--' + this.channelSelected);
        }catch(e){
            this.handleError(e,true,null);
        }
    }

    toggleFeedBack(){
        this.feedBackDisabled  = this.feedBackDisabled ? false : true;
    }

    async renderedCallback(){
        if(!this.isRendered){
            this.isRendered = true;
            this.checkUserAccess();
        }
    }
    async initialize(){
        try{
            this.isLoading = true;
            const response = await BwcDirectoryToolServices.initialize();
            if(!response){
                BwcUtils.log('response is null--' + response);
            }else{
                this.ChannelOptions = response.channels.map(element => ({ label: element.Channel_Name__c, value: element.Channel_Id__c }));
                this.ChannelOptions.unshift({label : 'All Channels', value : '-1'});
                this.channelSelected = response.employee.BWDefaultKMChannel__c;
            }
        }catch(e){
            this.handleError(e,true,null);
        }finally{
            this.isLoading = false;
        }
    }

    async getQuickLinks(){
        
        try{
            this.isLoadingQuickList = true;
            const responseWrapper = await BwcDirectoryToolServices.getQuickLists();
            if(responseWrapper){
               this.quickList = responseWrapper.quicklists;
               if(this.quickList.length > 0){
                    this.hasQuickLists = true;
                    let quicklId;
                    let index;
                    if(responseWrapper.defaultqlid){
                        quicklId=responseWrapper.defaultqlid;
                        index= this.quickList.findIndex( ({ quicklistid }) => quicklistid === quicklId );
                    }
                    if(index&&index !== -1){
                        this.quickList[index].quicklistClass='quickLinkSelected';
                    }else{
                        quicklId =this.quickList[0].quicklistid?this.quickList[0].quicklistid:null;
                        this.quickList[0].quicklistClass='quickLinkSelected';
                    }
                    this.handleSearchbyQuicklistId(quicklId);
               }else{
                this.hasQuickLists = false;
               }
            }else{
                const toastArgs = {
                    title:'Error',
                    message:'Error retrieving Quick Lists',
                    variant:'error',
                    duration : '5000'
                }
                BwcUtils.showToast(this, toastArgs);
            }
        }
        catch(e){
            this.handleError(e,true,'An unexpected error occurred while getting Quick Links.');
        }
        finally{
            this.isLoadingQuickList = false;
        }
    }
    handleQuickListClick(event){
        try{
            let quickListId = event.currentTarget.dataset.id;
            this.handleSearchbyQuicklistId(quickListId);

        }catch(e){
            this.handleError(e,true,null);
        }
    }

    handleSearchbyQuicklistId(qlID){
        try{
            BwcUtils.log('--event--' + qlID);
            this.template.querySelector('input[data-name="searchkey"]').value = null;
            this.searchKey = null;
            this.selectedQuickList = qlID;
            this.showResults = true;
            this.template.querySelector('c-bwc-Directory-Tool-Search-Results').handleCallout(null,null,this.selectedQuickList,'qlinks',this.channelSelected,1);
            let statusUpdate= BwcDirectoryToolServices.formatDate(new Date().toUTCString());
            this.statusUpdateTime = statusUpdate ? statusUpdate : new Date().toLocaleString();
            this.template.querySelectorAll('.quickLinkSelected').forEach(link => link.classList.remove('quickLinkSelected'));
            const selectedLinkId = qlID;
            const link = this.template.querySelector("[data-id='" + selectedLinkId + "']");
            if(link){
                link.className='quickLinkSelected';
            }
        }catch(e){
            this.handleError(e,true,null);
        }
    }

    handleSearchRefresh(event){
        try{
            BwcUtils.log('Clicked Refresh');
            this.showResults = true;
            let statusUpdate= BwcDirectoryToolServices.formatDate(new Date().toUTCString());
            this.statusUpdateTime = statusUpdate ? statusUpdate : new Date().toLocaleString();
            this.template.querySelectorAll('.quickLinkSelected').forEach(link => link.classList.remove('quickLinkSelected'));
            this.template.querySelector('c-bwc-Directory-Tool-Search-Results').handleCallout('0',this.searchKeyFinal,null,'search',this.channelSelected,1);
        }catch(e){
            this.handleError(e,true,null);
        }  
    }

    handleSearch(event){
        try{
            this.searchKeyFinal = this.searchKey;
            BwcUtils.log('Clicked Search--' + this.searchKey + '---' + this.channelSelected);
            this.showResults = true;
            let statusUpdate= BwcDirectoryToolServices.formatDate(new Date().toUTCString());
            this.statusUpdateTime = statusUpdate ? statusUpdate : new Date().toLocaleString();
            this.template.querySelectorAll('.quickLinkSelected').forEach(link => link.classList.remove('quickLinkSelected'));
            this.template.querySelector('c-bwc-Directory-Tool-Search-Results').handleCallout('0',this.searchKeyFinal,null,'search',this.channelSelected,1);
        }catch(e){
            this.handleError(e,true,null);
        }
        
    }

   async handleSaveSettings(event){
        try{
            this.template.querySelector('input[data-name="searchkey"]').value = null;
            this.searchKey = null;
            this.showResults = false;
            await this.initialize();
            await this.getQuickLinks(); 
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
    
    openAdminPage(){
        window.open("http://myagenttools.web.att.com/dtadmin","_blank");
    }
}