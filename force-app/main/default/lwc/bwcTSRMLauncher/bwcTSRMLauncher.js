/* ================================================
* @class name: bwcTSRMLaunch
* @author: Salesforce Inc.
* @purpose: this is a client side fetch api call to TSRM system
* Devs can import the launchTSRM function into their files and pass a CTN , Interaction Id, Billing Account Number
* @created date (mm/dd/yyyy) :  03/20/2021
================================================*/ 
import { LightningElement, api } from 'lwc';
import getTSRMURL_METADATA from '@salesforce/apex/BWC_LIC_TSRMController.getTSRMMetaData';
import getTSRMRequest from '@salesforce/apex/BWC_LIC_TSRMController.getTSRMRequest';
import logAPICall from '@salesforce/apex/BWC_LIC_TSRMController.logAPICall';
import * as BwcUtils from 'c/bwcUtils';

//import getTSRMUrl from '@salesforce/apex/BWC_LIC_TSRMController.getTSRMURL';

//public function for other files to call functionality
export const launchTSRM = (interactionId,ctn,ban)=>{
    getTSRMRequest({ctn: ctn ,ban: ban,interactionId: interactionId})
    .then(result => {
        handleRequestForTSRM(JSON.parse(result),interactionId);
     })
     .catch(error => {
        BwcUtils.log(error);
     }).finally( {

     });
}
//fetch layer of logic

export const handleFetch = (async(request,urlData,interactionId) => {
    const url = new URL( window.location.href );
    try {
         fetch(urlData.endpoint, {
            method: 'POST', // *GET, POST, PUT, DELETE, etc.
            mode: 'cors', // no-cors, *cors, same-origin
            credentials: "include",
            headers: {
                cache: 'no-cache', // *default, no-cache, reload, force-cache, only-if-cached
                credentials: 'include', // include, *same-origin, omit
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(request)
        }).then((response)=> {
            BwcUtils.log(response);
            let resWrapper = {status: response.status, statusText: response.statusText };
            logAPICall({request: JSON.stringify(request), response: JSON.stringify(resWrapper), recordId: interactionId})
            .then((response1)=> {
                BwcUtils.log(response1);
            })
            .catch(error => {
                BwcUtils.error(error);
             });
            window.open(urlData.redirectUrl);

        }).catch((error)=>{
            BwcUtils.error(error);
        });


    } catch (error) {
        BwcUtils.error(error);

    } finally {
    }
});
//used for testing
export const handleFetchThenVersion = (async(request,urlData) => {
    const response =  fetch(urlData.endpoint, {
        method: 'POST', // *GET, POST, PUT, DELETE, etc.
        mode: 'no-cors', // no-cors, *cors, same-origin
        credentials: 'include',
        headers: {
            //  cache: 'no-cache', // *default, no-cache, reload, force-cache, only-if-cached
            // credentials: 'omit', // include, *same-origin, omit
            // 'Access-Control-Allow-Origin':'*',
            // content type
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(request)
    }).then((response)=> {
        BwcUtils.log(response);
        window.open(urlData.redirectUrl);

    }).then(result=> { 
     }
    ).catch((error)=>{
        BwcUtils.error(error);
    });



  /*  console.debug(res);
    console.debug();
    
    window.open(urlData.redirectUrl);
    }).catch((error)=>{

    });*/

});
//setup lay of logic
export const handleRequestForTSRM = (async (request,interactionId) => {

    getTSRMURL_METADATA()
    .then(result => {
        
        //console.log(JSON.parse(result));
        handleFetch(request,JSON.parse(result),interactionId);

    })
     .catch(error => {
        BwcUtils.log(error);
     });
});
//backup solution for TSRM
export const launchTSRMFromVF = (interactionId,ctn,ban)=>{
    getTSRMUrl().then(result => 
        {
         window.open(result+'?ctn='+ctn+'&interactionId='+ interactionId+'&ban='+ban);
        }).catch((error)=>{
            BwcUtils.error(error);
        }).finally(()=>
        {
            
        });
}

export default class bwcTSRMLaunch extends LightningElement {
    @api 
    unAuthLaunch(intId){
        launchTSRM(intId,'Unauth',null);
    }
}