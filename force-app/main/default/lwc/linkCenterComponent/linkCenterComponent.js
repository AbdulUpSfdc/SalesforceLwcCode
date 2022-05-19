import {
    LightningElement,
    wire
} from 'lwc';
import {
    NavigationMixin
} from "lightning/navigation";
import getLinkCenterArticles from "@salesforce/apex/LinkCenterController.getLinkCenterArticles";
import {
    refreshApex
} from '@salesforce/apex';
import formFactor from '@salesforce/client/formFactor';
import * as BwcUtils from 'c/bwcUtils';
import IMEILabel from '@salesforce/label/c.BWC_IMEISearch';
import RSALabel from '@salesforce/label/c.BWC_RequestRSAToken';
import KodiakLabel from '@salesforce/label/c.BWC_Kodiak';


export default class LinkCenterComponent extends NavigationMixin(
    LightningElement
) {
    searchKey = '';
    wiredArticles;
    linkArticlelist;
    largeDevice = false;
    isKodiakSearch = false;
    error;
    stack;
     errorCallback(error, stack) {
        this.error = error;
        console.log(error);
        console.log(stack);
    }

    @wire(getLinkCenterArticles, {
        searchKey: '$searchKey'
    })
    wiredGetActivityHistory(result) {
        this.wiredArticles = result;
        console.log('date', result);
        if (result.data) {
            if (result.data.isSuccess) {
                this.linkArticlelist = result.data.linkCenterKwList;
                BwcUtils.log(this.linkArticlelist );
            }
        } else if (result.error) {console.log("error");console.log(error.body);}
    }

    onSearch(evt) {
        evt.preventDefault();
        const isEnterKey = evt.keyCode === 13;
        if (isEnterKey || evt.target.value.length===0) {
            this.searchKey = evt.target.value;
        }
        this.refreshValues();
    }

    get BwcKodiakSearch() {return this.template.querySelector('c-bwcKodiakSearch');}

    refreshValues() {
        refreshApex(this.wiredArticles);
    }

    handleClick(evt) {
        evt.preventDefault();
        //let artid = evt.currentTarget.getAttribute("id").split("-")[0];
        let externalLinkUrl = evt.currentTarget.getAttribute("id");
        console.log("externalLinkUrl",(externalLinkUrl.slice(0,externalLinkUrl.lastIndexOf("-"))));
        //Open the BW_ExternalLink Url value on to another page on the same browser window
        window.open(externalLinkUrl.slice(0,externalLinkUrl.lastIndexOf("-")),'_blank');
        /*
        this[NavigationMixin.Navigate]({
            type: "standard__recordPage",
            attributes: {
                recordId: externalLinkUrl,
                actionName: "view"
            }
        });*/
    }

    handleKodiakRedirect(event){
        if(event.detail.isRedirected == true){
            this.isKodiakSearch = false;
        }
    }    

    handleClickInternal(evt) {
        evt.preventDefault();
        //let artid = evt.currentTarget.getAttribute("id").split("-")[0];
        const sfdcBaseURL = window.location.origin;
        const internalLinkUrl = evt.currentTarget.getAttribute("id");
        const internalComponent = evt.currentTarget.getAttribute("data-id");
        const salesforceLinkUrl = sfdcBaseURL;
        const articleTitle = evt.currentTarget.getAttribute("data-title");
        const recId = evt.currentTarget.getAttribute("data-compid");
        let navConfig;
        if(internalComponent === RSALabel ){
         navConfig = {
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'Request_Token_Authentication_Code'
            }
          };
        } else if(internalComponent ===  IMEILabel){
            navConfig = {
                type: 'standard__navItemPage',
                attributes: {
                    apiName: 'IMEI_Search'
                }
              };
        } else if(internalComponent ===  KodiakLabel){
            this.isKodiakSearch = true;
        }        
        else if(internalComponent) {          
            navConfig = {
                type: 'standard__component',
                attributes: {
                    componentName: internalComponent 
                },
                state : {
                    c__recordId : recId
                }
            };                                                                                                
        } else{
            //do Nothing
        }    
        this[NavigationMixin.Navigate](navConfig);
    }
    connectedCallback(){
        if(formFactor=='Large')
            this.largeDevice = true;
    }
}