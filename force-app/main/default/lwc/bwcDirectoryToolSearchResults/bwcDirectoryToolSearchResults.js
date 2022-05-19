import { LightningElement, api, track } from "lwc";
import * as BwcUtils from 'c/bwcUtils';
import * as BwcDirectoryToolServices from 'c/bwcDirectoryToolServices';
import BwcPageElementBase from 'c/bwcPageElementBase';

export default class bwcDirectoryToolSearchResults extends BwcPageElementBase {
    isLoading = false;
    responseOutput = [];
    searchResults = [];
    contactKeyCounter = 0;
    speediDialKeyCounter = 0;
    @track pagelinks = [];
    @track pagelinksTemp = [];
    pageGroupNo = 1;
    totalRecordsCount;
    searchLimit = '20';
    currentPageNo = 1;
    showPagination = false;
    maxPages = 0;
    disablePrev = false;
    disableNext = false;
    lastPage = 1;
    codeid;
    quicklistid;
    channelSelected;
    offset;
    addMore = false;
    backMore = false;
    maxPagesOnScreen = 15;

    errorLabel = 'An unexpected error occurred.Please contact your System Administrator.'; 
    @api showResults;
  
    @api
    handleCallout(offset,codeid,quicklistid,searchType,channelSelected,pageNo){
        try{
            if(pageNo == 1){
                this.currentPageNo = 1;
            }
            this.offset = offset;
            this.codeid = codeid;
            this.quicklistid = quicklistid;
            this.channelSelected = channelSelected;
            if(searchType == 'search'){
                this.responseOutput = [];
                this.directorySearchResultsContinuation(offset,codeid,channelSelected,pageNo);
            }else{
                this.responseOutput = [];
                this.directoryQuickLinksResultsContinuation(quicklistid,channelSelected);
            }
        }catch(e){
            this.handleError(e,true,'An unexpected error occurred while searching.');
        }
    }

    async directorySearchResultsContinuation(offset,codeid,channelSelected,pageNo){
        try{
            this.isLoading = true;
            let responseWrapper = await BwcDirectoryToolServices.directorySearchResultsContinuation(offset,codeid,this.searchLimit,channelSelected);
            if(responseWrapper){
                let response = responseWrapper;
                BwcUtils.log('--response--', response);
                this.buildSearchTableResponse(response.searchListResponse,pageNo);
            }else{
                BwcUtils.log('Failue Response');
                const toastArgs = {
                    title:'Error',
                    message:'Error getting search results.',
                    variant:'error',
                    duration : '5000'
                }
                BwcUtils.showToast(this, toastArgs);
            }
        }catch(e){
            this.handleError(e,true,'An unexpected error occurred while gettting search results.');
        }finally{
            this.isLoading = false;
        }
        
    }

    async directoryQuickLinksResultsContinuation(quicklistId,channelSelected){
        try{
            this.isLoading = true;
            let responseWrapper = await BwcDirectoryToolServices.directoryQuickLinksResultsContinuation(quicklistId,channelSelected);//JSON.parse(responseJson);
            if(responseWrapper){
                let response = responseWrapper;
                this.buildSearchTableResponse(response.searchListResponse,null);

            }else{
                BwcUtils.error('Failue Response');
                const toastArgs = {
                    title:'Error',
                    message:'Error getting Contact Results',
                    variant:'error',
                    duration : '5000'
                }
                BwcUtils.showToast(this, toastArgs);
            }
        }catch(e){
           this.handleError(e,true,'An unexpected error occurred while gettting quick link results.');
            
        }finally{
            this.isLoading = false;
        }
    }

