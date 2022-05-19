import fetchEmployeeInfo from '@salesforce/apex/BWC_EmployeeController.fetchEmployeeData';
import saveDetails from '@salesforce/apex/BWC_EmployeeController.saveDetails';
import * as BwcUtils from 'c/bwcUtils';

export const fetchEmployeeDetails = async (currentuserId) => {
    BwcUtils.log('call fetchEmployeeDetails');
    const responseJson = await fetchEmployeeInfo({delegateId : currentuserId});
    BwcUtils.log(`response fetchEmployeeDetails: ${responseJson}`);
    return responseJson;
}
export const saveEmployeeData = async (delegate1value,delegate2value,currentrecordId) => {
    BwcUtils.log('call saveEmployeeData');
    const saveresponseJson = await saveDetails({delegate1 : delegate1value,delegate2 : delegate2value,recordId : currentrecordId});
    BwcUtils.log(`response saveEmployeeData: ${saveresponseJson}`);
    const saveresponse = JSON.parse(saveresponseJson);
    return saveresponse;
}