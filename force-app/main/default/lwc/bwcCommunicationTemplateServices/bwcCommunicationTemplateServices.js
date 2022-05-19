import * as BwcUtils from 'c/bwcUtils';
import getCommRecordEmailTemp from  "@salesforce/apex/BWC_CommunicationTemplateController.getCommunication";
import updateDataOnCommunication from "@salesforce/apex/BWC_CommunicationTemplateController.updateDataOnCommunication";
import deleteDataOnCommunication from "@salesforce/apex/BWC_CommunicationTemplateController.deleteDataOnCommunication";

export const communicationTemplateData = async (recordId) => {
    const communicationresponseJson = await getCommRecordEmailTemp({communicationRecordId :recordId}); 
    BwcUtils.log('load response'+JSON.stringify(communicationresponseJson));
    return communicationresponseJson;
}
export const updateCommunicationData = async (templateId,templateName,recordId) => {
    const updatecommunicationresponseJson = await updateDataOnCommunication({templateId : templateId,templateName : templateName,communicationRecordId : recordId});
    const updateResponse = JSON.parse(updatecommunicationresponseJson);
    BwcUtils.log('update response'+JSON.stringify(updateResponse));
    return updateResponse;
}
export const deleteCommunicationData = async (templateId,templateName,recordId) => {
    const updatecommunicationresponseJson = await deleteDataOnCommunication({templateId : templateId,templateName : templateName,communicationRecordId : recordId});
    const deleteResponse = JSON.parse(updatecommunicationresponseJson);
    BwcUtils.log('delete response'+JSON.stringify(deleteResponse));
    return deleteResponse;
}