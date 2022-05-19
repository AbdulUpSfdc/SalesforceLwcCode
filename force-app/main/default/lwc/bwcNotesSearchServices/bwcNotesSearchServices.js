import * as BwcUtils from 'c/bwcUtils';
import getNotesSearchCont from '@salesforce/apexContinuation/BWC_NotesSearchController.getNotesSearchCont';

export const getNotesSearch = async (recordId, request) => {
  
    BwcUtils.log( 'call getNotesSearch', recordId, request );

    const requestJson = JSON.stringify(request);

    const responseJson = await getNotesSearchCont({ recordId, requestJson });

    const response = JSON.parse(responseJson);

    BwcUtils.log( 'response getNotesSearch', response );

    return response;
};