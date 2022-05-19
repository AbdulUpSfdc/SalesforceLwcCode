import * as BwcUtils from 'c/bwcUtils';
import cbrSearchCont from '@salesforce/apexContinuation/BWC_CustomerSearchController.cbrSearchCont';

export const cbrSearch = async (recordId, phoneNumber) => {

    BwcUtils.log(`CBR Search request: recordId ${recordId}, phoneNumber ${phoneNumber}`);

    const responseJson = await cbrSearchCont({recordId, phoneNumber});
    const response = JSON.parse(responseJson);

    BwcUtils.log('CBR Search response: ', response);

    return response;
}