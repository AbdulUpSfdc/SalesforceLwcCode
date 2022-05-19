public with sharing class BWC_CommunicationTemplateController {
    //This Method Retrives the Communication Template Record on load of the page
    @AuraEnabled
    public static List<Communication_Template_Mapping__c> getCommunication(string communicationRecordId){
        return BWC_CommunicationTemplateService.getCommunicationRecord(communicationRecordId);
    }

    //This Method Updates the Communication Template Record with the Selected Email Template
    @AuraEnabled
    public static String updateDataOnCommunication(String templateId, string templateName, string communicationRecordId){
        CommunicationResponseWrapper responseWrapper = new CommunicationResponseWrapper();
        
        String tempId= String.isNotEmpty(templateId) ? templateId : null;
        String tempName= String.isNotEmpty(templateName) ? templateName : null;
        
        try{
            BWC_CommunicationTemplateService.updateCommRecord(tempId,tempName,communicationRecordId);
            responseWrapper.success = true;
        }catch(System.Exception e){
            responseWrapper.success = false;
            responseWrapper.message = e.getMessage();
            throw BWC_Controller.handleException(e);
        }
        return responseWrapper.serialize();
    }
	////This Method Updates the Communication Template Record with the Selected SMS Template
    @AuraEnabled
    public static String deleteDataOnCommunication(String templateId, string templateName, string communicationRecordId){
        CommunicationResponseWrapper responseWrapper = new CommunicationResponseWrapper();
        
        String tempId= String.isNotEmpty(templateId) ? templateId : null;
        String tempName= String.isNotEmpty(templateName) ? templateName : null;
        
        try{
            BWC_CommunicationTemplateService.deleteCommRecord(tempId,tempName,communicationRecordId);
            responseWrapper.success = true;
        }catch(System.Exception e){
            responseWrapper.success = false;
            responseWrapper.message = e.getMessage();
            throw BWC_Controller.handleException(e);
        }
        return responseWrapper.serialize();
    }
    public class CommunicationResponseWrapper extends BWC_ResponseWrapper {
        public List<Communication_Template_Mapping__c> communications;
    }
}