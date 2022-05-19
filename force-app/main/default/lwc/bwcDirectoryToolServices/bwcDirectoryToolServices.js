import * as BwcUtils from 'c/bwcUtils';
import getEditSettingsApex from '@salesforce/apexContinuation/BWC_DirectoryToolController.editSettings';
import getQuickListsApex from '@salesforce/apexContinuation/BWC_DirectoryToolController.getQuickList';
import SaveEditSettingsApex from '@salesforce/apexContinuation/BWC_DirectoryToolController.saveEditSettings';
import initializeApex from '@salesforce/apex/BWC_DirectoryToolController.initialize';
import updateEmployeeRecordApex from '@salesforce/apex/BWC_DirectoryToolController.updateEmployeeRecord';
import directorySearchResultsContinuationApex from '@salesforce/apexContinuation/BWC_DirectoryToolController.searchContactList';
import directoryQuickLinksResultsContinuationApex from '@salesforce/apexContinuation/BWC_DirectoryToolController.searchbyQuickListId';
import getFeedbackApex from '@salesforce/apexContinuation/BWC_DirectoryToolController.getFeedback';
import addFeedbackApex from '@salesforce/apexContinuation/BWC_DirectoryToolController.addFeedback';
import getContactDetailsApex from '@salesforce/apexContinuation/BWC_DirectoryToolController.getContactDetails';
import checkUserAccessApex from '@salesforce/apex/BWC_DirectoryToolController.hasChannelAccess';


export const getEditSettings = async () => {
    const responseWrapperJson = await getEditSettingsApex();
    BwcUtils.log('Edit Settings : ' + responseWrapperJson);
    const responseWrapper = JSON.parse(responseWrapperJson);
    return responseWrapper;
}

export const getQuickLists = async () => {
    const responseWrapperJson = await getQuickListsApex();
    BwcUtils.log('getQuickLists  : ' + responseWrapperJson);
    const responseWrapper = JSON.parse(responseWrapperJson);
    return responseWrapper;
}

export const SaveEditSettings = async (locationSelected,dqlSelected,stateSelected) => {
    const responseWrapperJson = await SaveEditSettingsApex({
            locationid : locationSelected,
            quicklistid : dqlSelected,
            stateid : stateSelected
            });
    BwcUtils.log('Save Settings Response  : ' + responseWrapperJson);
    const responseWrapper = JSON.parse(responseWrapperJson);
    return responseWrapper;
}

export const initialize = async () => {
    const response = await initializeApex();
    return response;
}

export const updateEmployeeRecord = async (stateLabel,locationLabel,attid) => {
    const response = await updateEmployeeRecordApex({
            state : stateLabel,
            city : locationLabel,
            attuid : attid
        });
    return response;
}

export const directorySearchResultsContinuation = async (offset,codeid,searchLimit,channelSelected) => {
    const responseWrapperJson  = await directorySearchResultsContinuationApex({
            offset : offset,
            codeid : codeid,
            searchLimit : searchLimit,
            channelId : channelSelected
        });
    BwcUtils.log('Search Response  : ' + responseWrapperJson);
    const responseWrapper = JSON.parse(responseWrapperJson);
    return responseWrapper;
}


export const directoryQuickLinksResultsContinuation = async (quicklistId,channelSelected) => {
    const responseWrapperJson  = await directoryQuickLinksResultsContinuationApex({
            quicklistId : quicklistId,
            channelId : channelSelected
        });
    BwcUtils.log('Search Response  : ' + responseWrapperJson);
    const responseWrapper = JSON.parse(responseWrapperJson);
    return responseWrapper;
}

export const getFeedback = async (contactid,contactname) => {
    const responseWrapperJson  = await getFeedbackApex({
            contactid : contactid,
            contactname : contactname
        });
    BwcUtils.log('get Feedback Response  : ' + responseWrapperJson);
    const responseWrapper = JSON.parse(responseWrapperJson);
    return responseWrapper;
}

export const addFeedback = async (feedback,contactname,contactid,location,locationid) => {
    const responseWrapperJson  = await addFeedbackApex({
            feedback : feedback,
            contactname : contactname,
            contactid : contactid,
            location : location,
            locationid : locationid
        });
    BwcUtils.log('Add Feed Response  : ' + responseWrapperJson);
    const responseWrapper = JSON.parse(responseWrapperJson);
    return responseWrapper;
}

export const getContactDetails = async (codeName) => {
    BwcUtils.log('Code Name  : ' + codeName);
    const responseWrapperJson  = await getContactDetailsApex({
            codeName : codeName
        });
    BwcUtils.log('Get Contact Details Response  : ' + responseWrapperJson);
    const responseWrapper = JSON.parse(responseWrapperJson);
    return responseWrapper;
}

export const formatDate = (inputDate) => {
    try{
        if(!inputDate || !inputDate?.length > 0){
            BwcUtils.log('inputDate inside undefined');
            return undefined;
        }
        inputDate = inputDate + ' GMT';
        let dateOptions = {
                timeZoneName:'short',
                month:'short',
                year :'numeric',
                day:'numeric', 
                hour:'numeric',
                minute : 'numeric'
            };
        let finalDate = new Date(inputDate).toLocaleString('en-us',dateOptions);
        finalDate = finalDate?.replace(',','');
        finalDate = finalDate.toString() === 'Invalid Date' ? undefined : finalDate;
        BwcUtils.log('finalDate::' + finalDate);
        return finalDate;
    }catch(e){
        BwcUtils.error('Error in formatting Date',e)
        return undefined;
    }
}

export const checkUserAccess = async (recordId) => {
        BwcUtils.log('Record Id: '+recordId);
        const response = await checkUserAccessApex({
            recId : recordId
        });
        BwcUtils.log('Response '+response);
        return response;
}