    buildSearchTableResponse(searchResponse,pageNo){
        try{
        let searchResults = (searchResponse.length > 0 && searchResponse[0].searchresult !== undefined)? searchResponse[0].searchresult : [];
        this.totalRecordsCount =  (searchResponse.length > 0 && searchResponse[0].totalrecords !== undefined  && searchResponse[0].totalrecords !== '0')? searchResponse[0].totalrecords : undefined; 
        let parent = this;
        searchResults.forEach(searchResult => {
            let responseOutputObj = {};
            responseOutputObj['contactName'] = searchResult.contactName;
            responseOutputObj['phoneNumber'] = searchResult.contactNumber;
            responseOutputObj['ext'] = searchResult.extension;
            responseOutputObj['internal'] = searchResult.maininternal&&searchResult.maininternal===1;
            responseOutputObj['codeName'] = searchResult.codeName;
            responseOutputObj['hasOtherLanguages'] = false;
            responseOutputObj['hasAtLeastOneEnglish'] = false;
            responseOutputObj['hasAtLeastOneSpanish'] = false;
            responseOutputObj['hasAtLeastOneCustomer'] = false;
            let speedDials = (searchResult.speeddial !== undefined && searchResult.speeddial.length > 0) ? searchResult.speeddial : [];
            let speedDialArray = [];
            let regionorTypeArray = [];
            speedDials.forEach(speedDial => {
                responseOutputObj['hasAtLeastOneCustomer'] = true;
                let regionortypes = speedDial.regionortype !== undefined ? speedDial.regionortype : [];
                    regionortypes.forEach(regionortype =>{
                        let regionorTypeObject = {};
                        let langnums = regionortype.langnum !== undefined ? regionortype.langnum : [];
                        let langnumsArray = [];
                        regionorTypeObject['customerType'] = regionortype.labelname;
                        regionorTypeObject['hasEnglish'] = false;
                        regionorTypeObject['hasSpanish'] = false;
                        regionorTypeObject['hasOtherLanguages'] = false;
                        let langnumsObject = {}
                        langnums.forEach((langnum) =>{
                                 if(langnum.lang.toLowerCase() === 'english'){
                                regionorTypeObject['hasEnglish'] = true;
                                responseOutputObj['hasAtLeastOneEnglish'] = true;
                                langnumsObject['English'] = langnum.num;
                            }else if(langnum.lang.toLowerCase() === 'spanish'){
                                regionorTypeObject['hasSpanish'] = true;
                                responseOutputObj['hasAtLeastOneSpanish'] = true;
                                langnumsObject['Spanish'] = langnum.num;
                            }else{
                                regionorTypeObject['hasOtherLanguages'] = true;
                                responseOutputObj['hasOtherLanguages'] = true;
                                langnumsObject[langnum.lang] = langnum.num;
                                
                            }
                            
                        });
                        
                        regionorTypeObject['languages'] = langnumsObject;
                        regionorTypeArray.push(regionorTypeObject);
                    });
                    
            });
            responseOutputObj['speeddial'] = regionorTypeArray;
            this.responseOutput.push(responseOutputObj);
        });
        BwcUtils.log('final output--' + JSON.stringify(this.responseOutput));
        if(this.totalRecordsCount !== undefined){
            this.showPagination = true;
            this.buildPagination(this.totalRecordsCount,pageNo);
        }else{
            this.showPagination = false;
        }
        }catch(e){
            this.handleError(e,true,'An unexpected error occurred while displaying search results.')
        }
    }

    buildPagination(totalRecordsCount,pageNo){
        if(pageNo != 1){
            return;
        }
        this.pagelinks = [];
        totalRecordsCount = parseInt(totalRecordsCount);
         this.maxPages = Math.ceil(totalRecordsCount/20);
        for(let i  = 1; i <= this.maxPages; i++){
            let pageLinkObj = {};
            pageLinkObj['key'] = i.toString();
            pageLinkObj['class'] = 'neutral';
            if(i == 1){
                pageLinkObj['class'] = 'brand';
            }
            this.pagelinks.push(pageLinkObj);
        }
        if(this.pagelinks.length > this.maxPagesOnScreen){
            this.pagelinksTemp = this.pagelinks.slice(0,this.maxPagesOnScreen);
            this.pageGroupNo = 1;
        }
        this.prevNextToggle();
        this.morePages();
    }

    handleNext(event){
        try{
            this.currentPageNo += 1;
            this.selectedPage(this.currentPageNo);
            this.prevNextToggle();
            let offset = String((this.currentPageNo - 1) * 20);
            this.handleCallout(offset,this.codeid,null,'search',this.channelSelected,this.currentPageNo);
        }catch(e){
            this.handleError(e,true,null);
        }
        
    }

    handlePrev(event){
        try{
            this.currentPageNo -= 1;
            this.selectedPage(this.currentPageNo);
            this.prevNextToggle();
            let offset = String((this.currentPageNo - 1) * 20);
            this.handleCallout(offset,this.codeid,null,'search',this.channelSelected,this.currentPageNo);
        }catch(e){
            this.handleError(e,true,null);
        }
        
        
    }

    prevNextToggle(){
        this.disablePrev = this.currentPageNo == 1 ? true : false;
        this.disableNext = this.currentPageNo >= this.maxPages ? true : false;
        this.selectedPage(this.currentPageNo);
        let currentPageGroup = Math.ceil(this.currentPageNo / this.maxPagesOnScreen);
        this.slicePages(currentPageGroup);
    }

    handlePage(event){
        try{
            let key = event.target.label;
            if(this.currentPageNo == parseInt(key)){
                return;
            }
            this.currentPageNo = parseInt(key);
            this.prevNextToggle();
            BwcUtils.log('Handle Page--' + this.currentPageNo);
            let offset = String((this.currentPageNo - 1) * 20);
            this.handleCallout(offset,this.codeid,null,'search',this.channelSelected,this.currentPageNo);
        }catch(e){
            this.handleError(e,true,null);
        }
    }

    addMorePages(){
        try{
            this.pageGroupNo += 1;
            BwcUtils.log('--add--' + this.pageGroupNo);
            this.slicePages(this.pageGroupNo);
        }catch(e){
            this.handleError(e,true,null);
        }
        
       
    }

    backMorePages(){
        try{
        this.pageGroupNo -= 1;
        BwcUtils.log('--back--' + this.pageGroupNo);
        this.slicePages(this.pageGroupNo);
        }catch(e){
            this.handleError(e,true,null);
        }
        
    }

    slicePages(pageGroupNo){
        this.pageGroupNo = pageGroupNo;
        let begin = (pageGroupNo - 1) * this.maxPagesOnScreen ;
        let end = (pageGroupNo * this.maxPagesOnScreen) > this.pagelinks.length ? this.pagelinks.length : pageGroupNo * this.maxPagesOnScreen;
        this.pagelinksTemp = this.pagelinks.slice(begin,end);
        BwcUtils.log('--begin--' + begin + '--end--' + end + '--array--' + this.pagelinksTemp);
        this.morePages();
    }

    morePages(){
        this.addMore = this.pageGroupNo * this.maxPagesOnScreen >= this.maxPages ? true : false;
        this.backMore = this.pageGroupNo == 1 ? true : false;
    }

    resetPageLinkClass(){
        this.pagelinks.forEach(page=>{
            page.class = 'neutral';
        });
    }

    selectedPage(key){
        this.resetPageLinkClass();
        let objIndex = this.pagelinks.findIndex((obj => obj.key == key));
        BwcUtils.log('objIndex--' + objIndex);
        this.pagelinks[objIndex].class = 'brand';
    }

    openContactDetailPage(event){
        try{
            BwcUtils.log('Called open contact');
            let codeName = event.currentTarget.dataset.codename;
            let contactname = event.currentTarget.dataset.contactname;
            let selectedCont = this.responseOutput.find(element=> element.codeName === codeName);
            
            const message = {
                pageReference: {
                    type: 'standard__component',
                    attributes: {
                        componentName: 'c__BWCDTContactDetailPage'
                    },
                    state: {
                        c__contactId: codeName,
                        c__contactname : contactname,
                        c__response : JSON.stringify(selectedCont)
                    }
                },
                label: contactname,
                icon: 'custom:custom15'
            }
                BwcUtils.openSubTab(message);
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